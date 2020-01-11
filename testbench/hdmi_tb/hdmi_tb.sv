// Testbench for hdmi module (supports Icarus Verilog)
// By Sameer Puri https://github.com/sameer

`timescale 1 ps / 1 ps

module hdmi_tb();
// Declare inputs as regs and outputs as wires
reg clk_tmds = 0;
reg clk_pixel = 0;
reg [23:0] rgb = 0;
reg [15:0] audio_sample_word [1:0] = '{16'd0, ~16'd0};
reg [7:0] packet_type = 8'd2; // Audio

wire [2:0] tmds_p;
wire tmds_clock_p;
wire [2:0] tmds_n;
wire tmds_clock_n;
wire [9:0] cx;
wire [9:0] cy;
wire clk_packet;

`ifdef __ICARUS__
defparam U_hdmi.cycles_per_second = 100;
`endif

// Initialize all variables
initial begin   
  $dumpfile("hdmi_tb.vcd");
  $dumpvars(0, hdmi_tb);  
  // $display ("time\t clock clear count Q");	
  $monitor ("%g\t%b\t%b\t%b", $time, tmds_p, cx, cy);
  #240000 $finish;      // Terminate simulation
end

// Clock generator
always begin
  #1 clk_pixel = $time % 10 == 1 ? ~clk_pixel : clk_pixel; // Toggle every 10 ticks
  clk_tmds = ~clk_tmds; // Toggle every tick
end

// Connect DUT to test bench
hdmi U_hdmi (
  clk_tmds,
  clk_pixel,
  rgb,
  audio_sample_word,
  packet_type,
  tmds_p,
  tmds_clock_p,
  tmds_n,
  tmds_clock_n,
  cx,
  cy,
  clk_packet
);

endmodule
