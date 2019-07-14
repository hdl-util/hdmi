//--------------------------------------------------------
// Design  : Simple testbench for an 8-bit verilog counter
// Author  : Javier D. Garcia-Lasheras
//--------------------------------------------------------

module counter_tb();
// Declare inputs as regs and outputs as wires
reg clock, clear, count;
wire [7:0] Q;

defparam U_counter.cycles_per_second = 10;

// Initialize all variables
initial begin   
  $dumpfile("counter_tb.vcd");
  $dumpvars(0,counter_tb);     
  $display ("time\t clock clear count Q");	
  $monitor ("%g\t %b   %b     %b      %b", 
	  $time, clock, clear, count, Q);	
  clock = 1;       // initial value of clock
  clear = 0;       // initial value of clear
  count = 0;       // initial value of count enable
  #5 clear = 1;    // Assert the clear signal
  #10 clear = 0;   // De-assert clear signal
  #40 count = 1;   // Start count 
  #1000 $finish;      // Terminate simulation
end

// Clock generator
always begin
  #1 clock = ~clock; // Toggle clock every 5 ticks
end

// Connect DUT to test bench
counter U_counter (
clock,
clear,
count,
Q
);

endmodule
