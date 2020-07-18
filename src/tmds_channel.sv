// Implementation of HDMI Spec v1.4a Section 5.4: Encoding, Section 5.2.2.1: Video Guard Band, Section 5.2.3.3: Data Island Guard Bands.
// By Sameer Puri https://github.com/sameer

module tmds_channel
#(
    // TMDS Channel number.
    // There are only 3 possible channel numbers in HDMI 1.4a: 0, 1, 2.
    parameter int CN = 0
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
// Below is a direct implementation of Figure 5-7, using the same variable names.

logic signed [4:0] acc = 5'sd0;

logic [8:0] q_m;
logic [9:0] q_out;
logic [9:0] video_coding;
assign video_coding = q_out;

logic [3:0] N1D;
logic signed [4:0] N1q_m07;
logic signed [4:0] N0q_m07;
always_comb
begin
    N1D = video_data[0] + video_data[1] + video_data[2] + video_data[3] + video_data[4] + video_data[5] + video_data[6] + video_data[7];
    case(q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7])
        4'b0000: N1q_m07 = 5'sd0;
        4'b0001: N1q_m07 = 5'sd1;
        4'b0010: N1q_m07 = 5'sd2;
        4'b0011: N1q_m07 = 5'sd3;
        4'b0100: N1q_m07 = 5'sd4;
        4'b0101: N1q_m07 = 5'sd5;
        4'b0110: N1q_m07 = 5'sd6;
        4'b0111: N1q_m07 = 5'sd7;
        4'b1000: N1q_m07 = 5'sd8;
        default: N1q_m07 = 5'sd0;
    endcase
    N0q_m07 = 5'sd8 - N1q_m07;
end

logic signed [4:0] acc_add;

integer i;

always_comb
begin
    if (N1D > 4'd4 || (N1D == 4'd4 && video_data[0] == 1'd0))
    begin
        q_m[0] = video_data[0];
        for(i = 0; i < 7; i++)
            q_m[i + 1] = q_m[i] ~^ video_data[i + 1];
        q_m[8] = 1'b0;
    end
    else
    begin
        q_m[0] = video_data[0];
        for(i = 0; i < 7; i++)
            q_m[i + 1] = q_m[i] ^ video_data[i + 1];
        q_m[8] = 1'b1;
    end
    if (acc == 5'sd0 || (N1q_m07 == N0q_m07))
    begin
        if (q_m[8])
        begin
            acc_add = N1q_m07 - N0q_m07;
            q_out = {~q_m[8], q_m[8], q_m[7:0]};
        end
        else
        begin
            acc_add = N0q_m07 - N1q_m07;
            q_out = {~q_m[8], q_m[8], ~q_m[7:0]};
        end
    end
    else
    begin
        if ((acc > 5'sd0 && N1q_m07 > N0q_m07) || (acc < 5'sd0 && N1q_m07 < N0q_m07))
        begin
            q_out = {1'b1, q_m[8], ~q_m[7:0]};
            acc_add = (N0q_m07 - N1q_m07) + (q_m[8] ? 5'sd2 : 5'sd0);
        end
        else
        begin
            q_out = {1'b0, q_m[8], q_m[7:0]};
            acc_add = (N1q_m07 - N0q_m07) - (~q_m[8] ? 5'sd2 : 5'sd0);
        end
    end
end

always_ff @(posedge clk_pixel) acc <= mode != 3'd1 ? 5'sd0 : acc + acc_add;

// See Section 5.4.2
logic [9:0] control_coding;
always_comb
begin
    unique case(control_data)
        2'b00: control_coding = 10'b1101010100;
        2'b01: control_coding = 10'b0010101011;
        2'b10: control_coding = 10'b0101010100;
        2'b11: control_coding = 10'b1010101011;
    endcase
end

// See Section 5.4.3
logic [9:0] terc4_coding;
always_comb
begin
    unique case(data_island_data)
        4'b0000 : terc4_coding = 10'b1010011100;
        4'b0001 : terc4_coding = 10'b1001100011;
        4'b0010 : terc4_coding = 10'b1011100100;
        4'b0011 : terc4_coding = 10'b1011100010;
        4'b0100 : terc4_coding = 10'b0101110001;
        4'b0101 : terc4_coding = 10'b0100011110;
        4'b0110 : terc4_coding = 10'b0110001110;
        4'b0111 : terc4_coding = 10'b0100111100;
        4'b1000 : terc4_coding = 10'b1011001100;
        4'b1001 : terc4_coding = 10'b0100111001;
        4'b1010 : terc4_coding = 10'b0110011100;
        4'b1011 : terc4_coding = 10'b1011000110;
        4'b1100 : terc4_coding = 10'b1010001110;
        4'b1101 : terc4_coding = 10'b1001110001;
        4'b1110 : terc4_coding = 10'b0101100011;
        4'b1111 : terc4_coding = 10'b1011000011;
    endcase
end

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
