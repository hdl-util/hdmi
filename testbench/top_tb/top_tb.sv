`timescale 1 ps / 1 ps

module top_tb();

initial begin
  $dumpvars(0, top_tb);
  #36036000000ps $finish; // Terminate simulation after ~2 frames are generated
  // #10000ns $finish;
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
always #20000ps CLK_50MHZ = ~CLK_50MHZ;

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

logic [9:0] cx = 858 - 2;
logic [9:0] cy = 524;

logic [9:0] tmds_values [2:0] = '{10'dx, 10'dx, 10'dx};


logic [7:0] decoded_values [2:0];
genvar i;
genvar j;
generate
  for (j = 0; j < 3; j++)
  begin
    assign decoded_values[j][0] = tmds_values[j][9] == 1 ? ~tmds_values[j][0] : tmds_values[j][0];
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
  if (counter == 9)
    counter <= 0;
  else
    counter <= counter + 1'd1;

  tmds_values[0][counter] <= tmds_p[0];
  tmds_values[1][counter] <= tmds_p[1];
  tmds_values[2][counter] <= tmds_p[2];

  if (counter == 0)
  begin
    tmds_values[0][9:1] <= 9'd0;
    tmds_values[1][9:1] <= 9'd0;
    tmds_values[2][9:1] <= 9'd0;
  end
end

always @(posedge max10_top.clk_pixel)
begin
  cx <= cx == max10_top.hdmi.frame_width - 1 ? 0 : cx + 1;
  cy <= cx == max10_top.hdmi.frame_width-1'b1 ? cy == max10_top.hdmi.frame_height-1'b1 ? 0 : cy + 1'b1 : cy;
  $display("Decoded value for (%d, %d) %b, %b, %b", cx, cy, decoded_values[2], decoded_values[1], decoded_values[0]);
end

endmodule
