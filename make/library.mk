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

.PHONY: clean cleanobj cleandep cleanlst cleandebug cleanrelease

cleanlst:
	$(Q)$(ECHO) "+++ Remove lists..."
	$(Q)$(RM) -f $(LST_LIB)

cleandep:
	$(Q)$(ECHO) "+++ Remove dep..."
	$(Q)$(RM) -f $(DEP_LIB)

cleanobj:
	$(Q)$(ECHO) "+++ Remove obj..."
	$(Q)$(RM) -f $(OBJ_LIB)

cleanrelease: cleanobj cleandep cleanlst
	$(Q)$(ECHO) "+++ Remove release..."
	$(Q)$(RM) -f $(LIB)/libmd.a out.lst

cleandebug: cleanobj cleandep cleanlst
	$(Q)$(ECHO) "+++ Remove debug..."
	$(Q)$(RM) -f $(LIB)/libmd_debug.a out.lst

cleanasm: cleanlst

clean: cleanobj cleandep cleanlst cleandebug cleanrelease
	$(Q)$(ECHO) "+++ Cleaning done"

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
	$(Q)$(ECHO) "+++ Buildindi SGDK $@"
	$(Q)$(MKDIR) -p $(dir $@)
	$(Q)$(AR) rs $@ $(LTO_PLUGIN) @$< $(call QUIET, >> build.log 2>&1)

%.cmd : $(OBJ_LIB)
	$(Q)$(ECHO) "$(OBJ_LIB)" > $@

%.lst: %.c $(CC)
	$(Q)$(CC) $(CFLAGS_LIB) -c $< -o $@

%.o: %.c $(CC)
	$(Q)$(CC) $(CFLAGS_LIB) -MMD -c $< -o $@

%.o: %.s $(CC)
	$(Q)$(CC) -x assembler-with-cpp -Wa,--register-prefix-optional,--bitwise-or -MMD $(AFLAGS_LIB) -c $< -o $@

%.o: %.rs $(CC)
	$(Q)$(CC) -x assembler-with-cpp -Wa,--register-prefix-optional,--bitwise-or $(AFLAGS_LIB) -c $*.rs -o $@

%.rs: %.res $(RESCOMP_JAR)
	$(Q)$(ECHO) "+++ Building SGDK resources ..."
	$(Q)$(RESCOMP) $*.res $*.rs -dep $*.o $(call QUIET, >> build.log 2>&1)

%.o80: %.s80 $(ASMZ80)
	$(Q)$(ECHO) "+++ Compiling SGDK $< ..."
	$(Q)$(ASMZ80) $(FLAGSZ80_LIB) $< $@ out.lst $(call QUIET, >> build.log 2>&1)

%.s: %.o80 $(BINTOS)
	$(Q)$(ECHO) "+++ Compiling SGDK $< ..."
	$(Q)$(BINTOS) $< $(call QUIET, >> build.log 2>&1)

include $(GDK)/make/tools.mk

