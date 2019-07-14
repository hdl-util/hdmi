action = "simulation"
sim_tool = "ghdl"
sim_top = "counter_tb"

sim_post_cmd = "ghdl -r counter_tb --stop-time=6us --vcd=counter_tb.vcd; gtkwave counter_tb.vcd"

modules = {
  "local" : [ "../../../testbench/counter_tb/vhdl" ],
}
