// Implementation of HDMI Spec v1.3a Section 5.1: Overview, Section 5.2: Operating Modes, Section 5.3.1: Packet Header, Section 5.3.2: Null Packet, Section 5.4.1: Serialization
// By Sameer Puri https://github.com/sameer

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

// Defaults to 640x480 which should be supported by almost if not all HDMI sinks.
// See CEA-861-D for enumeration of video id codes.
// Formats 1, 2, 3, 4, and 16 are supported.
// Pixel repetition, interlaced scans and other special output modes are not implemented.
parameter VIDEO_ID_CODE = 1;

// Defaults to minimum bit lengths required to represent positions.
// Modify these parameters if you have alternate desired bit lengths.
parameter BIT_WIDTH = VIDEO_ID_CODE < 4 ? 9 : VIDEO_ID_CODE == 4 ? 10 : 11;
parameter BIT_HEIGHT = VIDEO_ID_CODE == 16 ? 10 : 9;

// HDMI sinks are backwards-compatible with DVI input.
// A true HDMI signal sends auxiliary data (i.e. audio) which cannot be properly parsed by sinks expecting a DVI signal.
// Enable this flag if the output should be a DVI signal (i.e. using an HDMI to DVI adapter, or direct DVI output).
parameter DVI_OUTPUT = 1'b0;

// True differential buffer built with altera_gpio_lite from the Intel IP Catalog.
// Interchangeable with Xilinx OBUFDS primitive where .din is .I, .pad_out is .O, .pad_out_b is .OB
OBUFDS obufds(.din({tmds_shift_red[0], tmds_shift_green[0], tmds_shift_blue[0], clk_pixel}), .pad_out({tmds_p, tmds_clock_p}), .pad_out_b({tmds_n,tmds_clock_n}));

// See CEA-861-D for more specifics formats described below.
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

// Wrap-around pixel position counters
always @(posedge clk_pixel)
begin
    cx <= cx == frame_width-1'b1 ? 1'b0 : cx + 1'b1;
    cy <= cx == frame_width-1'b1 ? cy == frame_height-1'b1 ? 1'b0 : cy + 1'b1 : cy;
end

// See Section 5.2
wire video_data_period = cx >= screen_start_x && cy >= screen_start_y;
wire video_guard = (cx >= screen_start_x - 2 && cx < screen_start_x) && cy >= screen_start_y;
wire video_preamble = (cx >= screen_start_x - 10 && cx < screen_start_x - 2) && cy >= screen_start_y;

// See Section 5.2.3.1
wire data_island_guard = !DVI_OUTPUT && ((cx >= screen_start_x - 2 && cx < screen_start_x) || (cx >= screen_start_x + 32 && cx < screen_start_x + 34)) && cy < screen_start_y;
wire data_island_preamble = !DVI_OUTPUT && (cx >= screen_start_x - 10 && cx < screen_start_x - 2) && cy < screen_start_y;
wire data_island_period = !DVI_OUTPUT && (cx >= screen_start_x && cx < screen_start_x + 32) && cy < screen_start_y;

reg [2:0] mode = 3'd0;
reg [23:0] video_data = 24'd0;
reg [11:0] data_island_data = 12'd0;
reg [5:0] control_data = 6'd0;

always @(posedge clk_pixel)
begin
    mode <= data_island_guard ? 3'd4 : data_island_period ? 3'd3 : video_guard ? 3'd2 : video_data_period ? 3'd1 : 3'd0;
    video_data <= rgb;
    // See Section 5.2.3.4, Section 5.3.1, Section 5.3.2
    data_island_data <= {4'd0, 4'd0, {cx != screen_start_x, 1'b0, vsync, hsync}}; // NULL packet
    control_data <= {{1'b0, data_island_preamble}, {1'b0, video_preamble || data_island_preamble}, {vsync, hsync}}; // ctrl3, ctrl2, ctrl1, ctrl0, vsync, hsync
end

wire [9:0] tmds_red, tmds_green, tmds_blue;
tmds_channel #(.CN(2)) red_channel (.clk_pixel(clk_pixel), .video_data(video_data[23:16]), .data_island_data(data_island_data[11:8]), .control_data(control_data[5:4]), .mode(mode), .tmds(tmds_red));
tmds_channel #(.CN(1)) green_channel (.clk_pixel(clk_pixel), .video_data(video_data[15:8]), .data_island_data(data_island_data[7:4]), .control_data(control_data[3:2]), .mode(mode), .tmds(tmds_green));
tmds_channel #(.CN(0)) blue_channel (.clk_pixel(clk_pixel), .video_data(video_data[7:0]), .data_island_data(data_island_data[3:0]), .control_data(control_data[1:0]), .mode(mode), .tmds(tmds_blue));

// See Section 5.4.1
reg [3:0] tmds_counter = 4'd0;

// All channels are initialized to the 0,0 control signal from 5.4.2.
// This gives time for the first pixel to be generated due to the 1-pixel clock delay.
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
