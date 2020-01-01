# verilog-hdmi

FPGA cores for HDMI video/audio output and VGA-compatible text mode written in Verilog.

## Why?

Most open source HDMI modules output a DVI signal, which HDMI sinks are backwards compatible with.

To send audio and other auxiliary data, a true HDMI signal must be sent. The HDMI module in this repository lets you do that.


## Usage

* Take HDMI modules from `modules/hdmi/verilog` and add them to your own project.
* Consult `top/max10/verilog/max10_top.v` for an example of usage.
* Please create an issue if you run into any problems

### Pixel/TMDS Clock

You'll need to set up a PLL for producing the HDMI clocks. The pixel clock for each format is shown below:

* 640x480 (1) @ 60Hz: 25.2MHz, @ 59.94Hz: 25.175MHz
* 720x480 (2,3) @ 60Hz: 27.027MHz, @ 59.94Hz: 27MHz
* 1280x720 (4) @ 60Hz: 74.25MHz, @ 59.94Hz: 74.176MHz
* 1920x1080 (16) @ 60Hz: 148.5MHz, @59.94Hz: 148.352MHz
* 720x576 (17, 18) @ 50Hz: 27MHz
* 1280x720 (19) @ 50Hz: 74.25MHz

The TMDS clock should be 10 times as fast as the pixel clock.  If you only have 1 PLL, you can try to set up the TMDS clock and pulse the pixel clock at 1/10th the speed.

## Potential limitations

* Resolution: some FPGAs don't support I/O at speeds high enough to achieve 720p/1080p
	* Workaround: use DDR other special I/O features
* LVDS/TMDS: if your FPGA doesn't support TMDS, you should be able to use LVDS instead (tested up to 720x480)
    * Needs further investigation
* Wiring: if you're using a breakout board or long lengths of untwisted wire, there might be a few pixels that jitter due to interference. Make sure you have all the necessary pins connected. Sometimes disconnecting the ground pins might actually reduce interference.

### Demo: VGA-compatible text mode, 720x480p on a Dell Ultrasharp 1080p Monitor

![GIF showing VGA-compatible text mode on a monitor](demo.gif)

### To-do List
- [x] 24-bit color
- [x] Data island packets
	- [x] Null packet
	- [x] ECC with BCH systematic encoding GF(2^8)
	- [ ] Audio clock regeneration
	- [ ] L-PCM audio
	- [ ] 1-bit audio
- [x] Video formats 1, 2, 3, 4, 16, 17, 18, and 19
- [x] VGA-compatible text mode
	- [x] IBM 8x16 font
	- [ ] Alternate fonts
- [ ] Other color formats (YCbCr, 32-bit color, etc.)
- [ ] Support other video id codes
	- [ ] Interlaced video
	- [ ] Pixel repetition

### Licensing

Dual-licensed under Apache License 2.0 and MIT License.

## Reference Documents

*These documents are not hosted here! They are available on Library Genesis.*

* [HDMI Specification v1.4a](https://libgen.is/book/index.php?md5=28FFF92120C7A2C88F91727004DA71ED)
* [EIA-CEA861-D.pdf](https://libgen.is/book/index.php?md5=CEE424CA0F098096B6B4EC32C32F80AA)
* [DVI Specification v1.0](https://www.cs.unc.edu/~stc/FAQs/Video/dvi_spec-V1_0.pdf)
* [IEC 60958-1](https://ia803003.us.archive.org/30/items/gov.in.is.iec.60958.1.2004/is.iec.60958.1.2004.pdf) (L-PCM audio)

## Special Thanks

* Mike Field's (@hamsternz) demos of DVI and HDMI output for helping me better understand HDMI
	* http://www.hamsterworks.co.nz/mediawiki/index.php/Dvid_test
	* http://www.hamsterworks.co.nz/mediawiki/index.php/Minimal_DVI-D
* Jean P. Nicolle (fpga4fun.com) for implementing TMDS 8b/10b encoding
	* https://www.fpga4fun.com/HDMI.html
