onfinish stop
run -all
if { [runStatus -full] == "break simulation_stop {\$finish}" } {
    echo Build succeeded
    quit -f -code 0
} else {
    echo Build failed with status [runStatus -full]
    quit -f -code 1
}
