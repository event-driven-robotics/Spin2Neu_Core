# defaults
ifndef clk_period
 clk_period=10
endif
ifndef test
 test=unknown
endif
ifndef enc_steps
 enc_steps=1970
endif
ifndef numrx
 numrx=32
endif
ifndef cntres
 cntres=16
endif
ifndef axi_addr_width
 axi_addr_width=10
endif
ifndef norandom
 norandom=0
endif

logname = $(test):clk_period:$(clk_period):enc_steps:$(enc_steps):numrx:$(numrx):cntres:$(cntres):norandom:$(norandom)

all:	sim
SHELL = /bin/sh

RED=\033[0;31m
GREEN=\033[0;32m
# No Color
NC=\033[0m

##########################################################################
#
# Misc Variables
#
##########################################################################

INCDIR= 
LIBLIST = -L fifo_generator_v13_2_1 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -L xpm 
TOPELAB = xil_defaultlib.tbench xil_defaultlib.glbl
##########################################################################
#
# Make Targets
#
##########################################################################
.PHONY: help
help:
	@echo "Syntax:"
	@echo "-------"
	@echo "make [make_target] [options]"
	@echo ""
	@echo "Arguments: [sim], compdut, comptbench, elaborate runsimulation elabsim "
	@echo "  sim: compile, elaborate and simulate the requested test"
	@echo "  compdut: compile only the dut"
	@echo "  comptbench: compile only the testbench"
	@echo "  elaborate: elaborate the testbench"
	@echo "  runsimulation: launch the simulation"
	@echo "  elabsim: elaborate tbench and launch simulation"
	@echo "  simw launch make sim with waveforms"
	@echo ""
	@echo "  clean, clean all"
	@echo ""
	@echo "Options:"
	@echo "  clkperiod=[10] ns"
	@echo "  test=[unknown] see ../../stimuli/ for test list"
	@echo "  enc_steps=1970 "
	@echo "  numrx=32 "
	@echo "  cntres=16 "
#	@echo "  axi_addr_width=10 "
	@echo "  noradnom=0 "
	@echo ""
    
checkresults:
	@../scripts/checktest/checktest $(test) ../log/$(logname)

simw:
	@$(MAKE) WAVES="-gui" \
	clk_period=$(clk_period) hormodules=$(hormodules) numlines=$(numlines) test=$(test)

viewwarning:
	@echo ""
	@echo "----------------------------------------------------------------"
	@echo -e "${RED}WARNING:${NC} The Randomization of DMA slave is driven by the        "
	@echo "         NORANDOM_DMA parameter of the testbench                "
	@echo "----------------------------------------------------------------"
	@echo ""
    
generate_ips:
	@echo -e "${GREEN}Generating ips simulation models...${NC}"
	@vivado -log ../log/generating_ips.log -m64 -mode batch -messageDb vivado.pb -notrace -source ../scripts/generate_ips

elabsim:
	@echo ""
	@$(MAKE) elaborate
	@echo ""
	@$(MAKE) runsimulation
	@echo ""

compdut:
	@echo -e "${GREEN}Compiling dut...${NC}"
	@$(MAKE) vlogcomp \
		PRJ=../../../rtl/vivado_ips/ips_vlog.prj
	@$(MAKE) vlogcomp				\
		PRJ=../../../rtl/cfg/dut_verilog.prj
	@$(MAKE) vhdcomp				\
		PRJ=../../../rtl/cfg/dut_vhdl.prj

comptbench:
	@echo -e "${GREEN}Compiling tbench...${NC}"
	@$(MAKE) vhdcomp				\
		PRJ=../../tbench/cfg/tbench.prj

elaborate:
	@echo -e "${GREEN}Elaborate the project...${NC}"
	@echo "clk_period=$(clk_period)"
	@echo "enc_steps=$(enc_steps)"
	@echo "numrx=$(numrx)"
	@echo "cntres=$(cntres)"
#	@echo "axi_addr_width=$(axi_addr_width)"
	@echo "norandom_dma=$(norandom)"
	@echo "test=$(test)"
	@ln -sf ../../stimuli/axi/$(test)/$(test).cmd ./AXI4LM_bfm.cmd 
#	@ln -sf ../../stimuli/axi/$(test)/dmasm.cmd ./dmasm.cmd 
	@cp  ../../stimuli/axi/$(test)/sim.tcl .
ifdef WAVES
	@sed -i.bak s/quit/#quit/g sim.tcl
	# 
endif   
	@if [ $(norandom) = 1 ]; then sed -i '1iadd_force {/tbench/bfm/norandom} -radix hex {1 0ns}' ./sim.tcl;  fi
	@rm -rf ./wave.wcfg
	@ln -s ../../stimuli/axi/$(test)/wave.wcfg .
	@echo "-----------------------------------------"
	@$(MAKE) elab TOPELAB="$(TOPELAB)"

runsimulation:
	@echo -e "${GREEN}Running Simulation...${NC}"
	@echo "Simulation $(logname) started at `date`" >> ../log/mismatch.log
	@$(MAKE) runsim TOP=$(_TOP_)
	@$(MAKE) checkresults 
	@echo "Simulation $(logname) terminated at `date`" >> ../log/mismatch.log

sim:
	@$(MAKE) viewwarning
	@echo ""
	@$(MAKE) generate_ips
	@echo ""
	@$(MAKE) compdut
	@echo ""
	@$(MAKE) comptbench
	@echo ""
	@$(MAKE) elaborate
	@echo ""
	@$(MAKE) runsimulation
	@echo ""


clean:
	@rm -rf	../lib/* ../wave/*.wdb ../log/*.* ./*.txt ./*.cmd ./*.log ./*.csv ./sim* ./elab* ./*.exe ./tmp? *.pb *.jou xsim*  *.wcfg *.rpt *.os vivado_* *.wdb .Xil
 
syn:
	@$(MAKE) synthesis

synthesis:
	@echo "----- Running Synthesis... ----------"
	@echo "Synthesis started at `date`" >> ../log/synth.log
	@$(MAKE) runsyn 
	@echo "Synthesis terminated at `date`" >> ../log/synth.log
##########################################################################
#
# vlogcomp/vhdcomp (compile)
#
##########################################################################

vlogcomp:
	xvlog -initfile ./xil.ini -i ../../../rtl/dut -prj $(PRJ)

vhdcomp:
	xvhdl -initfile ./xil.ini -prj $(PRJ)

##########################################################################
#
# elab (elaborate)
#
##########################################################################
elab:
	xelab   \
    -initfile ./xil.ini \
	-generic_top "CLK_PERIOD=$(clk_period)" \
	-generic_top "C_ENC_NUM_OF_STEPS=$(enc_steps)" \
	-debug all \
	-log ../log/elaborate.log \
	-m64 --debug typical --relax --mt 8 --snapshot tbench_behav  \
	$(TOPELAB) \
	$(LIBLIST) -L dut_lib
##########################################################################
#
# run the simulation
#
##########################################################################

ifdef WAVES
runsim:
	xsim \
	tbench_behav \
	${WAVES} \
	-key {Behavioral:sim_1:Functional:tbench} \
	-tclbatch sim.tcl \
	-log ../log/simulation.log \
	-view ./wave.wcfg
	mv ../log/simulation.log ../log/${logname}.log
else
runsim:
	xsim \
	tbench_behav \
	${WAVES} \
	-key {Behavioral:sim_1:Functional:tbench} \
	-tclbatch sim.tcl \
	-log ../log/simulation.log
	mv ../log/simulation.log ../log/${logname}.log
endif 


##########################################################################
#
# run the synthesis
#
##########################################################################

runsyn:
	vivado -log synthesis.vds -m64 -mode batch -source ../script/synth.tcl
	mv ./synthesis.vds ../log/

