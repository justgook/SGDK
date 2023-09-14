BIN_DIR:= $(GDK)/bin

LIB := $(GDK)/lib
SRC_LIB := $(GDK)/src
RES_LIB := $(GDK)/res
INCLUDE_LIB := $(GDK)/inc

JAVA := java
ECHO := echo

ifdef V
Q=
WGET:=wget
else
Q=@
MAKEFLAGS += --no-print-directory
WGET:=wget -q --show-progress
endif

define QUIET
	$(if $(V), , $(1))
endef

ifeq '$(findstring ;,$(PATH))' ';'
    detected_OS := Windows
else
    detected_OS := $(shell uname 2>/dev/null || echo Unknown)
    detected_OS := $(patsubst CYGWIN%,Cygwin,$(detected_OS))
    detected_OS := $(patsubst MSYS%,MSYS,$(detected_OS))
    detected_OS := $(patsubst MINGW%,MSYS,$(detected_OS))
endif

ifeq ($(detected_OS),Windows)
	BIN_DIR:= $(GDK)/bin
	GCC_BIN := $(BIN_DIR)

	SHELL := $(BIN_DIR)/sh.exe
	RM := $(BIN_DIR)/rm.exe
	CP := $(BIN_DIR)/cp.exe
	MKDIR := $(BIN_DIR)/mkdir.exe

	AR := $(BIN_DIR)/ar.exe
	CC := $(BIN_DIR)/gcc.exe
	LD:= $(BIN_DIR)/ld.exe
	NM:= $(BIN_DIR)/nm.exe
	OBJCPY := $(BIN_DIR)/objcopy.exe

	ASMZ80 := $(BIN_DIR)/sjasm.exe
	MACCER := $(BIN_DIR)/mac68k.exe
	BINTOS := $(BIN_DIR)/bintos.exe

	LTO_PLUGIN := --plugin=liblto_plugin-0.dll
	LIBGCC := $(LIB)/libgcc.a
else
	ifeq ($(detected_OS),Darwin)
		BIN_DIR := $(GDK)/bin-apple
	else
		BIN_DIR := $(GDK)/bin-linux
	endif

	GCC_BIN :=
	SHELL = sh
	RM = rm
	CP = cp
	MKDIR = mkdir

	PREFIX := m68k-elf-
	AR := $(shell command -v $(PREFIX)ar 2> /dev/null)
	ifndef AR
		AR = $(BIN_DIR)/m68k/bin/$(PREFIX)ar
	endif
	CC := $(shell command -v $(PREFIX)gcc 2> /dev/null)
	ifndef CC
		CC = $(BIN_DIR)/m68k/bin/$(PREFIX)gcc
	endif
	LD := $(shell command -v $(PREFIX)ld 2> /dev/null)
	ifndef LD
		LD = $(BIN_DIR)/m68k/bin/$(PREFIX)ld
	endif
	NM := $(shell command -v $(prefix)nm 2> /dev/null)
	ifndef NM
		NM = $(BIN_DIR)/m68k/bin/$(PREFIX)nm
	endif
	OBJCPY := $(shell command -v $(prefix)objcopy 2> /dev/null)
	ifndef OBJCPY
		OBJCPY = $(BIN_DIR)/m68k/bin/$(PREFIX)objcopy
	endif

	ASMZ80 := $(BIN_DIR)/sjasm
	MACCER := $(BIN_DIR)/mac68k
	BINTOS := $(BIN_DIR)/bintos

	LTO_PLUGIN :=
	LIBGCC := -lgcc
endif

RESCOMP_JAR := $(BIN_DIR)/rescomp.jar
SIZEBND_JAR := $(BIN_DIR)/sizebnd.jar
SIZEBND := $(JAVA) -jar $(SIZEBND_JAR)
RESCOMP := $(JAVA) -jar $(RESCOMP_JAR)

