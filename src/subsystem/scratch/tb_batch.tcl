set uvm_ral_list {{i_gpio_DW_apb_gpio.ralf i_gpio_DW_apb_gpio /i_gpio} {i_uart_DW_apb_uart.ralf i_uart_DW_apb_uart /i_uart}}
save_workspace; close_workspace
create_workspace -testbench  -name tb_Subsystem1  -design tb_Subsystem1  -root /root
sVer::tb_fixupSearchPath {/software/vip_amba/iip/latest /usr/synopsys/coretool_L-2016.09-SP1/auxx/dware/glue}
catch { sUtils::GuiTestSynchGUI }
instantiate_dut -name DUT -workspace /root/Subsystem1
sVer::instantiate_application_side_vip 1 0  1 1
sVer::instantiate_application_side_vip 1 1  1 1
set ::enableSvtVip 1
sVer::instantiate_clkgen
sAssemblerKb::markAllUnconnectedInterfacesAsUnused
catch { sUtils::GuiTestSynchGUI }
set_attribute [get_top_design] -attr TestBenchMode -value uvm
set_attribute [get_top_design] -attr RalListInfo -value $uvm_ral_list
set_activity_parameter SimulateSubsystemTestbench UvmEnabled  1

     # copy ral files from tb sim area and delete from Subsystem area
      foreach lst $uvm_ral_list {
        set ralFile [lindex $lst 0]
       
        # check if ralf file exists in <subsystem>/.., copy to tb sim and
        # delete forcefully
        if {[file exists [file join /root/Subsystem1 scratch $ralFile]]} {
          file copy -force [file join /root/Subsystem1 scratch $ralFile] [file join [get_logical_dir] scratch] 
          file delete -force [file join /root/Subsystem1 scratch $ralFile]
        } else {
          error_user CMD-024 [list "open" "file $ralFile"   ""]
          return 0
        }
      }
      

  ##########################################################
  #
  #   UVMTestText
  #
  ##########################################################
  
    ##########################################################
    
