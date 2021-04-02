module auxiliary_video_information_info_frame (
	header,
	sub
);
	parameter [1:0] VIDEO_FORMAT = 2'b00;
	parameter [0:0] ACTIVE_FORMAT_INFO_PRESENT = 1'b0;
	parameter [1:0] BAR_INFO = 2'b00;
	parameter [1:0] SCAN_INFO = 2'b00;
	parameter [1:0] COLORIMETRY = 2'b00;
	parameter [1:0] PICTURE_ASPECT_RATIO = 2'b00;
	parameter [3:0] ACTIVE_FORMAT_ASPECT_RATIO = 4'b1000;
	parameter [0:0] IT_CONTENT = 1'b0;
	parameter [2:0] EXTENDED_COLORIMETRY = 3'b000;
	parameter [1:0] RGB_QUANTIZATION_RANGE = 2'b00;
	parameter [1:0] NON_UNIFORM_PICTURE_SCALING = 2'b00;
	parameter signed [31:0] VIDEO_ID_CODE = 4;
	parameter [1:0] YCC_QUANTIZATION_RANGE = 2'b00;
	parameter [1:0] CONTENT_TYPE = 2'b00;
	parameter [3:0] PIXEL_REPETITION = 4'b0000;
	output wire [23:0] header;
	output wire [223:0] sub;
	localparam [4:0] LENGTH = 5'd13;
	localparam [7:0] VERSION = 8'd2;
	localparam [6:0] TYPE = 7'd2;
	assign header = {{3'b000, LENGTH}, VERSION, {1'b1, TYPE}};
	wire [7:0] packet_bytes [27:0];
	assign packet_bytes[0] = 8'd1 + ~(((((((((((((((header[23:16] + header[15:8]) + header[7:0]) + packet_bytes[13]) + packet_bytes[12]) + packet_bytes[11]) + packet_bytes[10]) + packet_bytes[9]) + packet_bytes[8]) + packet_bytes[7]) + packet_bytes[6]) + packet_bytes[5]) + packet_bytes[4]) + packet_bytes[3]) + packet_bytes[2]) + packet_bytes[1]);
	assign packet_bytes[1] = {1'b0, VIDEO_FORMAT, ACTIVE_FORMAT_INFO_PRESENT, BAR_INFO, SCAN_INFO};
	assign packet_bytes[2] = {COLORIMETRY, PICTURE_ASPECT_RATIO, ACTIVE_FORMAT_ASPECT_RATIO};
	assign packet_bytes[3] = {IT_CONTENT, EXTENDED_COLORIMETRY, RGB_QUANTIZATION_RANGE, NON_UNIFORM_PICTURE_SCALING};
	function automatic signed [6:0] sv2v_cast_7_signed;
		input reg signed [6:0] inp;
		sv2v_cast_7_signed = inp;
	endfunction
	assign packet_bytes[4] = {1'b0, sv2v_cast_7_signed(VIDEO_ID_CODE)};
	assign packet_bytes[5] = {YCC_QUANTIZATION_RANGE, CONTENT_TYPE, PIXEL_REPETITION};
	genvar i;
	generate
		if (BAR_INFO != 2'b00) begin
			assign packet_bytes[6] = 8'hff;
			assign packet_bytes[7] = 8'hff;
			assign packet_bytes[8] = 8'h00;
			assign packet_bytes[9] = 8'h00;
			assign packet_bytes[10] = 8'hff;
			assign packet_bytes[11] = 8'hff;
			assign packet_bytes[12] = 8'h00;
			assign packet_bytes[13] = 8'h00;
		end
		else begin
			assign packet_bytes[6] = 8'h00;
			assign packet_bytes[7] = 8'h00;
			assign packet_bytes[8] = 8'h00;
			assign packet_bytes[9] = 8'h00;
			assign packet_bytes[10] = 8'h00;
			assign packet_bytes[11] = 8'h00;
			assign packet_bytes[12] = 8'h00;
			assign packet_bytes[13] = 8'h00;
		end
		for (i = 14; i < 28; i = i + 1) begin : pb_reserved
			assign packet_bytes[i] = 8'd0;
		end
		for (i = 0; i < 4; i = i + 1) begin : pb_to_sub
			assign sub[i * 56+:56] = {packet_bytes[6 + (i * 7)], packet_bytes[5 + (i * 7)], packet_bytes[4 + (i * 7)], packet_bytes[3 + (i * 7)], packet_bytes[2 + (i * 7)], packet_bytes[1 + (i * 7)], packet_bytes[i * 7]};
		end
	endgenerate
endmodule
