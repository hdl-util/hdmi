module console (
           input wire clk_pixel,
           input wire [7:0] character,
           input wire [7:0] attribute,
           input wire [9:0] cx,
           input wire [9:0] cy,

           output reg [23:0] rgb = 24'd0
       );

wire [127:0] characterraster;
charactermap charactermap(.clk(clk_pixel), .character(character), .characterraster(characterraster));

wire [23:0] fgrgb, bgrgb;
wire blink;
attributemap attributemap(.clk(clk_pixel), .attribute(attribute), .fgrgb(fgrgb), .bgrgb(bgrgb), .blink(blink));

reg [9:0] prevcy = 0;
reg [3:0] vindex = 0;
reg [2:0] hindex = 0;
reg [5:0] blink_timer = 0;

always @(posedge clk_pixel)
begin
    if (cx == 0 && cy == 0)
    begin
        prevcy <= 0;
        vindex <= 0;
        hindex <= 0;
        blink_timer <= blink_timer + 1'b1;
    end
    else if (prevcy != cy)
    begin
        prevcy <= cy;
        vindex <= vindex + 1'b1;
        hindex <= 0;
    end
    else
    begin
        hindex <= hindex + 1'b1;
    end

    if (blink && blink_timer[5])
        rgb <= bgrgb;
    else
        rgb <= characterraster[{~vindex, ~hindex}] ? fgrgb : bgrgb;
end
endmodule
