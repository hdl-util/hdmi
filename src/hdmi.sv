// Implementation of HDMI Spec v1.4a
// By Sameer Puri https://github.com/sameer

module hdmi 
#(
    // Defaults to 640x480 which should be supported by almost if not all HDMI sinks.
    // See README.md or CEA-861-D for enumeration of video id codes.
    // Pixel repetition, interlaced scans and other special output modes are not implemented (yet).
    parameter int VIDEO_ID_CODE = 1,

    // Defaults to minimum bit lengths required to represent positions.
    // Modify these parameters if you have alternate desired bit lengths.
    parameter int BIT_WIDTH = VIDEO_ID_CODE < 4 ? 10 : VIDEO_ID_CODE == 4 ? 11 : 12,
    parameter int BIT_HEIGHT = VIDEO_ID_CODE == 16 ? 11: 10,

    // A true HDMI signal sends auxiliary data (i.e. audio, preambles) which prevents it from being parsed by DVI signal sinks.
    // HDMI signal sinks are fortunately backwards-compatible with DVI signals.
    // Enable this flag if the output should be a DVI signal. You might want to do this to reduce resource usage or if you're only outputting video.
    parameter bit DVI_OUTPUT = 1'b0,

    // When enabled, DDRIO (Double Data Rate I/O) is used and clk_pixel_x10 only needs to be five times as fast as clk_pixel.
    parameter bit DDRIO = 1'b0,

    // **All parameters below matter ONLY IF you plan on sending auxiliary data (DVI_OUTPUT == 1'b0)**

    // Specify the refresh rate in Hz you are using for audio calculations
    parameter real VIDEO_REFRESH_RATE = 59.94,

    // As specified in Section 7.3, the minimal audio requirements are met: 16-bit or more L-PCM audio at 32 kHz, 44.1 kHz, or 48 kHz.
    // See Table 7-4 or README.md for an enumeration of sampling frequencies supported by HDMI.
    // Note that sinks may not support rates above 48 kHz.
    parameter int AUDIO_RATE = 44100,

    // Defaults to 16-bit audio, the minmimum supported by HDMI sinks. Can be anywhere from 16-bit to 24-bit.
    parameter int AUDIO_BIT_WIDTH = 16,

    // Some HDMI sinks will show the source product description below to users (i.e. in a list of inputs instead of HDMI 1, HDMI 2, etc.).
    // If you care about this, change it below.
    parameter bit [8*8-1:0] VENDOR_NAME = {"Unknown", 8'd0}, // Must be 8 bytes null-padded 7-bit ASCII
    parameter bit [8*16-1:0] PRODUCT_DESCRIPTION = {"FPGA", 96'd0}, // Must be 16 bytes null-padded 7-bit ASCII
    parameter bit [7:0] SOURCE_DEVICE_INFORMATION = 8'h00 // See README.md or CTA-861-G for the list of valid codes
)
(
    input logic clk_pixel_x10,
    input logic clk_pixel,
    input logic clk_audio,
    input logic [23:0] rgb,
    input logic [AUDIO_BIT_WIDTH-1:0] audio_sample_word [1:0],

    // These outputs go to your HDMI port
    output logic [2:0] tmds_p,
    output logic tmds_clock_p,
    output logic [2:0] tmds_n,
    output logic tmds_clock_n,
    
    // All outputs below this line stay inside the FPGA
    // They are used (by you) to pick the color each pixel should have
    // i.e. always_ff @(posedge pixel_clk) rgb <= {8'd0, 8'(cx), 8'(cy)};
    output logic [BIT_WIDTH-1:0] cx = BIT_WIDTH'(0),
    output logic [BIT_HEIGHT-1:0] cy = BIT_HEIGHT'(0),
    
    // the screen is at the bottom right corner of the frame, namely:
    // frame_width = screen_start_x + screen_width
    // frame_height = screen_start_y + screen_height
    output logic [BIT_WIDTH-1:0] frame_width,
    output logic [BIT_HEIGHT-1:0] frame_height,
    output logic [BIT_WIDTH-1:0] screen_width,
    output logic [BIT_HEIGHT-1:0] screen_height,
    output logic [BIT_WIDTH-1:0] screen_start_x,
    output logic [BIT_HEIGHT-1:0] screen_start_y
);

localparam int NUM_CHANNELS = 3;
logic hsync;
logic vsync;

// See CEA-861-D for more specifics formats described below.
generate
    case (VIDEO_ID_CODE)
        1:
        begin
            assign frame_width = 800;
            assign frame_height = 525;
            assign screen_width = 640;
            assign screen_height = 480;
            assign hsync = ~(cx >= 16 && cx < 16 + 96);
            assign vsync = ~(cy >= 10 && cy < 10 + 2);
            end
        2, 3:
        begin
            assign frame_width = 858;
            assign frame_height = 525;
            assign screen_width = 720;
            assign screen_height = 480;
            assign hsync = ~(cx >= 16 && cx < 16 + 62);
            assign vsync = ~(cy >= 9 && cy < 9 + 6);
            end
        4:
        begin
            assign frame_width = 1650;
            assign frame_height = 750;
            assign screen_width = 1280;
            assign screen_height = 720;
            assign hsync = cx >= 110 && cx < 110 + 40;
            assign vsync = cy >= 5 && cy < 5 + 5;
        end
        16:
        begin
            assign frame_width = 2200;
            assign frame_height = 1125;
            assign screen_width = 1920;
            assign screen_height = 1080;
            assign hsync = cx >= 88 && cx < 88 + 44;
            assign vsync = cy >= 4 && cy < 4 + 5;
        end
        17, 18:
        begin
            assign frame_width = 864;
            assign frame_height = 625;
            assign screen_width = 720;
            assign screen_height = 576;
            assign hsync = ~(cx >= 12 && cx < 12 + 64);
            assign vsync = ~(cy >= 5 && cy < 5 + 5);
        end
        19:
        begin
            assign frame_width = 1980;
            assign frame_height = 750;
            assign screen_width = 1280;
            assign screen_height = 720;
            assign hsync = cx >= 440 && cx < 440 + 40;
            assign vsync = cy >= 5 && cy < 5 + 5;
        end
        97, 107:
        begin
            assign frame_width = 4400;
            assign frame_height = 2250;
            assign screen_width = 3840;
            assign screen_height = 2160;
            assign hsync = cx >= 176 && cx < 176 + 88;
            assign vsync = cy >= 8 && cy < 8 + 10;
        end
    endcase
    assign screen_start_x = frame_width - screen_width;
    assign screen_start_y = frame_height - screen_height;
endgenerate

// Wrap-around pixel position counters indicating the pixel to be generated by the user in THIS clock and sent out in the NEXT clock.
always_ff @(posedge clk_pixel)
begin
    cx <= cx == frame_width-1'b1 ? BIT_WIDTH'(0) : cx + 1'b1;
    cy <= cx == frame_width-1'b1 ? cy == frame_height-1'b1 ? BIT_HEIGHT'(0) : cy + 1'b1 : cy;
end

// See Section 5.2
logic video_data_period = 1;
always_ff @(posedge clk_pixel)
    video_data_period <= cx >= screen_start_x && cy >= screen_start_y;

logic [2:0] mode = 3'd1;
logic [23:0] video_data = 24'd0;
logic [5:0] control_data = 6'd0;
logic [11:0] data_island_data = 12'd0;

generate
    if (!DVI_OUTPUT)
    begin: true_hdmi_output
        logic video_guard = 0;
        logic video_preamble = 0;
        always_ff @(posedge clk_pixel)
        begin
            video_guard <= cx >= screen_start_x - 2 && cx < screen_start_x && cy >= screen_start_y;
            video_preamble <= cx >= screen_start_x - 10 && cx < screen_start_x - 2 && cy >= screen_start_y;
        end

        // See Section 5.2.3.1
        int max_num_packets_alongside;
        logic [4:0] num_packets_alongside;
        always_comb
        begin
            max_num_packets_alongside = (screen_start_x /* VD period */ - 2 /* V guard */ - 8 /* V preamble */ - 12 /* 12px control period */ - 2 /* DI guard */ - 2 /* DI start guard */ - 8 /* DI premable */) / 32;
            if (max_num_packets_alongside > 18)
                num_packets_alongside = 5'd18;
            else
                num_packets_alongside = 5'(max_num_packets_alongside);
        end

        logic data_island_period_instantaneous;
        assign data_island_period_instantaneous = num_packets_alongside > 0 && cx >= 10 && cx < 10 + num_packets_alongside * 32;
        logic packet_enable;
        assign packet_enable = data_island_period_instantaneous && 5'(cx + 22) == 5'd0;

        logic data_island_guard = 0;
        logic data_island_preamble = 0;
        logic data_island_period = 0;
        always_ff @(posedge clk_pixel)
        begin
            data_island_guard <= num_packets_alongside > 0 && ((cx >= 8 && cx < 10) || (cx >= 10 + num_packets_alongside * 32 && cx < 10 + num_packets_alongside * 32 + 2));
            data_island_preamble <= num_packets_alongside > 0 && /* cx >= 0 && */ cx < 8;
            data_island_period <= data_island_period_instantaneous;
        end

        // See Section 5.2.3.4
        logic [23:0] header;
        logic [55:0] sub [3:0];
        logic video_field_end;
        assign video_field_end = cx == frame_width - 1'b1 && cy == frame_height - 1'b1;
        logic [4:0] packet_pixel_counter;
        localparam real VIDEO_RATE = (VIDEO_ID_CODE == 1 ? 25.2E6
            : VIDEO_ID_CODE == 2 || VIDEO_ID_CODE == 3 ? 27.027E6
            : VIDEO_ID_CODE == 4 ? 74.25E6
            : VIDEO_ID_CODE == 16 ? 148.5E6
            : VIDEO_ID_CODE == 17 || VIDEO_ID_CODE == 18 ? 27E6
            : VIDEO_ID_CODE == 19 ? 74.25E6
            : VIDEO_ID_CODE == 97 || VIDEO_ID_CODE == 107 ? 594E6
            : 0) * (VIDEO_REFRESH_RATE == 59.94 ? 1000.0/1001.0 : 1); // https://groups.google.com/forum/#!topic/sci.engr.advanced-tv/DQcGk5R_zsM
        packet_picker #(
            .VIDEO_ID_CODE(VIDEO_ID_CODE),
            .VIDEO_RATE(VIDEO_RATE),
            .AUDIO_RATE(AUDIO_RATE),
            .AUDIO_BIT_WIDTH(AUDIO_BIT_WIDTH),
            .VENDOR_NAME(VENDOR_NAME),
            .PRODUCT_DESCRIPTION(PRODUCT_DESCRIPTION),
            .SOURCE_DEVICE_INFORMATION(SOURCE_DEVICE_INFORMATION)
        ) packet_picker (.clk_pixel(clk_pixel), .clk_audio(clk_audio), .video_field_end(video_field_end), .packet_enable(packet_enable), .packet_pixel_counter(packet_pixel_counter), .audio_sample_word(audio_sample_word), .header(header), .sub(sub));
        logic [8:0] packet_data;
        packet_assembler packet_assembler (.clk_pixel(clk_pixel), .data_island_period(data_island_period), .header(header), .sub(sub), .packet_data(packet_data), .counter(packet_pixel_counter));


        always_ff @(posedge clk_pixel)
        begin
            mode <= data_island_guard ? 3'd4 : data_island_period ? 3'd3 : video_guard ? 3'd2 : video_data_period ? 3'd1 : 3'd0;
            video_data <= rgb;
            control_data <= {{1'b0, data_island_preamble}, {1'b0, video_preamble || data_island_preamble}, {vsync, hsync}}; // ctrl3, ctrl2, ctrl1, ctrl0, vsync, hsync
            data_island_data[11:4] <= packet_data[8:1];
            data_island_data[3] <= cx != screen_start_x;
            data_island_data[2] <= packet_data[0];
            data_island_data[1:0] <= {vsync, hsync};
        end
    end
    else // DVI_OUTPUT = 1
    begin
        always_ff @(posedge clk_pixel)
        begin
            mode <= video_data_period;
            video_data <= rgb;
            control_data <= {4'b0000, {vsync, hsync}}; // ctrl3, ctrl2, ctrl1, ctrl0, vsync, hsync
        end
    end
endgenerate

// All logic below relates to the production and output of the 10-bit TMDS code.
logic [9:0] tmds [NUM_CHANNELS-1:0];
genvar i;
generate
    // TMDS code production.
    for (i = 0; i < NUM_CHANNELS; i++)
    begin: tmds_gen
        tmds_channel #(.CN(i)) tmds_channel (.clk_pixel(clk_pixel), .video_data(video_data[i*8+7:i*8]), .data_island_data(data_island_data[i*4+3:i*4]), .control_data(control_data[i*2+1:i*2]), .mode(mode), .tmds(tmds[i]));
    end

    // Shift registers are loaded with a set of values from tmds_channels every ten clk_pixel_x10. They are shifted out by the time the next set is loaded.
    // They are initialized to the 0,0 control signal from Section 5.4.2.
    // This gives time for the first pixel to be generated by the first clock.
    logic [9:0] tmds_shift [NUM_CHANNELS-1:0] = '{10'b1101010100, 10'b1101010100, 10'b1101010100};

    logic tmds_control = 1'd0;
    always_ff @(posedge clk_pixel)
        tmds_control <= !tmds_control;
    logic [3:0] tmds_control_synchronizer_chain = 2'd0;
    always_ff @(posedge clk_pixel_x10)
        tmds_control_synchronizer_chain <= {tmds_control, tmds_control_synchronizer_chain[3:1]};

    logic [9:0] tmds_mux [NUM_CHANNELS-1:0];
    always_comb
    begin
        if (tmds_control_synchronizer_chain[1] ^ tmds_control_synchronizer_chain[0])
            tmds_mux = tmds;
        else
            tmds_mux = tmds_shift;
    end

    // See Section 5.4.1
    for (i = 0; i < NUM_CHANNELS; i++)
    begin: tmds_shifting
        always_ff @(posedge clk_pixel_x10)
            tmds_shift[i] <= tmds_control_synchronizer_chain[1] ^ tmds_control_synchronizer_chain[0] ? tmds_mux[i] : tmds_shift[i] >> (DDRIO ? 2 : 1);
    end

    logic [9:0] tmds_shift_clk_pixel = 10'b0000011111;
    always_ff @(posedge clk_pixel_x10)
        tmds_shift_clk_pixel <= tmds_control_synchronizer_chain[1] ^ tmds_control_synchronizer_chain[0] ? 10'b0000011111 : {tmds_shift_clk_pixel[(DDRIO ? 1 : 0):0], tmds_shift_clk_pixel[9:(DDRIO ? 2 : 1)]};

    // Double data rate support
    logic [NUM_CHANNELS-1:0] tmds_current;
    logic tmds_current_clk;

    if (DDRIO)
    begin
        `ifdef SYNTHESIS // TODO: Is this really Vivado? https://forums.xilinx.com/t5/Simulation-and-Verification/Predefined-constant-for-simulation/td-p/986901
            `ifndef ALTERA_RESERVED_QIS
                for (i = 0; i < NUM_CHANNELS; i++)
                begin: oddr2_gen
                    ODDR2 #(.DDR_ALIGNMENT("NONE"), .INIT(1'b0), .SRTYPE("SYNC")) clock_forward_inst (.Q(tmds_current[i]), .C0(clk_pixel_x10), .C1(!clk_pixel_x10), .CE(1'b1), .D0(tmds_shift[i][0]), .D1(tmds_shift[i][1]), .R(1'b0), .S(1'b0));
                end
                ODDR2 #(.DDR_ALIGNMENT("NONE"), .INIT(1'b0), .SRTYPE("SYNC")) clock_forward_inst (.Q(tmds_current_clk), .C0(clk_pixel_x10), .C1(!clk_pixel_x10), .CE(1'b1), .D0(tmds_shift_clk_pixel[0]), .D1(tmds_shift_clk_pixel[1]), .R(1'b0), .S(1'b0));
            `endif
        `else
            altDDIO_out DDRIO (.dataout({tmds_current, tmds_current_clk}), .outclock(clk_pixel_x10), .datain_h({tmds_shift[2][0], tmds_shift[1][0], tmds_shift[0][0], tmds_shift_clk_pixel[0]}), .datain_l({tmds_shift[2][1], tmds_shift[1][1], tmds_shift[0][1], tmds_shift_clk_pixel[1]}), .aclr(1'b0), .aset(1'b0), .outclocken(1'b1), .sclr(1'b0), .sset(1'b0));
            defparam DDRIO.inverted_input_clocks = "OFF", DDRIO.lpm_hint = "UNUSED", DDRIO.lpm_type = "altDDIO_out", DDRIO.power_up_high = "OFF", DDRIO.width = NUM_CHANNELS + 1;
        `endif
    end
    else
    begin
        assign tmds_current = {tmds_shift[2][0], tmds_shift[1][0], tmds_shift[0][0]};
        assign tmds_current_clk = tmds_shift_clk_pixel[0];
    end

    // Differential signal output
    `ifdef SYNTHESIS // TODO: Is this really Vivado? https://forums.xilinx.com/t5/Simulation-and-Verification/Predefined-constant-for-simulation/td-p/986901
        `ifndef ALTERA_RESERVED_QIS
        for (i = 0; i < NUM_CHANNELS; i++)
        begin: obufds_gen
            OBUFDS obufds (.I(tmds_current[i]), .O(tmds_p[i]), .OB(tmds_n[i]));
        end
        OBUFDS OBUFDS_clock(.I(tmds_current_clk), .O(tmds_clock_p), .OB(tmds_clock_n));
        `endif
    `else
        // If Altera synthesis, a true differential buffer is built with altera_gpio_lite from the Intel IP Catalog.
        // If simulation, a mocked signal inversion is used.
        OBUFDS obufds(.din({tmds_current, tmds_current_clk}), .pad_out({tmds_p, tmds_clock_p}), .pad_out_b({tmds_n, tmds_clock_n}));
    `endif
endgenerate

endmodule
