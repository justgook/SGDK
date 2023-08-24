ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
GDK := $(abspath $(ROOT_DIR))

.DEFAULT_GOAL := release

ifeq ("$(CURDIR)","$(GDK)")
%: force
	@$(MAKE) -C $(GDK) -f $(GDK)/make/library.mk $@
else
%: force
	@$(MAKE) -f $(GDK)/make/game.mk $@
endif

force: ;
