// Implementation of HDMI Auxiliary Video InfoFrame packet.
// By Sameer Puri https://github.com/sameer

// See Section 8.2.1
module auxiliary_video_information_info_frame
#(
    parameter VIDEO_FORMAT = 2'b00, // 00 = RGB, 01 = YCbCr 4:2:2, 10 = YCbCr 4:4:4
    parameter ACTIVE_FORMAT_INFO_PRESENT = 1'b0, // Not valid
    parameter BAR_INFO = 2'b00, // Not valid
    parameter SCAN_INFO = 2'b00, // No data
    parameter COLORIMETRY = 2'b00, // No data
    parameter PICTURE_ASPECT_RATIO = 2'b00, // No data, See CEA-CEB16 for more information about Active Format Description processing.
    parameter ACTIVE_FORMAT_ASPECT_RATIO = 4'b1000, // Not valid unless ACTIVE_FORMAT_INFO_PRESENT = 1'b1, then Same as picture aspect ratio
    parameter IT_CONTENT = 1'b0, //  The IT content bit indicates when picture content is composed according to common IT practice (i.e. without regard to Nyquist criterion) and is unsuitable for analog reconstruction or filtering. When the IT content bit is set to 1, downstream processors should pass pixel data unfiltered and without analog reconstruction.
    parameter EXTENDED_COLORIMETRY = 3'b000, // Not valid unless COLORIMETRY = 2'b11. The extended colorimetry bits, EC2, EC1, and EC0, describe optional colorimetry encoding that may be applicable to some implementations and are always present, whether their information is valid or not (see CEA 861-D Section 7.5.5).
    parameter RGB_QUANTIZATION_RANGE = 2'b00, // Default. Displays conforming to CEA-861-D accept both a limited quantization range of 220 levels (16 to 235) anda full range of 256 levels (0 to 255) when receiving video with RGB color space (see CEA 861-D Sections 5.1, Section 5.2, Section 5.3 and Section 5.4). By default, RGB pixel data values should be assumed to have the limited range when receiving a CE video format, and the full range when receiving an IT format. The quantization bits allow the source to override this default and to explicitly indicate the current RGB quantization range.
    parameter NON_UNIFORM_PICTURE_SCALING = 2'b00, // None. The Nonuniform Picture Scaling bits shall be set if the source device scales the picture or has determined that scaling has been performed in a specific direction.
    parameter VIDEO_ID_CODE, // Same as the one from the HDMI module
    parameter YCC_QUANTIZATION_RANGE = 2'b00, // 00 = Limited, 01 = Full
    parameter CONTENT_TYPE = 2'b00, // No data, becomes Graphics if IT_CONTENT = 1'b1.
    parameter PIXEL_REPETITION = 4'b0000 // None
)
(
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);


localparam LENGTH = 5'd13;
localparam VERSION = 8'd2;
localparam TYPE = 7'd2;

assign header = {{3'b0, LENGTH}, VERSION, {1'b1, TYPE}};

// PB0-PB6 = sub0
// PB7-13 =  sub1
// PB14-20 = sub2
// PB21-27 = sub3
logic [7:0] pb [27:0];

assign pb[0] = ~(header[23:16] + header[15:8] + header[7:0] + pb[13] + pb[12] + pb[11] + pb[10] + pb[9] + pb[8] + pb[7] + pb[6] + pb[5] + pb[4] + pb[3] + pb[2] + pb[1]);
assign pb[1] = {1'b0, VIDEO_FORMAT, ACTIVE_FORMAT_INFO_PRESENT, BAR_INFO, SCAN_INFO};
assign pb[2] = {COLORIMETRY, PICTURE_ASPECT_RATIO, ACTIVE_FORMAT_ASPECT_RATIO};
assign pb[3] = {IT_CONTENT, EXTENDED_COLORIMETRY, RGB_QUANTIZATION_RANGE, NON_UNIFORM_PICTURE_SCALING};
assign pb[4] = {1'b0, VIDEO_ID_CODE};
assign pb[5] = {YCC_QUANTIZATION_RANGE, CONTENT_TYPE, PIXEL_REPETITION};

genvar i;
generate
    if (BAR_INFO != 2'b00) // Assign values to bars if BAR_INFO says they are valid.
        assign pb[13:6] = '{8'd0, 8'd0, ~8'd0, ~8'd0, 8'd0, 8'd0, ~8'd0, ~8'd0};
    else
        assign pb[13:6] = '{8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0};
    for (i = 14; i < 28; i++)
    begin: pb_reserved
        assign pb[i] = 8'd0;
    end
    for (i = 0; i < 4; i++)
    begin: pb_to_sub
        assign sub[i] = {pb[6 + i*7], pb[5 + i*7], pb[4 + i*7], pb[3 + i*7], pb[2 + i*7], pb[1 + i*7], pb[0 + i*7]};
    end
endgenerate

endmodule
