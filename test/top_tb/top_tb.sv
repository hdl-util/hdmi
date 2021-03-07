module top_tb();

timeunit 1ns;
timeprecision 1ns;

initial begin
  #40ms $finish;
end

top top ();

logic [9:0] cx = 800 - 4;
logic [9:0] cy = 525 - 1;

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
    : 4'bzzzz;
  end
endgenerate

always @(posedge top.clk_pixel)
begin
  tmds_values[0] <= top.hdmi.tmds_internal[0];
  tmds_values[1] <= top.hdmi.tmds_internal[1];
  tmds_values[2] <= top.hdmi.tmds_internal[2];
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

// PB0-PB6 = sub0
// PB7-13 =  sub1
// PB14-20 = sub2
// PB21-27 = sub3

// returns number of non-zero elements in array
function int check_non_zero_elem(logic [7:0] a0[]);
    check_non_zero_elem = 0;
    for(int i=$low(a0); i <= $high(a0); i++)
        if(a0[i] != 0) check_non_zero_elem++;
endfunction

logic [7:0] packet_bytes [0:27];
for (i = 0; i < 28; i++)
begin
  assign packet_bytes[i] = sub[i / 7][((i % 7) + 1) * 8 - 1 :(i % 7) * 8];
end

logic first_packet = 1;
logic first_audio_packet = 1;
logic [15:0] previous_sample [1:0];

