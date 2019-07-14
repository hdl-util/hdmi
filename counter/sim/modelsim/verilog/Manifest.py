action = "simulation"
sim_tool = "modelsim"
sim_top = "counter_tb"

sim_post_cmd = "vsim -novopt -do ../vsim.do -i counter_tb"

modules = {
  "local" : [ "../../../testbench/counter_tb/verilog" ],
}
