module sawtooth 
#(
    parameter BIT_WIDTH = 16
)
(
    input logic clk_audio,
    output logic signed [BIT_WIDTH-1:0] level = 16'sd0
);

always @(posedge clk_audio)
    level <= level + 16'sd638;
endmodule
