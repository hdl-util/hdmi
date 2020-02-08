`timescale 1 ps / 1 ps

module top_tb();

initial begin
  $dumpvars(0, top_tb);
  // #36036000000ps $finish; // Terminate simulation after ~2 frames are generated
  #20ms $finish;
end

logic clk_original = 0;
logic [2:0] tmds_p;
logic tmds_clock_p;
logic [2:0] tmds_n;
logic tmds_clock_n;

top top (
    .clk_original(clk_original),
    .tmds_p(tmds_p),
    .tmds_clock_p(tmds_clock_p),
    .tmds_n(tmds_n),
    .tmds_clock_n(tmds_clock_n)
);

logic [9:0] cx = 858 - 4;
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
    : 4'bZZZZ;
  end
endgenerate

logic [3:0] counter = 0;
always @(posedge top.clk_pixel_x10)
begin
  assert (counter == top.hdmi.tmds_counter) else $fatal("Shift-out counter doesn't match decoder counter");
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

logic [23:0] L [3:0];
logic [23:0] R [3:0];
logic [3:0] PCUVr [3:0];
logic [3:0] PCUVl [3:0];
generate
  for (i = 0; i< 4; i++)
  begin
    assign R[i] = sub[i][47:24];
    assign L[i] = sub[i][23:0];
    assign PCUVr[i] = sub[i][55:52];
    assign PCUVl[i] = sub[i][51:48];
  end
endgenerate
logic [2:0] num_samples_present;
assign num_samples_present = 3'(header[11]) + header[10] + header[9] + header[8];
logic [$clog2(192)-1:0] frame_counter = 0;
logic [191:0] channel_status [1:0] = '{192'dX, 192'dX};

logic first_packet = 1;

integer k;
always @(posedge top.clk_pixel)
begin
  cx <= cx == top.hdmi.frame_width - 1 ? 0 : cx + 1;
  cy <= cx == top.hdmi.frame_width-1'b1 ? cy == top.hdmi.frame_height-1'b1 ? 0 : cy + 1'b1 : cy;
  // if (top.hdmi.data_island_period && top.hdmi.packet_assembler.counter == 0)
  // begin
  //   $display("Packet assembler receiving sub %b %d at (%d, %d) with frame counter %d", top.hdmi.packet_assembler.sub[0], top.hdmi.packet_assembler.header[7:0], top.hdmi.cx - 1, top.hdmi.cy, top.hdmi.frame_counter);
  // end

  if (top.hdmi.true_hdmi_output.num_packets_alongside > 0 && (cx >= 8 && cx < 10) || (cx >= 10 + top.hdmi.true_hdmi_output.num_packets_alongside * 32 && cx < 10 + top.hdmi.true_hdmi_output.num_packets_alongside * 32 + 2))
  begin
    assert(tmds_values[2] == 10'b0100110011) else $fatal("Channel 2 DI GB incorrect: %b", tmds_values[2]);
    assert(tmds_values[1] == 10'b0100110011) else $fatal("Channel 1 DI GB incorrect");
    assert(tmds_values[0] == 10'b1010001110 || tmds_values[0] == 10'b1001110001 || tmds_values[0] == 10'b0101100011 || tmds_values[0] == 10'b1011000011) else $fatal("Channel 0 DI GB incorrect");
  end
  else if (top.hdmi.true_hdmi_output.num_packets_alongside > 0 && cx >= 10 && cx < 10 + top.hdmi.true_hdmi_output.num_packets_alongside * 32)
  begin
    data_counter <= data_counter + 1'd1;
    if (data_counter == 0)
    begin
      sub[3][63:1] <= 63'dX;
      sub[2][63:1] <= 63'dX;
      sub[1][63:1] <= 63'dX;
      sub[0][63:1] <= 63'dX;
      header[31:1] <= 31'dX;
      if (cx != 10 || !first_packet) // Packet complete
      begin
        first_packet <= 0;
        // $display("Received packet for (%d, %d)", cx - 32, cy);
        case(header[7:0])
          8'h00: begin
            $display("NULL packet");
          end
          8'h01: begin
            $display("Audio Clock Regen packet N = %d, CTS = %d", N, CTS);
            assert(header[23:8] === 16'd0) else $fatal("Clock regen HB1, HB2 should be X: %b, %b", header[23:16], header[15:8]);
            assert(sub[0] == sub[1] && sub[1] == sub[2] && sub[2] == sub[3]) else $fatal("Clock regen subpackets are different");
            assert(N == 128*48000/1000) else $fatal("Incorrect N: %d should be %d", N, 128*48000/1000);
            assert(CTS > 25738 - 1000 && CTS < 25738 + 1000) else $fatal("Incorrect CTS: %d out of bounds", CTS);
          end
          8'h02: begin
            $display("Audio Sample packet #%d - %d", frame_counter + 1, frame_counter + num_samples_present);
            assert(header[12] == 1'b0) else $fatal("Sample layout is not 2 channel");
            assert(header[11:8] == 4'd15 || header[11:8] == 4'd7 || header[11:8] == 4'd3 || header[11:8] == 4'd1) else $fatal("Sample present flag values unexpected: %b", header[11:8]);
            assert(header[19:16] == 4'd0) else $fatal("Sample flat values nonzero: %b", header[19:16]);
            for (k = 0; k < 4; k++)
            begin
              if (!header[8 + k]) // Sample not present
                continue;

              if ((frame_counter + k) % 192 == 0) // Last frame was end of IEC60958 frame, this sample starts a new frame
              begin
                assert(header[20 + k] == 1'b1) else $fatal("Sample B value low for sample %d with counter %d", k, frame_counter);
                // if (channel_status != '{192'dX, 192'dX})
                // begin
                //   assert(channel_status[0] == top.hdmi.audio_sample_packet.channel_status_left) else $fatal("Previous sample channel status left incorrect: %b", channel_status[0]);
                //   assert(channel_status[1] == top.hdmi.audio_sample_packet.channel_status_right) else $fatal("Previous sample channel status right incorrect: %b", channel_status[1]);
                // end
              end
              else
                assert(header[20 + k] == 1'b0) else $fatal("Sample B value high for sample %d with counter %d", k, frame_counter);
              assert(PCUVr[k][1] == 1'b0 && PCUVl[k][1] == 1'b0) else $fatal("Sample user data bits nonzero");
              assert(PCUVr[k][0] == 1'b0 && PCUVl[k][0] == 1'b0) else $fatal("Sample validity bits nonzero");
              assert(^{PCUVr[k][2:0], R[k]} == PCUVr[k][3]) else $fatal("Sample right parity not even: %b", {PCUVr[k], R[k]});
              assert(^{PCUVl[k][2:0], L[k]} == PCUVl[k][3]) else $fatal("Sample left parity not even: %b", {PCUVl[k], L[k]});
              channel_status[1][frame_counter + k] <= PCUVr[k][2];
              channel_status[0][frame_counter + k] <= PCUVl[k][2];
            end
            frame_counter <= (frame_counter + num_samples_present) % 192;
          end
          8'h82: begin
            $display("AVI InfoFrame");
          end
          8'h83: begin
            $display("SPD InfoFrame");
          end
          8'h84: begin
            $display("Audio InfoFrame");
          end
          default: begin
            $fatal("Unhandled packet type %h (%s) at %d, %d: %p", header[7:0], "Unknown", cx, cy, sub);
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
  // else if (cx == top.hdmi.frame_width - 3 && cy == top.hdmi.frame_height - 1)
  //   assert (tmds_values[2] == tmds_values[1] && tmds_values[0] == tmds_values[1] && tmds_values[2] == 10'b1101010100) else $fatal("Incorrect first value: %b", tmds_values[2]);
end

endmodule
