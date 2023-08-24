ifeq ($(shell command -v makeinfo 2> /dev/null),)
  $(error "'makeinfo' not found. Make sure the 'texinfo' package is installed.")
endif
ifeq ($(shell command -v wget 2> /dev/null),)
  $(error "'wget' not found. Make sure the 'wget' package is installed.")
endif

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
	@mkdir -p $(INSTALL_DIR)
	@cp -rf $(PREFIX)/* $(INSTALL_DIR)
	@echo "Toolchain installed to $(INSTALL_DIR)."
	@echo "Add $(INSTALL_DIR)/bin to your PATH before building projects."


mk-binutils: BUILD_DIR=$(BINUTILS_DIR)/build
mk-binutils: $(BINUTILS_DIR)
	@echo "+++ Building $(BINUTILS_DIR)..."
	@mkdir -p $(BUILD_DIR)
	@cd $(BUILD_DIR) && ../configure $(COMFLAGS) --enable-install-libbfd \
		--enable-shared=no --disable-werror > $(LOGDIR)/binutils.log 2>&1
	@$(MAKE) -C $(BUILD_DIR) all -j$(NPROC) >> $(LOGDIR)/binutils.log 2>&1
	@$(MAKE) -C $(BUILD_DIR) install-strip >> $(LOGDIR)/binutils.log 2>&1
	@rm -rf $(BUILD_DIR)
	@touch mk-binutils

mk-gcc: BUILD_DIR=$(GCC_DIR)/build
mk-gcc: $(GCC_DIR) $(GCC_PREREQ) mk-binutils
	@echo "+++ Building $(GCC_DIR)..."
	@mkdir -p $(BUILD_DIR)
	@cd $(BUILD_DIR) && ../configure $(COMFLAGS) \
		--enable-languages=$(LANGS1P) --without-headers --disable-libssp \
		--disable-threads --disable-tls --disable-multilib --enable-shared=no \
		--disable-werror >> $(LOGDIR)/gcc.log 2>&1
	@$(MAKE) -C $(BUILD_DIR) all -j$(NPROC) >> $(LOGDIR)/gcc.log 2>&1
	@$(MAKE) -C $(BUILD_DIR) install-strip >> $(LOGDIR)/gcc.log 2>&1
	@rm -rf $(BUILD_DIR)
	@touch mk-gcc

mk-newlib: BUILD_DIR=$(NEWLIB_DIR)/build
mk-newlib: $(NEWLIB_DIR) mk-gcc
	@echo "+++ Building $(NEWLIB_DIR)..."
	@mkdir -p $(BUILD_DIR)
	@cd $(BUILD_DIR) && ../configure $(COMFLAGS) \
		--disable-multilib --disable-werror > $(LOGDIR)/newlib.log 2>&1
	$(MAKE) -C $(BUILD_DIR) all -j$(NPROC) >> $(LOGDIR)/newlib.log 2>&1
	$(MAKE) -C $(BUILD_DIR) install  >> $(LOGDIR)/newlib.log 2>&1
	@rm -rf $(BUILD_DIR)
	@touch mk-newlib

mk-gcc2: BUILD_DIR=$(GCC_DIR)/build
mk-gcc2: $(GCC_DIR) mk-newlib
	@echo "+++ Building $(GCC_DIR) (Pass 2)..."
	@mkdir -p $(BUILD_DIR)
	@cd $(BUILD_DIR) && ../configure $(COMFLAGS) \
		--enable-languages=$(LANGS) --without-headers --with-newlib \
		--disable-hosted-libstdxx --disable-libssp --disable-threads \
		--disable-tls --disable-multilib --enable-shared=no --disable-werror \
		> $(LOGDIR)/gcc2.log 2>&1
	@$(MAKE) -C $(BUILD_DIR) all -j$(NPROC) >> $(LOGDIR)/gcc2.log 2>&1
	@$(MAKE) -C $(BUILD_DIR) install-strip >> $(LOGDIR)/gcc2.log 2>&1
	@rm -rf $(BUILD_DIR)
	@touch mk-gcc2

# Download packages from mirror and extract source packages with tar

$(BINUTILS_DIR):
	@wget $(DL_MIRROR)/gnu/binutils/$(BINUTILS_DIR).tar.xz -O - | tar -xJ


$(GCC_DIR):
ifeq ($(shell wget --spider $(DL_MIRROR)/gnu/gcc/$(GCC_DIR)/$(GCC_DIR).tar.xz 2> /dev/null || echo fail),fail)
	@wget $(DL_MIRROR)/gnu/gcc/$(GCC_DIR)/$(GCC_DIR).tar.gz -O - | tar -xz
else
	@wget $(DL_MIRROR)/gnu/gcc/$(GCC_DIR)/$(GCC_DIR).tar.xz -O - | tar -xJ
endif

$(NEWLIB_DIR):
	@wget ftp://sourceware.org/pub/newlib/$(NEWLIB_DIR).tar.gz -O - | tar -xz

# Handling of GCC prerequisites
$(GCC_PREREQ): $(GCC_DIR)
	@cd $(GCC_DIR) && ./contrib/download_prerequisites > $(LOGDIR)/gcc.log 2>&1

clean:
	@rm -rf work
	@rm -rf $(BINUTILS_DIR)
	@rm -rf $(GCC_DIR)
	@rm -rf $(NEWLIB_DIR)
	@rm -f mk-binutils mk-gcc mk-newlib mk-gcc2
