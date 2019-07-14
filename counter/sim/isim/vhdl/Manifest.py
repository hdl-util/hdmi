action = "simulation"
target = "xilinx"
sim_tool = "isim"
sim_top = "counter_tb"

sim_post_cmd = "./isim_proj -gui -tclbatch ../isim_cmd"

modules = {
  "local" : [ "../../../testbench/counter_tb/vhdl" ],
}


