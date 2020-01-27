// Testbench for hdmi module
// By Sameer Puri https://github.com/sameer

`timescale 1 ps / 1 ps

module hdmi_tb();
// Declare inputs as regs and outputs as wires
reg clk_tmds = 0;
reg clk_pixel = 0;
reg clk_audio = 0;
reg [23:0] rgb = 0;
reg [15:0] audio_sample_word [1:0] = '{16'd0, ~16'd0};

wire [2:0] tmds_p;
wire tmds_clock_p;
wire [2:0] tmds_n;
wire tmds_clock_n;
wire [9:0] cx;
wire [9:0] cy;

initial begin   
  $dumpvars(0, hdmi_tb);
  #9009000 $finish;      // Terminate simulation
end

// Clock generator
always #20 clk_pixel = ~clk_pixel; // Toggle every 10 ticks
always #1 clk_tmds = ~clk_tmds; // Toggle every tick
always #10000 clk_audio = ~clk_audio; 

logic [7:0] num_packets = 8'd0;
logic [4:0] counter = 5'd0;

logic [9:0] prevcx = 857;
logic [9:0] prevcy = 524;

logic prev_packet_enable = 0;
always @(posedge clk_pixel)
begin
  prev_packet_enable <= hdmi.true_hdmi_output.packet_picker.packet_enable;
  prevcx <= cx;
  prevcy <= cy;
  assert(hdmi.true_hdmi_output.num_packets_alongside <= 18) else $fatal("More packets than allowed per data island period will be transmitted: %d", hdmi.true_hdmi_output.num_packets_alongside);
  assert (hdmi.true_hdmi_output.packet_picker.audio_clock_regeneration_packet.sub[0] == hdmi.true_hdmi_output.packet_picker.audio_clock_regeneration_packet.sub[1] && hdmi.true_hdmi_output.packet_picker.audio_clock_regeneration_packet.sub[0] == hdmi.true_hdmi_output.packet_picker.audio_clock_regeneration_packet.sub[2] && hdmi.true_hdmi_output.packet_picker.audio_clock_regeneration_packet.sub[0] == hdmi.true_hdmi_output.packet_picker.audio_clock_regeneration_packet.sub[3]) else $fatal("Not all clock regen packets are the same");
  assert (hdmi.true_hdmi_output.packet_picker.audio_clock_regeneration_packet.N == 4096) else $fatal("Clock regen table gives incorrect N: %d", hdmi.true_hdmi_output.packet_picker.audio_clock_regeneration_packet.N);
  assert (hdmi.true_hdmi_output.packet_picker.audio_clock_regeneration_packet.CTS == 27000) else $fatal("Clock regen table gives incorrect CTS: %d", hdmi.true_hdmi_output.packet_picker.audio_clock_regeneration_packet.CTS);
  assert (hdmi.true_hdmi_output.packet_picker.audio_sample_packet.channel_status_left == {152'd0, 4'd0, 4'b0010, 2'd0, 2'd0, 4'b0011, 4'd1, 4'd0, 8'd0, 2'd0, 3'd0, 1'b1, 1'b0, 1'b0}) else $fatal("Channel status left doesn't match expected: %b", hdmi.true_hdmi_output.packet_picker.audio_sample_packet.channel_status_left[39:0]);
  assert (hdmi.true_hdmi_output.packet_picker.audio_sample_packet.channel_status_right == {152'd0, 4'd0, 4'b0010, 2'd0, 2'd0, 4'b0011, 4'd2, 4'd0, 8'd0, 2'd0, 3'd0, 1'b1, 1'b0, 1'b0}) else $fatal("Channel status right doesn't match expected: %b", hdmi.true_hdmi_output.packet_picker.audio_sample_packet.channel_status_right[39:0]);
  assert (hdmi.true_hdmi_output.packet_picker.audio_sample_packet.valid_bit == '{2'b00, 2'b00, 2'b00, 2'b00}) else $fatal("Audio invalid");
  assert (hdmi.true_hdmi_output.packet_picker.WORD_LENGTH_LIMIT == 0);
  assert (hdmi.true_hdmi_output.packet_picker.AUDIO_BIT_WIDTH_COMPARATOR == 20);
  assert (hdmi.true_hdmi_output.packet_picker.WORD_LENGTH == 3'b100);

  if (hdmi.true_hdmi_output.num_packets_alongside > 0 && cx >= 10 && cx < 10 + hdmi.true_hdmi_output.num_packets_alongside * 32 && (cx - 10) % 32 == 0)
    assert (hdmi.true_hdmi_output.packet_picker.packet_enable) else $fatal("Packet enable does not occur when expected");
  else
    assert (!hdmi.true_hdmi_output.packet_picker.packet_enable) else $fatal("Packet enable occurs at unexpected time");
  if (prevcx >= hdmi.screen_start_x && prevcy >= hdmi.screen_start_y)
    assert(hdmi.video_data_period == 3'd1) else $fatal("Video mode not active in screen area at (%d, %d) with guard %b", prevcx, prevcy, hdmi.true_hdmi_output.video_guard);
  else
    assert(hdmi.video_data_period != 3'd1) else $fatal("Video mode active in non-screen area at (%d, %d)", prevcx, prevcy);
  if (prev_packet_enable)
    counter <=  1'd1;
  if (hdmi.true_hdmi_output.data_island_period && hdmi.true_hdmi_output.packet_assembler.counter == 31)
    num_packets <= num_packets + 1'd1;
  if (counter != 0)
    counter <= counter + 1'd1;
  if (counter < 5'd24)
    assert (hdmi.true_hdmi_output.packet_data == {hdmi.true_hdmi_output.sub[3][2*counter+1], hdmi.true_hdmi_output.sub[2][2*counter+1], hdmi.true_hdmi_output.sub[1][2*counter+1], hdmi.true_hdmi_output.sub[0][2*counter+1], hdmi.true_hdmi_output.sub[3][2*counter], hdmi.true_hdmi_output.sub[2][2*counter], hdmi.true_hdmi_output.sub[1][2*counter], hdmi.true_hdmi_output.sub[0][2*counter], hdmi.true_hdmi_output.header[counter]}) else $fatal("Packet assembler not outputting correct data: %p", hdmi.true_hdmi_output.packet_data);
  assert (counter == hdmi.true_hdmi_output.packet_assembler.counter) else $fatal("Packet counter does not match expected");
end

// Connect DUT to test bench
hdmi #(.VIDEO_ID_CODE(3), .AUDIO_BIT_WIDTH(16)) hdmi(clk_tmds, clk_pixel, clk_audio, rgb, audio_sample_word, tmds_p, tmds_clock_p, tmds_n, tmds_clock_n, cx, cy);

endmodule
