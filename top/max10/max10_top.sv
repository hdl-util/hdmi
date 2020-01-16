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
    output wire tmds_clock_n
);
assign CLK_50MHZ_ENABLE = 1'b1;
assign CLK_32KHZ_ENABLE = 1'b1;

wire clk_tmds;
wire clk_pixel;
pll pll(.inclk0(CLK_50MHZ), .c0(clk_tmds), .c1(clk_pixel));

localparam AUDIO_BIT_WIDTH = 16;
wire [AUDIO_BIT_WIDTH-1:0] audio_in;
wire [AUDIO_BIT_WIDTH-1:0] audio_out;
sawtooth #(.BIT_WIDTH(AUDIO_BIT_WIDTH)) sawtooth (.clk_audio(CLK_32KHZ), .level(audio_in));

logic [7:0] remaining;
buffer #(.CHANNELS(1), .BIT_WIDTH(AUDIO_BIT_WIDTH)) buffer (.clk_audio(CLK_32KHZ), .clk_pixel(clk_pixel), .packet_enable(packet_enable && packet_type == 8'd2), .audio_in('{audio_in}), .audio_out('{audio_out}), .remaining(remaining));

logic [7:0] packet_type;
logic audio_clock_regeneration_sent = 1'b0;
logic audio_info_frame_sent = 1'b0;

always @(posedge clk_pixel)
begin
    if (cx == 0 && cy == 0) // RESET
    begin
        audio_clock_regeneration_sent <= 1'b0;
        audio_info_frame_sent <= 1'b0;
    end
    if (packet_enable)
    begin
        if (!audio_clock_regeneration_sent)
        begin
            packet_type <= 8'd1;
            audio_clock_regeneration_sent <= 1'b1;
        end
        else if (!audio_info_frame_sent)
        begin
            packet_type <= 8'h84;
            audio_info_frame_sent <= 1'b1;
        end
        else if (remaining > 0)
            packet_type <= 8'd2;
        else
            packet_type <= 8'd0;
    end
end

wire [23:0] rgb;
wire [9:0] cx, cy;
wire packet_enable;
hdmi #(.VIDEO_ID_CODE(3), .AUDIO_BIT_WIDTH(AUDIO_BIT_WIDTH)) hdmi(.clk_tmds(clk_tmds), .clk_pixel(clk_pixel), .rgb(rgb), .audio_sample_word('{audio_out, audio_out}), .packet_type(packet_type), .tmds_p(tmds_p), .tmds_clock_p(tmds_clock_p), .tmds_n(tmds_n), .tmds_clock_n(tmds_clock_n), .cx(cx), .cy(cy), .packet_enable(packet_enable));

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
