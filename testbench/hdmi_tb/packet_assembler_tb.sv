`timescale 1 ps / 1 ps
module packet_assembler_tb();

initial begin   
  $dumpvars(0, packet_assembler_tb);
  #1280 $finish;
end

logic clk_tmds = 0;
logic clk_pixel = 0;
logic data_island_period;
logic [23:0] header;
logic [55:0] sub [3:0];
logic [8:0] packet_data;

// Clock generator
always begin
  #10 clk_pixel = ~clk_pixel; // Toggle every 10 ticks
  #1 clk_tmds = ~clk_tmds; // Toggle every tick
end

logic [5:0] counter = 0;

assign data_island_period = counter < 32;
assign header = 24'h0D0282;
assign sub = '{56'd0, 56'd0, 56'd0, {8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'b01000000, 8'b00101111}};


always @(posedge clk_pixel)
begin
    counter <= counter + 1'b1;
    assert (counter == packet_assembler.counter || counter > 31) else $fatal("counters do not match: %d vs %d", counter, packet_assembler.counter);
    if (counter == 24)
        assert (packet_assembler.parity[4] == 8'b11100100) else $fatal("parity incorrect for header: %b", packet_assembler.parity[4]);
    if (counter == 28)
        assert (packet_assembler.parity[0] == 8'b01110001) else $fatal("parity incorrect for sub0: %b", packet_assembler.parity[0]);
end

packet_assembler packet_assembler(.clk_pixel(clk_pixel), .data_island_period(data_island_period), .header(header), .sub(sub), .packet_data(packet_data));

endmodule