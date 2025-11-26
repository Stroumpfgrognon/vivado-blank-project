# code to make the emulator firmware
# written by Prerna Baranwal

###added target help

#include $(dir $(lastword $(MAKEFILE_LIST)))firmware/scripts/quiet.mk

#SUBDIRS := $(shell find . -type f -name Makefile -exec dirname {} \;)
#SUBDIRS := $(filter-out .,$(SUBDIRS))
#SUBDIRS := $(sort $(patsubst ./%,%,$(SUBDIRS)))

# Create virtual targets for each
#SUBDIRS_PREREQS   := $(addsuffix prereqs,$(SUBDIRS))
#SUBDIRS_ALL       := $(addsuffix all,$(SUBDIRS))
#SUBDIRS_CLEAN     := $(addsuffix clean,$(SUBDIRS))
#SUBDIRS_RUN       := $(addsuffix run,$(SUBDIRS))	
#SUBDIRS_EMU       := $(addsuffix emulator,$(SUBDIRS))	

#.PHONY: prereqs all clean run emulator\
        $(SUBDIRS_PREREQS) $(SUBDIRS_ALL) $(SUBDIRS_CLEAN) $(SUBDIRS_RUN) $(SUBDIRS_EMU) 

# Aggregate rules
#prereqs: $(SUBDIRS_PREREQS)
#all: $(SUBDIRS_ALL)
#clean: $(SUBDIRS_CLEAN)
#run: $(SUBDIRS_RUN)
#help:
#	@$(MAKE) -C $(@D) help


# Forwarding rules
#$(SUBDIRS_PREREQS) $(SUBDIRS_ALL) $(SUBDIRS_CLEAN) $(SUBDIRS_RUN) $(SUBDIRS_EMU) :	
#	$(MAKE) -C $(@D) $(subst -,,$(@F))

#emulator:
#	@# existiert dieses Target im Unterordner?
#	@if [ -f $(@D)/Makefile ]; then \
		$(MAKE) -C $(@D) $(@F); \
	else \
		echo "Unknown target '$@'"; exit 1; \
	fi

# Finde alle Makefiles rekursiv
# Finde alle Makefiles rekursiv
DIRS := $(shell find . -type f -name Makefile -exec dirname {} \; | sort -u)

mytarget:
	@for d in $(DIRS); do \
		if grep -q "^mytarget:" $$d/Makefile; then \
			echo "→ running mytarget in $$d"; \
			$(MAKE) -C $$d mytarget; \
		fi; \
	done