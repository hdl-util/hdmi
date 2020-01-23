`timescale 1 ps / 1 ps

module top_tb();

initial begin
  $dumpvars(0, top_tb);
  // #36036000000ps $finish; // Terminate simulation after ~2 frames are generated
  #20ms $stop;
end

logic CLK_50MHZ = 0;
logic CLK_32KHZ = 0;
logic RST = 0;
logic CLK_50MHZ_ENABLE;
logic CLK_32KHZ_ENABLE;
logic [7:0] LED;
logic [2:0] tmds_p;
logic tmds_clock_p;
logic [2:0] tmds_n;
logic tmds_clock_n;
logic PWM_OUT;

// Clock generator
// always #1000ns CLK_32KHZ = ~CLK_32KHZ;
always #10ns CLK_50MHZ = ~CLK_50MHZ;

max10_top max10_top (
    .CLK_50MHZ(CLK_50MHZ),
    .CLK_32KHZ(CLK_32KHZ),
    .RST(RST),
    .CLK_50MHZ_ENABLE(CLK_50MHZ_ENABLE),
    .CLK_32KHZ_ENABLE(CLK_32KHZ_ENABLE),
    .LED(LED),
    .tmds_p(tmds_p),
    .tmds_clock_p(tmds_clock_p),
    .tmds_n(tmds_n),
    .tmds_clock_n(tmds_clock_n),
    .PWM_OUT(PWM_OUT)
);

logic [9:0] cx = 858 - 3;
logic [9:0] cy = 524;

logic [9:0] tmds_values [2:0] = '{10'dx, 10'dx, 10'dx};


logic [7:0] decoded_values [2:0];
logic [3:0] decoded_terc4_values [2:0];
genvar i;
genvar j;
generate
  for (j = 0; j < 3; j++)
  begin
    assign decoded_values[j][0] = tmds_values[j][9] ? ~tmds_values[j][0] : tmds_values[j][0];
    for (i = 1; i < 8; i++)
    begin
      assign decoded_values[j][i] = tmds_values[j][8] ? 
        (tmds_values[j][9] ? (~tmds_values[j][i]) ^ (~tmds_values[j][i-1]) : tmds_values[j][i] ^ tmds_values[j][i-1])
        : (tmds_values[j][9] ? (~tmds_values[j][i]) ~^ (~tmds_values[j][i-1]) : tmds_values[j][i] ~^ tmds_values[j][i-1]);
    end
    assign decoded_terc4_values[j] = tmds_values[j] == 10'b1010011100 ? 4'b0000
    : tmds_values[j] == 10'b1001100011 ? 4'b0001
    : tmds_values[j] == 10'b1011100100 ? 4'b0010
    : tmds_values[j] == 10'b1011100010 ? 4'b0011
    : tmds_values[j] == 10'b0101110001 ? 4'b0100
    : tmds_values[j] == 10'b0100011110 ? 4'b0101
    : tmds_values[j] == 10'b0110001110 ? 4'b0110
    : tmds_values[j] == 10'b0100111100 ? 4'b0111
    : tmds_values[j] == 10'b1011001100 ? 4'b1000
    : tmds_values[j] == 10'b0100111001 ? 4'b1001
    : tmds_values[j] == 10'b0110011100 ? 4'b1010
    : tmds_values[j] == 10'b1011000110 ? 4'b1011
    : tmds_values[j] == 10'b1010001110 ? 4'b1100
    : tmds_values[j] == 10'b1001110001 ? 4'b1101
    : tmds_values[j] == 10'b0101100011 ? 4'b1110
    : tmds_values[j] == 10'b1011000011 ? 4'b1111
    : 4'bXXXX;
  end
endgenerate

logic [3:0] counter = 0;
always @(posedge max10_top.clk_tmds)
begin
  assert (counter == max10_top.hdmi.tmds_counter) else $fatal("Shift-out counter doesn't match decoder counter");
  if (counter == 9)
  begin
    counter <= 0;
  end
  else
    counter <= counter + 1'd1;

  tmds_values[0][counter] <= tmds_p[0];
  tmds_values[1][counter] <= tmds_p[1];
  tmds_values[2][counter] <= tmds_p[2];

  if (counter == 0)
  begin
    tmds_values[0][9:1] <= 9'dX;
    tmds_values[1][9:1] <= 9'dX;
    tmds_values[2][9:1] <= 9'dX;
  end
end

logic [4:0] data_counter = 0;
logic [63:0] sub [3:0] = '{64'dX, 64'dX, 64'dX, 64'dX};
logic [31:0] header = 32'dX;

logic [19:0] N;
assign N = {sub[0][35:32], sub[0][47:40], sub[0][55:48]};
logic [19:0] CTS;
assign CTS = {sub[0][11:8], sub[0][23:16], sub[0][31:24]};

logic [23:0] L;
assign L = sub[0][23:0];
logic [23:0] R;
assign R = sub[0][47:24];
logic [3:0] PCUVr;
assign PCUVr = sub[0][55:52];
logic [3:0] PCUVl;
assign PCUVl = sub[0][51:48];
logic [$clog2(192)-1:0] frame_counter = 0;
logic [191:0] channel_status [1:0] = '{192'dX, 192'dX};

logic first_packet = 1;

always @(posedge max10_top.clk_pixel)
begin
  cx <= cx == max10_top.hdmi.frame_width - 1 ? 0 : cx + 1;
  cy <= cx == max10_top.hdmi.frame_width-1'b1 ? cy == max10_top.hdmi.frame_height-1'b1 ? 0 : cy + 1'b1 : cy;
  // if (max10_top.hdmi.data_island_period && max10_top.hdmi.packet_assembler.counter == 0)
  // begin
  //   $display("Packet assembler receiving sub %b %d at (%d, %d) with frame counter %d", max10_top.hdmi.packet_assembler.sub[0], max10_top.hdmi.packet_assembler.header[7:0], max10_top.hdmi.cx - 1, max10_top.hdmi.cy, max10_top.hdmi.frame_counter);
  // end

  if (cx >= max10_top.hdmi.screen_start_x - 2 && cx < max10_top.hdmi.screen_start_x && cy < max10_top.hdmi.screen_start_y)
  begin
    assert(tmds_values[2] == 10'b0100110011) else $fatal("Channel 2 DI GB incorrect");
    assert(tmds_values[1] == 10'b0100110011) else $fatal("Channel 1 DI GB incorrect");
    assert(tmds_values[0] == 10'b1010001110 || tmds_values[0] == 10'b1001110001 || tmds_values[0] == 10'b0101100011 || tmds_values[0] == 10'b1011000011) else $fatal("Channel 0 DI GB incorrect");
  end
  else if (cx >= max10_top.hdmi.screen_start_x && cx < max10_top.hdmi.screen_start_x + max10_top.hdmi.num_packets * 32 && cy < max10_top.hdmi.screen_start_y)
  begin
    data_counter <= data_counter + 1'd1;
    if (data_counter == 0)
    begin
      sub[3][63:1] <= 63'dX;
      sub[2][63:1] <= 63'dX;
      sub[1][63:1] <= 63'dX;
      sub[0][63:1] <= 63'dX;
      header[31:1] <= 31'dX;
      if (cx != max10_top.hdmi.screen_start_x || !first_packet) // Packet complete
      begin
        first_packet <= 0;
        // $display("Received packet for (%d, %d)", cx - 32, cy);
        case(header[7:0])
          8'h00: $display("NULL packet");
          8'h01: begin
            $display("Audio Clock Regen packet");
            assert(header[23:8] === 16'dX) else $fatal("Clock regen HB1, HB2 should be X: %b, %b", header[23:16], header[15:8]);
            assert(sub[0] == sub[1] && sub[1] == sub[2] && sub[2] == sub[3]) else $fatal("Clock regen subpackets are different");
            assert(N == max10_top.hdmi.audio_clock_regeneration_packet.N) else $fatal("Incorrect N: %d should be %d", N, max10_top.hdmi.audio_clock_regeneration_packet.N);
            assert(CTS == max10_top.hdmi.audio_clock_regeneration_packet.CTS) else $fatal("Incorrect CTS: %d should be %d", CTS, max10_top.hdmi.audio_clock_regeneration_packet.CTS);
          end
          8'h02: begin
            $display("Audio Sample packet #%d", frame_counter + 1);
            assert(sub[3:1] == '{64'd0, 64'd0, 64'd0}) else $fatal("Sample subpackets 1 through 3 are not empty");
            assert(header[12] == 1'b0) else $fatal("Sample layout is not 2 channel");
            assert(header[11:8] == 4'b0001) else $fatal("Sample present flag values unexpected: %b", header[11:8]);
            assert(header[19:16] == 4'd0) else $fatal("Sample flat values nonzero: %b", header[19:16]);
            if (frame_counter == 0)
            begin
              assert(header[23:20] == 4'b0001) else $fatal("Sample B values unexpected: %b", header[23:0]);
              if (channel_status != '{192'dX, 192'dX})
              begin
                assert(channel_status[0] == max10_top.hdmi.audio_sample_packet.channel_status_left) else $fatal("Previous sample channel status left incorrect: %b", channel_status[0]);
                assert(channel_status[1] == max10_top.hdmi.audio_sample_packet.channel_status_right) else $fatal("Previous sample channel status right incorrect: %b", channel_status[1]);
              end
            end
            else
              assert(header[23:20] == 4'd0) else $fatal("Sample B values nonzero: %b", header[23:20]);
            assert(PCUVr[1] == 1'b0 && PCUVl[1] == 1'b0) else $fatal("Sample user data bits nonzero");
            assert(PCUVr[0] == 1'b0 && PCUVl[0] == 1'b0) else $fatal("Sample validity bits nonzero");
            assert(^{PCUVr[2:0], R} == PCUVr[3]) else $fatal("Sample right parity not even: %b", {PCUVr, R});
            assert(^{PCUVl[2:0], L} == PCUVl[3]) else $fatal("Sample left parity not even: %b", {PCUVl, L});
            channel_status[1][frame_counter] <= PCUVr[2];
            channel_status[0][frame_counter] <= PCUVl[2];
            frame_counter <= frame_counter == 191 ? 0 : frame_counter + 1;
          end
          8'h84: begin
            $display("Audio InfoFrame");
          end
          default: begin
            $fatal("Unhandled packet type %h (%s)", header[7:0], header[7:0] == 8'h82 ? "AVI InfoFrame" : header[7:0] == 8'h84 ? "Audio InfoFrame" : "Unknown");
          end
        endcase
      end
    end
    // $display("Original value for (%d, %d) %b, %b, %b", cx, cy, tmds_values[2], tmds_values[1], tmds_values[0]);
    // $display("Decoded value for (%d, %d) %b, %b, %b", cx, cy, decoded_terc4_values[2], decoded_terc4_values[1], decoded_terc4_values[0]);
    sub[3][{data_counter, 1'b1}] <= decoded_terc4_values[2][3];
    sub[3][{data_counter, 1'b0}] <= decoded_terc4_values[1][3];
    sub[2][{data_counter, 1'b1}] <= decoded_terc4_values[2][2];
    sub[2][{data_counter, 1'b0}] <= decoded_terc4_values[1][2];
    sub[1][{data_counter, 1'b1}] <= decoded_terc4_values[2][1];
    sub[1][{data_counter, 1'b0}] <= decoded_terc4_values[1][1];
    sub[0][{data_counter, 1'b1}] <= decoded_terc4_values[2][0];
    sub[0][{data_counter, 1'b0}] <= decoded_terc4_values[1][0];
    header[data_counter] <= decoded_terc4_values[0][2];
  end
  // else if (cx == max10_top.hdmi.frame_width - 3 && cy == max10_top.hdmi.frame_height - 1)
  //   assert (tmds_values[2] == tmds_values[1] && tmds_values[0] == tmds_values[1] && tmds_values[2] == 10'b1101010100) else $fatal("Incorrect first value: %b", tmds_values[2]);
end

endmodule
