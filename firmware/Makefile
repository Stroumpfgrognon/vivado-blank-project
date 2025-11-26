# make file to make the main project 
# written by Prerna Baranwal
# modified from the open source libraries located at  https://github.com/analogdevicesinc/hdl/

PROJECT_NAME := firmware
PROJECT_PATH := $(dir $(lastword $(MAKEFILE_LIST)))
SCRIPTS_PATH := $(PROJECT_PATH)scripts/
LIBRARY_PATH := $(PROJECT_PATH)libraries/

include $(SCRIPTS_PATH)quiet.mk

# configuration files can be added here later on, for the moment its not needed

VIVADO := vivado -mode batch -source

# CMD variables to make unique directories for different configurations

CMD_VARIABLES := $(shell echo $(-*-command-variables-*-) | tac -s ' ')
ifneq ($(strip $(CMD_VARIABLES)), )
    PARAMS := $(shell echo $(CMD_VARIABLES) | sed -e 's/[=]/_/g')
    GEN_NAME := $(shell echo $(PARAMS) | sed -e $(GEN_SED) | sed -e 's/[ .]/_/g')
    DIR_NAME := $(if $(strip $(DIR_NAME)),$(DIR_NAME)_$(GEN_NAME),$(GEN_NAME))
endif


ifneq ($(strip $(DIR_NAME)), )
    PROJECT_NAME := $(DIR_NAME)/$(PROJECT_NAME)
    $(shell test -d $(DIR_NAME) || mkdir $(DIR_NAME))
    ADI_PROJECT_DIR := $(DIR_NAME)/
    export ADI_PROJECT_DIR
	VIVADO := vivado -log $(DIR_NAME)/vivado.log -journal $(DIR_NAME)/vivado.jou -mode batch -source 
endif

CLEAN_TARGET := *.cache
CLEAN_TARGET += *.data
CLEAN_TARGET += *.xpr
CLEAN_TARGET += xgui
CLEAN_TARGET +=  gui
CLEAN_TARGET += *.runs
CLEAN_TARGET += *.srcs
CLEAN_TARGET += *.sdk
CLEAN_TARGET += *.hw
CLEAN_TARGET += *.sim
CLEAN_TARGET += *.ip_user_files
CLEAN_TARGET += *.str
CLEAN_TARGET += mem_init_sys.txt
CLEAN_TARGET += *.csv
CLEAN_TARGET += *.hbs
CLEAN_TARGET += *.gen
CLEAN_TARGET += *.xpe
CLEAN_TARGET += *.xsa
CLEAN_TARGET += *.log
CLEAN_TARGET += *.jou

ifneq ($(strip $(DIR_NAME)), )
    CLEAN_TARGET := $(addprefix $(DIR_NAME)/,$(CLEAN_TARGET))
endif

CLEAN_TARGET += .Xil
CLEAN_TARGET += $(SCRIPTS_PATH)*.Xil
CLEAN_TARGET += $(SCRIPTS_PATH)*.log
CLEAN_TARGET += $(SCRIPTS_PATH)*.jou
CLEAN_TARGET += ../*.log
CLEAN_TARGET += ../*.jou


CLEAN_DIRS := $(dir $(wildcard */*_vivado.log))

RUN_TARGET := $(dir $(wildcard */*.bit))

PREREQS_TARGET := /data/Vivado/Vivado/2024.1/settings64.sh   ##/data/Vivado/Vivado/2024.1/settings64.sh				####I have a different path    /data/Xilinx2024.1/Vivado/2024.1/settings64.sh


# insert the main dependancies here
M_DEPS += emulator_const.xdc
M_DEPS += emulator.vhd
M_DEPS += emulator_project.tcl
M_DEPS += emulator_run.tcl

M_DEPS += $(LIBRARY_PATH)emulator_env.tcl
M_DEPS += $(LIBRARY_PATH)run_impl_tests.tcl
M_DEPS += $(LIBRARY_PATH)run_implementation.tcl

.PHONY: .PHONY: mytarget

mytarget:
	@echo "Hello from $(CURDIR)"
#prereqs does not work at the moment will need to be modified later on 
prereqs:
	$(call prereqs, $(PREREQS_TARGET), $(HL)$(PROJECT_NAME)$(NC) project)
	@$(call PREREQS_TARGET) && echo "Vivado environment loaded."
all:
	echo "testing in wrong file"
#	$(PROJECT_NAME)/emulator.xsa
clean:
	-rm -f reference.dcp
	$(call clean,$(CLEAN_TARGET), $(HL)$(PROJECT_NAME)$(NC) project)
	-rm -Rf ${DIR_NAME}
run: 
	echo "running in falscher file"

MODE ?= "default"

$(PROJECT_NAME).sdk/emulator.xsa: $(M_DEPS)
	@if [ $(MODE) = incr ]; then \
		if [ -f */impl_1/emulator_routed.dcp ]; then \
			echo Found previous run result at `ls */impl_1/emulator_routed.dcp`; \
			cp -u */impl_1/emulator_routed.dcp ./reference.dcp ; \
		fi; \
		if [ -f ./reference.dcp ]; then \
			echo Using reference checkpoint for incremental compilation; \
		fi; \
	else \
		rm -f reference.dcp; \
	fi;
	-rm -rf $(CLEAN_TARGET)
	$(call build, \
		$(VIVADO) emulator_project.tcl, \
		$(PROJECT_NAME)_vivado.log, \
		$(HL)$(PROJECT_NAME)$(NC) project)

TARGET ?= "xilinx"

$()%/component.xml: FORCE
	flock $(dir $@).lock sh -c " \
	if [ -n \"${REQUIRED_VIVADO_VERSION}\" ]; then \
		$(MAKE) -C $(dir $@) REQUIRED_VIVADO_VERSION=${REQUIRED_VIVADO_VERSION} || \
		$(MAKE) -C $(dir $@) all REQUIRED_VIVADO_VERSION=${REQUIRED_VIVADO_VERSION}; \
	else \
		$(MAKE) -C $(dir $@) $(TARGET) || \
		$(MAKE) -C $(dir $@) all; \
	fi"; exit $$?