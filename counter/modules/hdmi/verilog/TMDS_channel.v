// Implementation of HDMI Spec v1.3a Section 5.4: Encoding
// Sameer Puri https://purisa.me

module TMDS_channel(
           input clk,
           input [7:0] VD,
           input [3:0] DID,
           input [1:0] CD,
           input [2:0] M,  // Mode select (0 = control, 1 = video, 2 = video guard, 3 = island, 4 = island guard)
           output reg [9:0] TMDS = 0
       );

parameter CN = 0; // Channel Number

function [9:0] control_coding;
    input [1:0] cd;
    case (cd)
        2'b00 : control_coding = 10'b1101010100;
        2'b01 : control_coding = 10'b0010101011;
        2'b10 : control_coding = 10'b0101010100;
        2'b11 : control_coding = 10'b1010101011;
    endcase
endfunction

function [9:0] terc4_coding;
    input [3:0] d;
    case (d)
        4'b0000: terc4_coding = 10'b1010011100;
        4'b0001: terc4_coding = 10'b1001100011;
        4'b0010: terc4_coding = 10'b1011100100;
        4'b0011: terc4_coding = 10'b1011100010;
        4'b0100: terc4_coding = 10'b0101110001;
        4'b0101: terc4_coding = 10'b0100011110;
        4'b0110: terc4_coding = 10'b0110001110;
        4'b0111: terc4_coding = 10'b0100111100;
        4'b1000: terc4_coding = 10'b1011001100;
        4'b1001: terc4_coding = 10'b0100111001;
        4'b1010: terc4_coding = 10'b0110011100;
        4'b1011: terc4_coding = 10'b1011000110;
        4'b1100: terc4_coding = 10'b1010001110;
        4'b1101: terc4_coding = 10'b1001110001;
        4'b1110: terc4_coding = 10'b0101100011;
        4'b1111: terc4_coding = 10'b1011000011;
    endcase
endfunction

reg signed [4:0] CNT = $signed(4'd0);

task video_coding;
    input [7:0] d;
    output [9:0] video_coding;
    reg [2:0] N1d = 0;
    reg [3:0] N1q_m = 0;
    reg [3:0] N0q_m;
    reg [8:0] q_m;
    integer i;
    for (i = 1; i < 8; i=i+1) // 1 bit saving here by ignoring d[0]
        N1d = N1d + d[i];
    
    q_m[0] = d[0];
    if (N1d > 3'd3)
    begin
        for (i = 1; i < 8; i=i+1)
            q_m[i] = ~(q_m[i-1] ^ d[i]);
        q_m[8] = 0;
    end
    else
    begin 
        for (i = 1; i < 8; i=i+1)
            q_m[i] = q_m[i-1] ^ d[i];
        q_m[8] = 1;
    end

    for (i = 0; i < 8; i=i+1) // Excludes 9th bit
        N1q_m = N1q_m + q_m[i];
    N0q_m = 4'd8 - N1q_m;

    if (CNT == $signed(4'd0) || N1q_m == 4'd4)
    begin
        video_coding[9] = ~q_m[8];
        video_coding[8] = q_m[8];
        video_coding[7:0] = q_m[8] ? q_m[7:0] : ~q_m[7:0];
        if (q_m[8] == 0)
            CNT = CNT + ($signed(N0q_m) - $signed(N1q_m));
        else
            CNT = CNT + ($signed(N1q_m) - $signed(N0q_m));
    end
    else
    begin
        video_coding[9] = 1'b0;
        video_coding[8] = q_m[8];
        video_coding[7:0] = q_m[7:0];
        if ((CNT > $signed(4'd0) && N1q_m > 4'd4) || (CNT < $signed(4'd0) && N0q_m > 4'd4))
        begin
            video_coding[9] = 1'b1;
            video_coding[7:0] = ~video_coding[7:0];
            CNT = CNT + $signed({q_m[8], 1'b0}) + ($signed(N0q_m) - $signed(N1q_m));
        end
        else
            CNT = CNT - $signed({~q_m[8], 1'b0}) + ($signed(N1q_m) - $signed(N0q_m));
    end 
endtask

function [9:0] video_guard_band;
    input cn;
    case (cn)
        2'd0: video_guard_band = 10'b1011001100;
        2'd1: video_guard_band = 10'b0100110011;
        2'd2: video_guard_band = 10'b1011001100;
        default: video_guard_band = 0;
    endcase
endfunction

function [9:0] data_guard_band;
    input cn;
    case (cn)
        2'd1: data_guard_band = 10'b0100110011;
        2'd2: data_guard_band = 10'b0100110011;
        default: data_guard_band = 0;
    endcase
endfunction

always @(posedge clk)
begin
    CNT = M == 2'd1 ? CNT : $signed(4'd0);
    case (M)
        2'd0: TMDS = control_coding(CD);
        2'd1: video_coding(VD, TMDS);
        2'd2: TMDS = video_guard_band(CN);
        2'd3: TMDS = terc4_coding(DID);
        2'd4: TMDS = data_guard_band(CN);
    endcase
end

endmodule
