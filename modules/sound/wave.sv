module sawtooth 
#(
    parameter BIT_WIDTH = 16
)
(
    input logic clk_audio,
    output logic signed [BIT_WIDTH-1:0] level = $signed(0)
);

always @(posedge clk_audio)
    level <= level + $signed(BIT_WIDTH'(1));
endmodule
