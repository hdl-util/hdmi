// Implementation of HDMI Spec v1.4a Section 5.4: Encoding, Section 5.2.2.1: Video Guard Band, Section 5.2.3.3: Data Island Guard Bands.
// By Sameer Puri https://github.com/sameer

module tmds_channel
#(
    // TMDS Channel number.
    // There are only 3 possible channel numbers in HDMI 1.4a: 0, 1, 2.
    parameter CN = 0
)
(
    input logic clk_pixel,
    input logic [7:0] video_data,
    input logic [3:0] data_island_data,
    input logic [1:0] control_data,
    input logic [2:0] mode,  // Mode select (0 = control, 1 = video, 2 = video guard, 3 = island, 4 = island guard)
    output logic [9:0] tmds = 10'b1101010100
);

// See Section 5.4.4.1
// Below is a direct implementation of Figure 5-7, using the same variable names. condN refers to the Nth conditional diamond.

reg signed [4:0] acc = 4'd0;

wire [3:0] N1D = video_data[0] + video_data[1] + video_data[2] + video_data[3] + video_data[4] + video_data[5] + video_data[6] + video_data[7];

wire cond1 = N1D > 4'd4 || (N1D == 4'd4 && video_data[0] == 1'd0);
wire [8:0] q_m = {~cond1, cond1 ? (q_m[6:0] ~^ video_data[7:1]) : (q_m[6:0] ^ video_data[7:1]), video_data[0]};

wire [3:0] N1q_m07 = q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7];
wire [3:0] N0q_m07 = 4'd8 - N1q_m07;

wire cond2 = acc == 0 || (N1q_m07 == 4'd4);
wire cond3 = (acc > 0 && N1q_m07 > 4'd4) || (acc < 0 && N1q_m07 < 4'd4);

wire [9:0] q_out = {cond2 ? ~q_m[8] : cond3, q_m[8], ((cond2 && q_m[8]) || !cond3) ? q_m[7:0] : ~q_m[7:0] };
wire [9:0] video_coding = q_out;

wire signed [4:0] acc_pt1 = ((cond2 && ~q_m[8]) || (!cond2 && !cond3)) ? $signed(N1q_m07) - $signed(N0q_m07) : $signed(N0q_m07) - $signed(N1q_m07);
wire signed [2:0] acc_pt2 = cond2 ? $signed(2'd0) : cond3 ? $signed({q_m[8], 1'b0}) : -$signed({~q_m[8], 1'b0});
wire signed [4:0] acc_new = acc + (acc_pt1 + acc_pt2);

always @(posedge clk_pixel) acc <= mode != 3'd1 ? $signed(4'd0) : acc_new;

// See Section 5.4.2
wire [9:0] control_coding = 
    control_data == 2'b00 ? 10'b1101010100
    : control_data == 2'b01 ? 10'b0010101011 
    : control_data == 2'b10 ? 10'b0101010100
    : 10'b1010101011;

// See Section 5.4.3
wire [9:0] terc4_coding =
    data_island_data == 4'b0000 ? 10'b1010011100
    : data_island_data == 4'b0001 ? 10'b1001100011
    : data_island_data == 4'b0010 ? 10'b1011100100
    : data_island_data == 4'b0011 ? 10'b1011100010
    : data_island_data == 4'b0100 ? 10'b0101110001
    : data_island_data == 4'b0101 ? 10'b0100011110
    : data_island_data == 4'b0110 ? 10'b0110001110
    : data_island_data == 4'b0111 ? 10'b0100111100
    : data_island_data == 4'b1000 ? 10'b1011001100
    : data_island_data == 4'b1001 ? 10'b0100111001
    : data_island_data == 4'b1010 ? 10'b0110011100
    : data_island_data == 4'b1011 ? 10'b1011000110
    : data_island_data == 4'b1100 ? 10'b1010001110
    : data_island_data == 4'b1101 ? 10'b1001110001
    : data_island_data == 4'b1110 ? 10'b0101100011
    : 10'b1011000011;

// See Section 5.2.2.1
logic [9:0] video_guard_band;
generate
    if (CN == 0 || CN == 2)
        assign video_guard_band = 10'b1011001100;
    else
        assign video_guard_band = 10'b0100110011;
endgenerate

// See Section 5.2.3.3
logic [9:0] data_guard_band;
generate
    if (CN == 1 || CN == 2)
        assign data_guard_band = 10'b0100110011;
    else
        assign data_guard_band = control_data == 2'b00 ? 10'b1010001110
            : control_data == 2'b01 ? 10'b1001110001
            : control_data == 2'b10 ? 10'b0101100011
            : 10'b1011000011;
endgenerate

// Apply selected mode.
always @(posedge clk_pixel)
begin
    case (mode)
        3'd0: tmds <= control_coding;
        3'd1: tmds <= video_coding;
        3'd2: tmds <= video_guard_band;
        3'd3: tmds <= terc4_coding;
        3'd4: tmds <= data_guard_band;
    endcase
end

endmodule
