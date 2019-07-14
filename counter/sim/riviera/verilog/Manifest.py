action = "simulation"
sim_tool = "riviera"
sim_top = "counter_tb"

sim_post_cmd = "vsim -do ../vsim.do"

modules = {
  "local" : [ "../../../testbench/counter_tb/verilog" ],
}
