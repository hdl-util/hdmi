// Implementation of HDMI Spec v1.3a Section 5.4: Encoding
// By Sameer Puri https://purisa.me

module tmds_channel(
           input clk_pixel,
           input [7:0] video_data,
           input [3:0] data_island_data,
           input [1:0] control_data,
           input [2:0] mode,  // Mode select (0 = control, 1 = video, 2 = video guard, 3 = island, 4 = island guard)
           output reg [9:0] tmds = 10'b1101010100
       );

parameter CN = 0; // Channel Number

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

/////////////////////////////////////
// (c) fpga4fun.com & KNJN LLC 2013
wire [7:0] din = video_data;
wire [3:0] Nb1s = din[0] + din[1] + din[2] + din[3] + din[4] + din[5] + din[6] + din[7];
wire XNOR = (Nb1s>4'd4) || (Nb1s==4'd4 && din[0]==1'b0);
wire [8:0] q_m = {~XNOR, q_m[6:0] ^ din[7:1] ^ {7{XNOR}}, din[0]};

reg [3:0] balance_acc = 0;
wire [3:0] balance = q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7] - 4'd4;
wire balance_sign_eq = (balance[3] == balance_acc[3]);
wire invert_q_m = (balance==0 || balance_acc==0) ? ~q_m[8] : balance_sign_eq;
wire [3:0] balance_acc_inc = balance - ({q_m[8] ^ ~balance_sign_eq} & ~(balance==0 || balance_acc==0));
wire [3:0] balance_acc_new = invert_q_m ? balance_acc-balance_acc_inc : balance_acc+balance_acc_inc;
wire [9:0] video_coding = {invert_q_m, q_m[8], q_m[7:0] ^ {8{invert_q_m}}};

always @(posedge clk_pixel) balance_acc <= mode != 3'd1 ? 4'd0 : balance_acc_new;
////////////////////////////////////

wire [9:0] control_coding = 
    control_data == 2'b00 ? 10'b1101010100
    : control_data == 2'b01 ? 10'b0010101011 
    : control_data == 2'b10 ? 10'b0101010100
    : 10'b0101010100;

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


wire [9:0] video_guard_band = (CN == 2'd0 || CN == 2'd2) ? 10'b1011001100 : 10'b0100110011;

wire [9:0] data_guard_band = (CN == 2'd1 || CN == 2'd2) ? 10'b0100110011
    : control_data == 2'b00 ? 10'b1010001110
    : control_data == 2'b01 ? 10'b1001110001
    : control_data == 2'b10 ? 10'b0101100011
    : 10'b1011000011;

endmodule
