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
always #30517578.125ps CLK_32KHZ = ~CLK_32KHZ;
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

always @(posedge max10_top.clk_pixel)
begin
  cx <= cx == max10_top.hdmi.frame_width - 1 ? 0 : cx + 1;
  cy <= cx == max10_top.hdmi.frame_width-1'b1 ? cy == max10_top.hdmi.frame_height-1'b1 ? 0 : cy + 1'b1 : cy;
  if (max10_top.hdmi.data_island_guard)
  begin
    $display("DI guard at (%d, %d)", max10_top.hdmi.cx - 1, max10_top.hdmi.cy);
  end
  if (max10_top.hdmi.mode == 3'd4)
  begin
    $display("DI guard TMDS at (%d, %d) sending %b, shift is %b with counter %d", max10_top.hdmi.cx - 2, max10_top.hdmi.cy, max10_top.hdmi.tmds_gen[2].tmds_channel.data_guard_band, max10_top.hdmi.tmds_shift[2], max10_top.hdmi.tmds_counter);
  end
  if (cx >= max10_top.hdmi.screen_start_x - 2 && cx < max10_top.hdmi.screen_start_x && cy < max10_top.hdmi.screen_start_y)
  begin
    assert(tmds_values[2] == 10'b0100110011) else $fatal("Channel 2 DI GB incorrect");
    assert(tmds_values[1] == 10'b0100110011) else $fatal("Channel 1 DI GB incorrect");
    assert(tmds_values[0] == 10'b1011000011) else $fatal("Channel 0 DI GB incorrect");
    $display("Original value for (%d, %d) %b, %b, %b", cx, cy, tmds_values[2], tmds_values[1], tmds_values[0]);
    $display("Decoded value for (%d, %d) %b, %b, %b", cx, cy, decoded_values[2], decoded_values[1], decoded_values[0]);
  end
  else if (cx == max10_top.hdmi.frame_width - 3 && cy == max10_top.hdmi.frame_height - 1)
    assert (tmds_values[2] == tmds_values[1] && tmds_values[0] == tmds_values[1] && tmds_values[2] == 10'b1101010100) else $fatal("Incorrect first value: %b", tmds_values[2]);
end

endmodule
