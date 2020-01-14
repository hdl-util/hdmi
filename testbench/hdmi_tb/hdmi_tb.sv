// Testbench for hdmi module
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
wire packet_enable;

`ifdef __ICARUS__
defparam hdmi.cycles_per_second = 100;
`endif

// Initialize all variables
initial begin   
  $dumpfile("hdmi_tb.vcd");
  $dumpvars(0, hdmi_tb);
  // $display ("time\t clock clear count Q");	
  // $monitor ("%g\t%b\t%b\t%b", $time, tmds_p, cx, cy);
  #240000 $finish;      // Terminate simulation
end

// Clock generator
always begin
  #1 clk_pixel = $time % 10 == 1 ? ~clk_pixel : clk_pixel; // Toggle every 10 ticks
  clk_tmds = ~clk_tmds; // Toggle every tick
end

logic [4:0] counter = 5'd0;

always @(posedge clk_pixel)
begin
  assert(hdmi.num_packets <= 18) else $fatal("More packets than allowed per data island period will be transmitted: %d", hdmi.num_packets);
  if (cx >= hdmi.screen_start_x && cy >= hdmi.screen_start_y)
  begin
    assert(hdmi.mode == 3'd1) else $fatal("Video mode not active in screen area, mode is actually %d", hdmi.mode);
  end
  assert (hdmi.audio_clock_regeneration_packet.N == 4096) else $fatal("Clock regen table gives incorrect N: %d", hdmi.audio_clock_regeneration_packet.N);
  assert (hdmi.audio_clock_regeneration_packet.CTS == 27000) else $fatal("Clock regen table gives incorrect CTS: %d", hdmi.audio_clock_regeneration_packet.CTS);
  assert ((hdmi.packet_type == 8'd2 ~^ hdmi.packet_enable_fanout[2] ~^ hdmi.packet_enable)) else $fatal("Packet enable does not reach audio packet when packet type is audio packet");
  assert (hdmi.audio_bit_width_block.audio_sample_packet.channel_status_left == {152'd0, 4'd0, 4'b0010, 2'd0, 2'd0, 4'b0011, 4'd1, 4'd0, 8'd0, 2'd0, 3'd0, 1'b1, 1'b0, 1'b0}) else $fatal("Channel status left doesn't match expected: %b", hdmi.audio_bit_width_block.audio_sample_packet.channel_status_left[39:0]);
  assert (hdmi.audio_bit_width_block.audio_sample_packet.channel_status_right == {152'd0, 4'd0, 4'b0010, 2'd0, 2'd0, 4'b0011, 4'd2, 4'd0, 8'd0, 2'd0, 3'd0, 1'b1, 1'b0, 1'b0}) else $fatal("Channel status right doesn't match expected: %b", hdmi.audio_bit_width_block.audio_sample_packet.channel_status_right[39:0]);
  if (packet_enable)
    counter <=  1'd1;
  if (counter != 0)
    counter <= counter + 1'd1;
  if (counter < 5'd24)
    assert (hdmi.packet_data == {hdmi.sub[3][2*counter+1], hdmi.sub[2][2*counter+1], hdmi.sub[1][2*counter+1], hdmi.sub[0][2*counter+1], hdmi.sub[3][2*counter], hdmi.sub[2][2*counter], hdmi.sub[1][2*counter], hdmi.sub[0][2*counter], hdmi.header[counter]}) else $fatal("Packet assembler not outputting correct data");
  assert (counter == hdmi.packet_assembler.counter) else $fatal("Packet counter does not match expected");
end

// Connect DUT to test bench
hdmi #(.VIDEO_ID_CODE(3)) hdmi (
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
  packet_enable
);

endmodule
