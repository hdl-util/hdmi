action = "simulation"
sim_tool = "iverilog"
sim_top = "counter_tb"

iverilog_opt = "-g2012"

sim_pre_cmd ="echo IMPORTANT, IVerilog always needs a Verilog testbench, no matter if the DUT is written in VHDL!"
sim_post_cmd = "vvp counter_tb.vvp; gtkwave counter_tb.vcd"

files = [
    "../../../modules/counter/vhdl/counter.vhd",
    "../../../testbench/counter_tb/verilog/counter_tb.v",
]

