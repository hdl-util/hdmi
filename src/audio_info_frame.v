module audio_info_frame (
	header,
	sub
);
	parameter [2:0] AUDIO_CHANNEL_COUNT = 3'd1;
	parameter [7:0] CHANNEL_ALLOCATION = 8'h00;
	parameter [0:0] DOWN_MIX_INHIBITED = 1'b0;
	parameter [3:0] LEVEL_SHIFT_VALUE = 4'd0;
	parameter [1:0] LOW_FREQUENCY_EFFECTS_PLAYBACK_LEVEL = 2'b00;
	output wire [23:0] header;
	output wire [223:0] sub;
	localparam [3:0] AUDIO_CODING_TYPE = 4'd0;
	localparam [2:0] SAMPLING_FREQUENCY = 3'd0;
	localparam [1:0] SAMPLE_SIZE = 2'd0;
	localparam [4:0] LENGTH = 5'd10;
	localparam [7:0] VERSION = 8'd1;
	localparam [6:0] TYPE = 7'd4;
	assign header = {{3'b000, LENGTH}, VERSION, {1'b1, TYPE}};
	wire [7:0] packet_bytes [27:0];
	assign packet_bytes[0] = 8'd1 + ~(((((((header[23:16] + header[15:8]) + header[7:0]) + packet_bytes[5]) + packet_bytes[4]) + packet_bytes[3]) + packet_bytes[2]) + packet_bytes[1]);
	assign packet_bytes[1] = {AUDIO_CODING_TYPE, 1'b0, AUDIO_CHANNEL_COUNT};
	assign packet_bytes[2] = {3'd0, SAMPLING_FREQUENCY, SAMPLE_SIZE};
	assign packet_bytes[3] = 8'd0;
	assign packet_bytes[4] = CHANNEL_ALLOCATION;
	assign packet_bytes[5] = {DOWN_MIX_INHIBITED, LEVEL_SHIFT_VALUE, 1'b0, LOW_FREQUENCY_EFFECTS_PLAYBACK_LEVEL};
	genvar i;
	generate
		for (i = 6; i < 28; i = i + 1) begin : pb_reserved
			assign packet_bytes[i] = 8'd0;
		end
		for (i = 0; i < 4; i = i + 1) begin : pb_to_sub
			assign sub[i * 56+:56] = {packet_bytes[6 + (i * 7)], packet_bytes[5 + (i * 7)], packet_bytes[4 + (i * 7)], packet_bytes[3 + (i * 7)], packet_bytes[2 + (i * 7)], packet_bytes[1 + (i * 7)], packet_bytes[i * 7]};
		end
	endgenerate
endmodule
