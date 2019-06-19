# UltimateRTC

Tool to set the GEOS system clock from the onboard real-time clock of the 1541
Ultimate II cartridge.

## How to use

UltimateRTC is an auto-exec program, and will run automatically at startup if
copied to your GEOS boot disk. Alternatively, you can double-click to run it
after startup like a normal application.

If the cartridge is not present, or the clock cannot be read for whatever
reason, an error message will be shown, but after it is dismissed, startup 
will continue with the clock left untouched.

Note that this tool does not propagate clock changes back from GEOS to the
Ultimate II - the Ultimate II clock must still be set using its configuration
menu.

## Requirements

- A real Commodore 64 or 128 system (not much point in running this in an
  emulator).
- A 1541 Ultimate II or II+ cartridge, with the command interface enabled.
- A GEOS boot disk (GEOS 64 and GEOS 128 are both supported).

## Building

The following tools are required, and must be on your default path

- `make`
- [CC65](https://github.com/cc65/cc65) version 2.18 or newer
- [VICE](http://vice-emu.sourceforge.net) - in particular, the `c1541` tool
- [ImageMagick](https://imagemagick.org) - only needed if editing the icon image

With all these tools on your path, all you need to do is run `make`, which will
produce both a standalone `.cvt` file for use with CONVERT, and a `.d64` disk
image containing the ready-to-use executable. The disk image format can be
changed by setting `IMGTYPE` in the `make` command line. For example, `make
IMGTYPE=d81` will produce a `.d81` disk image for those lucky people with a
1581 drive.

If disk images called `GEOS64.D64` and `GEOS128.D64` (as available at
[cbmfiles.com](http://cbmfiles.com/geos/geos-13.php)) are present, `make
bootdisks` (or `make boot64.d64` and `make boot128.d64`) will use them as
templates to produce GEOS boot disks with UltimateRTC installed as an auto-exec.

For debugging the date-parsing and date-setting logic in an emulator without a
1541U2, the `make` option `MOCK=1` builds a version that skips all the device
IO, and parses and sets the date from a mock date string.

## A note on Y2K compatibility

The GEOS programmers manual says that the year is represented as an offset from
1900, which would suggest that GEOS is Y2K-safe, the actual implementation does
not reflect this, and post-2000 dates stored this way behave oddly.

However, if the representation is treated as modulo-100, representing 2000 as
`$00`, date calculations are correct. Some programs may display them as
20th-century dates, but patches for popular affected programs [are
available](http://www.zimmers.net/anonftp/pub/cbm/geos/patches/index.html).

For more information see [the comments in
`time1.s`](https://github.com/mist64/geos/blob/master/kernal/time/time1.s) in
the disassembled GEOS source code.
