#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3

#**************************************************************
# Create Clock
#**************************************************************

#create_clock -name {clk_50} -period 20.000 -waveform { 0.000 0.500 } [get_ports {clk}]
#create_clock -name {clk_100} -period 10.000 -waveform { 0.000 0.500 } [get_ports {u3|altpll_component|auto_generated|pll1|clk[0]}]

#**************************************************************
# Create Generated Clock
#**************************************************************
derive_pll_clocks -create_base_clocks
#derive_pll_clocks
#create_generated_clock -name clk_sdram -source [get_pins {u3|altpll_component|auto_generated|pll1|clk[0]}] [get_ports {sdramClkOut}] 
#create_generated_clock -name sd1clk_pin -source [get_pins {mySysClock|altpll_component|pll|clk[1]}] [get_ports {sdr_clk}]

#**************************************************************
# Set Clock Uncertainty
#**************************************************************

derive_clock_uncertainty;

#**************************************************************
# Set Input Delay
#**************************************************************

#set_input_delay -clock clk_sdram -max 6.4 [get_ports sdram_dq*]
#set_input_delay -clock clk_sdram -min 0 [get_ports sdram_dq*]

#**************************************************************
# Set Output Delay
#**************************************************************

#set_output_delay -clock clk_sdram -max 1.5 [get_ports sdram_*]
#set_output_delay -clock clk_sdram -min -0.8 [get_ports sdram_*] -add_delay

#**************************************************************
# Set Multicycle Path
#**************************************************************

