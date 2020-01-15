action = "simulation"
sim_tool = "modelsim"
sim_top = "packet_assembler_tb"

sim_post_cmd = "vsim -novopt -do ../vsim.do -i packet_assembler_tb"

modules = {
  "local" : [ "../../../testbench/hdmi_tb" ],
}
