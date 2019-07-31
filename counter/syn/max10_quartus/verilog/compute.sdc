# Constrain clock port CLK_50MHZ with a 10-ns requirement

# create_clock -period 10 [get_ports CLK_50MHZ]

# Automatically apply a generate clock on the output of phase-locked loops (PLLs)
# This command can be safely left in the SDC even if no PLLs exist in the design

# derive_pll_clocks

# Constrain the input I/O path

# set_input_delay -clock CLK_50MHZ -max 3 [all_inputs]
# set_input_delay -clock CLK_50MHZ -min 2 [all_inputs]

# Constrain the output I/O path

# set_output_delay -clock CLK_50MHZ -max 3 [all_inputs]
# set_output_delay -clock CLK_50MHZ -min 2 [all_inputs]
