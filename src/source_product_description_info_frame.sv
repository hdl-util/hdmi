// Implementation of HDMI SPD InfoFrame packet.
// By Sameer Puri https://github.com/sameer

// See CEA-861-D Section 6.5 page 72 (84 in PDF)
module source_product_description_info_frame
#(
    parameter bit [8*8-1:0] VENDOR_NAME = 0,
    parameter bit [8*16-1:0] PRODUCT_DESCRIPTION = 0,
    parameter bit [7:0] SOURCE_DEVICE_INFORMATION = 0
)
(
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);

localparam bit [4:0] LENGTH = 5'd25;
localparam bit [7:0] VERSION = 8'd1;
localparam bit [6:0] TYPE = 7'd3;

assign header = {{3'b0, LENGTH}, VERSION, {1'b1, TYPE}};

// PB0-PB6 = sub0
// PB7-13 =  sub1
// PB14-20 = sub2
// PB21-27 = sub3
logic [7:0] packet_bytes [27:0];

assign packet_bytes[0] = 8'd1 + ~(header[23:16] + header[15:8] + header[7:0] + packet_bytes[24] + packet_bytes[23] + packet_bytes[22] + packet_bytes[21] + packet_bytes[20] + packet_bytes[19] + packet_bytes[18] + packet_bytes[17] + packet_bytes[16] + packet_bytes[15] + packet_bytes[14] + packet_bytes[13] + packet_bytes[12] + packet_bytes[11] + packet_bytes[10] + packet_bytes[9] + packet_bytes[8] + packet_bytes[7] + packet_bytes[6] + packet_bytes[5] + packet_bytes[4] + packet_bytes[3] + packet_bytes[2] + packet_bytes[1]);


byte vendor_name [0:7];
byte product_description [0:15];

genvar i;
generate
    for (i = 0; i < 8; i++)
    begin: vendor_to_bytes
        assign vendor_name[i] = VENDOR_NAME[(7-i+1)*8-1:(7-i)*8];
    end
    for (i = 0; i < 16; i++)
    begin: product_to_bytes
        assign product_description[i] = PRODUCT_DESCRIPTION[(15-i+1)*8-1:(15-i)*8];
    end

    for (i = 1; i < 9; i++)
    begin: pb_vendor
        assign packet_bytes[i] = vendor_name[i - 1] == 8'h30 ? 8'h00 : vendor_name[i - 1];
    end
    for (i = 9; i < LENGTH; i++)
    begin: pb_product
        assign packet_bytes[i] = product_description[i - 9] == 8'h30 ? 8'h00 : product_description[i - 9];
    end
    assign packet_bytes[LENGTH] = SOURCE_DEVICE_INFORMATION;
    for (i = 26; i < 28; i++)
    begin: pb_reserved
        assign packet_bytes[i] = 8'd0;
    end
    for (i = 0; i < 4; i++)
    begin: pb_to_sub
        assign sub[i] = {packet_bytes[6 + i*7], packet_bytes[5 + i*7], packet_bytes[4 + i*7], packet_bytes[3 + i*7], packet_bytes[2 + i*7], packet_bytes[1 + i*7], packet_bytes[0 + i*7]};
    end
endgenerate

endmodule
