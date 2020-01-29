module max10_top (
    input wire CLK_50MHZ,
    input wire CLK_32KHZ,
    input wire RST,

    output wire CLK_50MHZ_ENABLE,
    output wire CLK_32KHZ_ENABLE,
    output wire [7:0] LED,

    output wire [2:0] tmds_p,
    output wire tmds_clock_p,
    output wire [2:0] tmds_n,
    output wire tmds_clock_n,

    output wire PWM_OUT
);
assign CLK_50MHZ_ENABLE = 1'b1;
assign CLK_32KHZ_ENABLE = 1'b0;

wire clk_tmds;
wire clk_pixel;
wire clk_audio;
pll pll(.inclk0(CLK_50MHZ), .c0(clk_tmds), .c1(clk_pixel), .c2(clk_audio));

localparam AUDIO_BIT_WIDTH = 16;
localparam AUDIO_RATE = 48000;
localparam WAVE_RATE = 480;

logic [AUDIO_BIT_WIDTH-1:0] audio_sample_word;
sawtooth #(.BIT_WIDTH(AUDIO_BIT_WIDTH), .SAMPLE_RATE(AUDIO_RATE), .WAVE_RATE(WAVE_RATE)) sawtooth (.clk_audio(clk_audio), .level(audio_sample_word));

logic [AUDIO_BIT_WIDTH:0] pwm_acc = 0;
assign PWM_OUT = pwm_acc[AUDIO_BIT_WIDTH];
always @(posedge clk_audio)
    pwm_acc <= pwm_acc[AUDIO_BIT_WIDTH-1:0] + audio_sample_word;

logic [23:0] rgb;
logic [9:0] cx, cy;
hdmi #(.VIDEO_ID_CODE(3), .AUDIO_RATE(AUDIO_RATE), .AUDIO_BIT_WIDTH(AUDIO_BIT_WIDTH)) hdmi(.clk_tmds(clk_tmds), .clk_pixel(clk_pixel), .clk_audio(clk_audio), .rgb(rgb), .audio_sample_word('{audio_sample_word, audio_sample_word}), .tmds_p(tmds_p), .tmds_clock_p(tmds_clock_p), .tmds_n(tmds_n), .tmds_clock_n(tmds_clock_n), .cx(cx), .cy(cy));

logic [7:0] character = 8'h30;
logic [5:0] prevcy = 6'd0;
always @(posedge clk_pixel)
begin
    if (cy == 10'd0)
    begin
        character <= 8'h30;
        prevcy <= 6'd0;
    end
    else if (prevcy != cy[9:4])
    begin
        character <= character + 8'h01;
        prevcy <= cy[9:4];
    end
end

console console(.clk_pixel(clk_pixel), .character(character), .attribute({cx[9], cy[8:6], cx[8:5]}), .cx(cx), .cy(cy), .rgb(rgb));
endmodule
