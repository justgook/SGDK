
$(BIN_UNIX)/m68k/bin/$(PREFIX)ar $(BIN_UNIX)/m68k/bin/$(PREFIX)gcc $(BIN_UNIX)/m68k/bin/$(PREFIX)ld $(BIN_UNIX)/m68k/bin/$(PREFIX)nm $(BIN_UNIX)/m68k/bin/$(PREFIX)objcopy:
	$(MKDIR) -p $(BIN_UNIX)/toolchain-build
	$(MAKE) -C $(BIN_UNIX)/toolchain-build -f $(abspath $(GDK))/make/toolchain.mk
	$(MAKE) -C $(BIN_UNIX)/toolchain-build -f $(abspath $(GDK))/make/toolchain.mk install INSTALL_DIR=$(BIN_UNIX)/m68k

SJASMEP_DIR := $(GDK)/tools/sjasmep
$(BIN_UNIX)/sjasm:
	$(MKDIR) -p $(dir $@)
	cd $(SJASMEP_DIR) && $(MAKE)
	$(CP) $(SJASMEP_DIR)/sjasm $@

$(BIN_UNIX)/bintos: $(GDK)/tools/bintos/src/*.c
	$(MKDIR) -p $(dir $@)
	gcc -O2 -s $(GDK)/tools/bintos/src/bintos.c -o $@

$(BIN_UNIX)/xgmtool:
	$(MKDIR) -p $(dir $@)
	gcc -fexpensive-optimizations -Os -s $(GDK)/tools/xgmtool/src/*.c -o $@

$(RESCOMP_EXE): $(BIN_UNIX)/xgmtool
	echo "TODO: do compilation of $@ for real"
	$(CP) $(BIN_WIN)/rescomp.jar $@

$(SIZEBND_EXE):
	echo "TODO: do compilation of $@ for real"
	$(CP) $(BIN_WIN)/sizebnd.jar $@

$(BIN_UNIX)/mac68k:
	$(ECHO) implement build for $@
