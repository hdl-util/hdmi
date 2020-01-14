module packet_picker (
    input logic packet_enable,
    input logic [7:0] packet_type,
    
    input logic [23:0] headers [255:0],
    input logic [55:0] subs [255:0] [3:0],

    output logic packet_enable_fanout [255:0],
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);
// Based on selected packet type, use a mux to send packet_enable to the correct packet generator.
genvar i;
generate
    for (i = 0; i < 256; i++) begin: fanout
        assign packet_enable_fanout[i] = i == packet_type && packet_enable;
    end
endgenerate

assign header = headers[packet_type];
assign sub = subs[packet_type];

endmodule
