# capture

## pru1 code

* captures 12 bits in register r31 (bits 0 to 11) every rise and fall of a clock on bit 12.
* data is copied into a circular buffer (default 4MB set in setup.sh)

## capture

* copies data out of circular buffer to stdout or a file if provided

# license

[based on prudaq](https://github.com/google/prudaq), which is distributed with the Apache 2 license:
https://github.com/google/prudaq/blob/master/LICENSE
