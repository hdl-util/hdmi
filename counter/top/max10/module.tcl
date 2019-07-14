
set module [lindex $quartus(args) 0]


if [string match "quartus_map" $module] {

    # Include commands here that are run 
    # after analysis and synthesis
    post_message "Running after analysis & synthesis"
}


if [string match "quartus_fit" $module] {

    # Include commands here that are run 
    # after fitter (Place & Route)
    post_message "Running after place & route"
}


if [string match "quartus_asm" $module] {

    # Include commands here that are run 
    # after assembler (Generate programming files)
    post_message "Running after timing analysis"
}


if [string match "quartus_tan" $module] {

    # Include commands here that are run 
    # after timing analysis
    post_message "Running after timing analysis"
}


