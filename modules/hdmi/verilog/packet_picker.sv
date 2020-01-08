module packet_picker (
    input logic clk_packet,
    input logic [7:0] packet_type,
    
    input logic [23:0] headers [127:0],
    input logic [55:0] subs [127:0] [3:0],

    output logic clk_packet_fanout [127:0],
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);
// Based on selected packet type, sends clk_packet to the correct packet generator and sends its output back to the HDMI module.
genvar i;
generate
    for (i = 0; i < 128; i++) begin: fanout
        assign clk_packet_fanout[i] = i == packet_type ? clk_packet : 1'b0;
    end
endgenerate

assign header = headers[packet_type];
assign sub = subs[packet_type];

endmodule
