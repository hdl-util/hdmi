
post_message "Assigning pinout"

# Load Quartus II Tcl Project package
package require ::quartus::project

project_open -revision compute compute

set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85
set_global_assignment -name POWER_PRESET_COOLING_SOLUTION "NO HEAT SINK WITH STILL AIR"
set_global_assignment -name POWER_BOARD_THERMAL_MODEL "NONE (CONSERVATIVE)"
set_global_assignment -name NUM_PARALLEL_PROCESSORS 8

set_location_assignment PIN_21 -to LED[0]
set_location_assignment PIN_22 -to LED[1]
set_location_assignment PIN_24 -to LED[2]
set_location_assignment PIN_25 -to LED[3]
set_location_assignment PIN_32 -to LED[4]
set_location_assignment PIN_33 -to LED[5]
set_location_assignment PIN_38 -to LED[6]
set_location_assignment PIN_39 -to LED[7]

set_location_assignment PIN_27 -to CLK_32KHZ
set_location_assignment PIN_30 -to CLK_32KHZ_ENABLE

set_location_assignment PIN_26 -to CLK_50MHZ
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to CLK_50MHZ
set_location_assignment PIN_17 -to CLK_50MHZ_ENABLE

set_location_assignment PIN_47 -to TMDSp[2]
set_location_assignment PIN_46 -to TMDSn[2]
set_location_assignment PIN_45 -to TMDSp[1]
set_location_assignment PIN_44 -to TMDSn[1]
set_location_assignment PIN_43 -to TMDSp[0]
set_location_assignment PIN_41 -to TMDSn[0]
set_location_assignment PIN_52 -to TMDS_clockp
set_location_assignment PIN_50 -to TMDS_clockn

set_instance_assignment -name IO_STANDARD LVDS -to TMDSp[2]
set_instance_assignment -name IO_STANDARD LVDS -to TMDSp[1]
set_instance_assignment -name IO_STANDARD LVDS -to TMDSp[0]
set_instance_assignment -name IO_STANDARD LVDS -to TMDS_clockp
set_instance_assignment -name IO_STANDARD LVDS -to TMDSn[2]
set_instance_assignment -name IO_STANDARD LVDS -to TMDSn[1]
set_instance_assignment -name IO_STANDARD LVDS -to TMDSn[0]
set_instance_assignment -name IO_STANDARD LVDS -to TMDS_clockn

# Commit assignments
export_assignments
project_close

