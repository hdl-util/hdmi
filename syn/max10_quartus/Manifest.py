target = "altera"
action = "synthesis"

syn_family = "MAX 10"
syn_device = "10M04SA"
syn_grade = "C8G"
syn_package = "E144"
syn_top = "max10_top"
syn_project = "compute"
syn_tool = "quartus"

quartus_preflow = "../../top/max10/pinout.tcl"
quartus_postmodule = "../../top/max10/module.tcl"

modules = {
  "local" : [ "../../top/max10" ],
}

