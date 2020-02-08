module top (
    input logic clk_original,

    output logic [2:0] tmds_p,
    output logic tmds_clock_p,
    output logic [2:0] tmds_n,
    output logic tmds_clock_n
);

logic clk_pixel;
logic clk_pixel_x10;
logic clk_audio;

pll pll(.inclk0(clk_original), .c0(clk_pixel_x10), .c1(clk_pixel), .c2(clk_audio));

logic signed [15:0] audio_sample_word = 16'sd0; // Since the L-PCM audio is 2-channel by default, this is mono audio.
always @(posedge clk_audio) // Sawtooth wave generator
  audio_sample_word <= audio_sample_word + 16'sd638;

logic [23:0] rgb;
logic [9:0] cx, cy;
// Border test (left = red, top = green, right = blue, bottom = blue, fill = black)
always @(posedge clk_pixel)
  rgb <= {cx == 138 ? ~8'd0 : 8'd0, cy == 45 ? ~8'd0 : 8'd0, cx == 857 || cy == 524 ? ~8'd0 : 8'd0};

// 720x480 @ 59.94Hz
hdmi #(.VIDEO_ID_CODE(3), .VIDEO_REFRESH_RATE(59.94), .AUDIO_RATE(48000), .AUDIO_BIT_WIDTH(16)) hdmi(.clk_pixel_x10(clk_pixel_x10), .clk_pixel(clk_pixel), .clk_audio(clk_audio), .rgb(rgb), .audio_sample_word('{audio_sample_word, audio_sample_word}), .tmds_p(tmds_p), .tmds_clock_p(tmds_clock_p), .tmds_n(tmds_n), .tmds_clock_n(tmds_clock_n), .cx(cx), .cy(cy));

endmodule
