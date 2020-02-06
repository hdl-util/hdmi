// This is a FAKE PLL! You should be using the PLL IP available from your FPGA vendor

`timescale 1 ns / 100 ps

module pll (
	input wire inclk0,
	output reg c0 = 0,
	output reg c1 = 1,
	output reg c2 = 0
);

always #2 c0 = ~c0; // Faked as 250 MHz
always #20 c1 = ~c1; // Faked as 25 MHz
always #10417 c2 = ~c2;

endmodule
