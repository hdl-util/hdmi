// Implementation of HDMI packet choice logic.
// By Sameer Puri https://github.com/sameer

module packet_picker
#(
    parameter VIDEO_ID_CODE,
    parameter VIDEO_RATE,
    parameter AUDIO_BIT_WIDTH,
    parameter AUDIO_RATE
)
(
    input logic clk_pixel,
    input logic clk_audio,
    input logic video_field_end,
    input logic packet_enable,
    input logic [4:0] packet_pixel_counter,
    input logic [AUDIO_BIT_WIDTH-1:0] audio_sample_word [1:0],
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);

// Connect the current packet type's data to the output.
logic [7:0] packet_type = 8'd0;
logic [23:0] headers [255:0];
logic [55:0] subs [255:0] [3:0];
assign header = headers[packet_type];
assign sub = subs[packet_type];

// NULL packet
// "An HDMI Sink shall ignore bytes HB1 and HB2 of the Null Packet Header and all bytes of the Null Packet Body."
`ifdef MODEL_TECH
assign headers[0] = {8'd0, 8'd0, 8'd0}; assign subs[0] = '{56'd0, 56'd0, 56'd0, 56'd0};
`else
assign headers[0] = {8'dX, 8'dX, 8'd0}; assign subs[0] = '{56'dX, 56'dX, 56'dX, 56'dX};
`endif

// Audio Clock Regeneration Packet
logic clk_slow_wrap;
audio_clock_regeneration_packet #(.VIDEO_RATE(VIDEO_RATE), .AUDIO_RATE(AUDIO_RATE)) audio_clock_regeneration_packet (.clk_pixel(clk_pixel), .clk_audio(clk_audio), .clk_slow_wrap(clk_slow_wrap), .header(headers[1]), .sub(subs[1]));

// Audio Sample packet
localparam SAMPLING_FREQUENCY = AUDIO_RATE == 32000 ? 4'b0011
    : AUDIO_RATE == 44100 ? 4'b0000
    : AUDIO_RATE == 88200 ? 4'b1000
    : AUDIO_RATE == 176400 ? 4'b1100
    : AUDIO_RATE == 48000 ? 4'b0010
    : AUDIO_RATE == 96000 ? 4'b1010
    : AUDIO_RATE == 192000 ? 4'b1110
    : 4'bXXXX;
localparam AUDIO_BIT_WIDTH_COMPARATOR = AUDIO_BIT_WIDTH < 20 ? 20 : AUDIO_BIT_WIDTH == 20 ? 25 : AUDIO_BIT_WIDTH < 24 ? 24 : AUDIO_BIT_WIDTH == 24 ? 29 : -1;
localparam WORD_LENGTH = 3'(AUDIO_BIT_WIDTH_COMPARATOR - AUDIO_BIT_WIDTH);
localparam WORD_LENGTH_LIMIT = AUDIO_BIT_WIDTH <= 20 ? 1'b0 : 1'b1;

localparam MAX_SAMPLES_PER_PACKET = AUDIO_RATE <= 48000 ? 2 : AUDIO_RATE <= 88200 ? 3 : 4;
logic [(MAX_SAMPLES_PER_PACKET == 4 ? 2 : 1):0] samples_remaining = 1'd0;
logic [AUDIO_BIT_WIDTH-1:0] audio_sample_word_buffer [MAX_SAMPLES_PER_PACKET-1:0] [1:0];
logic audio_buffer_rst = 1'b0;
always @(posedge clk_audio or posedge audio_buffer_rst)
begin
    if (audio_buffer_rst)
        samples_remaining <= 1'd0;
    else
    begin
        audio_sample_word_buffer[samples_remaining] <= audio_sample_word;
        samples_remaining <= samples_remaining + 1'd1;
    end
end

logic [23:0] audio_sample_word_buffer_padded [3:0] [1:0];
genvar i;
genvar j;
generate
    for (i = 0; i < 4; i++)
    begin: outer_pad
        for (j = 0; j < 2; j++)
        begin: inner_pad
            if (MAX_SAMPLES_PER_PACKET >= i + 1)
                assign audio_sample_word_buffer_padded[i][j] = {(24-AUDIO_BIT_WIDTH)'(0), audio_sample_word_buffer[i][j]};
            `ifdef MODEL_TECH
            else
                assign audio_sample_word_buffer_padded[i][j] = 24'd0;
            `else
            else
                assign audio_sample_word_buffer_padded[i][j] = 24'dX;
            `endif
        end
    end
endgenerate

logic [23:0] audio_sample_word_packet [3:0] [1:0];
logic [3:0] audio_sample_word_present_packet;

logic [7:0] frame_counter = 8'd0;
integer k;
always @(posedge clk_pixel)
begin
    if (packet_pixel_counter == 5'd31 && packet_type == 8'h02) // Keep track of current IEC 60958 frame
    begin
        for (k = 0; k < MAX_SAMPLES_PER_PACKET; k++)
            frame_counter = frame_counter + audio_sample_word_present_packet[k];
        if (frame_counter >= 8'd192)
            frame_counter = frame_counter - 8'd192;
    end
end
audio_sample_packet #(.SAMPLING_FREQUENCY(SAMPLING_FREQUENCY), .WORD_LENGTH({{WORD_LENGTH[0], WORD_LENGTH[1], WORD_LENGTH[2]}, WORD_LENGTH_LIMIT})) audio_sample_packet (.frame_counter(frame_counter), .valid_bit('{2'b00, 2'b00, 2'b00, 2'b00}), .user_data_bit('{2'b00, 2'b00, 2'b00, 2'b00}), .audio_sample_word(audio_sample_word_packet), .audio_sample_word_present(audio_sample_word_present_packet), .header(headers[2]), .sub(subs[2]));


auxiliary_video_information_info_frame #(.VIDEO_ID_CODE(7'(VIDEO_ID_CODE))) auxiliary_video_information_info_frame(.header(headers[130]), .sub(subs[130]));


source_product_description_info_frame source_product_description_info_frame(.header(headers[131]), .sub(subs[131]));


audio_info_frame audio_info_frame(.header(headers[132]), .sub(subs[132]));


// "A Source shall always transmit... [an InfoFrame] at least once per two Video Fields"
logic audio_info_frame_sent = 1'b0;
logic auxiliary_video_information_info_frame_sent = 1'b0;
logic source_product_description_info_frame_sent = 1'b0;
logic last_clk_slow_wrap = 1'b0;
always @(posedge clk_pixel)
begin
    if (audio_buffer_rst)
        audio_buffer_rst <= 1'b0;

    if (video_field_end)
    begin
        audio_info_frame_sent <= 1'b0;
        auxiliary_video_information_info_frame_sent <= 1'b0;
        source_product_description_info_frame_sent <= 1'b0;
    end

    if (packet_enable)
    begin
        if (samples_remaining != 4'd0)
        begin
            packet_type <= 8'd2;
            audio_sample_word_packet <= audio_sample_word_buffer_padded;
            audio_sample_word_present_packet <= {samples_remaining >= 3'd4, samples_remaining >= 3'd3, samples_remaining >= 3'd2, samples_remaining >= 3'd1};
            audio_buffer_rst <= 1'b1;
        end
        else if (last_clk_slow_wrap != clk_slow_wrap)
        begin
            packet_type <= 8'd1;
            last_clk_slow_wrap <= clk_slow_wrap;
        end
        else if (!audio_info_frame_sent)
        begin
            packet_type <= 8'h84;
            audio_info_frame_sent <= 1'b1;
        end
        else if (!auxiliary_video_information_info_frame_sent)
        begin
            packet_type <= 8'h82;
            auxiliary_video_information_info_frame_sent <= 1'b1;
        end
        else if (!source_product_description_info_frame_sent)
        begin
            packet_type <= 8'h83;
            source_product_description_info_frame_sent <= 1'b1;
        end
        else
            packet_type <= 8'd0;
    end
end

endmodule
