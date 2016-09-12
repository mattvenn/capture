# can run `make Q=` to see commands as they run
Q := @

CFLAGS += --std=gnu99 -O2 -Wall

CC := $(Q)$(CC)
RM := $(Q)$(RM)
PASM := $(Q)pasm -DBUILD_WITH_PASM=1
DTC := $(Q)dtc

.PHONY: all clean install

TARGETS := capture pru1.bin capture-00A0.dtbo

all: $(TARGETS)

clean:
	$(RM) $(TARGETS) *.o

install: capture-00A0.dtbo
	$(Q)install -v $^ /lib/firmware

%.bin: %.p
	$(PASM) -b $^

capture: capture.o
	$(CC) -o $@ $^ -l prussdrv

%.dtbo: %.dts
	$(DTC) -I dts -b0 -O dtb -@ -o $@ $^

