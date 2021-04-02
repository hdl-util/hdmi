module audio_clock_regeneration_packet (
	clk_pixel,
	clk_audio,
	clk_audio_counter_wrap,
	header,
	sub
);
	parameter real VIDEO_RATE = 25.2E6;
	parameter signed [31:0] AUDIO_RATE = 48e3;
	input wire clk_pixel;
	input wire clk_audio;
	output reg clk_audio_counter_wrap = 0;
	output wire [23:0] header;
	output wire [223:0] sub;
	function automatic signed [19:0] sv2v_cast_20_signed;
		input reg signed [19:0] inp;
		sv2v_cast_20_signed = inp;
	endfunction
	localparam [19:0] N = ((AUDIO_RATE % 125) == 0 ? sv2v_cast_20_signed((16 * AUDIO_RATE) / 125) : ((AUDIO_RATE % 225) == 0 ? sv2v_cast_20_signed((196 * AUDIO_RATE) / 225) : sv2v_cast_20_signed((AUDIO_RATE * 16) / 125)));
	localparam signed [31:0] CLK_AUDIO_COUNTER_WIDTH = $clog2(N / 128);
	function automatic [CLK_AUDIO_COUNTER_WIDTH - 1:0] sv2v_cast_C4DBD;
		input reg [CLK_AUDIO_COUNTER_WIDTH - 1:0] inp;
		sv2v_cast_C4DBD = inp;
	endfunction
	localparam [CLK_AUDIO_COUNTER_WIDTH - 1:0] CLK_AUDIO_COUNTER_END = sv2v_cast_C4DBD((N / 128) - 1);
	function automatic signed [CLK_AUDIO_COUNTER_WIDTH - 1:0] sv2v_cast_C4DBD_signed;
		input reg signed [CLK_AUDIO_COUNTER_WIDTH - 1:0] inp;
		sv2v_cast_C4DBD_signed = inp;
	endfunction
	reg [CLK_AUDIO_COUNTER_WIDTH - 1:0] clk_audio_counter = sv2v_cast_C4DBD_signed(0);
	reg internal_clk_audio_counter_wrap = 1'd0;
	always @(posedge clk_audio)
		if (clk_audio_counter == CLK_AUDIO_COUNTER_END) begin
			clk_audio_counter <= sv2v_cast_C4DBD_signed(0);
			internal_clk_audio_counter_wrap <= !internal_clk_audio_counter_wrap;
		end
		else
			clk_audio_counter <= clk_audio_counter + 1'd1;
	reg [1:0] clk_audio_counter_wrap_synchronizer_chain = 2'd0;
	always @(posedge clk_pixel) clk_audio_counter_wrap_synchronizer_chain <= {internal_clk_audio_counter_wrap, clk_audio_counter_wrap_synchronizer_chain[1]};
	function automatic signed [31:0] sv2v_cast_32_signed;
		input reg signed [31:0] inp;
		sv2v_cast_32_signed = inp;
	endfunction
	localparam [19:0] CYCLE_TIME_STAMP_COUNTER_IDEAL = sv2v_cast_20_signed(sv2v_cast_32_signed(((VIDEO_RATE * sv2v_cast_32_signed(N)) / 128) / AUDIO_RATE));
	localparam signed [31:0] CYCLE_TIME_STAMP_COUNTER_WIDTH = $clog2(sv2v_cast_20_signed(sv2v_cast_32_signed(CYCLE_TIME_STAMP_COUNTER_IDEAL * 1.1)));
	reg [19:0] cycle_time_stamp = 20'd0;
	function automatic signed [CYCLE_TIME_STAMP_COUNTER_WIDTH - 1:0] sv2v_cast_EFA8E_signed;
		input reg signed [CYCLE_TIME_STAMP_COUNTER_WIDTH - 1:0] inp;
		sv2v_cast_EFA8E_signed = inp;
	endfunction
	reg [CYCLE_TIME_STAMP_COUNTER_WIDTH - 1:0] cycle_time_stamp_counter = sv2v_cast_EFA8E_signed(0);
	function automatic signed [(20 - CYCLE_TIME_STAMP_COUNTER_WIDTH) - 1:0] sv2v_cast_66F15_signed;
		input reg signed [(20 - CYCLE_TIME_STAMP_COUNTER_WIDTH) - 1:0] inp;
		sv2v_cast_66F15_signed = inp;
	endfunction
	always @(posedge clk_pixel)
		if (clk_audio_counter_wrap_synchronizer_chain[1] ^ clk_audio_counter_wrap_synchronizer_chain[0]) begin
			cycle_time_stamp_counter <= sv2v_cast_EFA8E_signed(0);
			cycle_time_stamp <= {sv2v_cast_66F15_signed(0), cycle_time_stamp_counter + sv2v_cast_EFA8E_signed(1)};
			clk_audio_counter_wrap <= !clk_audio_counter_wrap;
		end
		else
			cycle_time_stamp_counter <= cycle_time_stamp_counter + sv2v_cast_EFA8E_signed(1);
	assign header = 24'bxxxxxxxxxxxxxxxx00000001;
	genvar i;
	generate
		for (i = 0; i < 4; i = i + 1) begin : same_packet
			assign sub[i * 56+:56] = {N[7:0], N[15:8], {4'd0, N[19:16]}, cycle_time_stamp[7:0], cycle_time_stamp[15:8], {4'd0, cycle_time_stamp[19:16]}, 8'd0};
		end
	endgenerate
endmodule
