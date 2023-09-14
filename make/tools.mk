$(BIN_DIR)/m68k/bin/$(PREFIX)ar $(BIN_DIR)/m68k/bin/$(PREFIX)gcc $(BIN_DIR)/m68k/bin/$(PREFIX)ld $(BIN_DIR)/m68k/bin/$(PREFIX)nm $(BIN_DIR)/m68k/bin/$(PREFIX)objcopy &:
	$(Q)$(MKDIR) -p $(BIN_DIR)/toolchain-build
	$(Q)$(MAKE) -C $(BIN_DIR)/toolchain-build -f $(abspath $(GDK))/make/toolchain.mk
	$(Q)$(MAKE) -C $(BIN_DIR)/toolchain-build -f $(abspath $(GDK))/make/toolchain.mk install INSTALL_DIR=$(BIN_DIR)/m68k

SJASMEP_DIR := $(GDK)/tools/sjasmep
$(BIN_DIR)/sjasm:
	$(MKDIR) -p $(dir $@)
	cd $(SJASMEP_DIR) && $(MAKE)
	$(CP) $(SJASMEP_DIR)/sjasm $@

$(BIN_DIR)/bintos: $(GDK)/tools/bintos/src/*.c
	$(MKDIR) -p $(dir $@)
	gcc -O2 -s $(GDK)/tools/bintos/src/bintos.c -o $@

$(BIN_DIR)/xgmtool:
	$(MKDIR) -p $(dir $@)
	gcc -fexpensive-optimizations -Os -s $(GDK)/tools/xgmtool/src/*.c -o $@

## JAVA TOOLD
$(RESCOMP_JAR): $(BIN_DIR)/xgmtool
	echo "TODO: do compilation of $@ for real"
	$(CP) $(GDK)/bin/rescomp.jar $@

$(SIZEBND_JAR):
	echo "TODO: do compilation of $@ for real"
	$(CP) $(GDK)/bin/sizebnd.jar $@

$(BIN_DIR)/mac68k:
	$(ECHO) implement build for $@

