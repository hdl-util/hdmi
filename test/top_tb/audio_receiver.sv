module audio_receiver (
    input logic [19:0] n,
    input logic [19:0] cts,
    input logic clk_pixel,
    input logic [23:0] samples [3:0],
    input logic samples_present [3:0]
);

logic clk_audio = 1'b0;

always
begin
    #n;
end

endmodule