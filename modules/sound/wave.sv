module sawtooth 
#(
    parameter BIT_WIDTH = 16
)
(
    input logic clk_audio,
    output logic [BIT_WIDTH:0] level = BIT_WIDTH'(0)
);

always @(posedge clk_audio)
    level <= level + 1'd1;
endmodule
