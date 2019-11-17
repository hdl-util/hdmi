module data_island (
    input clk_pixel,
    input enable,
    input [15:0] sub4, // See Table 5-8 Packet Types
    input [55:0] sub0,
    input [55:0] sub1,
    input [55:0] sub2,
    input [55:0] sub3,
    output reg [8:0] data // See Figure 5-4
);

reg [7:0] ecc0 = 8'd0, ecc1 = 8'd0, ecc2 = 8'd0, ecc3 = 8'd0, ecc4 = 8'd0;

wire [7:0] ecc0_next = (ecc0 >> 1) ^ (ecc0[0] ^ bch0[0]) ? 8'b10000011 : 8'd0;
wire [7:0] ecc1_next = (ecc1 >> 1) ^ (ecc1[0] ^ bch1[0]) ? 8'b10000011 : 8'd0;
wire [7:0] ecc2_next = (ecc2 >> 1) ^ (ecc2[0] ^ bch2[0]) ? 8'b10000011 : 8'd0;
wire [7:0] ecc3_next = (ecc3 >> 1) ^ (ecc3[0] ^ bch3[0]) ? 8'b10000011 : 8'd0;
wire [7:0] ecc4_next = (ecc4 >> 1) ^ (ecc4[0] ^ bch4) ? 8'b10000011 : 8'd0;

wire [7:0] ecc0_nextnext = (ecc0_next >> 1) ^ (ecc0_next[0] ^ bch0[1]) ? 8'b10000011 : 8'd0;
wire [7:0] ecc1_nextnext = (ecc1_next >> 1) ^ (ecc1_next[0] ^ bch1[1]) ? 8'b10000011 : 8'd0;
wire [7:0] ecc2_nextnext = (ecc2_next >> 1) ^ (ecc2_next[0] ^ bch2[1]) ? 8'b10000011 : 8'd0;
wire [7:0] ecc3_nextnext = (ecc3_next >> 1) ^ (ecc3_next[0] ^ bch3[1]) ? 8'b10000011 : 8'd0;

always @(posedge clk_pixel)
begin
    if (enable)
    begin
        if (counter < 24) // Compute ECC only on subpacket data
            ecc0 <= ecc0_nextnext;
            ecc1 <= ecc1_nextnext;
            ecc2 <= ecc2_nextnext;
            ecc3 <= ecc3_nextnext;
            ecc4 <= ecc4_next; 
        else if (counter == 31) // Reset ECC for next packet
        begin
            ecc0 <= 8'd0;
            ecc1 <= 8'd0;
            ecc2 <= 8'd0;
            ecc3 <= 8'd0;
            ecc4 <= 8'd0;
        end
    end
end

wire [63:0] bch0 = {ecc0, sub0}, bch1 = {ecc1, sub1}, bch2 = {ecc2, sub2}, bch3 = {ecc3, sub3};
wire [31:0] bch4 = {ecc4, sub4};

reg [4:0] counter = 5'd0;

always @(posedge clk_pixel)
begin
    if (enable)
    begin
        data <= {{bch3[2*counter], bch2[2*counter], bch1[2*counter], bch0[2*counter]}, {bch3[counter], bch2[counter], bch1[counter], bch0[counter]}, {bch4[counter]}};
        counter <= counter + 1'b1;
    end
end

endmodule