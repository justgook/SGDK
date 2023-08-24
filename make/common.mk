# Common definitions

BIN_WIN:= $(GDK)/bin
BIN_UNIX:= $(GDK)/bin-unix

LIB := $(GDK)/lib
SRC_LIB := $(GDK)/src
RES_LIB := $(GDK)/res
INCLUDE_LIB := $(GDK)/inc
MAKEFILE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
MAKEFILE_DIR := $(subst \,/,$(MAKEFILE_DIR))

JAVA := java
ECHO := echo


ifeq ($(OS),Windows_NT)
	# Native Windows
	RESCOMP_EXE := $(BIN_WIN)/rescomp.jar
	SIZEBND_EXE := $(BIN_WIN)/sizebnd.jar
	SIZEBND := $(JAVA) -jar $(BIN_WIN)/sizebnd.jar
	RESCOMP := $(JAVA) -jar $(BIN_WIN)/rescomp.jar
	GCC_BIN := $(BIN_WIN)
	SHELL := $(BIN_WIN)/sh.exe
	RM := $(BIN_WIN)/rm.exe
	CP := $(BIN_WIN)/cp.exe
	MKDIR := $(BIN_WIN)/mkdir.exe

	AR := $(BIN_WIN)/ar.exe
	CC := $(BIN_WIN)/gcc.exe
	LD:= $(BIN_WIN)/ld.exe
	NM:= $(BIN_WIN)/nm.exe
	OBJCPY := $(BIN_WIN)/objcopy.exe
	ASMZ80 := $(BIN_WIN)/sjasm.exe
	MACCER := $(BIN_WIN)/mac68k.exe
	BINTOS := $(BIN_WIN)/bintos.exe
	LTO_PLUGIN := --plugin=liblto_plugin-0.dll
	LIBGCC := $(LIB)/libgcc.a
else
	# Native Linux and Docker
	RESCOMP_EXE := $(BIN_UNIX)/rescomp.jar
	SIZEBND_EXE := $(BIN_UNIX)/sizebnd.jar
	SIZEBND := $(JAVA) -jar $(BIN_UNIX)/sizebnd.jar
	RESCOMP := $(JAVA) -jar $(BIN_UNIX)/rescomp.jar
	#GCC_BIN := $(BIN_UNIX)/m68k
# GCC_BIN :=  ""
	SHELL = sh
	RM = rm
	CP = cp
	MKDIR = mkdir

	PREFIX := m68k-elf-
	AR := $(shell command -v $(PREFIX)ar 2> /dev/null)
	ifndef AR
		AR = $(BIN_UNIX)/m68k/bin/$(PREFIX)ar
	endif
	CC := $(shell command -v $(PREFIX)gcc 2> /dev/null)
	ifndef CC
		CC = $(BIN_UNIX)/m68k/bin/$(PREFIX)gcc
	endif
	LD := $(shell command -v $(PREFIX)ld 2> /dev/null)
	ifndef LD
		LD = $(BIN_UNIX)/m68k/bin/$(PREFIX)ld
	endif
	NM := $(shell command -v $(prefix)nm 2> /dev/null)
	ifndef NM
		NM = $(BIN_UNIX)/m68k/bin/$(PREFIX)nm
	endif
	OBJCPY := $(shell command -v $(prefix)objcopy 2> /dev/null)
	ifndef OBJCPY
		OBJCPY = $(BIN_UNIX)/m68k/bin/$(PREFIX)objcopy
	endif
	ASMZ80 := $(BIN_UNIX)/sjasm
	MACCER := $(BIN_UNIX)/mac68k
	BINTOS := $(BIN_UNIX)/bintos
	LTO_PLUGIN :=
	LIBGCC := -lgcc
endif
