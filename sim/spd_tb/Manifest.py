action = "simulation"
sim_tool = "modelsim"
sim_top = "spd_tb"

sim_post_cmd = "vsim -novopt -do ../vsim.do -c spd_tb"

modules = {
  "local" : [ "../../test/spd_tb" ],
}
