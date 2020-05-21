module audio_clock_tb ();

localparam AUDIO_RATE = 48000;

hdmi #(.VIDEO_ID_CODE(1), .AUDIO_RATE(AUDIO_RATE), .VIDEO_REFRESH_RATE(59.94)) hdmi_640x480_60Hz();
hdmi #(.VIDEO_ID_CODE(1), .AUDIO_RATE(AUDIO_RATE), .VIDEO_REFRESH_RATE(60)) hdmi_640x480_59_94Hz();
hdmi #(.VIDEO_ID_CODE(4), .AUDIO_RATE(AUDIO_RATE), .VIDEO_REFRESH_RATE(59.94)) hdmi_1280x720_59_94Hz();
hdmi #(.VIDEO_ID_CODE(16), .AUDIO_RATE(AUDIO_RATE), .VIDEO_REFRESH_RATE(60)) hdmi_1920x1080_60Hz();
hdmi #(.VIDEO_ID_CODE(17), .AUDIO_RATE(AUDIO_RATE), .VIDEO_REFRESH_RATE(60)) hdmi_720x576_50Hz();

initial
begin
    assert(hdmi_640x480_60Hz.true_hdmi_output.packet_picker.audio_clock_regeneration_packet.N == 6144);
    assert(hdmi_640x480_60Hz.true_hdmi_output.packet_picker.audio_clock_regeneration_packet.CYCLE_TIME_STAMP_COUNTER_IDEAL == 25175);
    assert(hdmi_640x480_59_94Hz.true_hdmi_output.packet_picker.audio_clock_regeneration_packet.N == 6144);
    assert(hdmi_640x480_59_94Hz.true_hdmi_output.packet_picker.audio_clock_regeneration_packet.CYCLE_TIME_STAMP_COUNTER_IDEAL == 25200);
    assert(hdmi_1280x720_59_94Hz.true_hdmi_output.packet_picker.audio_clock_regeneration_packet.N == 6144);
    assert(hdmi_1280x720_59_94Hz.true_hdmi_output.packet_picker.audio_clock_regeneration_packet.CYCLE_TIME_STAMP_COUNTER_IDEAL == 74176);
    assert(hdmi_1920x1080_60Hz.true_hdmi_output.packet_picker.audio_clock_regeneration_packet.N == 6144);
    assert(hdmi_1920x1080_60Hz.true_hdmi_output.packet_picker.audio_clock_regeneration_packet.CYCLE_TIME_STAMP_COUNTER_IDEAL == 148500);
    assert(hdmi_720x576_50Hz.true_hdmi_output.packet_picker.audio_clock_regeneration_packet.N == 6144);
    assert(hdmi_720x576_50Hz.true_hdmi_output.packet_picker.audio_clock_regeneration_packet.CYCLE_TIME_STAMP_COUNTER_IDEAL == 27000);
    $finish;
end

endmodule
