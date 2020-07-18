// Implementation of HDMI Auxiliary Video InfoFrame packet.
// By Sameer Puri https://github.com/sameer

// See Section 8.2.1
module auxiliary_video_information_info_frame
#(
    parameter bit [1:0] VIDEO_FORMAT = 2'b00, // 00 = RGB, 01 = YCbCr 4:2:2, 10 = YCbCr 4:4:4
    parameter bit ACTIVE_FORMAT_INFO_PRESENT = 1'b0, // Not valid
    parameter bit [1:0] BAR_INFO = 2'b00, // Not valid
    parameter bit [1:0] SCAN_INFO = 2'b00, // No data
    parameter bit [1:0] COLORIMETRY = 2'b00, // No data
    parameter bit [1:0] PICTURE_ASPECT_RATIO = 2'b00, // No data, See CEA-CEB16 for more information about Active Format Description processing.
    parameter bit [3:0] ACTIVE_FORMAT_ASPECT_RATIO = 4'b1000, // Not valid unless ACTIVE_FORMAT_INFO_PRESENT = 1'b1, then Same as picture aspect ratio
    parameter bit IT_CONTENT = 1'b0, //  The IT content bit indicates when picture content is composed according to common IT practice (i.e. without regard to Nyquist criterion) and is unsuitable for analog reconstruction or filtering. When the IT content bit is set to 1, downstream processors should pass pixel data unfiltered and without analog reconstruction.
    parameter bit [2:0] EXTENDED_COLORIMETRY = 3'b000, // Not valid unless COLORIMETRY = 2'b11. The extended colorimetry bits, EC2, EC1, and EC0, describe optional colorimetry encoding that may be applicable to some implementations and are always present, whether their information is valid or not (see CEA 861-D Section 7.5.5).
    parameter bit [1:0] RGB_QUANTIZATION_RANGE = 2'b00, // Default. Displays conforming to CEA-861-D accept both a limited quantization range of 220 levels (16 to 235) anda full range of 256 levels (0 to 255) when receiving video with RGB color space (see CEA 861-D Sections 5.1, Section 5.2, Section 5.3 and Section 5.4). By default, RGB pixel data values should be assumed to have the limited range when receiving a CE video format, and the full range when receiving an IT format. The quantization bits allow the source to override this default and to explicitly indicate the current RGB quantization range.
    parameter bit [1:0] NON_UNIFORM_PICTURE_SCALING = 2'b00, // None. The Nonuniform Picture Scaling bits shall be set if the source device scales the picture or has determined that scaling has been performed in a specific direction.
    parameter int VIDEO_ID_CODE = 4, // Same as the one from the HDMI module
    parameter bit [1:0] YCC_QUANTIZATION_RANGE = 2'b00, // 00 = Limited, 01 = Full
    parameter bit [1:0] CONTENT_TYPE = 2'b00, // No data, becomes Graphics if IT_CONTENT = 1'b1.
    parameter bit [3:0] PIXEL_REPETITION = 4'b0000 // None
)
(
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);


localparam bit [4:0] LENGTH = 5'd13;
localparam bit [7:0] VERSION = 8'd2;
localparam bit [6:0] TYPE = 7'd2;

assign header = {{3'b0, LENGTH}, VERSION, {1'b1, TYPE}};

// PB0-PB6 = sub0
// PB7-13 =  sub1
// PB14-20 = sub2
// PB21-27 = sub3
logic [7:0] packet_bytes [27:0];

assign packet_bytes[0] = 8'd1 + ~(header[23:16] + header[15:8] + header[7:0] + packet_bytes[13] + packet_bytes[12] + packet_bytes[11] + packet_bytes[10] + packet_bytes[9] + packet_bytes[8] + packet_bytes[7] + packet_bytes[6] + packet_bytes[5] + packet_bytes[4] + packet_bytes[3] + packet_bytes[2] + packet_bytes[1]);
assign packet_bytes[1] = {1'b0, VIDEO_FORMAT, ACTIVE_FORMAT_INFO_PRESENT, BAR_INFO, SCAN_INFO};
assign packet_bytes[2] = {COLORIMETRY, PICTURE_ASPECT_RATIO, ACTIVE_FORMAT_ASPECT_RATIO};
assign packet_bytes[3] = {IT_CONTENT, EXTENDED_COLORIMETRY, RGB_QUANTIZATION_RANGE, NON_UNIFORM_PICTURE_SCALING};
assign packet_bytes[4] = {1'b0, 7'(VIDEO_ID_CODE)};
assign packet_bytes[5] = {YCC_QUANTIZATION_RANGE, CONTENT_TYPE, PIXEL_REPETITION};

genvar i;
generate
    if (BAR_INFO != 2'b00) // Assign values to bars if BAR_INFO says they are valid.
    begin
        assign packet_bytes[6] = 8'hff;
        assign packet_bytes[7] = 8'hff;
        assign packet_bytes[8] = 8'h00;
        assign packet_bytes[9] = 8'h00;
        assign packet_bytes[10] = 8'hff;
        assign packet_bytes[11] = 8'hff;
        assign packet_bytes[12] = 8'h00;
        assign packet_bytes[13] = 8'h00;
    end else begin
        assign packet_bytes[6] = 8'h00;
        assign packet_bytes[7] = 8'h00;
        assign packet_bytes[8] = 8'h00;
        assign packet_bytes[9] = 8'h00;
        assign packet_bytes[10] = 8'h00;
        assign packet_bytes[11] = 8'h00;
        assign packet_bytes[12] = 8'h00;
        assign packet_bytes[13] = 8'h00;
    end
    for (i = 14; i < 28; i++)
    begin: pb_reserved
        assign packet_bytes[i] = 8'd0;
    end
    for (i = 0; i < 4; i++)
    begin: pb_to_sub
        assign sub[i] = {packet_bytes[6 + i*7], packet_bytes[5 + i*7], packet_bytes[4 + i*7], packet_bytes[3 + i*7], packet_bytes[2 + i*7], packet_bytes[1 + i*7], packet_bytes[0 + i*7]};
    end
endgenerate

endmodule
