action = "simulation"
sim_tool = "modelsim"
sim_top = "audio_param_tb"

sim_post_cmd = "vsim -novopt -do ../vsim.do -c audio_param_tb"

modules = {
  "local" : [ "../../test/audio_param_tb" ],
}
