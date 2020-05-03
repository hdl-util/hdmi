`timescale 1 ps / 1 ps

module spd_tb();

logic [55:0] sub [3:0];

source_product_description_info_frame #(
    .VENDOR_NAME({"Unknown", 8'h00}),
    .PRODUCT_DESCRIPTION({"FPGA", 96'd0}),
    .SOURCE_DEVICE_INFORMATION(8'h00)
) source_product_description_info_frame (.sub(sub));

initial
begin
  #1ps;
  assert(source_product_description_info_frame.vendor_name == '{8'h55, 8'h6e, 8'h6b, 8'h6e, 8'h6f, 8'h77, 8'h6e, 8'h00}) else $fatal(0, "%p", source_product_description_info_frame.vendor_name);
  assert(source_product_description_info_frame.product_description == '{8'h46, 8'h50, 8'h47, 8'h41, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00});
  assert(sub[0] == {"wonknU", 8'h54}) else $fatal(0, "%h expected %h", sub[0], {"wonknU", 8'h54});
  assert(sub[1] == {8'd0, "AGPF", 8'd0, "n"}) else $fatal(0, "%h expected %h", sub[1], {8'd0, "AGPF", 8'd0, "n"});
  assert(sub[2] == 56'd0) else $fatal(0, "subpacket 3 should be 0");
  $finish;
end

endmodule
