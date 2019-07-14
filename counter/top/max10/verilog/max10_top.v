module max10_top (
           input  wire       CLK_50MHZ,
           input  wire       CLK_32KHZ,
           input  wire			RST,

           output wire       	CLK_50MHZ_ENABLE,
           output wire			CLK_32KHZ_ENABLE,
           output wire	[7:0]	LED,

           output wire [2:0] 	TMDSp,
           output wire			TMDS_clockp,
           output wire [2:0] 	TMDSn,
           output wire			TMDS_clockn
       );
assign CLK_50MHZ_ENABLE = 1'b1;
assign CLK_32KHZ_ENABLE = 1'b0;


wire CLK_TMDS;
wire CLK_PIXEL;
pll pll(.inclk0(CLK_50MHZ), .c0(CLK_TMDS), .c1(CLK_PIXEL));

wire [23:0] rgb;
wire [9:0] cx, cy;
hdmi hdmi(.CLK_TMDS(CLK_TMDS), .CLK_PIXEL(CLK_PIXEL), .rgb(rgb), .TMDSp(TMDSp), .TMDS_clockp(TMDS_clockp), .TMDSn(TMDSn), .TMDS_clockn(TMDS_clockn), .cx(cx), .cy(cy));


// always @(posedge CLK_PIXEL)
// begin
// 	if (cy < 16 || cy >= 464 || cx < 18 || cx >= 619)
// 		rgb <= 24'hff0000;
// 	else
// 		rgb <= 24'h000000;
// end


reg [7:0] character = 8'h30;
reg [5:0] prevcy = 0;
always @(posedge CLK_PIXEL)
begin
    if (cy == 0)
    begin
        character <= 8'h30;
        prevcy <= 0;
    end
    else if (prevcy != cy[9:4])
    begin
        character <= character + 8'h01;
        prevcy <= cy[9:4];
    end
end

// reg [7:0] firstchar = 8'h30;
// always @(posedge CLK_PIXEL)
// begin
// 	if (cx == 0 && cy == 0)
// 	begin
// 		character <= 0;
// 		firstchar <= 0;
// 		prevcy <= 0;
// 	end
// 	else if (cy == prevcy)
// 	begin
// 		if (cx % 8 == 0)
// 			character = character + 1'b1;
// 	end
// 	else if (cy != prevcy)
// 	begin
// 		if (cy % 16 == 0)
// 			firstchar = character + 1'b1;
// 		prevcy = cy;
// 		character = firstchar;
// 	end

// end
console console(.CLK_PIXEL(CLK_PIXEL), .character(character), .attribute(8'b00001111), .cx(cx), .cy(cy), .rgb(rgb));
endmodule
