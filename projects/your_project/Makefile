CURRENT_PROJECT := your_project

VIVADO := vivado -notrace -nolog -nojournal -mode batch -source 

VIVADO_SCRIPT := generate.tcl

.PHONY: project test impl all clean

project:
	@$(VIVADO) $(CURDIR)/$(VIVADO_SCRIPT) -tclargs make_project

$(CURRENT_PROJECT)/$(CURRENT_PROJECT).xpr:
	@$(VIVADO) $(CURDIR)/$(VIVADO_SCRIPT) -tclargs make_project

simu:
	@$(VIVADO) $(CURDIR)/$(VIVADO_SCRIPT) -tclargs make_simulations

impl: $(CURRENT_PROJECT)/$(CURRENT_PROJECT).xpr
	@$(VIVADO) $(CURDIR)/$(VIVADO_SCRIPT) -tclargs make_implementation

all: 
	@$(VIVADO) $(CURDIR)/$(VIVADO_SCRIPT) -tclargs all

clean:
	@echo "Cleaning Vivado logs and temporary files..."
	@rm -f *.log *.jou *.str *.debug *.pb *.wdb
	@rm -rf .Xil
	@rm -rf $(CURDIR)/$(CURRENT_PROJECT)
	@rm -rf $(CURDIR)/xsim.dir
	@echo "Clean complete."