integer k;
always @(posedge top.clk_pixel)
begin
  cx <= cx == top.frame_width - 1 ? 0 : cx + 1;
  cy <= cx == top.frame_width-1'b1 ? cy == top.frame_height-1'b1 ? 0 : cy + 1'b1 : cy;
  if (top.hdmi.true_hdmi_output.num_packets_alongside > 0 && (cx >= top.screen_width + 8 && cx < top.screen_width + 10) || (cx >= top.screen_width + 10 + top.hdmi.true_hdmi_output.num_packets_alongside * 32 && cx < top.screen_width + 10 + top.hdmi.true_hdmi_output.num_packets_alongside * 32 + 2))
  begin
    assert(tmds_values[2] == 10'b0100110011) else $fatal("Channel 2 DI GB incorrect: %b", tmds_values[2]);
    assert(tmds_values[1] == 10'b0100110011) else $fatal("Channel 1 DI GB incorrect");
    assert(tmds_values[0] == 10'b1010001110 || tmds_values[0] == 10'b1001110001 || tmds_values[0] == 10'b0101100011 || tmds_values[0] == 10'b1011000011) else $fatal("Channel 0 DI GB incorrect");
  end
  else if (top.hdmi.true_hdmi_output.num_packets_alongside > 0 && cx >= top.screen_width + 10 && cx < top.screen_width + 10 + top.hdmi.true_hdmi_output.num_packets_alongside * 32)
  begin
    data_counter <= data_counter + 1'd1;
    if (data_counter == 0)
    begin
      sub[3][63:1] <= 63'dX;
      sub[2][63:1] <= 63'dX;
      sub[1][63:1] <= 63'dX;
      sub[0][63:1] <= 63'dX;
      header[31:1] <= 31'dX;
      if (cx != top.screen_width + 10 || !first_packet) // Packet complete
      begin
        first_packet <= 0;
        case(header[7:0])
          8'h00: begin
            $display("NULL packet");
          end
          8'h01: begin
            $display("Audio Clock Regen packet N = %d, CTS = %d", N, CTS);
            assert(header[23:8] === 16'd0) else $fatal("Clock regen HB1, HB2 should be X: %b, %b", header[23:16], header[15:8]);
            assert(sub[0] == sub[1] && sub[1] == sub[2] && sub[2] == sub[3]) else $fatal("Clock regen subpackets are different");
            assert(N == 128*48000/1000) else $fatal("Incorrect N: %d should be %d", N, 128*48000/1000);
            if (CTS == 24939)
              $warning("CTS is out of spec, this should only happen once while warming up at the beginning of the testbench.");
            assert(CTS == 25200 || CTS == 25199 || CTS == 24939) else $fatal("Incorrect CTS, should hover around 25200: %d", CTS);
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
              channel_status[1][frame_counter + k] = PCUVr[k][2];
              channel_status[0][frame_counter + k] = PCUVl[k][2];
              if ((frame_counter + k) % 192 == 0) // Last frame was end of IEC60958 frame, this sample starts a new frame
              begin
                if (!first_audio_packet)
                begin
                  assert(channel_status[0] == top.hdmi.true_hdmi_output.packet_picker.audio_sample_packet.channel_status_left) else $fatal("Incorrect left channel status: %h should be %h", channel_status[0], top.hdmi.true_hdmi_output.packet_picker.audio_sample_packet.channel_status_left);
                  assert(channel_status[1] == top.hdmi.true_hdmi_output.packet_picker.audio_sample_packet.channel_status_right) else $fatal("Incorrect right channel status: %h should be %h", channel_status[1], top.hdmi.true_hdmi_output.packet_picker.audio_sample_packet.channel_status_right);
                  assert(previous_sample[0] - 1'd1 == L[k][23:8]) else $fatal("Expected left channel sample to be 1 less than previous: %d - 1 != %d", previous_sample[0], L[k][23:8]);
                  assert(previous_sample[1] + 1'd1 == R[k][23:8]) else $fatal("Expected right channel sample to be 1 greater than previous: %d + 1 != %d", previous_sample[1], R[k][23:8]);
                end
                first_audio_packet <= 0;
                assert(header[20 + k] == 1'b1) else $fatal("Sample B value low for sample %d with counter %d", k, frame_counter);
              end
              else
                assert(header[20 + k] == 1'b0) else $fatal("Sample B value high for sample %d with counter %d", k, frame_counter);
              assert(PCUVr[k][1] == 1'b0 && PCUVl[k][1] == 1'b0) else $fatal("Sample user data bits nonzero");
              assert(PCUVr[k][0] == 1'b0 && PCUVl[k][0] == 1'b0) else $fatal("Sample validity bits nonzero");
              assert({PCUVr[k][3:0], R[k]} % 2 == 0) else $fatal("Sample right parity not even: %b", {PCUVr[k], R[k]});
              assert({PCUVl[k][3:0], L[k]} % 2 == 0) else $fatal("Sample left parity not even: %b", {PCUVl[k], L[k]});
              previous_sample = '{R[k][23:8], L[k][23:8]};
            end
            frame_counter <= (frame_counter + num_samples_present) % 192;
          end
          8'h82: begin
            $display("AVI InfoFrame");
            assert(packet_bytes.sum() + header[23:16] + header[15:8] + header[7:0] == 8'd0) else $fatal("Bad checksum");
            assert(check_non_zero_elem(packet_bytes[14:27]) == 0) else $fatal("Reserved bytes not 0");
          end
          8'h83: begin
            $display("SPD InfoFrame this is a %s created by %s that is a 0x%h", string'(packet_bytes[9:24]), string'(packet_bytes[1:8]), packet_bytes[25]);
            assert(packet_bytes.sum() + header[23:16] + header[15:8] + header[7:0] == 8'd0) else $fatal("Bad checksum");
            assert(check_non_zero_elem(packet_bytes[26:27]) == 0) else $fatal("Reserved bytes not 0");
          end
          8'h84: begin
            $display("Audio InfoFrame");
            assert(packet_bytes.sum() + header[23:16] + header[15:8] + header[7:0] == 8'd0) else $fatal("Bad checksum");
            assert(packet_bytes[1] == 8'd1) else $fatal("Only channel count of 2 should be set");
            assert(packet_bytes[2] == 8'd0 && packet_bytes[3] == 8'd0) else $fatal("These are refer to stream header");
            assert(check_non_zero_elem(packet_bytes[6:27]) == 0) else $fatal("Reserved bytes not 0");
          end
          default: begin
            $fatal("Unhandled packet type %h (%s) at %d, %d: %p", header[7:0], "Unknown", cx, cy, sub);
          end
        endcase
      end
    end
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
end

endmodule
