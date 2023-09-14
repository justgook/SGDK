ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
GDK := $(abspath $(ROOT_DIR))
include $(GDK)/make/common.mk

.DEFAULT_GOAL := release

define LOGO

  ███████╗ ██████╗ ██████╗ ██╗  ██╗
  ██╔════╝██╔════╝ ██╔══██╗██║ ██╔╝
  ███████╗██║  ███╗██║  ██║█████╔╝
  ╚════██║██║   ██║██║  ██║██╔═██╗
  ███████║╚██████╔╝██████╔╝██║  ██╗
  ╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝
endef

ifeq ("$(CURDIR)","$(GDK)")
%: export LOGO:=$(LOGO)
%:
	$(Q)$(ECHO) "$${LOGO}"
	$(Q)$(MAKE) -C $(GDK) -f $(GDK)/make/library.mk $@
else
%: export LOGO:=$(LOGO)
%:
	$(Q)$(ECHO) "$${LOGO}"
	$(Q)$(MAKE) -f $(GDK)/make/game.mk $@
endif

