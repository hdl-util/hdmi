# verilog-hdmi

FPGA cores for HDMI video/audio output and VGA-compatible text mode written in Verilog.

## Why?

Most open source HDMI modules output a DVI signal, which HDMI sinks are backwards compatible with.

To send audio and other auxiliary data, a true HDMI signal must be sent. The HDMI module in this repository lets you do that.


## Usage

* Take HDMI modules from `modules/hdmi/verilog` and add them to your own project.
* Consult `top/max10/verilog/max10_top.v` for an example of usage.
* Please create an issue if you run into any problems


### Demo: VGA-compatible text mode, 720x480p on a Dell Ultrasharp 1080p Monitor

![GIF showing VGA-compatible text mode on a monitor](demo.gif)

### To-do List
- [x] 24-bit color
- [x] Null data island packets
- [x] Video formats 1, 2, 3, 4, and 16
- [x] VGA-compatible text mode
	- [x] IBM 8x16 font
	- [ ] Alternate fonts
- [ ] LPCM audio data island packets
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

## Special Thanks

* Mike Field's (@hamsternz) demos of DVI and HDMI output for helping me better understand HDMI
* Jean P. Nicolle (fpga4fun.com) for implementing TMDS 8b/10b encoding
