// Implementation of HDMI SPD InfoFrame packet.
// By Sameer Puri https://github.com/sameer

// See CEA-861-D Section 6.5 page 72 (84 in PDF)
module source_product_description_info_frame
#(
    parameter VENDOR_NAME,
    parameter PRODUCT_DESCRIPTION,
    parameter SOURCE_DEVICE_INFORMATION
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
logic [7:0] packet_bytes [27:0];

assign packet_bytes[0] = ~(header[23:16] + header[15:8] + header[7:0] + packet_bytes[24] + packet_bytes[23] + packet_bytes[22] + packet_bytes[21] + packet_bytes[20] + packet_bytes[19] + packet_bytes[18] + packet_bytes[17] + packet_bytes[16] + packet_bytes[15] + packet_bytes[14] + packet_bytes[13] + packet_bytes[12] + packet_bytes[11] + packet_bytes[10] + packet_bytes[9] + packet_bytes[8] + packet_bytes[7] + packet_bytes[6] + packet_bytes[5] + packet_bytes[4] + packet_bytes[3] + packet_bytes[2] + packet_bytes[1]);

genvar i;
generate
    for (i = 1; i < 9; i++)
    begin: pb_vendor
        assign packet_bytes[i] = vendor_name[i*8-1:(i-1)*8];
    end
    for (i = 9; i < 25; i++)
    begin: pb_product
        assign packet_bytes[i] = product_description[(i-8)*8-1:(i-9)*8];
    end
    assign packet_bytes[25] = SOURCE_DEVICE_INFORMATION;
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
