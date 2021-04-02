module packet_assembler (
	clk_pixel,
	reset,
	data_island_period,
	header,
	sub,
	packet_data,
	counter
);
	input wire clk_pixel;
	input wire reset;
	input wire data_island_period;
	input wire [23:0] header;
	input wire [223:0] sub;
	output wire [8:0] packet_data;
	output reg [4:0] counter = 5'd0;
	always @(posedge clk_pixel)
		if (reset)
			counter <= 5'd0;
		else if (data_island_period)
			counter <= counter + 5'd1;
	wire [5:0] counter_t2 = {counter, 1'b0};
	wire [5:0] counter_t2_p1 = {counter, 1'b1};
	reg [39:0] parity = 40'h0000000000;
	wire [63:0] bch [3:0];
	assign bch[0] = {parity[0+:8], sub[0+:56]};
	assign bch[1] = {parity[8+:8], sub[56+:56]};
	assign bch[2] = {parity[16+:8], sub[112+:56]};
	assign bch[3] = {parity[24+:8], sub[168+:56]};
	wire [31:0] bch4 = {parity[32+:8], header};
	assign packet_data = {bch[3][counter_t2_p1], bch[2][counter_t2_p1], bch[1][counter_t2_p1], bch[0][counter_t2_p1], bch[3][counter_t2], bch[2][counter_t2], bch[1][counter_t2], bch[0][counter_t2], bch4[counter]};
	function automatic [7:0] next_ecc;
		input reg [7:0] ecc;
		input reg [7:0] next_bch_bit;
		next_ecc = (ecc >> 1) ^ (ecc[0] ^ next_bch_bit ? 8'b10000011 : 8'd0);
	endfunction
	wire [7:0] parity_next [4:0];
	wire [31:0] parity_next_next;
	genvar i;
	generate
		for (i = 0; i < 5; i = i + 1) begin : parity_calc
			if (i == 4) begin
				assign parity_next[i] = next_ecc(parity[i * 8+:8], header[counter]);
			end
			else begin
				assign parity_next[i] = next_ecc(parity[i * 8+:8], sub[(i * 56) + counter_t2]);
				assign parity_next_next[i * 8+:8] = next_ecc(parity_next[i], sub[(i * 56) + counter_t2_p1]);
			end
		end
	endgenerate
	always @(posedge clk_pixel)
		if (reset)
			parity <= 40'h0000000000;
		else if (data_island_period) begin
			if (counter < 5'd28) begin
				parity[0+:32] <= parity_next_next;
				if (counter < 5'd24)
					parity[32+:8] <= parity_next[4];
			end
			else if (counter == 5'd31)
				parity <= 40'h0000000000;
		end
		else
			parity <= 40'h0000000000;
endmodule
