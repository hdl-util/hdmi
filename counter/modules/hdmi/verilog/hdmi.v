module hdmi (
           input wire CLK_TMDS,
           input wire CLK_PIXEL,
           input wire [23:0]rgb,

           output wire [2:0] TMDSp,
           output wire TMDS_clockp,
           output wire [2:0] TMDSn,
           output wire TMDS_clockn,
           output reg [9:0] cx,
           output reg [9:0] cy
       );


OBUFDS obufds(.din({TMDS_shift_red[0], TMDS_shift_green[0], TMDS_shift_blue[0], CLK_PIXEL}), .pad_out({TMDSp, TMDS_clockp}), .pad_out_b({TMDSn,TMDS_clockn}));

parameter FRAME_WIDTH = 10'd800;
parameter FRAME_HEIGHT = 10'd525;
parameter SCREEN_WIDTH = 10'd640;
parameter SCREEN_HEIGHT = 10'd480;

always @(posedge CLK_PIXEL) cx <= cx == FRAME_WIDTH-1 ? 10'd0 : cx+1;
always @(posedge CLK_PIXEL) cy <= cx == FRAME_WIDTH-1 ? (cy == FRAME_HEIGHT-1 ? 10'd0 : cy+1) : cy;

wire hsync = cx >= 10'd656 && cx < 10'd752;
wire vsync = cy >= 10'd490 && cy < 10'd492;
wire draw_area = cx < SCREEN_WIDTH && cy < SCREEN_HEIGHT;

wire	[9:0]	TMDS_red, TMDS_green, TMDS_blue;
TMDS_channel #(.CN(2)) red_channel (.clk(CLK_PIXEL), .VD(rgb[23:16]), .CD(2'b00), .M(draw_area ? 2'd1 : 2'd0), .TMDS(TMDS_red));
TMDS_channel #(.CN(1)) green_channel (.clk(CLK_PIXEL), .VD(rgb[15:8]), .CD(2'b00), .M(draw_area ? 2'd1 : 2'd0), .TMDS(TMDS_green));
TMDS_channel #(.CN(0)) blue_channel (.clk(CLK_PIXEL), .VD(rgb[7:0]), .CD({vsync,hsync}), .M(draw_area ? 2'd1 : 2'd0), .TMDS(TMDS_blue));


reg [3:0] TMDS_mod10=0;  // modulus 10 counter
reg [9:0] TMDS_shift_red=0, TMDS_shift_green=0, TMDS_shift_blue=0;
reg TMDS_shift_load=0;
always @(posedge CLK_TMDS) TMDS_shift_load <= (TMDS_mod10==9);

always @(posedge CLK_TMDS)
begin
    TMDS_shift_red   <= TMDS_shift_load ? TMDS_red   : TMDS_shift_red  [9:1];
    TMDS_shift_green <= TMDS_shift_load ? TMDS_green : TMDS_shift_green[9:1];
    TMDS_shift_blue  <= TMDS_shift_load ? TMDS_blue  : TMDS_shift_blue [9:1];
    TMDS_mod10 <= (TMDS_mod10==4'd9) ? 1'b0 : TMDS_mod10+1'b1;
end

endmodule
