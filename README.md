# hdmi

[![Build Status](https://travis-ci.org/hdl-util/hdmi.svg?branch=master)](https://travis-ci.org/hdl-util/hdmi)

SystemVerilog code for FPGA HDMI 1.4a video/audio output.

## Why?

Most open source HDMI code outputs a DVI signal, which HDMI sinks are backwards compatible with.

To send audio and support other HDMI-only functionality, a true HDMI signal must be sent. The code in this repository lets you do that.

### Demo: VGA-compatible text mode, 720x480p on a Dell Ultrasharp 1080p Monitor

![GIF showing VGA-compatible text mode on a monitor](demo.gif)

## Usage

1. Take files from `src/` and add them to your own project. If you use [hdlmake](https://hdlmake.readthedocs.io/en/master/), you can add this repository itself as a remote module. Note that hdlmake may not resolve altera_gpio_lite properly.
2. Other helpful modules for displaying text / generating sound are also available in this GitHub organization.
3. Consult the usage example in `top/top.sv`
4. See [hdmi-demo](https://github.com/hdl-util/hdmi-demo) for code that runs the demo in the GIF
5. Please create an issue if you run into any problems

### Platform Support

- [x] Altera
- [ ] Xilinx (untested but should work)
- [ ] Lattice (unknown)

### To-do List (upon request)
- [x] 24-bit color
- [x] Data island packets
	- [x] Null packet
	- [x] ECC with BCH systematic encoding GF(2^8)
	- [x] Audio clock regeneration
	- [x] L-PCM audio
		- [x] 2-channel
		- [ ] 3-channel to 8-channel
	- [ ] 1-bit audio
	- [x] Audio InfoFrame
	- [x] Auxiliary Video Information InfoFrame
	- [x] Source Product Descriptor InfoFrame
	- [ ] MPEG Source InfoFrame
		- NOTE—Problems with the MPEG Source Infoframe have been identified that were not able to be fixed in time for CEA-861-D. Implementation is strongly discouraged until a future revision fixes the problems
- [x] Video formats 1, 2, 3, 4, 16, 17, 18, and 19
- [x] VGA-compatible text mode
	- [x] IBM 8x16 font
	- [ ] Alternate fonts
- [ ] Other color formats (YCbCr, 32-bit color, etc.)
- [ ] Support other video id codes
	- [ ] Interlaced video
	- [ ] Pixel repetition
- [ ] Special I/O features
        - [x] DDIO


### Pixel/TMDS Clock

You'll need to set up a PLL for producing the two HDMI clocks. The pixel clock for each supported format is shown below:

|Video Resolution|Video ID Code(s)|Refresh Rate|Pixel Clock Frequency|
|---|---|---|---|
|640x480|1|60Hz|25.2MHz|
|640x480|1|59.94Hz|25.175MHz|
|720x480|2, 3|60Hz|27.027MHz|
|720x480|2, 3|59.94Hz|27MHz|
|1280x720|4|60Hz|74.25MHz|
|1280x720|4|59.94Hz|74.176MHz|
|1920x1080|16|60Hz|148.5MHz|
|1920x1080|16|59.94Hz|148.352MHz|
|720x576|17, 18|50Hz|27MHz|
|1280x720|19|50Hz|74.25MHz|

The TMDS clock should be 10 times as fast as the pixel clock.  If you only have 1 PLL, you can try to set up the TMDS clock and pulse the pixel clock at 1/10th the speed.

### L-PCM Audio Bitrate / Sampling Frequency

Both bitrate and frequency are specified as parameters of the HDMI module. Bitrate can be any value from 16 through 24. Below is a simple mapping of sample frequency to the appropriate parameter

|Sampling Frequency|AUDIO_RATE value|
|---|---|
|32 kHz|32000|
|44.1 kHz|44100|
|88.2 kHz|88200|
|176.4 kHz|176400|
|48 kHz|48000|
|96 kHz|96000|
|192 kHz|192000|

### Things to be aware of / Troubleshooting

* Limited resolution: some FPGAs don't support I/O at speeds high enough to achieve 720p/1080p
    * Workaround: use DDR/other special I/O features like I/O serializers
* FPGA does not support TMDS: many FPGAs without a dedicated HDMI output don't support TMDS
    * You should be able to directly use LVDS (3.3v) instead, tested up to 720x480
    * This might not work if your video has a high number of transitions or you plan to use higher resolutions
    * Solution: AC-couple the 3.3v LVDS wires to by adding 100nF capacitors in series, as close to the transmitter as possible
        * Why? TMDS is current mode logic, and driving a CML receiver with LVDS is detailed in [Figure 9 of Interfacing LVDS with other differential-I/O types](https://m.eet.com/media/1135468/330072.pdf)
            * Resistors are not needed since Vcc = 3.3v for both the transmitter and receiver
        * Example: See `J13`, on the [Arduino MKR Vivado 4000 schematic](https://content.arduino.cc/assets/vidor_c10_sch.zip), where LVDS IO Standard pins on a Cyclone 10 FPGA have 100nF series capacitors
* Poor wiring: if you're using a breakout board or long lengths of untwisted wire, there might be a few pixels that jitter due to interference
    * Make sure you have all the necessary pins connected (GND pins, etc.)
    * Try switching your HDMI cable; some cheap cables like [these I got from Amazon](https://www.amazon.com/gp/product/B01JO9PB7E/) have poor shielding
* Hot-Plug unaware: all modules are unaware of hotplug
    * This shouldn't affect anything in the long term; the only stateful value is hdmi.tmds_channel.acc
    * You should decide hotplug behavior (i.e. pause/resume on disconnect/connect, or ignore it)
* EDID not implemented: it is assumed you know what format you want at synthesis time, so there is no dynamic decision on video format
    * To be implemented...
* SCL/SCA voltage level: I2C on a 5V logic level, as confirmed in the [TPD12S016 datasheet](https://www.ti.com/lit/ds/symlink/tpd12s016.pdf), which is unsupported by most FPGAs
    * Solution: use a bidirectional logic level shifter compatible with I2C to convert 3.3v LVTTL to 5v
    * Solution: use 2.5V I/O standard with 6.65k pull-up resistors to 3.3v (as done in `J13` on the [Arduino MKR Vivado 4000 schematic](https://content.arduino.cc/assets/vidor_c10_sch.zip))
        * To investigate: why do they do this, and does it work at all?


## Licensing

Dual-licensed under Apache License 2.0 and MIT License.

## Alternatives

- [HDMI Intel FPGA IP Core](https://www.intel.com/content/www/us/en/programmable/products/intellectual-property/ip/interface-protocols/m-alt-hdmi-megacore.html): Stratix/Arria/Cyclone
- [Xilinx HDMI solutions](https://www.xilinx.com/products/intellectual-property/hdmi.html#overview): Virtex/Kintex/Zynq/Artix
- [Artix 7 HDMI Processing](https://github.com/hamsternz/Artix-7-HDMI-processing): VHDL, decode & encode
- [SimpleVOut](https://github.com/cliffordwolf/SimpleVOut): many formats, no auxiliary data

## Reference Documents

*These documents are not hosted here! They are available on Library Genesis and at other locations.*

* [HDMI Specification v1.4a](https://libgen.is/book/index.php?md5=28FFF92120C7A2C88F91727004DA71ED)
* [EIA-CEA861-D.pdf](https://libgen.is/book/index.php?md5=CEE424CA0F098096B6B4EC32C32F80AA)
* [DVI Specification v1.0](https://www.cs.unc.edu/~stc/FAQs/Video/dvi_spec-V1_0.pdf)
* [IEC 60958-1](https://ia803003.us.archive.org/30/items/gov.in.is.iec.60958.1.2004/is.iec.60958.1.2004.pdf)
* [IEC 60958-3](https://ia800905.us.archive.org/22/items/gov.in.is.iec.60958.3.2003/is.iec.60958.3.2003.pdf)
* [E-DDC v1.2](https://glenwing.github.io/docs/)

## Special Thanks

* Mike Field's (@hamsternz) demos of DVI and HDMI output for helping me better understand HDMI
	* http://www.hamsterworks.co.nz/mediawiki/index.php/Dvid_test
	* http://www.hamsterworks.co.nz/mediawiki/index.php/Minimal_DVI-D
* Jean P. Nicolle (fpga4fun.com) for sparking my interest in HDMI
	* https://www.fpga4fun.com/HDMI.html
* Bureau of Indian Standards for free equivalents of non-free IEC standards 60958-1, 60958-3, etc.
* Glenwing for links to many VESA standard documents
