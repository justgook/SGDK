ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
GDK := $(abspath $(ROOT_DIR)/..)

include $(GDK)/make/common.mk

SRC := src
RES := res
INCLUDE := inc
OUT := out

SRC_C= $(wildcard *.c)
SRC_C+= $(wildcard $(SRC)/*.c)
SRC_C+= $(wildcard $(SRC)/*/*.c)
SRC_C+= $(wildcard $(SRC)/*/*/*.c)
SRC_C:= $(filter-out $(SRC)/boot/rom_head.c,$(SRC_C))
ifeq ($(SRC_C),)
SRC_C=$(SRC)/main.c
endif
SRC_S= $(wildcard *.s)
SRC_S+= $(wildcard $(SRC)/*.s)
SRC_S+= $(wildcard $(SRC)/*/*.s)
SRC_S+= $(wildcard $(SRC)/*/*/*.s)
SRC_ASM= $(wildcard *.asm)
SRC_ASM+= $(wildcard $(SRC)/*.asm)
SRC_ASM+= $(wildcard $(SRC)/*/*.asm)
SRC_ASM+= $(wildcard $(SRC)/*/*/*.asm)
SRC_S80= $(wildcard *.s80)
SRC_S80+= $(wildcard $(SRC)/*.s80)
SRC_S80+= $(wildcard $(SRC)/*/*.s80)
SRC_S80+= $(wildcard $(SRC)/*/*/*.s80)

