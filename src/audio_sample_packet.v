module audio_sample_packet (
	frame_counter,
	valid_bit,
	user_data_bit,
	audio_sample_word,
	audio_sample_word_present,
	header,
	sub
);
	parameter [0:0] GRADE = 1'b0;
	parameter [0:0] SAMPLE_WORD_TYPE = 1'b0;
	parameter [0:0] COPYRIGHT_NOT_ASSERTED = 1'b1;
	parameter [2:0] PRE_EMPHASIS = 3'b000;
	parameter [1:0] MODE = 2'b00;
	parameter [7:0] CATEGORY_CODE = 8'd0;
	parameter [3:0] SOURCE_NUMBER = 4'd0;
	parameter [3:0] SAMPLING_FREQUENCY = 4'b0000;
	parameter [1:0] CLOCK_ACCURACY = 2'b00;
	parameter [3:0] WORD_LENGTH = 0;
	parameter [3:0] ORIGINAL_SAMPLING_FREQUENCY = 4'b0000;
	parameter [0:0] LAYOUT = 1'b0;
	input wire [7:0] frame_counter;
	input wire [7:0] valid_bit;
	input wire [7:0] user_data_bit;
	input wire [191:0] audio_sample_word;
	input wire [3:0] audio_sample_word_present;
	output wire [23:0] header;
	output reg [223:0] sub;
	wire [3:0] CHANNEL_LEFT = 4'd1;
	wire [3:0] CHANNEL_RIGHT = 4'd2;
	localparam [7:0] CHANNEL_STATUS_LENGTH = 8'd192;
	wire [191:0] channel_status_left;
	assign channel_status_left = {152'd0, ORIGINAL_SAMPLING_FREQUENCY, WORD_LENGTH, 2'b00, CLOCK_ACCURACY, SAMPLING_FREQUENCY, CHANNEL_LEFT, SOURCE_NUMBER, CATEGORY_CODE, MODE, PRE_EMPHASIS, COPYRIGHT_NOT_ASSERTED, SAMPLE_WORD_TYPE, GRADE};
	wire [CHANNEL_STATUS_LENGTH - 1:0] channel_status_right;
	assign channel_status_right = {152'd0, ORIGINAL_SAMPLING_FREQUENCY, WORD_LENGTH, 2'b00, CLOCK_ACCURACY, SAMPLING_FREQUENCY, CHANNEL_RIGHT, SOURCE_NUMBER, CATEGORY_CODE, MODE, PRE_EMPHASIS, COPYRIGHT_NOT_ASSERTED, SAMPLE_WORD_TYPE, GRADE};
	assign header[19:12] = {4'b0000, {3'b000, LAYOUT}};
	assign header[7:0] = 8'd2;
	wire [1:0] parity_bit [3:0];
	reg [7:0] aligned_frame_counter [3:0];
	function automatic [7:0] sv2v_cast_8;
		input reg [7:0] inp;
		sv2v_cast_8 = inp;
	endfunction
	genvar i;
	generate
		for (i = 0; i < 4; i = i + 1) begin : sample_based_assign
			always @(*)
				if (sv2v_cast_8(frame_counter + i) >= CHANNEL_STATUS_LENGTH)
					aligned_frame_counter[i] = sv2v_cast_8((frame_counter + i) - CHANNEL_STATUS_LENGTH);
				else
					aligned_frame_counter[i] = sv2v_cast_8(frame_counter + i);
			assign header[20 + i] = (aligned_frame_counter[i] == 8'd0) && audio_sample_word_present[i];
			assign header[8 + i] = audio_sample_word_present[i];
			assign parity_bit[i][0] = ^{channel_status_left[aligned_frame_counter[i]], user_data_bit[i * 2], valid_bit[i * 2], audio_sample_word[(i * 2) * 24+:24]};
			assign parity_bit[i][1] = ^{channel_status_right[aligned_frame_counter[i]], user_data_bit[(i * 2) + 1], valid_bit[(i * 2) + 1], audio_sample_word[((i * 2) + 1) * 24+:24]};
			always @(*)
				if (audio_sample_word_present[i])
					sub[i * 56+:56] = {{parity_bit[i][1], channel_status_right[aligned_frame_counter[i]], user_data_bit[(i * 2) + 1], valid_bit[(i * 2) + 1], parity_bit[i][0], channel_status_left[aligned_frame_counter[i]], user_data_bit[i * 2], valid_bit[i * 2]}, audio_sample_word[((i * 2) + 1) * 24+:24], audio_sample_word[(i * 2) * 24+:24]};
				else
					sub[i * 56+:56] = 56'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
		end
	endgenerate
endmodule
