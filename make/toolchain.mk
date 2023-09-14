ifeq ($(shell command -v makeinfo 2> /dev/null),)
  $(error "'makeinfo' not found. Make sure the 'texinfo' package is installed.")
endif
ifeq ($(shell command -v wget 2> /dev/null),)
  $(error "'wget' not found. Make sure the 'wget' package is installed.")
endif

ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
GDK := $(abspath $(ROOT_DIR)/..)
include $(GDK)/make/common.mk

# ifdef V
define log_to_file
	$(if $(V), , >> $(1) 2>&1)
endef

INSTALL_DIR  ?= /opt/toolchains/m68k-elf
DL_MIRROR    ?= http://ftpmirror.gnu.org

BINUTILS_VER ?= 2.40
GCC_VER      ?= 13.1.0
NEWLIB_VER   ?= 4.2.0.20211231

BINUTILS_DIR  = binutils-$(BINUTILS_VER)
GCC_DIR       = gcc-$(GCC_VER)
NEWLIB_DIR    = newlib-$(NEWLIB_VER)

GCC_PREREQ  = $(GCC_DIR)/isl
GCC_PREREQ += $(GCC_DIR)/gmp
GCC_PREREQ += $(GCC_DIR)/mpc
GCC_PREREQ += $(GCC_DIR)/mpfr

# Detect the number of processors for a parallel make
ifeq ($(shell uname),Darwin)
	NPROC := $(shell sysctl -n hw.logicalcpu)
else
	NPROC := $(shell nproc)
endif

TARGET := m68k-elf
PREFIX := $(shell pwd)/work
PATH   := $(PREFIX)/bin:$(PATH)
LOGDIR := $(shell pwd)
SHASUM := shasum -a 256 -c
LANGS  ?= c

COMFLAGS := --target=m68k-elf --with-cpu=m68000 --prefix=$(PREFIX) --libdir=$(PREFIX)/lib --libexecdir=$(PREFIX)/libexec

.PHONY: all without-newlib install clean

all: LANGS1P = c
all: mk-gcc2

without-newlib: LANGS1P = c
without-newlib: mk-gcc

