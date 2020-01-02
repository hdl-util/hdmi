// 2-channel L-PCM or IEC 61937 audio in IEC 60958 frames with consumer grade IEC 60958-3
module audio_sample_packet (
    input wire packet_clk,
    // See IEC 60958-1 4.4 and Annex A. 0 indicates the signal is suitable for decoding to an analog audio signal.
    input wire [1:0] valid_bit = 2'b00,
    // See IEC 60958-3 Section 6. 0 indicates that no user data is being sent
    input wire [1:0] user_data_bit = 2'b00,
    input wire [23:0] audio_sample_word [1:0],
    output reg [15:0] sub4,
    output reg [55:0] sub3,
    output reg [55:0] sub2,
    output reg [55:0] sub1,
    output reg [55:0] sub0,
);

// A thorough explanation of the below parameters can be found in IEC 60958-3 5.2, 5.3.

// 0 = Consumer, 1 = Professional
wire GRADE = 1'b0;

// 0 = LPCM, 1 = IEC 61937 compressed
parameter SAMPLE_WORD_TYPE = 1'b0;

// 0 = asserted, 1 = not asserted
parameter COPYRIGHT_ASSERTED = 1'b1;

// 000 = no pre-emphasis, 100 = 50μs/15μs pre-emphasis
parameter PRE_EMPHASIS = 3'b000;

// Only one valid value
parameter MODE = 2'b00;

// Set to all 0s for general device.
parameter CATEGORY_CODE = 8'd0;

// Not really sure what this is
parameter SOURCE_NUMBER = 4'b0000;

// Left or right channel for stereo audio
wire CHANNEL_LEFT = 4'b1000;
wire CHANNEL_RIGHT = 4'b0100;

// 0000 = 44.1 kHz
parameter SAMPLING_FREQUENCY = 4'b0000;

// Normal accuracy: +/- 1000 * 10E-6 (00), High accuracy +/- 50 * 10E-6 (10)
parameter CLOCK_ACCURACY = 2'b00;

// Maxmium length of 20 bits (0) or 24 bits (1) followed by a 3-bit representation of the number of bits to subtract (except 101 is actually subtract 0)
parameter WORD_LENGTH = 4'b0100;

// Frequency prior to conversion in a consumer playback system. 0000 = not indicated.
parameter ORIGINAL_SAMPLING_FREQUENCY = 4'b0000;

// 2-channel = 0, >= 3-channel = 1
wire LAYOUT = 1'b0;

// See IEC 60958-1 5.1, Table 2
wire [191:0] channel_status_left = {GRADE, SAMPLE_WORD_TYPE, COPYRIGHT_ASSERTED, PRE_EMPHASIS, MODE, CATEGORY_CODE, SOURCE_NUMBER, CHANNEL_LEFT, SAMPLING_FREQUENCY, CLOCK_ACCURACY, 2'b00, WORD_LENGTH, ORIGINAL_SAMPLING_FREQUENCY, 152'd0};
wire [191:0] channel_status_right = {GRADE, SAMPLE_WORD_TYPE, COPYRIGHT_ASSERTED, PRE_EMPHASIS, MODE, CATEGORY_CODE, SOURCE_NUMBER, CHANNEL_RIGHT, SAMPLING_FREQUENCY, CLOCK_ACCURACY, 2'b00, WORD_LENGTH, ORIGINAL_SAMPLING_FREQUENCY, 152'd0};


reg [7:0] frame_counter = 8'd0;

always @(posedge packet_clk)
begin
    frame_counter <= frame_counter == 8'd191 ? 8'd0 : frame_counter + 8'd1;
    // See HDMI 1.4a Table 5-12: Audio Sample Packet Header.
    sub4 <= {8'b00000010, {3'b000, LAYOUT, 4'b0001}, {3'b000, frame_counter == 8'd0, 4'b0000}};
    sub3 <= 56'd0;
    sub2 <= 56'd0;
    sub1 <= 56'd0;
    sub0 <= {audio_sample_word[0], audio_sample_word[1], {^{audio_sample_word[1], valid_bit[1], user_data_bit[1], channel_status_right[frame_counter]}, channel_status_right[frame_counter], user_data_bit[1], valid_bit[1]}, {^{audio_sample_word[0], valid_bit[0], user_data_bit[0], channel_status_left[frame_counter]}, channel_status_left[frame_counter], user_data_bit[0], valid_bit[0]}};
end

endmodule
