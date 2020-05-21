# hdmi

[English](./README.md) | [Français](./README_fr.md) | [Help translate](https://github.com/hdl-util/hdmi/issues/11)

[![Statut de Construction](https://travis-ci.com/hdl-util/hdmi.svg?branch=master)](https://travis-ci.com/hdl-util/hdmi)

SystemVerilog code pour transmettre vidéo/audio HDMI 1.4a sur un [FPGA](https://fr.wikipedia.org/wiki/Circuit_logique_programmable#FPGA).

## Pourquoi?

La plupart des implementations open source d'un source HDMI transmettre en réalité un signal DVI, avec qui les sinks HDMI (i.e. TVs/moniteurs) sont rétrocompatible. Pour supporter audio et l'autre HDMI seulement fonctionnalité, on doit transmettre un signal HDMI vrai. Le code dans ce dépôt permettez-vous de faire ça sans licencer un bloc HDMI IP de n'importe qui.

### Démo: Mode texte VGA-compatible, 720x480p sur un Moniteur Dell Ultrasharp 1080p

![GIF showing VGA-compatible text mode on a monitor](demo.gif)

## Usage

1. Take files from `src/` and add them to your own project. If you use [hdlmake](https://hdlmake.readthedocs.io/en/master/), you can add this repository itself as a remote module.
1. Other helpful modules for displaying text / generating sound are also available in this GitHub organization.
1. Consult the simple usage example in `top/top.sv`.
1. See [hdmi-demo](https://github.com/hdl-util/hdmi-demo) for code that runs the demo as seen the demo GIF.
1. Read through the parameters in `hdmi.sv` and tailor any instantiations to your situation.
1. Please create an issue if you run into a problem or have any questions. Make sure you have consulted the troubleshooting section first.

### Platform Support

S'il vous plaît regarder le readme principal pour l'information à jour.

### Liste de choses à faire

S'il vous plaît regarder le readme principal pour l'information à jour.

### Horloge Pixel

Vous devrez configurer un PLL pour produire 2 horloges HDMI. S'il vous plaît regarder le readme principal pour la configuration de l'horloge première (l'horloge pixel).

La deuxième est une horloge 10 fois plus rapide que l'horloge pixel. Même si ton FPGA a un seul PLL, le MegaWizard Altera (ou le équivalent Xilinx)  devrait pouvour les deux. Vous pouvez éviter d'utiliser deux facteurs de multiplication différents avec la fonction DDRIO, ce qui nécessite une horloge deuxième seulement 5 fois plus rapide.

### Débit Binaire Audio L-PCM / Fréquence d'échantillonnage

Débit binaire audio et fréquence sont spécifiés comme paramètres du module HDMI. Débit binaire peut être n'importe quelle valeur de 16 à 24. S'il vous plaît regarder le readme principal pour une cartographie simple de la fréquence d'échantillonnage aux paramètres appropriés.

### Source Device Information Code

This code is sent in the Source Product Description InfoFrame via `SOURCE_DEVICE_INFORMATION` to give HDMI sinks an idea of what capabilities an HDMI source might have. It may be used for displaying a relevant icon in an input list (i.e. DVD logo for a DVD player).

### Things to be aware of / Troubleshooting

* Limited resolution: some FPGAs don't support I/O at speeds high enough to achieve 720p/1080p
    * Workaround: use DDR/other special I/O features like I/O serializers
	* Workaround: Altera FPGA users can try to specify speed grade C6 and see if it works, though yours may be C7 or C8. If it doesn't work, try enabling DDRIO.
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
    * This shouldn't affect anything in the long term; the only stateful value is `hdmi.tmds_channel[2:0].acc`
    * You should decide hotplug behavior (i.e. pause/resume on disconnect/connect, or ignore it)
* EDID not implemented: it is assumed you know what format you want at synthesis time, so there is no dynamic decision on video format
    * To be implemented in a display protocol independent manner
* SCL/SCA voltage level: though unused by this implementation...it is I2C on a 5V logic level, as confirmed in the [TPD12S016 datasheet](https://www.ti.com/lit/ds/symlink/tpd12s016.pdf), which is unsupported by most FPGAs
    * Solution: use a bidirectional logic level shifter compatible with I2C to convert 3.3v LVTTL to 5v
    * Solution: use 3.3-V LVTTL I/O standard with 6.65k pull-up resistors to 3.3v (as done in `J13` on the [Arduino MKR Vivado 4000 schematic](https://content.arduino.cc/assets/vidor_c10_sch.zip))
	* Emailed Arduino support: safe to use as long as the HDMI slave does not have pull-ups

## Licensing

Dual-licensed under Apache License 2.0 and MIT License.

### Adoption HDMI

Moi je ne suis pas un avocat -- l'avis ci dessous est donné sur la base de discussion sur [une publication Hacker News](https://news.ycombinator.com/item?id=22279308) et ma recherche.

HDMI itself is not a royalty free technology, unfortunately. You are free to use it for testing, development, etc. but to receive the HDMI LA's (licensing administration) blessing to create and sell end-user products:


> The manufacturer of the finished end-user product MUST be a licensed HDMI Adopter, and
> The finished end-user product MUST satisfy all requirements as defined in the Adopter Agreement including but not limited to passing compliance testing either at an HDMI ATC or through self-testing.


Becoming an adopter means you have to pay a flat annual fee (~ $1k-$2k) and a per device royalty (~ $0.05). If you are selling an end-user device and DO NOT want to become an adopter, you can turn on the `DVI_OUTPUT` parameter, which will disable any HDMI-only logic, like audio.

Please consult your lawyer if you have any concerns. Here are a few noteworthy cases that may help you make a decision:

* Arduino LLC is not an adopter, yet sells the [Arduino MKR Vidor 4000](https://store.arduino.cc/usa/mkr-vidor-4000) FPGA 
    * It has a micro-HDMI connector
    * [Having an HDMI connector does not require a license](https://electronics.stackexchange.com/questions/28202/legality-of-using-hdmi-connectors-in-non-hdmi-product)
    * Official examples provided by Arduino on GitHub only perform DVI output
    * It is a user's choice to program the FPGA for HDMI output
    * Therefore: the device isn't an end-user product under the purview of HDMI LA
* Unlicensed DisplayPort to HDMI cables (2011)
    * [Articles suggests that the HDMI LA can recall illegal products](https://www.pcmag.com/archive/displayport-to-hdmi-cables-illegal-could-be-recalled-266671?amp=1).
    * But these cables [are still sold on Amazon](https://www.amazon.com/s?k=hdmi+to+displayport+cable)
    * Therefore: the power of HDMI LA to enforce licensing is unclear
* [Terminated Adopters](https://hdmi.org/adopter/terminated)
    * There are currently 1,043 terminated adopters
    * Includes noteworthy companies like Xilinx, Lattice Semiconductor, Cypress Semiconductor, EVGA (!), etc.
    * No conclusion
* Raspberry Pi Trading Ltd is licensed
    * They include the HDMI logo for products
    * Therefore: Raspberry Pi products are legal, licensed end-user products

## Alternative Implementations

- [HDMI Intel FPGA IP Core](https://www.intel.com/content/www/us/en/programmable/products/intellectual-property/ip/interface-protocols/m-alt-hdmi-megacore.html): Stratix/Arria/Cyclone
- [Xilinx HDMI solutions](https://www.xilinx.com/products/intellectual-property/hdmi.html#overview): Virtex/Kintex/Zynq/Artix
- [Artix 7 HDMI Processing](https://github.com/hamsternz/Artix-7-HDMI-processing): VHDL, decode & encode
- [SimpleVOut](https://github.com/cliffordwolf/SimpleVOut): many formats, no auxiliary data

If you know of another good alternative, open an issue and it will be added.

## Reference Documents

*These documents are not hosted here! They are available on Library Genesis and at other locations.*

* [HDMI Specification v1.4b](https://b-ok.cc/book/5499564/fe35f4)
* [HDMI Specification v2.0](https://b-ok.cc/book/5464885/1f0b4c)
* [EIA-CEA861-D.pdf](https://libgen.is/book/index.php?md5=CEE424CA0F098096B6B4EC32C32F80AA)
* [CTA-861-G.pdf](https://b-ok.cc/book/5463292/52859e)
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
* @glenwing for [links to many VESA standard documents](https://glenwing.github.io/docs/)
