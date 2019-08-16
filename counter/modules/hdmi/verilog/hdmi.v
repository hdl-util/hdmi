// Implementation of HDMI Spec v1.3a Section 5.1: Overview && Section 5.2: Operating Modes
// By Sameer Puri https://purisa.me

module hdmi (
           input wire clk_tmds,
           input wire clk_pixel,
           input wire [23:0] rgb,

           output wire [2:0] tmds_p,
           output wire tmds_clock_p,
           output wire [2:0] tmds_n,
           output wire tmds_clock_n,
           output reg [BIT_WIDTH:0] cx = 0,
           output reg [BIT_HEIGHT:0] cy = 0
);

// See CEA-861-D for enumeration of video id codes.
// Formats 1, 2, 3, 4, and 16 are supported.
// Pixel repetition, interlaced scans and other special output modes are not implemented.
parameter VIDEO_ID_CODE = 3;
parameter BIT_WIDTH = 9;//VIDEO_ID_CODE < 4 ? 9 : VIDEO_ID_CODE == 4 ? 10 : 11;
parameter BIT_HEIGHT = 9;//VIDEO_ID_CODE == 16 ? 10 : 9;

// True differential buffer IP from Quartus.
// Interchangeable with Xilinx OBUFDS primitive where .din is .I, .pad_out is .O, .pad_out_b is .OB
OBUFDS obufds(.din({tmds_shift_red[0], tmds_shift_green[0], tmds_shift_blue[0], clk_pixel}), .pad_out({tmds_p, tmds_clock_p}), .pad_out_b({tmds_n,tmds_clock_n}));

reg [BIT_WIDTH:0] frame_width = 858;
reg [BIT_HEIGHT:0] frame_height = 525;
reg [BIT_WIDTH:0] screen_width = 720;
reg [BIT_HEIGHT:0] screen_height = 480;
wire [BIT_WIDTH:0] screen_start_x = frame_width - screen_width;
wire [BIT_HEIGHT:0] screen_start_y = frame_height - screen_height;

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
end

reg hsync = 0;
reg vsync = 0;
always @(posedge clk_pixel)
begin
case (VIDEO_ID_CODE)
    1:
    begin
        hsync <= ~(cx > 15 && cx <= 15 + 96);
        vsync <= ~(cy < 2);
    end
    2, 3:
    begin
        hsync <= ~(cx > 15 && cx <= 15 + 62);
        vsync <= ~(cy > 5 && cy < 12);
    end
    4:
    begin
        hsync <= cx > 109 && cx <= 109 + 40;
        vsync <= cy < 5;
    end
    16:
    begin
        hsync <= cx > 87 && cx <= 87 + 44;
        vsync <= cy < 5;
    end
endcase
end

always @(posedge clk_pixel)
begin
    cx <= cx == frame_width-1'b1 ? 1'b0 : cx + 1'b1;
    cy <= cx == frame_width-1'b1 ? cy == frame_height-1'b1 ? 1'b0 : cy + 1'b1 : cy;
end

wire video_data_period = cx >= screen_start_x && cy >= screen_start_y;
wire video_guard = (cx >= screen_start_x - 2 && cx < screen_start_x) && cy >= screen_start_y;
wire video_preamble = (cx >= screen_start_x - 10 && cx < screen_start_x - 2) && cy >= screen_start_y;

wire data_island_guard = ((cx >= screen_start_x - 2 && cx < screen_start_x) || (cx >= screen_start_x + 32 && cx < screen_start_x + 34)) && cy < screen_start_y;
wire data_island_preamble = (cx >= screen_start_x - 10 && cx < screen_start_x - 2) && cy < screen_start_y;
wire data_island_period = (cx >= screen_start_x && cx < screen_start_x + 32) && cy < screen_start_y;
// wire data_island_guard = ((cx >= screen_start_x - 50 && cx < screen_start_x - 48) || (cx >= screen_start_x - 16 && cx < screen_start_x - 14)) && vsync;
// wire data_island_preamble = (cx >= screen_start_x - 58 && cx < screen_start_x - 50) && vsync;
// wire data_island_period = (cx >= screen_start_x - 48 && cx < screen_start_x - 16) && vsync;

reg [2:0] mode = 3'd0;
reg [23:0] video_data = 24'd0;
reg [11:0] data_island_data = 12'd0;
reg [5:0] control_data = 6'd0;

always @(posedge clk_pixel)
begin
    mode <= data_island_guard ? 3'd4 : data_island_period ? 3'd3 : video_guard ? 3'd2 : video_data_period ? 3'd1 : 3'd0;
    video_data <= rgb;
    data_island_data <= {4'd0, 4'd0, {cx != screen_start_x, 1'b0, vsync, hsync}}; // NULL packet
    control_data <= {{1'b0, data_island_preamble}, {1'b0, video_preamble || data_island_preamble}, {vsync, hsync}}; // ctrl3, ctrl2, ctrl1, ctrl0, vsync, hsync
end

wire [9:0] tmds_red, tmds_green, tmds_blue;
tmds_channel #(.CN(2)) red_channel (.clk_pixel(clk_pixel), .video_data(video_data[23:16]), .data_island_data(data_island_data[11:8]), .control_data(control_data[5:4]), .mode(mode), .tmds(tmds_red));
tmds_channel #(.CN(1)) green_channel (.clk_pixel(clk_pixel), .video_data(video_data[15:8]), .data_island_data(data_island_data[7:4]), .control_data(control_data[3:2]), .mode(mode), .tmds(tmds_green));
tmds_channel #(.CN(0)) blue_channel (.clk_pixel(clk_pixel), .video_data(video_data[7:0]), .data_island_data(data_island_data[3:0]), .control_data(control_data[1:0]), .mode(mode), .tmds(tmds_blue));

reg [3:0] tmds_counter = 4'd0;
reg [9:0] tmds_shift_red = 10'b1101010100, tmds_shift_green = 10'b1101010100, tmds_shift_blue = 10'b1101010100;

always @(posedge clk_tmds)
begin
    if (tmds_counter == 4'd10)
    begin
        tmds_shift_red <= tmds_red;
        tmds_shift_green <= tmds_green;
        tmds_shift_blue <= tmds_blue;
        tmds_counter <= 4'd1;
    end
    else
    begin
        tmds_shift_red <= tmds_shift_red[9:1];
        tmds_shift_green <= tmds_shift_green[9:1];
        tmds_shift_blue <= tmds_shift_blue[9:1];
        tmds_counter <= tmds_counter + 1'b1;
    end
end

endmodule
