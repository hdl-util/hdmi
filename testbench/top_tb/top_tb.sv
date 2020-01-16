`timescale 1 ps / 1 ps

module top_tb();

initial begin
  $dumpvars(0, top_tb);
  #50ms $finish; // Terminate simulation after ~3 frames are generated
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

endmodule
