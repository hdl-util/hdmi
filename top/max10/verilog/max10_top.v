module max10_top (
           input  wire       CLK_50MHZ,
           input  wire       CLK_32KHZ,
        //    input  wire			RST,

           output wire       	CLK_50MHZ_ENABLE,
           output wire			CLK_32KHZ_ENABLE,
           output wire	[7:0]	LED,

           output wire [2:0] 	tmds_p,
           output wire			tmds_clock_p,
           output wire [2:0] 	tmds_n,
           output wire			tmds_clock_n
       );
assign CLK_50MHZ_ENABLE = 1'b1;
assign CLK_32KHZ_ENABLE = 1'b0;

wire clk_tmds;
wire clk_pixel;
pll pll(.inclk0(CLK_50MHZ), .c0(clk_tmds), .c1(clk_pixel));

wire [23:0] rgb;
wire [9:0] cx, cy;
hdmi #(.VIDEO_ID_CODE(3)) hdmi(.clk_tmds(clk_tmds), .clk_pixel(clk_pixel), .rgb(rgb), .tmds_p(tmds_p), .tmds_clock_p(tmds_clock_p), .tmds_n(tmds_n), .tmds_clock_n(tmds_clock_n), .cx(cx), .cy(cy));

reg [7:0] character = 8'h30;
reg [5:0] prevcy = 0;
always @(posedge clk_pixel)
begin
    if (cy == 0)
    begin
        character <= 8'h30;
        prevcy <= 0;
    end
    else if (prevcy != cy[9:4])
    begin
        character <= character + 8'h01;
        prevcy <= cy[9:4];
    end
end

console console(.clk_pixel(clk_pixel), .character(character), .attribute({cx[9], cy[8:6], cx[8:5]}), .cx(cx), .cy(cy), .rgb(rgb));
endmodule
