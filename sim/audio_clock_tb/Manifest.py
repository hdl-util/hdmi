action = "simulation"
sim_tool = "modelsim"
sim_top = "audio_clock_tb"

sim_post_cmd = "vsim -do ../vsim.do -c audio_clock_tb"

modules = {
  "local" : [ "../../test/audio_clock_tb" ],
}
