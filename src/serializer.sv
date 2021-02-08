module serializer
#(
    parameter int NUM_CHANNELS = 3,
    parameter real VIDEO_RATE
)
(
    input logic clk_pixel,
    input logic clk_pixel_x5,
    input logic [9:0] tmds_internal [NUM_CHANNELS-1:0],
    output logic [2:0] tmds,
    output logic tmds_clock
);

`ifndef VERILATOR
    `ifdef SYNTHESIS
        `ifndef ALTERA_RESERVED_QIS
            // Based on VHDL implementation by Furkan Cayci, 2010
            logic [9:0] tmds_internal_plus_clock [NUM_CHANNELS:0];
            assign tmds_internal_plus_clock =tmds_internal_plus_clock '{10'b0000011111, tmds_internal[2], tmds_internal[1], tmds_internal[0]};
            logic [1:0] cascade [NUM_CHANNELS:0];
            genvar i;
            generate
                for (i = 0; i <= NUM_CHANNELS; i++)
                begin: xilinx_serialize
                    OSERDES2 #(.DATA_RATE_OQ("DDR"), .DATA_RATE_TQ("SDR"), .DATA_WIDTH(10), .SERDES_MODE("MASTER"), .TRISTATE_WIDTH(1))
                        primary (
                            .OQ(i == NUM_CHANNELS ? tmds_clock : tmds[i]),
                            .OFB(),
                            .TQ(),
                            .TFB(),
                            .SHIFTOUT1(),
                            .SHIFTOUT2(),
                            .TBYTEOUT(),
                            .CLK(clk_pixel_x5),
                            .CLKDIV(clk_pixel),
                            .D1(tmds_internal_plus_clock[i][0]),
                            .D2(tmds_internal_plus_clock[i][1]),
                            .D3(tmds_internal_plus_clock[i][2]),
                            .D4(tmds_internal_plus_clock[i][3]),
                            .D5(tmds_internal_plus_clock[i][4]),
                            .D6(tmds_internal_plus_clock[i][5]),
                            .D7(tmds_internal_plus_clock[i][6]),
                            .D8(tmds_internal_plus_clock[i][7]),
                            .TCE(1'b0),
                            .OCE(1'b1),
                            .TBYTEIN(1'b0),
                            .RST(),
                            .SHIFTIN1(cascade[i][0]),
                            .SHIFTIN2(cascade[i][1]),
                            .T1(1'b0),
                            .T2(1'b0),
                            .T3(1'b0),
                            .T4(1'b0)
                        );
                    OSERDES2 #(.DATA_RATE_OQ("DDR"), .DATA_RATE_TQ("SDR"), .DATA_WIDTH(10), .SERDES_MODE("SLAVE"), .TRISTATE_WIDTH(1))
                        secondary (
                            .OQ(),
                            .OFB(),
                            .TQ(),
                            .TFB(),
                            .SHIFTOUT1(cascade[i][0]),
                            .SHIFTOUT2(cascade[i][1]),
                            .TBYTEOUT(),
                            .CLK(clk_pixel_x5),
                            .CLKDIV(clk_pixel),
                            .D1(1'b0),
                            .D2(1'b0),
                            .D3(tmds_internal_plus_clock[i][8]),
                            .D4(tmds_internal_plus_clock[i][9]),
                            .D5(1'b0),
                            .D6(1'b0),
                            .D7(1'b0),
                            .D8(1'b0),
                            .TCE(1'b0),
                            .OCE(1'b1),
                            .TBYTEIN(1'b0),
                            .RST(),
                            .SHIFTIN1(1'b0),
                            .SHIFTIN2(1'b0),
                            .T1(1'b0),
                            .T2(1'b0),
                            .T3(1'b0),
                            .T4(1'b0)
                        );
                end
            endgenerate
        `endif
    `else
        logic [9:0] tmds_reversed [NUM_CHANNELS-1:0];
        genvar i, j;
        generate
            for (i = 0; i < NUM_CHANNELS; i++)
            begin: tmds_rev
                for (j = 0; j < 10; j++)
                begin: tmds_rev_channel
                    assign tmds_reversed[i][j] = tmds_internal[i][9-j];
                end
            end
        endgenerate
        `ifdef MODEL_TECH
            logic [3:0] position = 4'd0;
            always_ff @(posedge clk_pixel_x5)
            begin
                tmds <= {tmds_reversed[2][position], tmds_reversed[1][position], tmds_reversed[0][position]};
                tmds_clock <= position >= 4'd5;
                position <= position == 4'd9 ? 4'd0 : position + 1'd1;
            end
            always_ff @(negedge clk_pixel_x5)
            begin
                tmds <= {tmds_reversed[2][position], tmds_reversed[1][position], tmds_reversed[0][position]};
                tmds_clock <= position >= 4'd5;
                position <= position == 4'd9 ? 4'd0 : position + 1'd1;
            end
        `else
            altlvds_tx	ALTLVDS_TX_component (
                .tx_in ({10'b1111100000, tmds_reversed[2], tmds_reversed[1], tmds_reversed[0]}),
                .tx_inclock (clk_pixel_x5),
                .tx_out ({tmds_clock, tmds[2], tmds[1], tmds[0]}),
                .tx_outclock (),
                .pll_areset (1'b0),
                .sync_inclock (1'b0),
                .tx_coreclock (),
                .tx_data_reset (1'b0),
                .tx_enable (1'b1),
                .tx_locked (),
                .tx_pll_enable (1'b1),
                .tx_syncclock (clk_pixel));
            defparam
                ALTLVDS_TX_component.center_align_msb = "UNUSED",
                ALTLVDS_TX_component.common_rx_tx_pll = "OFF",
                ALTLVDS_TX_component.coreclock_divide_by = 1,
                // ALTLVDS_TX_component.data_rate = "800.0 Mbps",
                ALTLVDS_TX_component.deserialization_factor = 10,
                ALTLVDS_TX_component.differential_drive = 0,
                ALTLVDS_TX_component.enable_clock_pin_mode = "UNUSED",
                ALTLVDS_TX_component.implement_in_les = "OFF",
                ALTLVDS_TX_component.inclock_boost = 0,
                ALTLVDS_TX_component.inclock_data_alignment = "EDGE_ALIGNED",
                ALTLVDS_TX_component.inclock_period = int'(10000000.0 / (VIDEO_RATE * 10.0)),
                ALTLVDS_TX_component.inclock_phase_shift = 0,
                // ALTLVDS_TX_component.intended_device_family = "Cyclone V",
                ALTLVDS_TX_component.lpm_hint = "CBX_MODULE_PREFIX=altlvds_tx_inst",
                ALTLVDS_TX_component.lpm_type = "altlvds_tx",
                ALTLVDS_TX_component.multi_clock = "OFF",
                ALTLVDS_TX_component.number_of_channels = 4,
                // ALTLVDS_TX_component.outclock_alignment = "EDGE_ALIGNED",
                // ALTLVDS_TX_component.outclock_divide_by = 1,
                // ALTLVDS_TX_component.outclock_duty_cycle = 50,
                // ALTLVDS_TX_component.outclock_multiply_by = 1,
                // ALTLVDS_TX_component.outclock_phase_shift = 0,
                // ALTLVDS_TX_component.outclock_resource = "Dual-Regional clock",
                ALTLVDS_TX_component.output_data_rate = int'(VIDEO_RATE * 10.0),
                ALTLVDS_TX_component.pll_compensation_mode = "AUTO",
                ALTLVDS_TX_component.pll_self_reset_on_loss_lock = "OFF",
                ALTLVDS_TX_component.preemphasis_setting = 0,
                // ALTLVDS_TX_component.refclk_frequency = "20.000000 MHz",
                ALTLVDS_TX_component.registered_input = "OFF",
                ALTLVDS_TX_component.use_external_pll = "ON",
                ALTLVDS_TX_component.use_no_phase_shift = "ON",
                ALTLVDS_TX_component.vod_setting = 0,
                ALTLVDS_TX_component.clk_src_is_pll = "off";
        `endif
    `endif
`endif
endmodule