// Implementation of HDMI Spec v1.3a Section 5.4: Encoding
// By Sameer Puri https://purisa.me

module tmds_channel(
           input clk_pixel,
           input [7:0] video_data,
           input [3:0] data_island_data,
           input [1:0] control_data,
           input [2:0] mode,  // Mode select (0 = control, 1 = video, 2 = video guard, 3 = island, 4 = island guard)
           output reg [9:0] tmds = 0
       );

parameter CN = 0; // Channel Number

reg signed [4:0] disparity_counter = $signed(5'd0);
always @(posedge clk_pixel)
begin
    if (mode != 2'd1)
        disparity_counter = $signed(5'd0);

    case (mode)
        3'd0: tmds = control_coding(control_data);
        3'd1: video_coding(video_data, tmds);
        3'd2: video_guard_band(tmds);
        3'd3: tmds = terc4_coding(data_island_data);
        3'd4: data_guard_band(tmds);
        default: tmds = 10'd0;
    endcase
end

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

task video_coding;
    input [7:0] d;
    output [9:0] video_coding;
    reg [3:0] N1d = 0;
    reg [3:0] N1q_m = 0;
    reg [3:0] N0q_m;
    reg [8:0] q_m;
    reg signed [3:0] diff;
    integer i;

    for (i = 0; i < 8; i=i+1)
        N1d = N1d + d[i];
    
    q_m[0] = d[0];
    if (N1d > 4'd4 | (N1d == 4'd4 & d[0] == 1'b0))
    begin
        for (i = 1; i < 8; i=i+1)
            q_m[i] = q_m[i-1] ^~ d[i];
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

    if (disparity_counter == $signed(4'd0) | N1q_m == 4'd4)
    begin
        video_coding = {~q_m[8], q_m[8], q_m[8] ? q_m[7:0] : ~q_m[7:0]};
        if (q_m[8] == 0)
            diff = $signed(N0q_m) - $signed(N1q_m);
        else
            diff = $signed(N1q_m) - $signed(N0q_m);
    end
    else
    begin
        if ((disparity_counter > $signed(4'd0) & N1q_m > 4'd4) | (disparity_counter < $signed(4'd0) & N1q_m < 4'd4))
        begin
            video_coding = {1'b1, q_m[8], ~q_m[7:0]};
            diff = $signed({q_m[8],1'b0}) + ($signed(N0q_m) - $signed(N1q_m));
        end
        else
            video_coding = {1'b0, q_m[8], q_m[7:0]};
            diff = - $signed({~q_m[8],1'b0}) + ($signed(N1q_m) - $signed(N0q_m));
    end 
    disparity_counter = disparity_counter + diff;
endtask

task video_guard_band;
    output [9:0] video_guard_band;
    case (CN)
        2'd0: video_guard_band = 10'b1011001100;
        2'd1: video_guard_band = 10'b0100110011;
        2'd2: video_guard_band = 10'b1011001100;
        default: video_guard_band = 0;
    endcase
endtask

task data_guard_band;
    output [9:0] data_guard_band;
    case (CN)
        2'd0: data_guard_band = terc4_coding({2'b11, control_data});
        2'd1: data_guard_band = 10'b0100110011;
        2'd2: data_guard_band = 10'b0100110011;
        default: data_guard_band = 0;
    endcase
endtask

endmodule
