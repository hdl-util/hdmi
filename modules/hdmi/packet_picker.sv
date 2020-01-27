module packet_picker
#(
    parameter VIDEO_ID_CODE = 1,
    parameter VIDEO_RATE = 0,
    parameter BIT_WIDTH = 12,
    parameter BIT_HEIGHT = 11,
    parameter AUDIO_BIT_WIDTH = 16,
    parameter AUDIO_RATE = 32000
)
(
    input logic clk_pixel,
    input logic clk_audio,
    input logic packet_enable,
    input logic data_island_period,
    input logic [4:0] packet_pixel_counter,
    input logic [BIT_WIDTH-1:0] cx,
    input logic [BIT_HEIGHT-1:0] cy,
    input logic [AUDIO_BIT_WIDTH-1:0] audio_sample_word [1:0],
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);

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
localparam SAMPLING_FREQUENCY = AUDIO_RATE == 32000 ? 4'b0011
    : AUDIO_RATE == 44100 ? 4'b0000
    : AUDIO_RATE == 88200 ? 4'b1000
    : AUDIO_RATE == 176400 ? 4'b1100
    : AUDIO_RATE == 48000 ? 4'b0010
    : AUDIO_RATE == 96000 ? 4'b1010
    : AUDIO_RATE == 192000 ? 4'b1110
    : 4'bXXXX;

// See Section 7.2.3. Values taken from "Other" row in Tables 7-1, 7-2, 7-3.
localparam n = AUDIO_RATE % 125 == 0 ? 20'(16 * AUDIO_RATE / 125) : AUDIO_RATE % 225 == 0 ? 20'(196 * AUDIO_RATE / 225) : 20'(AUDIO_RATE * 16 / 125);
logic [19:0] cts;
audio_clock_regeneration_packet audio_clock_regeneration_packet (.n(n), .cts(cts), .header(headers[1]), .sub(subs[1]));

// Audio Sample packet
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
always @(posedge clk_pixel)
begin
    if (data_island_period && packet_pixel_counter == 5'd31 && packet_type == 8'h02) // Keep track of current IEC 60958 frame
    begin
        if (audio_sample_word_present_packet == 4'b0001)
            frame_counter <= frame_counter == 8'd191 ? 8'd0 : frame_counter + 3'd1;
        else if (audio_sample_word_present_packet[3:1] == 3'b001)
            frame_counter <= frame_counter >= 8'd190 ? 8'(frame_counter + 2 - 192) : frame_counter + 3'd2;
        else if (audio_sample_word_present_packet[3:2] == 2'b01)
            frame_counter <= frame_counter >= 8'd189 ? 8'(frame_counter + 3 - 192) : frame_counter + 3'd3;
        else if (audio_sample_word_present_packet[3] == 1'b1)
            frame_counter <= frame_counter >= 8'd188 ? 8'(frame_counter + 4 - 192) : frame_counter + 3'd4;
    end
end
audio_sample_packet #(.SAMPLING_FREQUENCY(SAMPLING_FREQUENCY), .WORD_LENGTH({{WORD_LENGTH[0], WORD_LENGTH[1], WORD_LENGTH[2]}, WORD_LENGTH_LIMIT})) audio_sample_packet (.frame_counter(frame_counter), .valid_bit('{2'b00, 2'b00, 2'b00, 2'b00}), .user_data_bit('{2'b00, 2'b00, 2'b00, 2'b00}), .audio_sample_word(audio_sample_word_packet), .audio_sample_word_present(audio_sample_word_present_packet), .header(headers[2]), .sub(subs[2]));

auxiliary_video_information_info_frame #(.VIDEO_ID_CODE(7'(VIDEO_ID_CODE))) auxiliary_video_information_info_frame(.header(headers[130]), .sub(subs[130]));

audio_info_frame audio_info_frame(.header(headers[132]), .sub(subs[132]));

logic audio_info_frame_sent = 1'b0;
logic audio_clock_regeneration_sent = 1'b1;

localparam SLOWCLK_WIDTH = $clog2(n / 128);
localparam SLOWCLK_END = SLOWCLK_WIDTH'(n / 128);
logic [SLOWCLK_WIDTH-1:0] slowclk_counter = SLOWCLK_WIDTH'(1);
logic wrap = 1'b0;
logic last_wrap = 1'b0;
always @(posedge clk_audio)
begin
    slowclk_counter <= slowclk_counter == SLOWCLK_END ? SLOWCLK_WIDTH'(0) : slowclk_counter + SLOWCLK_WIDTH'(1);
    if (slowclk_counter == SLOWCLK_END)
        wrap <= wrap + 1'b1;
end

logic [19:0] cts_counter = 20'd0;
always @(posedge clk_pixel)
begin
    if (audio_buffer_rst)
        audio_buffer_rst <= 1'b0;

    if (cx == 0 && cy == 0)
        audio_info_frame_sent <= 1'b0;

    if (packet_enable)
    begin
        if (samples_remaining != 4'd0)
        begin
            packet_type <= 8'd2;
            audio_sample_word_packet <= audio_sample_word_buffer_padded;
            audio_sample_word_present_packet <= {samples_remaining >= 3'd4, samples_remaining >= 3'd3, samples_remaining >= 3'd2, samples_remaining >= 3'd1};
            audio_buffer_rst <= 1'b1;
        end
        else if (wrap != last_wrap)
        begin
            packet_type <= 8'd1;
            // cts <= 20'd27000;
            // if (cts != cts_counter)
            //     cts <= cts_counter;
            // else
            cts <= cts_counter;
            audio_clock_regeneration_sent <= 1'b1;
            last_wrap <= wrap;
        end
        else if (!audio_info_frame_sent)
        begin
            packet_type <= 8'h84;
            audio_info_frame_sent <= 1'b1;
        end
        else
            packet_type <= 8'd0;

        cts_counter <= (samples_remaining == 4'd0 && wrap != last_wrap) ? 20'd0 : cts_counter + 1'd1;
    end
end

endmodule