install:
	$(Q)mkdir -p $(INSTALL_DIR)
	$(Q)cp -rf $(PREFIX)/* $(INSTALL_DIR)
	$(Q)echo "Toolchain installed to $(INSTALL_DIR)."
	$(Q)echo "Add $(INSTALL_DIR)/bin to your PATH before building projects."


mk-binutils: BUILD_DIR=$(BINUTILS_DIR)/build
mk-binutils: LOGFILE=$(LOGDIR)/binutils.log
mk-binutils: $(BINUTILS_DIR)
	$(Q)echo "+++ Building $(BINUTILS_DIR) ($(LOGFILE))..."
	$(Q)mkdir -p $(BUILD_DIR)
	$(Q)cd $(BUILD_DIR) && ../configure $(COMFLAGS) --enable-install-libbfd \
		--enable-shared=no --disable-werror > $(LOGDIR)/binutils.log 2>&1
	$(Q)$(MAKE) -C $(BUILD_DIR) all -j$(NPROC) $(call log_to_file, LOGFILE)
	$(Q)$(MAKE) -C $(BUILD_DIR) install-strip $(call log_to_file, LOGFILE)
	$(Q)rm -rf $(BUILD_DIR)
	$(Q)touch mk-binutils

mk-gcc: BUILD_DIR=$(GCC_DIR)/build
mk-gcc: LOGFILE=$(LOGDIR)/gcc.log
mk-gcc: $(GCC_DIR) $(GCC_PREREQ) mk-binutils
	$(Q)echo "+++ Building $(GCC_DIR) ($(LOGFILE))..."
	$(Q)mkdir -p $(BUILD_DIR)
	$(Q)cd $(BUILD_DIR) && ../configure $(COMFLAGS) \
		--enable-languages=$(LANGS1P) --without-headers --disable-libssp \
		--disable-threads --disable-tls --disable-multilib --enable-shared=no \
		--disable-werror $(call log_to_file, LOGFILE)
	$(Q)$(MAKE) -C $(BUILD_DIR) all -j$(NPROC) $(call log_to_file, LOGFILE)
	$(Q)$(MAKE) -C $(BUILD_DIR) install-strip $(call log_to_file, LOGFILE)
	$(Q)rm -rf $(BUILD_DIR)
	$(Q)touch mk-gcc

mk-newlib: BUILD_DIR=$(NEWLIB_DIR)/build
mk-newlib: LOGFILE=$(LOGDIR)/newlib.log
mk-newlib: $(NEWLIB_DIR) mk-gcc
	$(Q)echo "+++ Building $(NEWLIB_DIR) ($(LOGFILE))..."
	$(Q)mkdir -p $(BUILD_DIR)
	$(Q)cd $(BUILD_DIR) && ../configure $(COMFLAGS) \
		--disable-multilib --disable-werror $(call log_to_file, LOGFILE)
	$(Q)$(MAKE) -C $(BUILD_DIR) all -j$(NPROC) $(call log_to_file, LOGFILE)
	$(Q)$(MAKE) -C $(BUILD_DIR) install $(call log_to_file, LOGFILE)
	$(Q)rm -rf $(BUILD_DIR)
	$(Q)touch mk-newlib

mk-gcc2: BUILD_DIR=$(GCC_DIR)/build
mk-gcc2: LOGFILE=$(LOGDIR)/gcc2.log
mk-gcc2: $(GCC_DIR) mk-newlib
	$(Q)echo "+++ Building  $(GCC_DIR) -  pass 2 - ($(LOGFILE))..."
	$(Q)mkdir -p $(BUILD_DIR)
	$(Q)cd $(BUILD_DIR) && ../configure $(COMFLAGS) \
		--enable-languages=$(LANGS) --without-headers --with-newlib \
		--disable-hosted-libstdxx --disable-libssp --disable-threads \
		--disable-tls --disable-multilib --enable-shared=no --disable-werror \
		$(call log_to_file, LOGFILE)
	$(Q)$(MAKE) -C $(BUILD_DIR) all -j$(NPROC) $(call log_to_file, LOGFILE)
	$(Q)$(MAKE) -C $(BUILD_DIR) install-strip $(call log_to_file, LOGFILE)
	$(Q)rm -rf $(BUILD_DIR)
	$(Q)touch mk-gcc2

# Download packages from mirror and extract source packages with tar

$(BINUTILS_DIR):
	$(Q)echo "+++ Downloading $(BINUTILS_DIR)..."
	$(Q)$(WGET) $(DL_MIRROR)/gnu/binutils/$(BINUTILS_DIR).tar.xz -O - | tar -xJ

$(GCC_DIR):
	$(Q)echo "+++ Downloading $(GCC_DIR)..."
ifeq ($(shell $(WGET) --spider $(DL_MIRROR)/gnu/gcc/$(GCC_DIR)/$(GCC_DIR).tar.xz 2> /dev/null || echo fail),fail)
	$(Q)$(WGET) $(DL_MIRROR)/gnu/gcc/$(GCC_DIR)/$(GCC_DIR).tar.gz -O - | tar -xz
else
	$(Q)$(WGET) $(DL_MIRROR)/gnu/gcc/$(GCC_DIR)/$(GCC_DIR).tar.xz -O - | tar -xJ
endif

$(NEWLIB_DIR):
	$(Q)echo "+++ Downloading $(NEWLIB_DIR)..."
	$(Q)$(WGET) ftp://sourceware.org/pub/newlib/$(NEWLIB_DIR).tar.gz -O - | tar -xz

# Handling of GCC prerequisites
$(GCC_PREREQ): LOGFILE=$(LOGDIR)/gcc.log
$(GCC_PREREQ): $(GCC_DIR)
	$(Q)cd $(GCC_DIR) && ./contrib/download_prerequisites $(call log_to_file, LOGFILE)

clean:
	$(Q)rm -rf work
	$(Q)rm -rf $(BINUTILS_DIR)
	$(Q)rm -rf $(GCC_DIR)
	$(Q)rm -rf $(NEWLIB_DIR)
	$(Q)rm -f mk-binutils mk-gcc mk-newlib mk-gcc2

