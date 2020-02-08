// Implementation of HDMI SPD InfoFrame packet.
// By Sameer Puri https://github.com/sameer

// See CEA-861-D Section 6.5 page 72 (84 in PDF)
module source_product_description_info_frame
#(
    parameter VENDOR_NAME = "Unknown\0",
    parameter PRODUCT_DESCRIPTION = "FPGA\0\0\0\0\0\0\0\0\0\0\0\0",
    parameter SOURCE_DEVICE_INFORMATION = 8'h00
)
(
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);

bit [8*8-1:0] vendor_name = VENDOR_NAME;
bit [16*8-1:0] product_description = PRODUCT_DESCRIPTION;

localparam LENGTH = 5'd25;
localparam VERSION = 8'd1;
localparam TYPE = 7'd3;

assign header = {{3'b0, LENGTH}, VERSION, {1'b1, TYPE}};

// PB0-PB6 = sub0
// PB7-13 =  sub1
// PB14-20 = sub2
// PB21-27 = sub3
logic [7:0] pb [27:0];

assign pb[0] = ~(header[23:16] + header[15:8] + header[7:0] + pb[24] + pb[23] + pb[22] + pb[21] + pb[20] + pb[19] + pb[18] + pb[17] + pb[16] + pb[15] + pb[14] + pb[13] + pb[12] + pb[11] + pb[10] + pb[9] + pb[8] + pb[7] + pb[6] + pb[5] + pb[4] + pb[3] + pb[2] + pb[1]);

genvar i;
generate
    for (i = 1; i < 9; i++)
    begin: pb_vendor
        assign pb[i] = vendor_name[i*8-1:(i-1)*8];
    end
    for (i = 9; i < 25; i++)
    begin: pb_product
        assign pb[i] = product_description[(i-8)*8-1:(i-9)*8];
    end
    assign pb[25] = SOURCE_DEVICE_INFORMATION;
    for (i = 26; i < 28; i++)
    begin: pb_reserved
        assign pb[i] = 8'd0;
    end
    for (i = 0; i < 4; i++)
    begin: pb_to_sub
        assign sub[i] = {pb[6 + i*7], pb[5 + i*7], pb[4 + i*7], pb[3 + i*7], pb[2 + i*7], pb[1 + i*7], pb[0 + i*7]};
    end
endgenerate

endmodule