RES_C= $(wildcard $(RES)/*.c)
RES_S= $(wildcard $(RES)/*.s)
RES_RES= $(wildcard *.res)
RES_RES+= $(wildcard $(RES)/*.res)

RES_RS= $(RES_RES:.res=.rs)
RES_H= $(RES_RES:.res=.h)
RES_DEP= $(RES_RES:.res=.d)
RES_DEPS= $(addprefix $(OUT)/, $(RES_DEP))

OBJ= $(RES_RES:.res=.o)
OBJ+= $(RES_S:.s=.o)
OBJ+= $(RES_C:.c=.o)
OBJ+= $(SRC_S80:.s80=.o)
OBJ+= $(SRC_ASM:.asm=.o)
OBJ+= $(SRC_S:.s=.o)
OBJ+= $(SRC_C:.c=.o)
OBJS:= $(addprefix $(OUT)/, $(OBJ))

DEPS:= $(OBJS:.o=.d)

#-include $(DEPS)

LST:= $(SRC_C:.c=.lst)
LSTS:= $(addprefix $(OUT)/, $(LST))

INCS:= -I$(INCLUDE) -I$(SRC) -I$(RES) -I$(INCLUDE_LIB) -I$(RES_LIB)
DEFAULT_FLAGS= $(EXTRA_FLAGS) -DSGDK_GCC -m68000 -Wall -Wextra -Wno-shift-negative-value -Wno-main -Wno-unused-parameter -fno-builtin -fms-extensions $(INCS) -B$(GCC_BIN)
FLAGSZ80:= -i$(SRC) -i$(INCLUDE) -i$(RES) -i$(SRC_LIB) -i$(INCLUDE_LIB)

release: FLAGS= $(DEFAULT_FLAGS) -O3 -fuse-linker-plugin -fno-web -fno-gcse -fno-unit-at-a-time -fomit-frame-pointer -flto -ffat-lto-objects
release: CFLAGS= $(FLAGS)
release: AFLAGS= $(FLAGS)
release: LIBMD= $(LIB)/libmd.a
release: $(LIB)/libmd.a $(OUT)/rom.bin $(OUT)/symbol.txt

.PHONY: release

debug: FLAGS= $(DEFAULT_FLAGS) -O1 -DDEBUG=1
debug: CFLAGS= $(FLAGS) -ggdb
debug: AFLAGS= $(FLAGS)
debug: LIBMD= $(LIB)/libmd_debug.a
debug: $(OUT)/rom.bin $(OUT)/rom.out $(OUT)/symbol.txt
.PHONY: debug

asm: FLAGS= $(DEFAULT_FLAGS) -O3 -fuse-linker-plugin -fno-web -fno-gcse -fno-unit-at-a-time -fomit-frame-pointer -S
asm: CFLAGS= $(FLAGS)
asm: AFLAGS= $(FLAGS)
asm: LIBMD= $(LIB)/libmd.a
asm: $(LSTS)
.PHONY: asm

define MAIN_C_CONTENT
#include "genesis.h"

int main(bool hardReset){
    VDP_drawText("Hello SGDK!", 12, 12);
    while(TRUE) { SYS_doVBlankProcess(); }
    return 0;
}
endef

$(SRC)/main.c: export MAIN_C_CONTENT:=$(MAIN_C_CONTENT)
$(SRC)/main.c:
	$(MKDIR) -p $(dir $@)
	$(ECHO) "$${MAIN_C_CONTENT}" > $@

# include ext.mk if it exists (better to do it after release rule definition)
ifneq ("$(wildcard $(GDK)/ext.mk)","")
    include $(GDK)/ext.mk
endif

all: release
default: release

Default: release
Debug: debug
Release: release
Asm: asm

cleantmp:
	$(RM) -f $(RES_RS)
.PHONY: cleantmp

cleandep:
	$(RM) -f $(DEPS)
.PHONY: cleandep

cleanlst:
	$(RM) -f $(LSTS)
.PHONY: cleanlst

cleanres: cleantmp
	$(RM) -f $(RES_H) $(RES_DEP) $(RES_DEPS)
.PHONY: cleanres

cleanobj:
	$(RM) -f $(OBJS) $(OUT)/sega.o $(OUT)/rom_head.bin $(OUT)/rom_head.o $(OUT)/rom.out
.PHONY: cleanobj

clean: cleanobj cleanres cleanlst cleandep
	$(RM) -f out.lst $(OUT)/cmd_ $(OUT)/symbol.txt $(OUT)/rom.nm $(OUT)/rom.wch $(OUT)/rom.bin
.PHONY: clean

cleanrelease: clean
.PHONY: cleanrelease

cleandebug: clean
.PHONY: cleandebug

cleanasm: cleanlst
.PHONY: cleanasm

cleandefault: clean
cleanDefault: clean
.PHONY: cleandefault cleanDefault

cleanRelease: cleanrelease
cleanDebug: cleandebug
cleanAsm: cleanasm
.PHONY: cleanRelease cleanDebug cleanAsm


$(OUT)/rom.bin: $(OUT)/rom.out $(OBJCPY) $(SIZEBND_EXE)
	$(OBJCPY) -O binary $(OUT)/rom.out $(OUT)/rom.bin
	$(SIZEBND) $(OUT)/rom.bin -sizealign 131072 -checksum

$(OUT)/symbol.txt: $(OUT)/rom.out $(NM)
	$(NM) $(LTO_PLUGIN) -n $< > $@

$(OUT)/rom.out: $(OUT)/sega.o $(OUT)/cmd_ $(LIBMD) $(CC)
	$(MKDIR) -p $(dir $@)
	$(CC) -B$(GCC_BIN) -n -T $(GDK)/md.ld -nostdlib $(OUT)/sega.o @$(OUT)/cmd_ $(LIBMD) $(LIBGCC) -o $(OUT)/rom.out -Wl,--gc-sections
	$(RM) $(OUT)/cmd_

$(OUT)/cmd_: $(OBJS)
	$(MKDIR) -p $(dir $@)
	$(ECHO) "$(OBJS)" > $(OUT)/cmd_

$(OUT)/sega.o: $(OUT)/boot/sega.s $(OUT)/rom_head.bin
	$(CC) -x assembler-with-cpp -Wa,--register-prefix-optional,--bitwise-or $(AFLAGS) -c $(OUT)/boot/sega.s -o $@

$(OUT)/rom_head.bin: $(OUT)/rom_head.o
	$(OBJCPY) -O binary $< $@

$(OUT)/rom_head.o: $(SRC)/boot/rom_head.c
	$(MKDIR) -p $(dir $@)
	$(CC) $(DEFAULT_FLAGS) -c $< -o $@

$(OUT)/boot/sega.s: $(SRC_LIB)/boot/sega.s
	$(ECHO) $@
	$(MKDIR) -p $(dir $@)
	$(CP) $< $@

$(SRC)/boot/rom_head.c: $(SRC_LIB)/boot/rom_head.c
	$(MKDIR) -p $(dir $@)
	$(CP) $< $@

$(OUT)/%.lst: %.c
	$(MKDIR) -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(OUT)/%.o: %.c
	$(MKDIR) -p $(dir $@)
	$(CC) $(CFLAGS) -MMD -c $< -o $@

$(OUT)/%.o: %.s
	$(MKDIR) -p $(dir $@)
	$(CC) -x assembler-with-cpp -Wa,--register-prefix-optional,--bitwise-or $(AFLAGS) -MMD -c $< -o $@

$(OUT)/%.o: %.rs $(CC)
	$(MKDIR) -p $(dir $@)
	$(CC) -x assembler-with-cpp -Wa,--register-prefix-optional,--bitwise-or $(AFLAGS) -c $*.rs -o $@
	$(CP) $*.d $(OUT)/$*.d
	$(RM) $*.d

%.rs: %.res $(RESCOMP_EXE)
	$(RESCOMP) $*.res $*.rs -dep $(OUT)/$*.o

%.s: %.asm
	$(MACCER) -o $@ $<

%.o80: %.s80
	$(ASMZ80) $(FLAGSZ80) $< $@ out.lst

%.s: %.o80
	$(BINTOS) $<

$(LIB)/libmd.a:
	make -C $(GDK) -f $(GDK)/make/makelib.mk $@
$(LIB)/libmd_debug.a:
	make -C $(GDK) -f $(GDK)/make/makelib.mk $@

include $(GDK)/make/tools.mk
