// Testbench for hdmi module
// By Sameer Puri https://github.com/sameer

`timescale 1 ps / 1 ps

module hdmi_tb();
// Declare inputs as regs and outputs as wires
reg clk_tmds = 0;
reg clk_pixel = 0;
reg [23:0] rgb = 0;
reg [15:0] audio_sample_word [3:0] [1:0] = '{'{16'd0, 16'd0}, '{16'd0, 16'd0}, '{16'd0, 16'd0}, '{16'd0, ~16'd0}};
reg audio_sample_word_present [3:0] = '{1'b0, 1'b0, 1'b0, 1'b1};
reg [7:0] packet_type = 8'd2; // Audio

wire [2:0] tmds_p;
wire tmds_clock_p;
wire [2:0] tmds_n;
wire tmds_clock_n;
wire [9:0] cx;
wire [9:0] cy;
wire packet_enable;

initial begin   
  $dumpvars(0, hdmi_tb);
  #9009000 $finish;      // Terminate simulation
end

// Clock generator
always begin
  #10 clk_pixel = ~clk_pixel; // Toggle every 10 ticks
  #1 clk_tmds = ~clk_tmds; // Toggle every tick
end

logic [7:0] num_packets = 8'd0;
logic [4:0] counter = 5'd0;

logic [9:0] prevcx = 857;
logic [9:0] prevcy = 524;

logic prev_packet_enable;
always @(posedge clk_pixel)
  prev_packet_enable <= packet_enable;

always @(posedge clk_pixel)
begin
  prevcx <= hdmi.cx;
  prevcy <= hdmi.cy;
  assert(hdmi.num_packets <= 18) else $fatal("More packets than allowed per data island period will be transmitted: %d", hdmi.num_packets);
  assert (hdmi.audio_clock_regeneration_packet.sub[0] == hdmi.audio_clock_regeneration_packet.sub[1] && hdmi.audio_clock_regeneration_packet.sub[0] == hdmi.audio_clock_regeneration_packet.sub[2] && hdmi.audio_clock_regeneration_packet.sub[0] == hdmi.audio_clock_regeneration_packet.sub[3]) else $fatal("Not all clock regen packets are the same");
  assert (hdmi.audio_clock_regeneration_packet.N == 4096) else $fatal("Clock regen table gives incorrect N: %d", hdmi.audio_clock_regeneration_packet.N);
  assert (hdmi.audio_clock_regeneration_packet.CTS == 27000) else $fatal("Clock regen table gives incorrect CTS: %d", hdmi.audio_clock_regeneration_packet.CTS);
  assert (hdmi.audio_sample_packet.channel_status_left == {152'd0, 4'd0, 4'b0010, 2'd0, 2'd0, 4'b0011, 4'd1, 4'd0, 8'd0, 2'd0, 3'd0, 1'b1, 1'b0, 1'b0}) else $fatal("Channel status left doesn't match expected: %b", hdmi.audio_sample_packet.channel_status_left[39:0]);
  assert (hdmi.audio_sample_packet.channel_status_right == {152'd0, 4'd0, 4'b0010, 2'd0, 2'd0, 4'b0011, 4'd2, 4'd0, 8'd0, 2'd0, 3'd0, 1'b1, 1'b0, 1'b0}) else $fatal("Channel status right doesn't match expected: %b", hdmi.audio_sample_packet.channel_status_right[39:0]);
  assert (hdmi.audio_sample_packet.valid_bit == '{2'b00, 2'b00, 2'b00, 2'b00}) else $fatal("Audio invalid");
  assert (hdmi.WORD_LENGTH_LIMIT == 0);
  assert (hdmi.AUDIO_BIT_WIDTH_COMPARATOR == 20);
  assert (hdmi.WORD_LENGTH == 3'b100);

  if ((cx - hdmi.screen_start_x) % 32 == 0 && cx < hdmi.screen_start_x + hdmi.num_packets * 32 && cx >= hdmi.screen_start_x && cy < hdmi.screen_start_y)
    assert (hdmi.packet_enable) else $fatal("Packet enable does not occur when expected");
  else
    assert (!hdmi.packet_enable) else $fatal("Packet enable occurs at unexpected time");
  if (prevcx >= hdmi.screen_start_x && prevcy >= hdmi.screen_start_y)
    assert(hdmi.video_data_period == 3'd1) else $fatal("Video mode not active in screen area at (%d, %d) with guard %b", prevcx, prevcy, hdmi.video_guard);
  else
    assert(hdmi.video_data_period != 3'd1) else $fatal("Video mode active in non-screen area at (%d, %d)", prevcx, prevcy);
  if (prev_packet_enable)
    counter <=  1'd1;
  if (hdmi.data_island_period && hdmi.packet_assembler.counter == 31)
    num_packets <= num_packets == 191 ? 0 : num_packets + 1'd1;
  if (counter != 0)
    counter <= counter + 1'd1;
  if (counter < 5'd24)
    assert (hdmi.packet_data == {hdmi.sub[3][2*counter+1], hdmi.sub[2][2*counter+1], hdmi.sub[1][2*counter+1], hdmi.sub[0][2*counter+1], hdmi.sub[3][2*counter], hdmi.sub[2][2*counter], hdmi.sub[1][2*counter], hdmi.sub[0][2*counter], hdmi.header[counter]}) else $fatal("Packet assembler not outputting correct data");
  if (hdmi.packet_assembler.counter == 0 && num_packets == 0)
    assert (hdmi.packet_assembler.header[20] == 1'b1) else $fatal("Did not indicate first frame in channel status block");
  assert (num_packets == hdmi.audio_sample_packet.frame_counter) else $fatal("Frame counter does not match number of packets sent: %d vs %d", hdmi.audio_sample_packet.frame_counter, num_packets);

  assert (counter == hdmi.packet_assembler.counter) else $fatal("Packet counter does not match expected");
  if (counter == 5'd31)
  begin
    assert (hdmi.packet_assembler.parity[4] == (num_packets != 0 ? 8'b01100101 : 8'b11010110)) else $fatal("Parity unexpected for 4: %b", hdmi.packet_assembler.parity[4]);
    assert (hdmi.packet_assembler.parity[3:1] == '{8'd0, 8'd0, 8'd0, 8'd0}) else $fatal("Parity is nonzero for 3 to 1: %b, %b, %b, %b", hdmi.packet_assembler.parity[3], hdmi.packet_assembler.parity[2], hdmi.packet_assembler.parity[1]);
    assert (hdmi.packet_assembler.parity[0] == 8'b10100110 || hdmi.packet_assembler.parity[0] == 8'b00010001 || hdmi.packet_assembler.parity[0] == 8'b11100111 || hdmi.packet_assembler.parity[0] == 8'b01010000) else $fatal("Parity incorrect for 0: %b, with sub0 = %b, counter = %d", hdmi.packet_assembler.parity[0], hdmi.packet_assembler.sub[0], num_packets);
  end
end

// Connect DUT to test bench
hdmi #(.VIDEO_ID_CODE(3), .AUDIO_BIT_WIDTH(16)) hdmi (
  clk_tmds,
  clk_pixel,
  rgb,
  audio_sample_word,
  audio_sample_word_present,
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
