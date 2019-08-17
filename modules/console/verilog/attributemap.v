module attributemap (
           input wire clk,
           input wire [7:0] attribute,
           output reg [23:0] fgrgb,
           output reg [23:0] bgrgb,
           output reg blink
       );
// See https://en.wikipedia.org/wiki/Video_Graphics_Array#Color_palette
always @(posedge clk)
begin
    case(attribute[3:0])
        4'h0: fgrgb <= 24'h000000;
        4'h1: fgrgb <= 24'h0000AA;
        4'h2: fgrgb <= 24'h00AA00;
        4'h3: fgrgb <= 24'h00AAAA;
        4'h4: fgrgb <= 24'hAA0000;
        4'h5: fgrgb <= 24'hAA00AA;
        4'h6: fgrgb <= 24'hAA5500;
        4'h7: fgrgb <= 24'hAAAAAA;
        4'h8: fgrgb <= 24'h555555;
        4'h9: fgrgb <= 24'h5555FF;
        4'hA: fgrgb <= 24'h55FF55;
        4'hB: fgrgb <= 24'h55FFFF;
        4'hC: fgrgb <= 24'hFF5555;
        4'hD: fgrgb <= 24'hFF55FF;
        4'hE: fgrgb <= 24'hFFFF55;
        4'hF: fgrgb <= 24'hFFFFFF;
    endcase
    case(attribute[6:4])
        3'b000: bgrgb <= 24'h000000;
        3'b001: bgrgb <= 24'h0000AA;
        3'b010: bgrgb <= 24'h00AA00;
        3'b011: bgrgb <= 24'h00AAAA;
        3'b100: bgrgb <= 24'hAA0000;
        3'b101: bgrgb <= 24'hAA00AA;
        3'b110: bgrgb <= 24'hAA5500;
        3'b111: bgrgb <= 24'hAAAAAA;
    endcase
    blink <= attribute[7];
end
endmodule
