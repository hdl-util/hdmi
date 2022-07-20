module serializer
#(
    parameter int NUM_CHANNELS = 3,
    parameter real VIDEO_RATE
)
(
    input logic clk_pixel,
    input logic clk_pixel_x5,
    input logic reset,
    input logic [9:0] tmds_internal [NUM_CHANNELS-1:0],
    output logic [2:0] tmds,
    output logic tmds_clock
);

`ifndef VERILATOR
    `ifdef SYNTHESIS
        `ifndef ALTERA_RESERVED_QIS
            // https://www.xilinx.com/support/documentation/user_guides/ug471_7Series_SelectIO.pdf
            logic tmds_plus_clock [NUM_CHANNELS:0];
            assign tmds_plus_clock = '{tmds_clock, tmds[2], tmds[1], tmds[0]};
            logic [9:0] tmds_internal_plus_clock [NUM_CHANNELS:0];
            assign tmds_internal_plus_clock = '{10'b0000011111, tmds_internal[2], tmds_internal[1], tmds_internal[0]};
            logic [1:0] cascade [NUM_CHANNELS:0];

            // this is requried for OSERDESE2 to work
            logic internal_reset = 1'b1;
            always @(posedge clk_pixel)
            begin
                internal_reset <= 1'b0;
            end
            genvar i;
            generate
                for (i = 0; i <= NUM_CHANNELS; i++)
                begin: xilinx_serialize
                    OSERDESE2 #(
                        .DATA_RATE_OQ("DDR"),
                        .DATA_RATE_TQ("SDR"),
                        .DATA_WIDTH(10),
                        .SERDES_MODE("MASTER"),
                        .TRISTATE_WIDTH(1),
                        .TBYTE_CTL("FALSE"),
                        .TBYTE_SRC("FALSE")
                    ) primary (
                        .OQ(tmds_plus_clock[i]),
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
                        .RST(reset || internal_reset),
                        .SHIFTIN1(cascade[i][0]),
                        .SHIFTIN2(cascade[i][1]),
                        .T1(1'b0),
                        .T2(1'b0),
                        .T3(1'b0),
                        .T4(1'b0)
                    );
                    OSERDESE2 #(
                        .DATA_RATE_OQ("DDR"),
                        .DATA_RATE_TQ("SDR"),
                        .DATA_WIDTH(10),
                        .SERDES_MODE("SLAVE"),
                        .TRISTATE_WIDTH(1),
                        .TBYTE_CTL("FALSE"),
                        .TBYTE_SRC("FALSE")
                    ) secondary (
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
                        .RST(reset || internal_reset),
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
    `elsif GW_IDE
        OSER10 gwSer0( 
            .Q( tmds[ 0 ] ),
            .D0( tmds_internal[ 0 ][ 0 ] ),
            .D1( tmds_internal[ 0 ][ 1 ] ),
            .D2( tmds_internal[ 0 ][ 2 ] ),
            .D3( tmds_internal[ 0 ][ 3 ] ),
            .D4( tmds_internal[ 0 ][ 4 ] ),
            .D5( tmds_internal[ 0 ][ 5 ] ),
            .D6( tmds_internal[ 0 ][ 6 ] ),
            .D7( tmds_internal[ 0 ][ 7 ] ),
            .D8( tmds_internal[ 0 ][ 8 ] ),
            .D9( tmds_internal[ 0 ][ 9 ] ),
            .PCLK( clk_pixel ),
            .FCLK( clk_pixel_x5 ),
            .RESET( reset ) );

        OSER10 gwSer1( 
          .Q( tmds[ 1 ] ),
          .D0( tmds_internal[ 1 ][ 0 ] ),
          .D1( tmds_internal[ 1 ][ 1 ] ),
          .D2( tmds_internal[ 1 ][ 2 ] ),
          .D3( tmds_internal[ 1 ][ 3 ] ),
          .D4( tmds_internal[ 1 ][ 4 ] ),
          .D5( tmds_internal[ 1 ][ 5 ] ),
          .D6( tmds_internal[ 1 ][ 6 ] ),
          .D7( tmds_internal[ 1 ][ 7 ] ),
          .D8( tmds_internal[ 1 ][ 8 ] ),
          .D9( tmds_internal[ 1 ][ 9 ] ),
          .PCLK( clk_pixel ),
          .FCLK( clk_pixel_x5 ),
          .RESET( reset ) );

        OSER10 gwSer2( 
          .Q( tmds[ 2 ] ),
          .D0( tmds_internal[ 2 ][ 0 ] ),
          .D1( tmds_internal[ 2 ][ 1 ] ),
          .D2( tmds_internal[ 2 ][ 2 ] ),
          .D3( tmds_internal[ 2 ][ 3 ] ),
          .D4( tmds_internal[ 2 ][ 4 ] ),
          .D5( tmds_internal[ 2 ][ 5 ] ),
          .D6( tmds_internal[ 2 ][ 6 ] ),
          .D7( tmds_internal[ 2 ][ 7 ] ),
          .D8( tmds_internal[ 2 ][ 8 ] ),
          .D9( tmds_internal[ 2 ][ 9 ] ),
          .PCLK( clk_pixel ),
          .FCLK( clk_pixel_x5 ),
          .RESET( reset ) );
          
        assign tmds_clock = clk_pixel;
  
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
            `ifdef ALTERA_RESERVED_QIS
                altlvds_tx	ALTLVDS_TX_component (
                    .tx_in ({10'b1111100000, tmds_reversed[2], tmds_reversed[1], tmds_reversed[0]}),
                    .tx_inclock (clk_pixel_x5),
                    .tx_out ({tmds_clock, tmds[2], tmds[1], tmds[0]}),
                    .tx_outclock (),
                    .pll_areset (1'b0),
                    .sync_inclock (1'b0),
                    .tx_coreclock (),
                    .tx_data_reset (reset),
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
                `else
                    // We don't know what the platform is so the best bet is an IP-less implementation.
                    // Shift registers are loaded with a set of values from tmds_channels every clk_pixel.
                    // They are shifted out on clk_pixel_x5 by the time the next set is loaded.
                    logic [9:0] tmds_shift [NUM_CHANNELS-1:0] = '{10'd0, 10'd0, 10'd0};

                    logic tmds_control = 1'd0;
                    always_ff @(posedge clk_pixel)
                        tmds_control <= !tmds_control;

                    logic [3:0] tmds_control_synchronizer_chain = 4'd0;
                    always_ff @(posedge clk_pixel_x5)
                        tmds_control_synchronizer_chain <= {tmds_control, tmds_control_synchronizer_chain[3:1]};

                    logic load;
                    assign load = tmds_control_synchronizer_chain[1] ^ tmds_control_synchronizer_chain[0];
                    logic [9:0] tmds_mux [NUM_CHANNELS-1:0];
                    always_comb
                    begin
                        if (load)
                            tmds_mux = tmds_internal;
                        else
                            tmds_mux = tmds_shift;
                    end

                    // See Section 5.4.1
                    for (i = 0; i < NUM_CHANNELS; i++)
                    begin: tmds_shifting
                        always_ff @(posedge clk_pixel_x5)
                            tmds_shift[i] <= load ? tmds_mux[i] : tmds_shift[i] >> 2;
                    end

                    logic [9:0] tmds_shift_clk_pixel = 10'b0000011111;
                    always_ff @(posedge clk_pixel_x5)
                        tmds_shift_clk_pixel <= load ? 10'b0000011111 : {tmds_shift_clk_pixel[1:0], tmds_shift_clk_pixel[9:2]};

                    logic [NUM_CHANNELS-1:0] tmds_shift_negedge_temp;
                    for (i = 0; i < NUM_CHANNELS; i++)
                    begin: tmds_driving
                        always_ff @(posedge clk_pixel_x5)
                        begin
                            tmds[i] <= tmds_shift[i][0];
                            tmds_shift_negedge_temp[i] <= tmds_shift[i][1];
                        end
                        always_ff @(negedge clk_pixel_x5)
                            tmds[i] <= tmds_shift_negedge_temp[i];
                    end
                    logic tmds_clock_negedge_temp;
                    always_ff @(posedge clk_pixel_x5)
                    begin
                        tmds_clock <= tmds_shift_clk_pixel[0];
                        tmds_clock_negedge_temp <= tmds_shift_clk_pixel[1];
                    end
                    always_ff @(negedge clk_pixel_x5)
                        tmds_clock <= tmds_shift_negedge_temp;

                `endif
        `endif
    `endif
`endif
endmodule
