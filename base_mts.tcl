####
# BASE MTS PROJECT
# THIS DOES NOT INCLUDE THE ZYNQMP: YOU CREATE THAT SEPARATELY, THEN
# RUN THIS SCRIPT
####

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:smartconnect:1.0\
xilinx.com:ip:debug_bridge:3.0\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:system_management_wiz:1.3\
xilinx.com:ip:usp_rf_data_converter:2.6\
xilinx.com:ip:xlconcat:2.1\
xilinx.com:ip:zynq_ultra_ps_e:3.4\
xilinx.com:ip:axi_bram_ctrl:4.1\
xilinx.com:ip:blk_mem_gen:8.4\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
pl_gpio_adc_if\
adc_cap_x2\
adc_cap_x2\
adc_cap_x2\
adc_cap_x2\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: adc_cap_3
proc create_hier_cell_adc_cap_3 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_adc_cap_3() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS


  # Create pins
  create_bd_pin -dir I capture
  create_bd_pin -dir O done
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -type rst s_axi_aresetn
  create_bd_pin -dir I -type clk s_axis_aclk
  create_bd_pin -dir I -type rst s_axis_aresetn

  # Create instance: adc_cap_x2_0, and set properties
  set block_name adc_cap_x2
  set block_cell_name adc_cap_x2_0
  if { [catch {set adc_cap_x2_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $adc_cap_x2_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {256} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $axi_bram_ctrl_0


  # Create instance: blk_mem_gen_0, and set properties
  set blk_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0 ]
  set_property -dict [list \
    CONFIG.Memory_Type {True_Dual_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {URAM} \
  ] $blk_mem_gen_0


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S_AXIS] [get_bd_intf_pins adc_cap_x2_0/s_axis]
  connect_bd_intf_net -intf_net adc_cap_x2_0_BRAM_A [get_bd_intf_pins adc_cap_x2_0/BRAM_A] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]

  # Create port connections
  connect_bd_net -net aclk_0_1 [get_bd_pins s_axis_aclk] [get_bd_pins adc_cap_x2_0/aclk]
  connect_bd_net -net adc_cap_x2_0_done_o [get_bd_pins done] [get_bd_pins adc_cap_x2_0/done_o]
  connect_bd_net -net aresetn_0_1 [get_bd_pins s_axis_aresetn] [get_bd_pins adc_cap_x2_0/aresetn]
  connect_bd_net -net capture_i_0_1 [get_bd_pins capture] [get_bd_pins adc_cap_x2_0/capture_i]
  connect_bd_net -net s_axi_aclk_0_1 [get_bd_pins s_axi_aclk] [get_bd_pins adc_cap_x2_0/clk_i] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk]
  connect_bd_net -net s_axi_aresetn_0_1 [get_bd_pins s_axi_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: adc_cap_2
proc create_hier_cell_adc_cap_2 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_adc_cap_2() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS


  # Create pins
  create_bd_pin -dir I capture
  create_bd_pin -dir O done
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -type rst s_axi_aresetn
  create_bd_pin -dir I -type clk s_axis_aclk
  create_bd_pin -dir I -type rst s_axis_aresetn

  # Create instance: adc_cap_x2_0, and set properties
  set block_name adc_cap_x2
  set block_cell_name adc_cap_x2_0
  if { [catch {set adc_cap_x2_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $adc_cap_x2_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {256} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $axi_bram_ctrl_0


  # Create instance: blk_mem_gen_0, and set properties
  set blk_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0 ]
  set_property -dict [list \
    CONFIG.Memory_Type {True_Dual_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {URAM} \
  ] $blk_mem_gen_0


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S_AXIS] [get_bd_intf_pins adc_cap_x2_0/s_axis]
  connect_bd_intf_net -intf_net adc_cap_x2_0_BRAM_A [get_bd_intf_pins adc_cap_x2_0/BRAM_A] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]

  # Create port connections
  connect_bd_net -net aclk_0_1 [get_bd_pins s_axis_aclk] [get_bd_pins adc_cap_x2_0/aclk]
  connect_bd_net -net adc_cap_x2_0_done_o [get_bd_pins done] [get_bd_pins adc_cap_x2_0/done_o]
  connect_bd_net -net aresetn_0_1 [get_bd_pins s_axis_aresetn] [get_bd_pins adc_cap_x2_0/aresetn]
  connect_bd_net -net capture_i_0_1 [get_bd_pins capture] [get_bd_pins adc_cap_x2_0/capture_i]
  connect_bd_net -net s_axi_aclk_0_1 [get_bd_pins s_axi_aclk] [get_bd_pins adc_cap_x2_0/clk_i] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk]
  connect_bd_net -net s_axi_aresetn_0_1 [get_bd_pins s_axi_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: adc_cap_1
proc create_hier_cell_adc_cap_1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_adc_cap_1() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS


  # Create pins
  create_bd_pin -dir I capture
  create_bd_pin -dir O done
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -type rst s_axi_aresetn
  create_bd_pin -dir I -type clk s_axis_aclk
  create_bd_pin -dir I -type rst s_axis_aresetn

  # Create instance: adc_cap_x2_0, and set properties
  set block_name adc_cap_x2
  set block_cell_name adc_cap_x2_0
  if { [catch {set adc_cap_x2_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $adc_cap_x2_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {256} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $axi_bram_ctrl_0


  # Create instance: blk_mem_gen_0, and set properties
  set blk_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0 ]
  set_property -dict [list \
    CONFIG.Memory_Type {True_Dual_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {URAM} \
  ] $blk_mem_gen_0


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S_AXIS] [get_bd_intf_pins adc_cap_x2_0/s_axis]
  connect_bd_intf_net -intf_net adc_cap_x2_0_BRAM_A [get_bd_intf_pins adc_cap_x2_0/BRAM_A] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]

  # Create port connections
  connect_bd_net -net aclk_0_1 [get_bd_pins s_axis_aclk] [get_bd_pins adc_cap_x2_0/aclk]
  connect_bd_net -net adc_cap_x2_0_done_o [get_bd_pins done] [get_bd_pins adc_cap_x2_0/done_o]
  connect_bd_net -net aresetn_0_1 [get_bd_pins s_axis_aresetn] [get_bd_pins adc_cap_x2_0/aresetn]
  connect_bd_net -net capture_i_0_1 [get_bd_pins capture] [get_bd_pins adc_cap_x2_0/capture_i]
  connect_bd_net -net s_axi_aclk_0_1 [get_bd_pins s_axi_aclk] [get_bd_pins adc_cap_x2_0/clk_i] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk]
  connect_bd_net -net s_axi_aresetn_0_1 [get_bd_pins s_axi_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: adc_cap_0
proc create_hier_cell_adc_cap_0 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_adc_cap_0() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS


  # Create pins
  create_bd_pin -dir I capture
  create_bd_pin -dir O done
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -type rst s_axi_aresetn
  create_bd_pin -dir I -type clk s_axis_aclk
  create_bd_pin -dir I -type rst s_axis_aresetn

  # Create instance: adc_cap_x2_0, and set properties
  set block_name adc_cap_x2
  set block_cell_name adc_cap_x2_0
  if { [catch {set adc_cap_x2_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $adc_cap_x2_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property CONFIG.USE_DEBUG {1} $adc_cap_x2_0


  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]
  set_property -dict [list \
    CONFIG.DATA_WIDTH {256} \
    CONFIG.SINGLE_PORT_BRAM {1} \
  ] $axi_bram_ctrl_0


  # Create instance: blk_mem_gen_0, and set properties
  set blk_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0 ]
  set_property -dict [list \
    CONFIG.Memory_Type {True_Dual_Port_RAM} \
    CONFIG.PRIM_type_to_Implement {URAM} \
  ] $blk_mem_gen_0


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S_AXIS] [get_bd_intf_pins adc_cap_x2_0/s_axis]
  connect_bd_intf_net -intf_net adc_cap_x2_0_BRAM_A [get_bd_intf_pins adc_cap_x2_0/BRAM_A] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]

  # Create port connections
  connect_bd_net -net aclk_0_1 [get_bd_pins s_axis_aclk] [get_bd_pins adc_cap_x2_0/aclk]
  connect_bd_net -net adc_cap_x2_0_done_o [get_bd_pins done] [get_bd_pins adc_cap_x2_0/done_o]
  connect_bd_net -net aresetn_0_1 [get_bd_pins s_axis_aresetn] [get_bd_pins adc_cap_x2_0/aresetn]
  connect_bd_net -net capture_i_0_1 [get_bd_pins capture] [get_bd_pins adc_cap_x2_0/capture_i]
  connect_bd_net -net s_axi_aclk_0_1 [get_bd_pins s_axi_aclk] [get_bd_pins adc_cap_x2_0/clk_i] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk]
  connect_bd_net -net s_axi_aresetn_0_1 [get_bd_pins s_axi_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set S_AXIS_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {375000000} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {16} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $S_AXIS_0

  set S_AXIS_1 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_1 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {375000000} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {16} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $S_AXIS_1

  set S_AXIS_2 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_2 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {375000000} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {16} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $S_AXIS_2

  set S_AXIS_3 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_3 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {375000000} \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {16} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $S_AXIS_3

  set Vp_Vn_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vp_Vn_0 ]

  set adc0_clk_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 adc0_clk_0 ]

  set adc1_clk_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 adc1_clk_0 ]

  set adc2_clk_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 adc2_clk_0 ]

  set adc3_clk_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 adc3_clk_0 ]

  set m00_axis_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m00_axis_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {375000000} \
   ] $m00_axis_0

  set m02_axis_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m02_axis_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {375000000} \
   ] $m02_axis_0

  set m10_axis_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m10_axis_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {375000000} \
   ] $m10_axis_0

  set m12_axis_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m12_axis_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {375000000} \
   ] $m12_axis_0

  set m20_axis_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m20_axis_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {375000000} \
   ] $m20_axis_0

  set m22_axis_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m22_axis_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {375000000} \
   ] $m22_axis_0

  set m30_axis_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m30_axis_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {375000000} \
   ] $m30_axis_0

  set m32_axis_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m32_axis_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {375000000} \
   ] $m32_axis_0

  set sysref_in_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_usp_rf_data_converter:diff_pins_rtl:1.0 sysref_in_0 ]

  set vin0_01_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vin0_01_0 ]

  set vin0_23_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vin0_23_0 ]

  set vin1_01_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vin1_01_0 ]

  set vin1_23_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vin1_23_0 ]

  set vin2_01_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vin2_01_0 ]

  set vin2_23_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vin2_23_0 ]

  set vin3_01_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vin3_01_0 ]

  set vin3_23_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vin3_23_0 ]


  # Create ports
  set clk_adc0_0 [ create_bd_port -dir O -type clk clk_adc0_0 ]
  set pl_clk0 [ create_bd_port -dir O -type clk pl_clk0 ]
  set pl_resetn0 [ create_bd_port -dir O -type rst pl_resetn0 ]
  set s_axi_aclk_0 [ create_bd_port -dir I -type clk -freq_hz 187500000 s_axi_aclk_0 ]
  set s_axi_aresetn_0 [ create_bd_port -dir I -type rst s_axi_aresetn_0 ]
  set s_axis_aclk_0 [ create_bd_port -dir I -type clk -freq_hz 375000000 s_axis_aclk_0 ]
  set s_axis_aresetn_0 [ create_bd_port -dir I -type rst s_axis_aresetn_0 ]
  set user_sysref_adc_0 [ create_bd_port -dir I user_sysref_adc_0 ]

  # Create instance: adc_cap_0
  create_hier_cell_adc_cap_0 [current_bd_instance .] adc_cap_0

  # Create instance: adc_cap_1
  create_hier_cell_adc_cap_1 [current_bd_instance .] adc_cap_1

  # Create instance: adc_cap_2
  create_hier_cell_adc_cap_2 [current_bd_instance .] adc_cap_2

  # Create instance: adc_cap_3
  create_hier_cell_adc_cap_3 [current_bd_instance .] adc_cap_3

  # Create instance: axi_smc, and set properties
  set axi_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc ]
  set_property -dict [list \
    CONFIG.NUM_MI {4} \
    CONFIG.NUM_SI {1} \
  ] $axi_smc


  # Create instance: debug_bridge_0, and set properties
  set debug_bridge_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:debug_bridge:3.0 debug_bridge_0 ]
  set_property CONFIG.C_DEBUG_MODE {2} $debug_bridge_0


  # Create instance: pl_gpio_adc_if_0, and set properties
  set block_name pl_gpio_adc_if
  set block_cell_name pl_gpio_adc_if_0
  if { [catch {set pl_gpio_adc_if_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $pl_gpio_adc_if_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: ps8_0_axi_periph, and set properties
  set ps8_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 ps8_0_axi_periph ]
  set_property CONFIG.NUM_MI {3} $ps8_0_axi_periph


  # Create instance: rst_ps8_0_99M, and set properties
  set rst_ps8_0_99M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps8_0_99M ]

  # Create instance: rst_s_axi_aclk_0_187M, and set properties
  set rst_s_axi_aclk_0_187M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_s_axi_aclk_0_187M ]

  # Create instance: system_management_wiz_0, and set properties
  set system_management_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:system_management_wiz:1.3 system_management_wiz_0 ]

  # Create instance: usp_rf_data_converter_0, and set properties
  set usp_rf_data_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:usp_rf_data_converter:2.6 usp_rf_data_converter_0 ]
  set_property -dict [list \
    CONFIG.ADC0_Multi_Tile_Sync {true} \
    CONFIG.ADC0_Outclk_Freq {187.500} \
    CONFIG.ADC0_PLL_Enable {true} \
    CONFIG.ADC0_Refclk_Freq {600.000} \
    CONFIG.ADC0_Sampling_Rate {3} \
    CONFIG.ADC1_Outclk_Freq {187.500} \
    CONFIG.ADC1_PLL_Enable {true} \
    CONFIG.ADC1_Refclk_Freq {600.000} \
    CONFIG.ADC1_Sampling_Rate {3} \
    CONFIG.ADC2_Outclk_Freq {187.500} \
    CONFIG.ADC2_PLL_Enable {true} \
    CONFIG.ADC2_Refclk_Freq {600.000} \
    CONFIG.ADC2_Sampling_Rate {3} \
    CONFIG.ADC3_Outclk_Freq {187.500} \
    CONFIG.ADC3_PLL_Enable {true} \
    CONFIG.ADC3_Refclk_Freq {600.000} \
    CONFIG.ADC3_Sampling_Rate {3} \
    CONFIG.ADC_Dither00 {false} \
    CONFIG.ADC_Dither02 {false} \
    CONFIG.ADC_Dither10 {false} \
    CONFIG.ADC_Dither12 {false} \
    CONFIG.ADC_Dither20 {false} \
    CONFIG.ADC_Dither22 {false} \
    CONFIG.ADC_Dither30 {false} \
    CONFIG.ADC_Dither32 {false} \
    CONFIG.ADC_Slice02_Enable {true} \
    CONFIG.ADC_Slice10_Enable {true} \
    CONFIG.ADC_Slice12_Enable {true} \
    CONFIG.ADC_Slice20_Enable {true} \
    CONFIG.ADC_Slice22_Enable {true} \
    CONFIG.ADC_Slice30_Enable {true} \
    CONFIG.ADC_Slice32_Enable {true} \
  ] $usp_rf_data_converter_0


  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property CONFIG.NUM_PORTS {8} $xlconcat_0

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXIS_0_1 [get_bd_intf_ports S_AXIS_0] [get_bd_intf_pins adc_cap_0/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS_1_1 [get_bd_intf_ports S_AXIS_1] [get_bd_intf_pins adc_cap_1/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS_2_1 [get_bd_intf_ports S_AXIS_2] [get_bd_intf_pins adc_cap_2/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS_3_1 [get_bd_intf_ports S_AXIS_3] [get_bd_intf_pins adc_cap_3/S_AXIS]
  connect_bd_intf_net -intf_net Vp_Vn_0_1 [get_bd_intf_ports Vp_Vn_0] [get_bd_intf_pins system_management_wiz_0/Vp_Vn]
  connect_bd_intf_net -intf_net adc0_clk_0_1 [get_bd_intf_ports adc0_clk_0] [get_bd_intf_pins usp_rf_data_converter_0/adc0_clk]
  connect_bd_intf_net -intf_net adc1_clk_0_1 [get_bd_intf_ports adc1_clk_0] [get_bd_intf_pins usp_rf_data_converter_0/adc1_clk]
  connect_bd_intf_net -intf_net adc2_clk_0_1 [get_bd_intf_ports adc2_clk_0] [get_bd_intf_pins usp_rf_data_converter_0/adc2_clk]
  connect_bd_intf_net -intf_net adc3_clk_0_1 [get_bd_intf_ports adc3_clk_0] [get_bd_intf_pins usp_rf_data_converter_0/adc3_clk]
  connect_bd_intf_net -intf_net axi_smc_M00_AXI [get_bd_intf_pins adc_cap_0/S_AXI] [get_bd_intf_pins axi_smc/M00_AXI]
  connect_bd_intf_net -intf_net axi_smc_M01_AXI [get_bd_intf_pins adc_cap_1/S_AXI] [get_bd_intf_pins axi_smc/M01_AXI]
  connect_bd_intf_net -intf_net axi_smc_M02_AXI [get_bd_intf_pins adc_cap_2/S_AXI] [get_bd_intf_pins axi_smc/M02_AXI]
  connect_bd_intf_net -intf_net axi_smc_M03_AXI [get_bd_intf_pins adc_cap_3/S_AXI] [get_bd_intf_pins axi_smc/M03_AXI]
  connect_bd_intf_net -intf_net ps8_0_axi_periph_M00_AXI [get_bd_intf_pins ps8_0_axi_periph/M00_AXI] [get_bd_intf_pins usp_rf_data_converter_0/s_axi]
  connect_bd_intf_net -intf_net ps8_0_axi_periph_M01_AXI [get_bd_intf_pins ps8_0_axi_periph/M01_AXI] [get_bd_intf_pins system_management_wiz_0/S_AXI_LITE]
  connect_bd_intf_net -intf_net ps8_0_axi_periph_M02_AXI [get_bd_intf_pins debug_bridge_0/S_AXI] [get_bd_intf_pins ps8_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net sysref_in_0_1 [get_bd_intf_ports sysref_in_0] [get_bd_intf_pins usp_rf_data_converter_0/sysref_in]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_m00_axis [get_bd_intf_ports m00_axis_0] [get_bd_intf_pins usp_rf_data_converter_0/m00_axis]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_m02_axis [get_bd_intf_ports m02_axis_0] [get_bd_intf_pins usp_rf_data_converter_0/m02_axis]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_m10_axis [get_bd_intf_ports m10_axis_0] [get_bd_intf_pins usp_rf_data_converter_0/m10_axis]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_m12_axis [get_bd_intf_ports m12_axis_0] [get_bd_intf_pins usp_rf_data_converter_0/m12_axis]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_m20_axis [get_bd_intf_ports m20_axis_0] [get_bd_intf_pins usp_rf_data_converter_0/m20_axis]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_m22_axis [get_bd_intf_ports m22_axis_0] [get_bd_intf_pins usp_rf_data_converter_0/m22_axis]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_m30_axis [get_bd_intf_ports m30_axis_0] [get_bd_intf_pins usp_rf_data_converter_0/m30_axis]
  connect_bd_intf_net -intf_net usp_rf_data_converter_0_m32_axis [get_bd_intf_ports m32_axis_0] [get_bd_intf_pins usp_rf_data_converter_0/m32_axis]
  connect_bd_intf_net -intf_net vin0_01_0_1 [get_bd_intf_ports vin0_01_0] [get_bd_intf_pins usp_rf_data_converter_0/vin0_01]
  connect_bd_intf_net -intf_net vin0_23_0_1 [get_bd_intf_ports vin0_23_0] [get_bd_intf_pins usp_rf_data_converter_0/vin0_23]
  connect_bd_intf_net -intf_net vin1_01_0_1 [get_bd_intf_ports vin1_01_0] [get_bd_intf_pins usp_rf_data_converter_0/vin1_01]
  connect_bd_intf_net -intf_net vin1_23_0_1 [get_bd_intf_ports vin1_23_0] [get_bd_intf_pins usp_rf_data_converter_0/vin1_23]
  connect_bd_intf_net -intf_net vin2_01_0_1 [get_bd_intf_ports vin2_01_0] [get_bd_intf_pins usp_rf_data_converter_0/vin2_01]
  connect_bd_intf_net -intf_net vin2_23_0_1 [get_bd_intf_ports vin2_23_0] [get_bd_intf_pins usp_rf_data_converter_0/vin2_23]
  connect_bd_intf_net -intf_net vin3_01_0_1 [get_bd_intf_ports vin3_01_0] [get_bd_intf_pins usp_rf_data_converter_0/vin3_01]
  connect_bd_intf_net -intf_net vin3_23_0_1 [get_bd_intf_ports vin3_23_0] [get_bd_intf_pins usp_rf_data_converter_0/vin3_23]
  connect_bd_intf_net -intf_net zynq_ultra_ps_e_0_M_AXI_HPM0_FPD [get_bd_intf_pins ps8_0_axi_periph/S00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_FPD]
  connect_bd_intf_net -intf_net zynq_ultra_ps_e_0_M_AXI_HPM1_FPD [get_bd_intf_pins axi_smc/S00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM1_FPD]

  # Create port connections
  connect_bd_net -net adc_cap_0_done [get_bd_pins adc_cap_0/done] [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net adc_cap_1_done [get_bd_pins adc_cap_1/done] [get_bd_pins xlconcat_0/In1]
  connect_bd_net -net adc_cap_2_done [get_bd_pins adc_cap_2/done] [get_bd_pins xlconcat_0/In2]
  connect_bd_net -net adc_cap_3_done [get_bd_pins adc_cap_3/done] [get_bd_pins xlconcat_0/In3]
  connect_bd_net -net capture_1 [get_bd_pins adc_cap_0/capture] [get_bd_pins adc_cap_1/capture] [get_bd_pins adc_cap_2/capture] [get_bd_pins adc_cap_3/capture] [get_bd_pins pl_gpio_adc_if_0/capture_o]
  connect_bd_net -net pl_gpio_adc_if_0_gpio_to_ps [get_bd_pins pl_gpio_adc_if_0/gpio_to_ps] [get_bd_pins zynq_ultra_ps_e_0/emio_gpio_i]
  connect_bd_net -net rst_ps8_0_99M_peripheral_aresetn [get_bd_pins debug_bridge_0/s_axi_aresetn] [get_bd_pins ps8_0_axi_periph/ARESETN] [get_bd_pins ps8_0_axi_periph/M00_ARESETN] [get_bd_pins ps8_0_axi_periph/M01_ARESETN] [get_bd_pins ps8_0_axi_periph/M02_ARESETN] [get_bd_pins ps8_0_axi_periph/S00_ARESETN] [get_bd_pins rst_ps8_0_99M/peripheral_aresetn] [get_bd_pins system_management_wiz_0/s_axi_aresetn] [get_bd_pins usp_rf_data_converter_0/s_axi_aresetn]
  connect_bd_net -net rst_s_axi_aclk_0_187M_peripheral_aresetn [get_bd_pins axi_smc/aresetn] [get_bd_pins rst_s_axi_aclk_0_187M/peripheral_aresetn]
  connect_bd_net -net s_axi_aclk_0_1 [get_bd_ports s_axi_aclk_0] [get_bd_pins adc_cap_0/s_axi_aclk] [get_bd_pins adc_cap_1/s_axi_aclk] [get_bd_pins adc_cap_2/s_axi_aclk] [get_bd_pins adc_cap_3/s_axi_aclk] [get_bd_pins axi_smc/aclk] [get_bd_pins pl_gpio_adc_if_0/adc_div2_clk] [get_bd_pins rst_s_axi_aclk_0_187M/slowest_sync_clk] [get_bd_pins zynq_ultra_ps_e_0/maxihpm1_fpd_aclk]
  connect_bd_net -net s_axi_aresetn_0_1 [get_bd_ports s_axi_aresetn_0] [get_bd_pins adc_cap_0/s_axi_aresetn] [get_bd_pins adc_cap_1/s_axi_aresetn] [get_bd_pins adc_cap_2/s_axi_aresetn] [get_bd_pins adc_cap_3/s_axi_aresetn]
  connect_bd_net -net s_axis_aclk_0_1 [get_bd_ports s_axis_aclk_0] [get_bd_pins adc_cap_0/s_axis_aclk] [get_bd_pins adc_cap_1/s_axis_aclk] [get_bd_pins adc_cap_2/s_axis_aclk] [get_bd_pins adc_cap_3/s_axis_aclk] [get_bd_pins usp_rf_data_converter_0/m0_axis_aclk] [get_bd_pins usp_rf_data_converter_0/m1_axis_aclk] [get_bd_pins usp_rf_data_converter_0/m2_axis_aclk] [get_bd_pins usp_rf_data_converter_0/m3_axis_aclk]
  connect_bd_net -net s_axis_aresetn_0_1 [get_bd_ports s_axis_aresetn_0] [get_bd_pins adc_cap_0/s_axis_aresetn] [get_bd_pins adc_cap_1/s_axis_aresetn] [get_bd_pins adc_cap_2/s_axis_aresetn] [get_bd_pins adc_cap_3/s_axis_aresetn] [get_bd_pins usp_rf_data_converter_0/m0_axis_aresetn] [get_bd_pins usp_rf_data_converter_0/m1_axis_aresetn] [get_bd_pins usp_rf_data_converter_0/m2_axis_aresetn] [get_bd_pins usp_rf_data_converter_0/m3_axis_aresetn]
  connect_bd_net -net user_sysref_adc_0_1 [get_bd_ports user_sysref_adc_0] [get_bd_pins usp_rf_data_converter_0/user_sysref_adc]
  connect_bd_net -net usp_rf_data_converter_0_clk_adc0 [get_bd_ports clk_adc0_0] [get_bd_pins usp_rf_data_converter_0/clk_adc0]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins pl_gpio_adc_if_0/done_i] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net zynq_ultra_ps_e_0_emio_gpio_o [get_bd_pins pl_gpio_adc_if_0/gpio_from_ps] [get_bd_pins zynq_ultra_ps_e_0/emio_gpio_o]
  connect_bd_net -net zynq_ultra_ps_e_0_emio_gpio_t [get_bd_pins pl_gpio_adc_if_0/gpio_direction] [get_bd_pins zynq_ultra_ps_e_0/emio_gpio_t]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_ports pl_clk0] [get_bd_pins debug_bridge_0/s_axi_aclk] [get_bd_pins pl_gpio_adc_if_0/ps_clk] [get_bd_pins ps8_0_axi_periph/ACLK] [get_bd_pins ps8_0_axi_periph/M00_ACLK] [get_bd_pins ps8_0_axi_periph/M01_ACLK] [get_bd_pins ps8_0_axi_periph/M02_ACLK] [get_bd_pins ps8_0_axi_periph/S00_ACLK] [get_bd_pins rst_ps8_0_99M/slowest_sync_clk] [get_bd_pins system_management_wiz_0/s_axi_aclk] [get_bd_pins usp_rf_data_converter_0/s_axi_aclk] [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_fpd_aclk] [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_ports pl_resetn0] [get_bd_pins rst_ps8_0_99M/ext_reset_in] [get_bd_pins rst_s_axi_aclk_0_187M/ext_reset_in] [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0]

  # Create address segments
  assign_bd_address -offset 0xB0000000 -range 0x00008000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs adc_cap_0/axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0xB0008000 -range 0x00008000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs adc_cap_1/axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0xB0010000 -range 0x00008000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs adc_cap_2/axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0xB0018000 -range 0x00008000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs adc_cap_3/axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0xA0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs debug_bridge_0/S_AXI/Reg0] -force
  assign_bd_address -offset 0xA0010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs system_management_wiz_0/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0xA0040000 -range 0x00040000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs usp_rf_data_converter_0/s_axi/Reg] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""

