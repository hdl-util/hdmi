module audio_param_tb ();

localparam AUDIO_RATE = 48000;

hdmi #(.AUDIO_RATE(AUDIO_RATE), .AUDIO_BIT_WIDTH(16)) hdmi_48khz_16bit();
hdmi #(.AUDIO_RATE(AUDIO_RATE), .AUDIO_BIT_WIDTH(20)) hdmi_48khz_20bit();
hdmi #(.AUDIO_RATE(AUDIO_RATE), .AUDIO_BIT_WIDTH(24)) hdmi_48khz_24bit();

initial
begin
    assert (hdmi_48khz_16bit.true_hdmi_output.packet_picker.audio_sample_packet.WORD_LENGTH == 4'b0010) else $fatal(1, "Incorrect word length");
    assert (hdmi_48khz_16bit.true_hdmi_output.packet_picker.audio_sample_packet.channel_status_left[35:32] == 4'b0010) else $fatal(1, "Incorrect word length %b", hdmi_48khz_16bit.true_hdmi_output.packet_picker.audio_sample_packet.channel_status_left);

    assert (hdmi_48khz_20bit.true_hdmi_output.packet_picker.audio_sample_packet.WORD_LENGTH == 4'b1010) else $fatal(1, "Incorrect word length");
    assert (hdmi_48khz_20bit.true_hdmi_output.packet_picker.audio_sample_packet.channel_status_left[35:32] == 4'b1010) else $fatal(1, "Incorrect word length");
    assert (hdmi_48khz_24bit.true_hdmi_output.packet_picker.audio_sample_packet.WORD_LENGTH == 4'b1011) else $fatal(1, "Incorrect word length");
    assert (hdmi_48khz_24bit.true_hdmi_output.packet_picker.audio_sample_packet.channel_status_left[35:32] == 4'b1011) else $fatal(1, "Incorrect word length");
    $finish;
end

endmodule
