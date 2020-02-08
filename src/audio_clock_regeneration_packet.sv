// Implementation of HDMI audio clock regeneration packet
// By Sameer Puri https://github.com/sameer

// See HDMI 1.4a Section 5.3.3
module audio_clock_regeneration_packet
#(
    parameter VIDEO_RATE,
    parameter AUDIO_RATE
)
(
    input logic clk_pixel,
    input logic clk_audio,
    output logic clk_slow_wrap = 1'b0,
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);

// See Section 7.2.3, values derived from "Other" row in Tables 7-1, 7-2, 7-3.
localparam N = AUDIO_RATE % 125 == 0 ? 20'(16 * AUDIO_RATE / 125) : AUDIO_RATE % 225 == 0 ? 20'(196 * AUDIO_RATE / 225) : 20'(AUDIO_RATE * 16 / 125);

localparam CLK_SLOW_WIDTH = $clog2(N / 128);
localparam CLK_SLOW_END = CLK_SLOW_WIDTH'(N / 128);
logic [CLK_SLOW_WIDTH-1:0] clk_slow_counter = CLK_SLOW_WIDTH'(1);
always @(posedge clk_audio)
begin
    if (clk_slow_counter == CLK_SLOW_END)
    begin
        clk_slow_counter <= CLK_SLOW_WIDTH'(0);
        clk_slow_wrap <= !clk_slow_wrap;
    end
    else
        clk_slow_counter <= clk_slow_counter + CLK_SLOW_WIDTH'(1);
end

localparam CTS_IDEAL = 20'(VIDEO_RATE*N/128/AUDIO_RATE);
localparam CTS_WIDTH = $clog2(20'(CTS_IDEAL * 1.1));
logic [19:0] cts;
logic last_clk_slow_wrap = 1'b0;
logic [CTS_WIDTH-1:0] cts_counter = CTS_WIDTH'(0);
always @(posedge clk_pixel)
begin
    if (last_clk_slow_wrap != clk_slow_wrap)
    begin
        cts_counter <= CTS_WIDTH'(0);
        cts <= {(20-CTS_WIDTH)'(0), cts_counter};
        last_clk_slow_wrap <= clk_slow_wrap;
    end
    else
        cts_counter <= cts_counter + CTS_WIDTH'(1);
end

// "An HDMI Sink shall ignore bytes HB1 and HB2 of the Audio Clock Regeneration Packet header."
`ifdef MODEL_TECH
assign header = {8'd0, 8'd0, 8'd1};
`else
assign header = {8'dX, 8'dX, 8'd1};
`endif
// "The four Subpackets each contain the same Audio Clock regeneration Subpacket."
genvar i;
generate
    for (i = 0; i < 4; i++)
    begin: same_packet
        assign sub[i] = {N[7:0], N[15:8], {4'd0, N[19:16]}, cts[7:0], cts[15:8], {4'd0, cts[19:16]}, 8'd0};
    end
endgenerate

endmodule
