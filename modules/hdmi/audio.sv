// Implementation of HDMI audio-related packets
// By Sameer Puri https://github.com/sameer

// See HDMI 1.4a Section 5.3.3.
module audio_clock_regeneration_packet
(
    input logic [19:0] n,
    input logic [19:0] cts,
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);

logic [19:0] N, CTS;
assign N = n;
assign CTS = cts;

// "An HDMI Sink shall ignore bytes HB1 and HB2 of the Audio Clock Regeneration Packet header."
`ifdef MODEL_TECH
assign header = {8'd0, 8'd0, 8'd1};
`else
assign header = {8'dX, 8'dX, 8'd1};
`endif
// "The four Subpackets each contain the same Audio Clock regeneration Subpacket."
genvar i;
generate
    for (i = 0; i < 4; i++)
    begin: same_packet
        assign sub[i] = {N[7:0], N[15:8], {4'd0, N[19:16]}, CTS[7:0], CTS[15:8], {4'd0, CTS[19:16]}, 8'd0};
    end
endgenerate

endmodule

// See Section 5.3.4.
// 2-channel L-PCM or IEC 61937 audio in IEC 60958 frames with consumer grade IEC 60958-3.
module audio_sample_packet 
#(
    // A thorough explanation of the below parameters can be found in IEC 60958-3 5.2, 5.3.

    // 0 = Consumer, 1 = Professional
    parameter GRADE = 1'b0,

    // 0 = LPCM, 1 = IEC 61937 compressed
    parameter SAMPLE_WORD_TYPE = 1'b0,

    // 0 = asserted, 1 = not asserted
    parameter COPYRIGHT_NOT_ASSERTED = 1'b1,

    // 000 = no pre-emphasis, 001 = 50μs/15μs pre-emphasis
    parameter PRE_EMPHASIS = 3'b000,

    // Only one valid value
    parameter MODE = 2'b00,

    // Set to all 0s for general device.
    parameter CATEGORY_CODE = 8'd0,

    // TODO: not really sure what this is...
    // 0 = "Do no take into account"
    parameter SOURCE_NUMBER = 4'd0,

    // 0000 = 44.1 kHz
    parameter SAMPLING_FREQUENCY = 4'b0000,

    // Normal accuracy: +/- 1000 * 10E-6 (00), High accuracy +/- 50 * 10E-6 (01)
    parameter CLOCK_ACCURACY = 2'b00,

    // 3-bit representation of the number of bits to subtract (except 101 is actually subtract 0) with LSB first, followed by maxmium length of 20 bits (0) or 24 bits (1)
    parameter WORD_LENGTH = 4'b0010,

    // Frequency prior to conversion in a consumer playback system. 0000 = not indicated.
    parameter ORIGINAL_SAMPLING_FREQUENCY = 4'b0000,

    // 2-channel = 0, >= 3-channel = 1
    parameter LAYOUT = 1'b0

)
(
    input logic [7:0] frame_counter,
    // See IEC 60958-1 4.4 and Annex A. 0 indicates the signal is suitable for decoding to an analog audio signal.
    input logic [1:0] valid_bit [3:0],
    // See IEC 60958-3 Section 6. 0 indicates that no user data is being sent
    input logic [1:0] user_data_bit [3:0],
    input logic [23:0] audio_sample_word [3:0] [1:0],
    input logic [3:0] audio_sample_word_present,
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);

// Left/right channel for stereo audio
logic [3:0] CHANNEL_LEFT = 4'd1;
logic [3:0] CHANNEL_RIGHT = 4'd2;

localparam CHANNEL_STATUS_LENGTH = 8'd192;
// See IEC 60958-1 5.1, Table 2
wire [CHANNEL_STATUS_LENGTH-1:0] channel_status_left = {152'd0, ORIGINAL_SAMPLING_FREQUENCY, WORD_LENGTH, 2'b00, CLOCK_ACCURACY, SAMPLING_FREQUENCY, CHANNEL_LEFT, SOURCE_NUMBER, CATEGORY_CODE, MODE, PRE_EMPHASIS, COPYRIGHT_NOT_ASSERTED, SAMPLE_WORD_TYPE, GRADE};
wire [CHANNEL_STATUS_LENGTH-1:0] channel_status_right = {152'd0, ORIGINAL_SAMPLING_FREQUENCY, WORD_LENGTH, 2'b00, CLOCK_ACCURACY, SAMPLING_FREQUENCY, CHANNEL_RIGHT, SOURCE_NUMBER, CATEGORY_CODE, MODE, PRE_EMPHASIS, COPYRIGHT_NOT_ASSERTED, SAMPLE_WORD_TYPE, GRADE};


// See HDMI 1.4a Table 5-12: Audio Sample Packet Header.
assign header[19:12] = {4'b0000, {3'b000, LAYOUT}};
assign header[7:0] = 8'd2;
logic [1:0] parity_bit [3:0];
logic [7:0] aligned_frame_counter [3:0];
genvar i;
generate
    for (i = 0; i < 4; i++)
    begin: sample_based_assign
        assign aligned_frame_counter[i] = 8'(frame_counter + i) >= 8'd192 ? 8'(frame_counter + i - 192) : 8'(frame_counter + i);
        assign header[23 - (3-i)] = aligned_frame_counter[i] == 8'd0 && audio_sample_word_present[i];
        assign header[11 - (3-i)] = audio_sample_word_present[i];
        assign parity_bit[i][0] = ^{channel_status_left[aligned_frame_counter[i]], user_data_bit[i][0], valid_bit[i][0], audio_sample_word[i][0]};
        assign parity_bit[i][1] = ^{channel_status_right[aligned_frame_counter[i]], user_data_bit[i][1], valid_bit[i][1], audio_sample_word[i][1]};
        // See HDMI 1.4a Table 5-13: Audio Sample Subpacket.
        `ifdef MODEL_TECH
        assign sub[i] = !audio_sample_word_present[i] ? 56'd0 : {{parity_bit[i][1], channel_status_right[aligned_frame_counter[i]], user_data_bit[i][1], valid_bit[i][1], parity_bit[i][0], channel_status_left[aligned_frame_counter[i]], user_data_bit[i][0], valid_bit[i][0]}, audio_sample_word[i][1], audio_sample_word[i][0]};
        `else
        assign sub[i] = !audio_sample_word_present[i] ? 56'dX : {{parity_bit[i][1], channel_status_right[aligned_frame_counter[i]], user_data_bit[i][1], valid_bit[i][1], parity_bit[i][0], channel_status_left[aligned_frame_counter[i]], user_data_bit[i][0], valid_bit[i][0]}, audio_sample_word[i][1], audio_sample_word[i][0]};
        `endif
    end
endgenerate

endmodule

// See Section 8.2.2
module audio_info_frame
#(
    parameter AUDIO_CHANNEL_COUNT = 3'd1, // 2 channels. See CEA-861-D table 17 for details.
    parameter CHANNEL_ALLOCATION = 8'h00, // Channel 0 = Front Left, Channel 1 = Front Right (0-indexed)
    parameter DOWN_MIX_INHIBITED = 1'b0, // Permitted or no information about any assertion of this. The DM_INH field is to be set only for DVD-Audio applications.
    parameter LEVEL_SHIFT_VALUE = 4'd0, // 4-bit unsigned number from 0dB up to 15dB, used for downmixing.
    parameter LOW_FREQUENCY_EFFECTS_PLAYBACK_LEVEL = 2'b00 // No information, LFE = bass-only info < 120Hz, used in Dolby Surround.
)
(
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);

