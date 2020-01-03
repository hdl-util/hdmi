module packet_picker (
    input logic clk_packet,
    input logic [7:0] select,
    
    input logic [23:0] headers [127:0],
    input logic [55:0] subs [127:0] [3:0],

    output logic clk_packet_fanout [127:0],
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);

genvar i;
generate
    for (i = 0; i < 128; i++) begin: fanout
        assign clk_packet_fanout[i] = i == select ? clk_packet : 1'b0;
    end
endgenerate

assign header = headers[select];
assign sub = subs[select];

endmodule
