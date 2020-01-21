module packet_picker (
    input logic [7:0] packet_type,
    input logic [23:0] headers [255:0],
    input logic [55:0] subs [255:0] [3:0],
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);

assign header = headers[packet_type];
assign sub = subs[packet_type];

endmodule