// NOTE—HDMI requires the coding type, sample size and sample frequency fields to be set to 0 ("Refer to Stream Header") as these items are carried in the audio stream
localparam AUDIO_CODING_TYPE = 4'd0; // Refer to stream header.
localparam SAMPLING_FREQUENCY = 3'd0; // Refer to stream header.
localparam SAMPLE_SIZE = 2'd0; // Refer to stream header.

localparam LENGTH = 5'd10;
localparam VERSION = 8'd1;
localparam TYPE = 7'd4;

assign header = {{3'b0, LENGTH}, VERSION, {1'b1, TYPE}};

// PB0-PB6 = sub0
// PB7-13 =  sub1
// PB14-20 = sub2
// PB21-27 = sub3
logic [7:0] pb [27:0];

assign pb[0] = ~(header[23:16] + header[15:8] + header[7:0] + pb[5] + pb[4] + pb[3] + pb[2] + pb[1]);
assign pb[1] = {AUDIO_CODING_TYPE, 1'b0, AUDIO_CHANNEL_COUNT};
assign pb[2] = {3'd0, SAMPLING_FREQUENCY, SAMPLE_SIZE};
assign pb[3] = 8'd0;
assign pb[4] = CHANNEL_ALLOCATION;
assign pb[5] = {DOWN_MIX_INHIBITED, LEVEL_SHIFT_VALUE, 1'b0, LOW_FREQUENCY_EFFECTS_PLAYBACK_LEVEL};

genvar i;
generate
    for (i = 6; i < 28; i++)
    begin: pb_reserved
        assign pb[i] = 8'd0;
    end
    for (i = 0; i < 4; i++)
    begin: pb_to_sub
        assign sub[i] = {pb[6 + i*7], pb[5 + i*7], pb[4 + i*7], pb[3 + i*7], pb[2 + i*7], pb[1 + i*7], pb[0 + i*7]};
    end
endgenerate
endmodule
