module hdmi (
	clk_pixel_x5,
	clk_pixel,
	clk_audio,
	reset,
	rgb,
	audio_sample_word,
	tmds,
	tmds_clock,
	cx,
	cy,
	frame_width,
	frame_height,
	screen_width,
	screen_height
);
	parameter signed [31:0] VIDEO_ID_CODE = 1;
	parameter signed [31:0] BIT_WIDTH = (VIDEO_ID_CODE < 4 ? 10 : (VIDEO_ID_CODE == 4 ? 11 : 12));
	parameter signed [31:0] BIT_HEIGHT = (VIDEO_ID_CODE == 16 ? 11 : 10);
	parameter [0:0] DVI_OUTPUT = 1'b0;
	parameter real VIDEO_REFRESH_RATE = 59.94;
	parameter signed [31:0] AUDIO_RATE = 44100;
	parameter signed [31:0] AUDIO_BIT_WIDTH = 16;
	parameter [63:0] VENDOR_NAME = {"Unknown", 8'd0};
	parameter [127:0] PRODUCT_DESCRIPTION = {"FPGA", 96'd0};
	parameter [7:0] SOURCE_DEVICE_INFORMATION = 8'h00;
	input wire clk_pixel_x5;
	input wire clk_pixel;
	input wire clk_audio;
	input wire reset;
	input wire [23:0] rgb;
	input wire [(2 * AUDIO_BIT_WIDTH) - 1:0] audio_sample_word;
	output wire [2:0] tmds;
	output wire tmds_clock;
	function automatic signed [BIT_WIDTH - 1:0] sv2v_cast_C479B_signed;
		input reg signed [BIT_WIDTH - 1:0] inp;
		sv2v_cast_C479B_signed = inp;
	endfunction
	output reg [BIT_WIDTH - 1:0] cx = sv2v_cast_C479B_signed(0);
	function automatic signed [BIT_HEIGHT - 1:0] sv2v_cast_4D393_signed;
		input reg signed [BIT_HEIGHT - 1:0] inp;
		sv2v_cast_4D393_signed = inp;
	endfunction
	output reg [BIT_HEIGHT - 1:0] cy = sv2v_cast_4D393_signed(0);
	output wire [BIT_WIDTH - 1:0] frame_width;
	output wire [BIT_HEIGHT - 1:0] frame_height;
	output wire [BIT_WIDTH - 1:0] screen_width;
	output wire [BIT_HEIGHT - 1:0] screen_height;
	localparam signed [31:0] NUM_CHANNELS = 3;
	wire hsync;
	wire vsync;
	wire [BIT_WIDTH - 1:0] hsync_porch_start;
	wire [BIT_WIDTH - 1:0] hsync_porch_size;
	wire [BIT_HEIGHT - 1:0] vsync_porch_start;
	wire [BIT_HEIGHT - 1:0] vsync_porch_size;
	wire invert;
	generate
		case (VIDEO_ID_CODE)
			1: begin
				assign frame_width = 800;
				assign frame_height = 525;
				assign screen_width = 640;
				assign screen_height = 480;
				assign hsync_porch_start = 16;
				assign hsync_porch_size = 96;
				assign vsync_porch_start = 10;
				assign vsync_porch_size = 2;
				assign invert = 1;
			end
			2, 3: begin
				assign frame_width = 858;
				assign frame_height = 525;
				assign screen_width = 720;
				assign screen_height = 480;
				assign hsync_porch_start = 16;
				assign hsync_porch_size = 62;
				assign vsync_porch_start = 9;
				assign vsync_porch_size = 6;
				assign invert = 1;
			end
			4: begin
				assign frame_width = 1650;
				assign frame_height = 750;
				assign screen_width = 1280;
				assign screen_height = 720;
				assign hsync_porch_start = 110;
				assign hsync_porch_size = 40;
				assign vsync_porch_start = 5;
				assign vsync_porch_size = 5;
				assign invert = 0;
			end
			16, 34: begin
				assign frame_width = 2200;
				assign frame_height = 1125;
				assign screen_width = 1920;
				assign screen_height = 1080;
				assign hsync_porch_start = 88;
				assign hsync_porch_size = 44;
				assign vsync_porch_start = 4;
				assign vsync_porch_size = 5;
				assign invert = 0;
			end
			17, 18: begin
				assign frame_width = 864;
				assign frame_height = 625;
				assign screen_width = 720;
				assign screen_height = 576;
				assign hsync_porch_start = 12;
				assign hsync_porch_size = 64;
				assign vsync_porch_start = 5;
				assign vsync_porch_size = 5;
				assign invert = 1;
			end
			19: begin
				assign frame_width = 1980;
				assign frame_height = 750;
				assign screen_width = 1280;
				assign screen_height = 720;
				assign hsync_porch_start = 440;
				assign hsync_porch_size = 40;
				assign vsync_porch_start = 5;
				assign vsync_porch_size = 5;
				assign invert = 0;
			end
			95, 105, 97, 107: begin
				assign frame_width = 4400;
				assign frame_height = 2250;
				assign screen_width = 3840;
				assign screen_height = 2160;
				assign hsync_porch_start = 176;
				assign hsync_porch_size = 88;
				assign vsync_porch_start = 8;
				assign vsync_porch_size = 10;
				assign invert = 0;
			end
		endcase
		assign hsync = invert ^ ((cx >= (screen_width + hsync_porch_start)) && (cx < ((screen_width + hsync_porch_start) + hsync_porch_size)));
		assign vsync = invert ^ ((cy >= (screen_height + vsync_porch_start)) && (cy < ((screen_height + vsync_porch_start) + vsync_porch_size)));
	endgenerate
	localparam real VIDEO_RATE = (VIDEO_ID_CODE == 1 ? 25.2E6 : ((VIDEO_ID_CODE == 2) || (VIDEO_ID_CODE == 3) ? 27.027E6 : (VIDEO_ID_CODE == 4 ? 74.25E6 : (VIDEO_ID_CODE == 16 ? 148.5E6 : ((VIDEO_ID_CODE == 17) || (VIDEO_ID_CODE == 18) ? 27E6 : (VIDEO_ID_CODE == 19 ? 74.25E6 : (VIDEO_ID_CODE == 34 ? 74.25E6 : ((((VIDEO_ID_CODE == 95) || (VIDEO_ID_CODE == 105)) || (VIDEO_ID_CODE == 97)) || (VIDEO_ID_CODE == 107) ? 594E6 : 0)))))))) * ((VIDEO_REFRESH_RATE == 59.94) || (VIDEO_REFRESH_RATE == 29.97) ? 1000.0 / 1001.0 : 1);
	always @(posedge clk_pixel)
		if (reset) begin
			cx <= sv2v_cast_C479B_signed(0);
			cy <= sv2v_cast_4D393_signed(0);
		end
		else begin
			cx <= (cx == (frame_width - 1'b1) ? sv2v_cast_C479B_signed(0) : cx + 1'b1);
			cy <= (cx == (frame_width - 1'b1) ? (cy == (frame_height - 1'b1) ? sv2v_cast_4D393_signed(0) : cy + 1'b1) : cy);
		end
	reg video_data_period = 0;
	always @(posedge clk_pixel)
		if (reset)
			video_data_period <= 0;
		else
			video_data_period <= (cx < screen_width) && (cy < screen_height);
	reg [2:0] mode = 3'd1;
	reg [23:0] video_data = 24'd0;
	reg [5:0] control_data = 6'd0;
	reg [11:0] data_island_data = 12'd0;
	generate
		if (!DVI_OUTPUT) begin : true_hdmi_output
			reg video_guard = 1;
			reg video_preamble = 0;
			always @(posedge clk_pixel)
				if (reset) begin
					video_guard <= 1;
					video_preamble <= 0;
				end
				else begin
					video_guard <= ((cx >= (frame_width - 2)) && (cx < frame_width)) && ((cy == (frame_height - 1)) || (cy < screen_height));
					video_preamble <= ((cx >= (frame_width - 10)) && (cx < (frame_width - 2))) && ((cy == (frame_height - 1)) || (cy < screen_height));
				end
			reg signed [31:0] max_num_packets_alongside;
			reg [4:0] num_packets_alongside;
			function automatic signed [4:0] sv2v_cast_5_signed;
				input reg signed [4:0] inp;
				sv2v_cast_5_signed = inp;
			endfunction
			always @(*) begin
				max_num_packets_alongside = ((frame_width - screen_width) - 34) / 32;
				if (max_num_packets_alongside > 18)
					num_packets_alongside = 5'd18;
				else
					num_packets_alongside = sv2v_cast_5_signed(max_num_packets_alongside);
			end
			wire data_island_period_instantaneous;
			assign data_island_period_instantaneous = ((num_packets_alongside > 0) && (cx >= (screen_width + 10))) && (cx < ((screen_width + 10) + (num_packets_alongside * 32)));
			wire packet_enable;
			function automatic [4:0] sv2v_cast_5;
				input reg [4:0] inp;
				sv2v_cast_5 = inp;
			endfunction
			assign packet_enable = data_island_period_instantaneous && (sv2v_cast_5((cx + screen_width) + 22) == 5'd0);
			reg data_island_guard = 0;
			reg data_island_preamble = 0;
			reg data_island_period = 0;
			always @(posedge clk_pixel)
				if (reset) begin
					data_island_guard <= 0;
					data_island_preamble <= 0;
					data_island_period <= 0;
				end
				else begin
					data_island_guard <= (num_packets_alongside > 0) && (((cx >= (screen_width + 8)) && (cx < (screen_width + 10))) || ((cx >= ((screen_width + 10) + (num_packets_alongside * 32))) && (cx < (((screen_width + 10) + (num_packets_alongside * 32)) + 2))));
					data_island_preamble <= ((num_packets_alongside > 0) && (cx >= screen_width)) && (cx < (screen_width + 8));
					data_island_period <= data_island_period_instantaneous;
				end
			wire [23:0] header;
			wire [223:0] sub;
			wire video_field_end;
			assign video_field_end = (cx == (screen_width - 1'b1)) && (cy == (screen_height - 1'b1));
			wire [4:0] packet_pixel_counter;
			packet_picker #(
				.VIDEO_ID_CODE(VIDEO_ID_CODE),
				.VIDEO_RATE(VIDEO_RATE),
				.AUDIO_RATE(AUDIO_RATE),
				.AUDIO_BIT_WIDTH(AUDIO_BIT_WIDTH),
				.VENDOR_NAME(VENDOR_NAME),
				.PRODUCT_DESCRIPTION(PRODUCT_DESCRIPTION),
				.SOURCE_DEVICE_INFORMATION(SOURCE_DEVICE_INFORMATION)
			) packet_picker(
				.clk_pixel(clk_pixel),
				.clk_audio(clk_audio),
				.reset(reset),
				.video_field_end(video_field_end),
				.packet_enable(packet_enable),
				.packet_pixel_counter(packet_pixel_counter),
				.audio_sample_word(audio_sample_word),
				.header(header),
				.sub(sub)
			);
			wire [8:0] packet_data;
			packet_assembler packet_assembler(
				.clk_pixel(clk_pixel),
				.reset(reset),
				.data_island_period(data_island_period),
				.header(header),
				.sub(sub),
				.packet_data(packet_data),
				.counter(packet_pixel_counter)
			);
			always @(posedge clk_pixel)
				if (reset) begin
					mode <= 3'd2;
					video_data <= 24'd0;
					control_data = 6'd0;
					data_island_data <= 12'd0;
				end
				else begin
					mode <= (data_island_guard ? 3'd4 : (data_island_period ? 3'd3 : (video_guard ? 3'd2 : (video_data_period ? 3'd1 : 3'd0))));
					video_data <= rgb;
					control_data <= {{1'b0, data_island_preamble}, {1'b0, video_preamble || data_island_preamble}, {vsync, hsync}};
					data_island_data[11:4] <= packet_data[8:1];
					data_island_data[3] <= cx != 0;
					data_island_data[2] <= packet_data[0];
					data_island_data[1:0] <= {vsync, hsync};
				end
		end
		else always @(posedge clk_pixel)
			if (reset) begin
				mode <= 3'd0;
				video_data <= 24'd0;
				control_data <= 6'd0;
			end
			else begin
				mode <= (video_data_period ? 3'd1 : 3'd0);
				video_data <= rgb;
				control_data <= {4'b0000, {vsync, hsync}};
			end
	endgenerate
	wire [29:0] tmds_internal;
	genvar i;
	generate
		for (i = 0; i < NUM_CHANNELS; i = i + 1) begin : tmds_gen
			tmds_channel #(.CN(i)) tmds_channel(
				.clk_pixel(clk_pixel),
				.video_data(video_data[(i * 8) + 7:i * 8]),
				.data_island_data(data_island_data[(i * 4) + 3:i * 4]),
				.control_data(control_data[(i * 2) + 1:i * 2]),
				.mode(mode),
				.tmds(tmds_internal[i * 10+:10])
			);
		end
	endgenerate
	serializer #(
		.NUM_CHANNELS(NUM_CHANNELS),
		.VIDEO_RATE(VIDEO_RATE)
	) serializer(
		.clk_pixel(clk_pixel),
		.clk_pixel_x5(clk_pixel_x5),
		.reset(reset),
		.tmds_internal(tmds_internal),
		.tmds(tmds),
		.tmds_clock(tmds_clock)
	);
endmodule
