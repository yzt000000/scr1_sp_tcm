#
# Defines tool version dependencies for this coreKit.
# This file should not generally be modified as it is read
# by coreConsultant each time the workspace is opened.
#

set ::RCE::toolVersionsMin(dc_shell) "2013.12-SP5"
set ::RCE::toolVersionsMax(dc_shell) ""
set ::RCE::toolVersionsMin(fm_shell) "2015.06-SP4"
set ::RCE::toolVersionsMax(fm_shell) ""
set ::RCE::toolVersionsMin(pt_shell) "2015.12"
set ::RCE::toolVersionsMax(pt_shell) ""
set ::RCE::toolVersionsMin(VCS) "2015.09-SP1"
set ::RCE::toolVersionsMax(VCS) ""
set ::RCE::toolVersionsMin(NC_Verilog) "15.10.005"
set ::RCE::toolVersionsMax(NC_Verilog) ""
set ::RCE::toolVersionsMin(MTI_Verilog) "10.4a"
set ::RCE::toolVersionsMax(MTI_Verilog) ""
set ::RCE::toolVersionsMin(synplicity) "2015.09-SP1"
set ::RCE::toolVersionsMax(synplicity) ""
set ::RCE::toolVersionsMin(vera) "2014.03-1"
set ::RCE::toolVersionsMax(vera) ""
set ::RCE::toolVersionsMin(vip:sio) "J-2014.12-SP2"
set ::RCE::toolVersionsMax(vip:sio) ""
set ::RCE::toolVersionsMin(vip:vmt) "J-2014.12-SP2"
set ::RCE::toolVersionsMax(vip:vmt) ""
set ::RCE::toolVersionsMin(vip:amba) "J-2014.12-SP2"
set ::RCE::toolVersionsMax(vip:amba) ""


# To completely disable checking of a particular tool,
# change the array entry for the tool (below) to '0'.
set ::RCE::verify_tool(MTI_Verilog) 1
set ::RCE::verify_tool(NC_Verilog) 1
set ::RCE::verify_tool(VCS) 1
set ::RCE::verify_tool(dc_shell) 1
set ::RCE::verify_tool(fm_shell) 1
set ::RCE::verify_tool(pt_shell) 1
set ::RCE::verify_tool(synplicity) 1
set ::RCE::verify_tool(vera) 1
set ::RCE::verify_tool(vip:amba) 1
set ::RCE::verify_tool(vip:sio) 1
set ::RCE::verify_tool(vip:vmt) 1

# Mapping of tool names to names for verify_tool command.
set ::RCE::verify_tool_names(MTI_Verilog) mti_vlog
set ::RCE::verify_tool_names(NC_Verilog) nc_vlog
set ::RCE::verify_tool_names(VCS) vcs
set ::RCE::verify_tool_names(dc_shell) dc_shell
set ::RCE::verify_tool_names(fm_shell) fm_shell
set ::RCE::verify_tool_names(pt_shell) pt_shell
set ::RCE::verify_tool_names(synplicity) synplify
set ::RCE::verify_tool_names(vera) vera
set ::RCE::verify_tool_names(vip:amba) vip:amba
set ::RCE::verify_tool_names(vip:sio) vip:sio
set ::RCE::verify_tool_names(vip:vmt) vip:vmt
set ::RCE::verify_tool_names(gcc_linux) gcc
set ::RCE::verify_tool_names(gcc) gcc
set ::RCE::verify_tool_names(gcc_hpux) gcc
set ::RCE::verify_tool_names(gcc_solaris) gcc
set ::RCE::verify_tool_names(cc_linux) cc
set ::RCE::verify_tool_names(cc) cc
set ::RCE::verify_tool_names(cc_hpux) cc
set ::RCE::verify_tool_names(cc_solaris) cc
