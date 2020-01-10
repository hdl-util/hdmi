action = "simulation"
sim_tool = "iverilog"
sim_top = "hdmi_tb"

sim_post_cmd = "vvp hdmi_tb.vvp; gtkwave hdmi_tb.vcd"

modules = {
  "local" : [ "../../testbench/hdmi_tb" ],
}

