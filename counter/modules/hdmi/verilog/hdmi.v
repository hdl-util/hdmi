// Implementation of HDMI Spec v1.3a Section 5.1: Overview & Section 5.2: Operating Modes
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

// See Page 21 of CEA-861-D, Format 3: 720x480p @59.94Hz
parameter FRAME_WIDTH = 10'd858;
parameter FRAME_HEIGHT = 10'd525;
parameter SCREEN_WIDTH = 10'd720;
parameter SCREEN_HEIGHT = 10'd480;
reg [9:0] FRAME_START_X = (FRAME_WIDTH - SCREEN_WIDTH);
reg [9:0] FRAME_START_Y = (FRAME_HEIGHT - SCREEN_HEIGHT);

always @(posedge CLK_PIXEL) cx <= cx == FRAME_WIDTH-1 ? 10'd0 : cx+1;
always @(posedge CLK_PIXEL) cy <= cx == FRAME_WIDTH-1 ? (cy == FRAME_HEIGHT-1 ? 10'd0 : cy+1) : cy;

wire hsync = ~(cx >= 16 && cx < 78);
wire vsync = ~(cy >= 7 && cy < 13);
wire draw_area = cx >= FRAME_START_X && cy >= FRAME_START_Y;
wire video_guard = cx >= FRAME_START_X - 2 && cx < FRAME_START_X;
wire video_preamble = cx >= FRAME_START_X - 10 && cx < FRAME_START_X - 2;
wire mode = draw_area ? 2'd1 : video_guard ? 2'd2 : 2'd0;
wire [3:0] ctrl = video_preamble ? 4'b0001 : 4'b0000;

wire	[9:0]	TMDS_red, TMDS_green, TMDS_blue;
TMDS_channel #(.CN(2)) red_channel (.clk(CLK_PIXEL), .VD(rgb[23:16]), .CD(ctrl[3:2]), .M(mode), .TMDS(TMDS_red));
TMDS_channel #(.CN(1)) green_channel (.clk(CLK_PIXEL), .VD(rgb[15:8]), .CD(ctrl[1:0]), .M(mode), .TMDS(TMDS_green));
TMDS_channel #(.CN(0)) blue_channel (.clk(CLK_PIXEL), .VD(rgb[7:0]), .CD({vsync,hsync}), .M(mode), .TMDS(TMDS_blue));


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
