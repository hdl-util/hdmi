module sawtooth 
#(
    parameter BIT_WIDTH = 16,
    parameter SAMPLE_RATE = 48000.0,
    parameter WAVE_RATE = 480
)
(
    input logic clk_audio,
    output logic signed [BIT_WIDTH-1:0] level = BIT_WIDTH'(0)
);

localparam INCREMENT = BIT_WIDTH'($signed(((WAVE_RATE * 2**BIT_WIDTH) / SAMPLE_RATE)));

always @(posedge clk_audio)
    level <= level + INCREMENT;
endmodule
