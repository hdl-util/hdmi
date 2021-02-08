// This is a FAKE PLL! You should be using the PLL IP available from your FPGA vendor

timeunit 1ps;
timeprecision 1ps;

module pll (
	output logic c0 = 0,
	output logic c1 = 0,
	output logic c2 = 0
);
always
begin
	#7937ps c0 = 1;
	#7937ps c0 = 0;
end

always
begin
	#39683ps c1 = 1;
	#39683ps c1 = 0;
end

always
begin
	#20833333ps c2 = 1;
	#20833333ps c2 = 0;
end

endmodule
