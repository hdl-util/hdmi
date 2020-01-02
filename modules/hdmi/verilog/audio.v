// L-PCM or IEC 61937 in IEC 60958 frames
module audio_sample_packet (
    
);

// 0 = LPCM, 1 = IEC 61937 compressed
parameter SAMPLE_WORD_TYPE = 1'b0;

// 0 = asserted, 1 = not asserted
parameter COPYRIGHT_ASSERTED = 1'b1;

// 000 = no pre-emphasis, 100 = 50μs/15μs pre-emphasis
parameter PRE_EMPHASIS = 3'b000;

// Only valid value
parameter MODE = 2'b00;

// Set to all 0s for general device.
parameter CATEGORY_CODE = 8'd0;

// Not really sure what this is
parameter SOURCE_NUMBER = 4'b0000;

// Left or right channel for stereo audio
parameter CHANNEL_NUMBER = 4'b1000;

// 0000 = 44.1 kHz
parameter SAMPLING_FREQUENCY = 4'b000;

// Normal accuracy: +/- 1000 * 10E-6 (00), High accuracy +/- 50 * 10E-6 (10)
parameter CLOCK_ACCURACY = 2'b00;

// Maxmium length of 20 bits (0) or 24 bits (1) followed by a 3-bit representation of the number of bits to subtract (except 101 is actually subtract 0)
parameter WORD_LENGTH = 4'b0100;

// Frequency prior to conversion in a consumer playback system. 0000 = not indicated.
parameter ORIGINAL_SAMPLING_FREQUENCY = 4'b0000;

// Implements consumer grade IEC 60958-3
reg [191:0] channel_status = {1'b0, SAMPLE_WORD_TYPE, COPYRIGHT_ASSERTED, PRE_EMPHASIS, MODE, CATEGORY_CODE, SOURCE_NUMBER, CHANNEL_NUMBER, SAMPLING_FREQUENCY, CLOCK_ACCURACY, 2'b00, WORD_LENGTH, ORIGINAL_SAMPLING_FREQUENCY, 152'd0};

// See IEC 60958-1 4.4 and Annex A.
// A value of 0 indicates the signal is suitable for decoding to an analog audio signal.
wire valid_bit = 1'b0;

// See IEC 60958-3 6.2. Not in use, so a default of 0 is suitable.
wire user_data_bit = 1'b0;



endmodule