#set_multicycle_path -from [get_clocks {clk_sdram}] -to [get_clocks {u3|altpll_component|auto_generated|pll1|clk[3]}] -setup -end 2
set_false_path -from [get_clocks {u3|altpll_component|auto_generated|pll1|clk[2]}] -to [get_clocks {u3|altpll_component|auto_generated|pll1|clk[0]}]
set_false_path -from [get_clocks {u3|altpll_component|auto_generated|pll1|clk[0]}] -to [get_clocks {u3|altpll_component|auto_generated|pll1|clk[2]}]
#set_false_path -from {RS65C816:u0|pc[1]} -to {RS65C816:u0|addr[20]}; set_false_path -from {RS65C816:u0|pc[2]} -to {RS65C816:u0|addr[20]}; set_false_path -from {RS65C816:u0|pc[1]} -to {RS65C816:u0|addr[19]}; set_false_path -from {RS65C816:u0|pc[2]} -to {RS65C816:u0|addr[19]}; set_false_path -from {RS65C816:u0|pc[2]} -to {RS65C816:u0|addr[22]}; set_false_path -from {RS65C816:u0|pc[1]} -to {RS65C816:u0|addr[22]}; set_false_path -from {RS65C816:u0|pc[3]} -to {RS65C816:u0|addr[20]}; set_false_path -from {RS65C816:u0|pc[3]} -to {RS65C816:u0|addr[22]}
#set_false_path -from {RS65C816:u0|pc[1]} -to {RS65C816:u0|pc[4]}; set_false_path -from {RS65C816:u0|addr[2]} -to {RS65C816:u0|pc[4]}; set_false_path -from {RS65C816:u0|pc[1]} -to {RS65C816:u0|addr[23]}; set_false_path -from {RS65C816:u0|addr[2]} -to {RS65C816:u0|addr[23]}; set_false_path -from {RS65C816:u0|pc[1]} -to {RS65C816:u0|addr[21]}; set_false_path -from {RS65C816:u0|rwData} -to {RS65C816:u0|pc[4]}; set_false_path -from {RS65C816:u0|addr[2]} -to {RS65C816:u0|addr[21]}; set_false_path -from {RS65C816:u0|addr[1]} -to {RS65C816:u0|pc[4]}
	#set_false_path -from {RS65C816:u0|pc[1]} -to {RS65C816:u0|addr[17]}; set_false_path -from {RS65C816:u0|pc[1]} -to {RS65C816:u0|addr[18]}; set_false_path -from {RS65C816:u0|pc[3]} -to {RS65C816:u0|addr[23]}; set_false_path -from {RS65C816:u0|pc[1]} -to {RS65C816:u0|pc[5]}; set_false_path -from {RS65C816:u0|rwData} -to {RS65C816:u0|addr[23]}; set_false_path -from {RS65C816:u0|addr[1]} -to {RS65C816:u0|addr[23]}; set_false_path -from {RS65C816:u0|pc[2]} -to {RS65C816:u0|addr[23]}; set_false_path -from {RS65C816:u0|pc[1]} -to {RS65C816:u0|pc[3]}; set_false_path -from {RS65C816:u0|addr[1]} -to {RS65C816:u0|addr[21]}; set_false_path -from {RS65C816:u0|pc[1]} -to {RS65C816:u0|addr[14]}; set_false_path -from {RS65C816:u0|pc[1]} -to {RS65C816:u0|addr[15]}; set_false_path -from {RS65C816:u0|addr[0]} -to {RS65C816:u0|addr[23]}; set_false_path -from {RS65C816:u0|addr[2]} -to {RS65C816:u0|addr[17]}; set_false_path -from {RS65C816:u0|pc[1]} -to {RS65C816:u0|addr[16]}; set_false_path -from {RS65C816:u0|rwData} -to {RS65C816:u0|addr[21]}; set_false_path -from {RS65C816:u0|addr[1]} -to {RS65C816:u0|addr[17]}; set_false_path -from {RS65C816:u0|addr[2]} -to {RS65C816:u0|addr[22]}; set_false_path -from {RS65C816:u0|pc[1]} -to {RS65C816:u0|addr[12]}; set_false_path -from {RS65C816:u0|pc[0]} -to {RS65C816:u0|addr[23]}; set_false_path -from {RS65C816:u0|pc[3]} -to {RS65C816:u0|addr[21]}; set_false_path -from {RS65C816:u0|addr[1]} -to {RS65C816:u0|addr[22]}; set_false_path -from {RS65C816:u0|pc[1]} -to {RS65C816:u0|pc[12]}; set_false_path -from {RS65C816:u0|pc[3]} -to {RS65C816:u0|addr[17]}; set_false_path -from {RS65C816:u0|pc[2]} -to {RS65C816:u0|addr[21]}; set_false_path -from {RS65C816:u0|pc[1]} -to {RS65C816:u0|opA[11]}; set_false_path -from {RS65C816:u0|pc[1]} -to {RS65C816:u0|addr[13]}; set_false_path -from {RS65C816:u0|addr[3]} -to {RS65C816:u0|addr[23]}; set_false_path -from {RS65C816:u0|addr[2]} -to {RS65C816:u0|addr[20]}; set_false_path -from {RS65C816:u0|pc[1]} -to {RS65C816:u0|pc[2]}; set_false_path -from {RS65C816:u0|rwData} -to {RS65C816:u0|addr[20]}; set_false_path -from {RS65C816:u0|pc[1]} -to {RS65C816:u0|pc[13]}; set_false_path -from {RS65C816:u0|rwData} -to {RS65C816:u0|addr[17]}; set_false_path -from {RS65C816:u0|addr[1]} -to {RS65C816:u0|addr[20]}; set_false_path -from {RS65C816:u0|pc[3]} -to {RS65C816:u0|addr[18]}; set_false_path -from {RS65C816:u0|rwData} -to {RS65C816:u0|addr[22]}; set_false_path -from {RS65C816:u0|pc[2]} -to {RS65C816:u0|addr[17]}; set_false_path -from {RS65C816:u0|addr[2]} -to {RS65C816:u0|addr[18]}; set_false_path -from {RS65C816:u0|rwData} -to {RS65C816:u0|addr[18]}; set_false_path -from {RS65C816:u0|addr[0]} -to {RS65C816:u0|addr[21]}; set_false_path -from {RS65C816:u0|addr[2]} -to {RS65C816:u0|addr[19]}; set_false_path -from {RS65C816:u0|addr[1]} -to {RS65C816:u0|addr[18]}; set_false_path -from {RS65C816:u0|pc[1]} -to {RS65C816:u0|pc[15]}; set_false_path -from {RS65C816:u0|addr[0]} -to {RS65C816:u0|addr[20]}; set_false_path -from {RS65C816:u0|addr[2]} -to {RS65C816:u0|pc[5]}; set_false_path -from {RS65C816:u0|pc[2]} -to {RS65C816:u0|addr[18]}; set_false_path -from {RS65C816:u0|pc[2]} -to {RS65C816:u0|pc[4]}; set_false_path -from {RS65C816:u0|pc[0]} -to {RS65C816:u0|addr[21]}; set_false_path -from {RS65C816:u0|pc[3]} -to {RS65C816:u0|pc[3]}; set_false_path -from {RS65C816:u0|addr[1]} -to {RS65C816:u0|pc[5]}; set_false_path -from {RS65C816:u0|addr[0]} -to {RS65C816:u0|addr[17]}; set_false_path -from {RS65C816:u0|addr[1]} -to {RS65C816:u0|addr[19]}; set_false_path -from {RS65C816:u0|addr[2]} -to {RS65C816:u0|pc[2]}; set_false_path -from {RS65C816:u0|pc[3]} -to {RS65C816:u0|pc[4]}; set_false_path -from {RS65C816:u0|addr[2]} -to {RS65C816:u0|pc[3]}; set_false_path -from {RS65C816:u0|rwData} -to {RS65C816:u0|pc[3]}; set_false_path -from {RS65C816:u0|rwData} -to {RS65C816:u0|addr[19]}