action = "simulation"
sim_tool = "modelsim"
sim_top = "hdmi_tb"

sim_post_cmd = "vsim -novopt -do ../vsim.do -i hdmi_tb"

modules = {
  "local" : [ "../../../testbench/hdmi_tb" ],
}
