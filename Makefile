include Project.mk
-include Common.mk

.PHONY: all clean burn

all: $(BUILD)/result.bin

clean:
	@rm -fr $(BUILD)

burn: all
	iceprog -S $(BUILD)/result.bin

$(BUILD)/result.bin: $(MODULES) $(BUILD)/.depend Makefile
	yosys -p "synth_ice40 -top top -blif $(BUILD)/result.blif" $(MODULES)
	arachne-pnr -d $(DEVICE) -P $(FOOTPRINT) -o $(BUILD)/result.asc -p pinmap.pcf $(BUILD)/result.blif
	icepack $(BUILD)/result.asc $(BUILD)/result.bin

.PRECIOUS: $(BUILD)/.depend
$(BUILD)/.depend:
	mkdir -p $(BUILD)
	touch $(BUILD)/.depend
