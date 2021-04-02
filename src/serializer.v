module serializer (
	clk_pixel,
	clk_pixel_x5,
	reset,
	tmds_internal,
	tmds,
	tmds_clock
);
	parameter signed [31:0] NUM_CHANNELS = 3;
	parameter real VIDEO_RATE = 0;
	input wire clk_pixel;
	input wire clk_pixel_x5;
	input wire reset;
	input wire [(NUM_CHANNELS * 10) - 1:0] tmds_internal;
	output reg [2:0] tmds;
	output reg tmds_clock;
	wire [9:0] tmds_reversed [NUM_CHANNELS - 1:0];
	genvar i;
	genvar j;
	generate
		for (i = 0; i < NUM_CHANNELS; i = i + 1) begin : tmds_rev
			for (j = 0; j < 10; j = j + 1) begin : tmds_rev_channel
				assign tmds_reversed[i][j] = tmds_internal[(i * 10) + (9 - j)];
			end
		end
	endgenerate
	reg [(NUM_CHANNELS * 10) - 1:0] tmds_shift = 30'h00000000;
	reg tmds_control = 1'd0;
	always @(posedge clk_pixel) tmds_control <= !tmds_control;
	reg [3:0] tmds_control_synchronizer_chain = 4'd0;
	always @(posedge clk_pixel_x5) tmds_control_synchronizer_chain <= {tmds_control, tmds_control_synchronizer_chain[3:1]};
	wire load;
	assign load = tmds_control_synchronizer_chain[1] ^ tmds_control_synchronizer_chain[0];
	reg [(NUM_CHANNELS * 10) - 1:0] tmds_mux;
	always @(*)
		if (load)
			tmds_mux = tmds_internal;
		else
			tmds_mux = tmds_shift;
	generate
		for (i = 0; i < NUM_CHANNELS; i = i + 1) begin : tmds_shifting
			always @(posedge clk_pixel_x5) tmds_shift[i * 10+:10] <= (load ? tmds_mux[i * 10+:10] : tmds_shift[i * 10+:10] >> 2);
		end
	endgenerate
	reg [9:0] tmds_shift_clk_pixel = 10'b0000011111;
	always @(posedge clk_pixel_x5) tmds_shift_clk_pixel <= (load ? 10'b0000011111 : {tmds_shift_clk_pixel[1:0], tmds_shift_clk_pixel[9:2]});
	reg [NUM_CHANNELS - 1:0] tmds_shift_negedge_temp;
	generate
		for (i = 0; i < NUM_CHANNELS; i = i + 1) begin : tmds_driving
			always @(posedge clk_pixel_x5) begin
				tmds[i] <= tmds_shift[i * 10];
				tmds_shift_negedge_temp[i] <= tmds_shift[(i * 10) + 1];
			end
			always @(negedge clk_pixel_x5) tmds[i] <= tmds_shift_negedge_temp[i];
		end
	endgenerate
	reg tmds_clock_negedge_temp;
	always @(posedge clk_pixel_x5) begin
		tmds_clock <= tmds_shift_clk_pixel[0];
		tmds_clock_negedge_temp <= tmds_shift_clk_pixel[1];
	end
	always @(negedge clk_pixel_x5) tmds_clock <= tmds_shift_negedge_temp;
endmodule
