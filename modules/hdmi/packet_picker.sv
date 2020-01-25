module packet_picker
#(
    parameter VIDEO_ID_CODE = 1,
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
assign headers[0] = {8'dX, 8'dX, 8'd0}; assign subs[0] = '{56'dX, 56'dX, 56'dX, 56'dX};


localparam REGEN_WIDTH = $clog2(AUDIO_RATE/100);
logic [REGEN_WIDTH-1:0] regen_counter = 0;
always @(posedge clk_audio)
    regen_counter <= regen_counter == REGEN_WIDTH'(AUDIO_RATE/100 - 1) ? 1'd0 : regen_counter + 1'd1;

logic [19:0] cts_counter = 20'd0, cts = 20'd0;
always @(posedge clk_pixel)
    cts_counter <= regen_counter == REGEN_WIDTH'(0) ? 20'd0 : cts_counter + 1'd1;


audio_clock_regeneration_packet #(.AUDIO_RATE(AUDIO_RATE)) audio_clock_regeneration_packet (.cts(cts), .header(headers[1]), .sub(subs[1]));

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
logic [7:0] frame_counter = 8'd0;
always @(posedge clk_pixel)
    if (data_island_period && packet_pixel_counter == 5'd31 && packet_type == 8'h02) // Keep track of current IEC 60958 frame
        frame_counter <= frame_counter == 8'd191 ? 8'd0 : frame_counter + 1'b1;

logic [3:0] samples_remaining;
logic [AUDIO_BIT_WIDTH-1:0] audio_out [1:0];
audio_buffer #(.CHANNELS(2), .BIT_WIDTH(AUDIO_BIT_WIDTH), .BUFFER_SIZE(16)) audio_buffer (.clk_audio(clk_audio), .clk_pixel(clk_pixel), .packet_enable(packet_enable && samples_remaining > 3'd0), .audio_in(audio_sample_word), .audio_out(audio_out), .remaining(samples_remaining));

logic [23:0] audio_sample_word_padded [1:0];
audio_sample_packet #(.SAMPLING_FREQUENCY(SAMPLING_FREQUENCY), .WORD_LENGTH({{WORD_LENGTH[0], WORD_LENGTH[1], WORD_LENGTH[2]}, WORD_LENGTH_LIMIT})) audio_sample_packet (.frame_counter(frame_counter), .valid_bit(2'b00), .user_data_bit(2'b00), .audio_sample_word(audio_sample_word_padded), .header(headers[2]), .sub(subs[2]));

auxiliary_video_information_info_frame #(.VIDEO_ID_CODE(7'(VIDEO_ID_CODE))) auxiliary_video_information_info_frame(.header(headers[130]), .sub(subs[130]));
audio_info_frame audio_info_frame(.header(headers[132]), .sub(subs[132]));

logic audio_clock_regeneration_sent = 1'b1;
logic audio_info_frame_sent = 1'b0;
always @(posedge clk_pixel)
begin
    if (cx == 0 && cy == 0) // RESET
        audio_info_frame_sent <= 1'b0;
    if (regen_counter == REGEN_WIDTH'(0) && cts_counter != 20'd0)
    begin
        audio_clock_regeneration_sent <= 1'b0;
        cts <= cts_counter;
    end
    if (packet_enable)
    begin
        if (samples_remaining > 4'd0)
        begin
            packet_type <= 8'd2;
            audio_sample_word_padded <= '{{(24-AUDIO_BIT_WIDTH)'(0), audio_out[1]}, {(24-AUDIO_BIT_WIDTH)'(0), audio_out[0]}};
        end
        else if (!audio_clock_regeneration_sent)
        begin
            packet_type <= 8'd1;
            audio_clock_regeneration_sent <= 1'b1;
        end
        else if (!audio_info_frame_sent)
        begin
            packet_type <= 8'h84;
            audio_info_frame_sent <= 1'b1;
        end
        else
            packet_type <= 8'd0;
    end
end

endmodule
