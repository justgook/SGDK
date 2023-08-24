.DEFAULT_GOAL := release
ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
GDK := $(abspath $(ROOT_DIR)/..)
include $(GDK)/make/common.mk


SRC_LIB_C := $(wildcard $(SRC_LIB)/*.c)
SRC_LIB_C += $(wildcard $(SRC_LIB)/ext/*.c)
SRC_LIB_C += $(wildcard $(SRC_LIB)/ext/*/*.c)
SRC_LIB_S := $(wildcard $(SRC_LIB)/*.s)
SRC_LIB_S += $(wildcard $(SRC_LIB)/ext/*.s)
SRC_LIB_S += $(wildcard $(SRC_LIB)/ext/*/*.s)
SRC_LIB_S80 := $(wildcard $(SRC_LIB)/*.s80)
SRC_LIB_S80 += $(wildcard $(SRC_LIB)/ext/*.s80)
SRC_LIB_S80 += $(wildcard $(SRC_LIB)/ext/*/*.s80)

RES_LIB_RES := $(wildcard $(RES_LIB)/*.res)

OBJ_LIB = $(RES_LIB_RES:.res=.o)
OBJ_LIB += $(SRC_LIB_S80:.s80=.o)
OBJ_LIB += $(SRC_LIB_S:.s=.o)
OBJ_LIB += $(SRC_LIB_C:.c=.o)

DEP_LIB := $(OBJ_LIB:.o=.d)

-include $(DEP_LIB)

LST_LIB := $(SRC_LIB_C:.c=.lst)

INCS_LIB := -I$(INCLUDE_LIB) -I$(SRC_LIB) -I$(RES_LIB)
DEFAULT_FLAGS_LIB := $(EXTRA_FLAGS) -DSGDK_GCC -m68000 -Wall -Wextra -Wno-shift-negative-value -Wno-unused-parameter -fno-builtin -fms-extensions $(INCS_LIB) -B$(GCC_BIN)
FLAGSZ80_LIB := -i$(SRC_LIB) -i$(INCLUDE_LIB)

release: $(LIB)/libmd.a

debug: FLAGS_LIB= $(DEFAULT_FLAGS_LIB) -O1 -DDEBUG=1
debug: CFLAGS_LIB= $(FLAGS_LIB) -ggdb
debug: AFLAGS_LIB= $(FLAGS_LIB)
debug: $(LIB)/libmd_debug.a

asm: FLAGS_LIB= $(DEFAULT_FLAGS_LIB) -O3 -fuse-linker-plugin -fno-web -fno-gcse -fno-unit-at-a-time -fomit-frame-pointer -S
asm: CFLAGS_LIB= $(FLAGS_LIB)
asm: AFLAGS_LIB= $(FLAGS_LIB)
asm: $(LST_LIB)

all: release debug asm
default: release

Default: release
Debug: debug
Release: release
Asm: asm

.PHONY: clean

cleanlst:
	$(RM) -f $(LST_LIB)

cleandep:
	$(RM) -f $(DEP_LIB)

cleanobj:
	$(RM) -f $(OBJ_LIB)

cleanrelease: cleanobj cleandep cleanlst
	$(RM) -f $(LIB)/libmd.a out.lst

cleandebug: cleanobj cleandep cleanlst
	$(RM) -f $(LIB)/libmd_debug.a out.lst

cleanasm: cleanlst

clean: cleanobj cleandep cleanlst
	$(RM) -f $(LIB)/libmd.a $(LIB)/libmd_debug.a out.lst

cleanall: clean
cleanAll: clean
cleandefault: clean
cleanDefault: clean

cleanRelease: cleanrelease
cleanDebug: cleandebug
cleanAsm: cleanasm

$(LIB)/libmd.a: FLAGS_LIB=$(DEFAULT_FLAGS_LIB) -O3 -fuse-linker-plugin -fno-web -fno-gcse -fno-unit-at-a-time -fomit-frame-pointer -flto -ffat-lto-objects
$(LIB)/libmd.a: CFLAGS_LIB=$(FLAGS_LIB)
$(LIB)/libmd.a: AFLAGS_LIB=$(FLAGS_LIB)

$(LIB)/libmd_debug.a: FLAGS_LIB= $(DEFAULT_FLAGS_LIB) -O1 -DDEBUG=1
$(LIB)/libmd_debug.a: CFLAGS_LIB= $(FLAGS_LIB) -ggdb
$(LIB)/libmd_debug.a: AFLAGS_LIB= $(FLAGS_LIB)

$(LIB)/%.a: %.cmd $(AR)
	$(MKDIR) -p $(dir $@)
	$(AR) rs $@ $(LTO_PLUGIN) @$<

%.cmd : $(OBJ_LIB)
	$(ECHO) "$(OBJ_LIB)" > $@

%.lst: %.c $(CC)
	$(CC) $(CFLAGS_LIB) -c $< -o $@

%.o: %.c $(CC)
	$(CC) $(CFLAGS_LIB) -MMD -c $< -o $@

%.o: %.s $(CC)
	$(CC) -x assembler-with-cpp -Wa,--register-prefix-optional,--bitwise-or -MMD $(AFLAGS_LIB) -c $< -o $@

%.o: %.rs $(CC)
	$(CC) -x assembler-with-cpp -Wa,--register-prefix-optional,--bitwise-or $(AFLAGS_LIB) -c $*.rs -o $@

%.rs: %.res $(RESCOMP_EXE)
	$(RESCOMP) $*.res $*.rs -dep $*.o

%.o80: %.s80 $(ASMZ80)
	$(ASMZ80) $(FLAGSZ80_LIB) $< $@ out.lst

%.s: %.o80 $(BINTOS)
	$(BINTOS) $<

include $(GDK)/make/tools.mk
