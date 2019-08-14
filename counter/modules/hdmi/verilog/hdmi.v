// Implementation of HDMI Spec v1.3a Section 5.1: Overview & Section 5.2: Operating Modes
// By Sameer Puri https://purisa.me

module hdmi (
           input wire clk_tmds,
           input wire clk_pixel,
           input wire [23:0] rgb,

           output wire [2:0] tmds_p,
           output wire tmds_clock_p,
           output wire [2:0] tmds_n,
           output wire tmds_clock_n,
           output reg [BIT_WIDTH:0] cx,
           output reg [BIT_HEIGHT:0] cy
);

// See CEA-861-D for enumeration of video id codes.
// Formats 1, 2, 3, 4, and 16 are supported.
// Pixel repetition, interlaced scans and other special output modes are not implemented.
parameter VIDEO_ID_CODE = 3;
parameter BIT_WIDTH = VIDEO_ID_CODE < 4 ? 9 : VIDEO_ID_CODE == 4 ? 10 : 11;
parameter BIT_HEIGHT = VIDEO_ID_CODE == 16 ? 10 : 9;

// True differential buffer IP from Quartus.
// Interchangeable with Xilinx OBUFDS primitive where .din is .I, .pad_out is .O, .pad_out_b is .OB
OBUFDS obufds(.din({tmds_shift_red[0], tmds_shift_green[0], tmds_shift_blue[0], clk_pixel}), .pad_out({tmds_p, tmds_clock_p}), .pad_out_b({tmds_n,tmds_clock_n}));

reg [BIT_WIDTH:0] frame_width;
reg [BIT_HEIGHT:0] frame_height;
reg [BIT_WIDTH:0] screen_width;
reg [BIT_HEIGHT:0] screen_height;
reg [BIT_WIDTH:0] screen_start_x;
reg [BIT_HEIGHT:0] screen_start_y;

always @*
begin
    case (VIDEO_ID_CODE)
        1:
        begin
            frame_width = 800;
            frame_height = 525;
            screen_width = 640;
            screen_height = 480;
            end
        2, 3:
        begin
            frame_width = 858;
            frame_height = 525;
            screen_width = 720;
            screen_height = 480;
            end
        4:
        begin
            frame_width = 1650;
            frame_height = 750;
            screen_width = 1280;
            screen_height = 720;
        end
        16:
        begin
            frame_width = 2200;
            frame_height = 1125;
            screen_width = 1920;
            screen_height = 1080;
        end
    endcase
    screen_start_x = frame_width - 1 - screen_width;
    screen_start_y = frame_height - 1 - screen_height;
end

reg hsync;
reg vsync;
always @(posedge clk_pixel)
begin
case (VIDEO_ID_CODE)
    1:
    begin
        hsync <= ~(cx > 15 && cx < 15 + 96);
        vsync <= ~(cy < 2);
    end
    2, 3:
    begin
        hsync <= ~(cx > 15 && cx < 15 + 62);
        vsync <= ~(cy > 5 && cy < 12);
    end
    4:
    begin
        hsync <= cx > 109 && cx < 109 + 40;
        vsync <= cy < 5;
    end
    16:
    begin
        hsync <= cx > 87 && cx < 87 + 44;
        vsync <= cy < 5;
    end
endcase
end

always @(posedge clk_pixel)
begin
    cy = cx == frame_width-1'b1 ? (cy == frame_height-1'b1 ? 1'b0 : cy+1'b1) : cy;
    cx = cx == frame_width-1'b1 ? 1'b0 : cx+1'b1;
end

wire video_data_period = cx >= screen_start_x && cy >= screen_start_y;
wire video_guard = cx >= screen_start_x - 2 && cx < screen_start_x && cy >= screen_start_y;
wire [2:0] mode = video_data_period ? 3'd1 : video_guard ? 3'd2 : 3'd0;

wire video_preamble = cx >= screen_start_x - 10 && cx < screen_start_x - 2 && cy >= screen_start_y;
wire [3:0] ctrl = video_preamble ? 4'b0001 : 4'b0000;

wire	[9:0]	tmds_red, tmds_green, tmds_blue;
tmds_channel #(.CN(2)) red_channel (.clk_pixel(clk_pixel), .video_data(rgb[23:16]), .control_data(ctrl[3:2]), .mode(mode), .tmds(tmds_red));
tmds_channel #(.CN(1)) green_channel (.clk_pixel(clk_pixel), .video_data(rgb[15:8]), .control_data(ctrl[1:0]), .mode(mode), .tmds(tmds_green));
tmds_channel #(.CN(0)) blue_channel (.clk_pixel(clk_pixel), .video_data(rgb[7:0]), .control_data({vsync,hsync}), .mode(mode), .tmds(tmds_blue));

reg [3:0] tmds_counter = 0;
reg [9:0] tmds_shift_red = 0, tmds_shift_green = 0, tmds_shift_blue = 0;

always @(posedge clk_tmds)
begin
    if (tmds_counter == 4'd9)
    begin
        tmds_shift_red = tmds_red;
        tmds_shift_green = tmds_green;
        tmds_shift_blue = tmds_blue;
        tmds_counter = 4'd0;
    end
    else
    begin
        tmds_shift_red = tmds_shift_red[9:1];
        tmds_shift_green = tmds_shift_green[9:1];
        tmds_shift_blue = tmds_shift_blue[9:1];
        tmds_counter = tmds_counter + 1'b1;
    end
end

endmodule
