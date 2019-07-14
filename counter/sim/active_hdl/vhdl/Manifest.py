action = "simulation"
sim_tool = "active_hdl"
sim_top = "counter_tb"

sim_post_cmd = (
    "vsimsa -do ../play_sim.do\n\t\t"
    "avhdl wave.asdb")

modules = {
  "local" : [ "../../../testbench/counter_tb/vhdl" ],
}

