include Project.mk
-include Common.mk

.PHONY: all
all: ice40

.PHONY: ice40
ice40: $(BUILD)/ice40.bin

$(BUILD)/ice40.blif: $(SOURCE)/*.v $(BUILD)/.depend Makefile
	yosys -q -p "read_verilog -noautowire $(SOURCE)/*.v"  \
	         -p "synth_ice40 -top top -blif $(BUILD)/ice40.blif"

$(BUILD)/ice40.asc: $(BUILD)/ice40.blif $(SOURCE)/ice40_pinmap.pcf
	arachne-pnr -d $(DEVICE) -P $(FOOTPRINT) -o $(BUILD)/ice40.asc  \
	            -p $(SOURCE)/ice40_pinmap.pcf $(BUILD)/ice40.blif

$(BUILD)/ice40.bin: $(BUILD)/ice40.asc
	icepack $(BUILD)/ice40.asc $(BUILD)/ice40.bin

.PHONY: burn
burn: all
	iceprog -S $(BUILD)/ice40.bin

.PHONY: clean
clean:
	@rm -fr $(BUILD)

.PRECIOUS: $(BUILD)/.depend
$(BUILD)/.depend:
	mkdir -p $(BUILD)
	touch $(BUILD)/.depend
