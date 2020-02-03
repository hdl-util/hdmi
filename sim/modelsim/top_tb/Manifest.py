action = "simulation"
sim_tool = "modelsim"
sim_top = "top_tb"

sim_post_cmd = "vsim -novopt -do ../vsim.do -c top_tb"

modules = {
  "local" : [ "../../../test/top_tb" ],
}
