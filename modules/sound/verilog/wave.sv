module sawtooth (
    input logic clk_32kHz,
    output logic [15:0] level = 16'd0
);

always @(posedge clk_32kHz)
begin
    level <= level + 16'd1;
end
endmodule
