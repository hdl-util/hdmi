`timescale 1 ps / 1 ps

module top_tb();

initial begin
  $dumpvars(0, top_tb);
  // #36036000000ps $finish; // Terminate simulation after ~2 frames are generated
  #20us $stop;
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

// Clock generator
always #100ns CLK_32KHZ = ~CLK_32KHZ;
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
    .tmds_clock_n(tmds_clock_n)
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

logic [5:0] data_counter = 0;
logic [63:0] sub [3:0] = '{64'dX, 64'dX, 64'dX, 64'dX};
logic [31:0] header = 32'dX;

always @(posedge max10_top.clk_pixel)
begin
  cx <= cx == max10_top.hdmi.frame_width - 1 ? 0 : cx + 1;
  cy <= cx == max10_top.hdmi.frame_width-1'b1 ? cy == max10_top.hdmi.frame_height-1'b1 ? 0 : cy + 1'b1 : cy;

  if (cx >= max10_top.hdmi.screen_start_x - 2 && cx < max10_top.hdmi.screen_start_x && cy < max10_top.hdmi.screen_start_y)
  begin
    assert(tmds_values[2] == 10'b0100110011) else $fatal("Channel 2 DI GB incorrect");
    assert(tmds_values[1] == 10'b0100110011) else $fatal("Channel 1 DI GB incorrect");
    assert(tmds_values[0] == 10'b1011000011) else $fatal("Channel 0 DI GB incorrect");
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
      if (cx != max10_top.hdmi.screen_start_x) // Packet complete
      begin
        $display("Received %s packet", header[7:0] == 8'h00 ? "NULL" : header[7:0] == 8'h01 ? "Audio Clock Regen" : header[7:0] == 8'h02 ? "Audio Sample" : header[7:0] == 8'h82 ? "AVI InfoFrame" : header[7:0] == 8'h84 ? "Audio InfoFrame" : "Unknown");
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
  else if (cx == max10_top.hdmi.frame_width - 3 && cy == max10_top.hdmi.frame_height - 1)
    assert (tmds_values[2] == tmds_values[1] && tmds_values[0] == tmds_values[1] && tmds_values[2] == 10'b1101010100) else $fatal("Incorrect first value: %b", tmds_values[2]);
end

endmodule
