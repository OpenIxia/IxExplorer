##################################################################################
# Utilities                                                                      #
##################################################################################
if {![info exists ::ixnHLT_log]} {
    proc ::my_ixnhlt_logger {s} {
        puts stderr $s; flush stderr; update; update idletasks
    }
    set ::ixnHLT_log ::my_ixnhlt_logger
}
if {![info exists ::ixnHLT_errorHandler]} {
    proc ::my_ixnhlt_errorhandler {module status} {
        set msg "FAIL - $module - [keylget status log]"
        $::ixnHLT_log $msg
        return -code error $msg
    }
    set ::ixnHLT_errorHandler ::my_ixnhlt_errorhandler
}
#################################################################################

if {[catch {package require Ixia} retCode]} {
    puts "FAIL - [info script] - $retCode"
    return 0
}
set test_name                   "OspfSampleScript"
set chassis_ip                  10.205.28.94
set tcl_server                  10.205.28.94
set ixnetwork_tcl_server        10.205.28.12:8079
set port_list                   [list 12/1 12/2]
set cfgErrors                   0
set vport_name_list {{{{Ethernet - 001}} {{Ethernet - 002}}}}

################################################################################
# Connect                                                                      #
################################################################################
set connect_status [::ixiangpf::connect                  \
        -reset                                           \
        -device                 $chassis_ip              \
        -port_list              $port_list               \
        -ixnetwork_tcl_server   $ixnetwork_tcl_server    \
        -tcl_server             $tcl_server              \
]

set port_1 [keylget connect_status port_handle.$chassis_ip.[lindex $port_list 0]]
set port_2 [keylget connect_status port_handle.$chassis_ip.[lindex $port_list 1]]
set port_handle [list $port_1 $port_2]

################################################################################
# Configure topology                                                           #
################################################################################
puts $port_1
puts $port_2
set topology_1_status [::ixiangpf::topology_config \
    -port_handle     $port_1                       \
    -topology_name   {{Topology 1}}                \
]

if {[keylget topology_1_status status] != $::SUCCESS} {
   $::ixnHLT_errorHandler [info script] $topology_1_status
}

set topology_1_handle [keylget topology_1_status topology_handle]
set ixnHLT(HANDLE,//topology:<1>) $topology_1_handle

set topology_2_status [::ixiangpf::topology_config \
    -port_handle      $port_2                     \
    -topology_name    {{Topology 2}}              \
]

if {[keylget topology_2_status status] != $::SUCCESS} {
    $::ixnHLT_errorHandler [info script] $topology_2_status
}

set topology_2_handle [keylget topology_2_status topology_handle]
set ixnHLT(HANDLE,//topology:<2>) $topology_2_handle

################################################################################
# Configure device group                                                       #
################################################################################
set device_group_1_status [::ixiangpf::topology_config \
    -topology_handle         $topology_1_handle        \
    -device_group_name       {"{Device Group 1}"}      \
    -device_group_multiplier 2                         \
    -device_group_enabled    1                         \
]
if {[keylget device_group_1_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $device_group_1_status
}
set deviceGroup_1_handle [keylget device_group_1_status device_group_handle]
set ixnHLT(HANDLE,//topology:<1>/deviceGroup:<1>) $deviceGroup_1_handle


set device_group_2_status [::ixiangpf::topology_config \
    -topology_handle          $topology_2_handle       \
    -device_group_name       {"{Device Group 2}"}      \
    -device_group_multiplier 2                         \
    -device_group_enabled    1                         \
]
if {[keylget device_group_2_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $device_group_2_status
}
set deviceGroup_2_handle [keylget device_group_2_status device_group_handle]
set ixnHLT(HANDLE,//topology:<2>/deviceGroup:<1>) $deviceGroup_2_handle

################################################################################
# Configure Ethernet                                                           #
################################################################################
set multivalue_1_status [::ixiangpf::multivalue_config \
    -pattern                counter                 \
    -nest_step              00.00.01.00.00.00       \
    -counter_direction      increment               \
    -counter_step           00.00.00.00.00.01       \
    -nest_enabled           1                       \
    -counter_start          00.11.01.00.00.01       \
    -nest_owner             $topology_1_handle      \
]

if {[keylget multivalue_1_status status] != $::SUCCESS} {
    $::ixnHLT_errorHandler [info script] $multivalue_1_status
}

set multivalue_1_handle [keylget multivalue_1_status multivalue_handle]
set ethernet_1_status [::ixiangpf::interface_config \
    -mtu                     1500                   \
    -src_mac_addr            $multivalue_1_handle   \
    -vlan_id                 1                      \
    -vlan_user_priority      0                      \
    -vlan_tpid               0x8100                 \
    -vlan_id_count           1                      \
    -protocol_handle         $deviceGroup_1_handle  \
    -protocol_name           {"{Ethernet 1}"}       \
    -vlan_id_step            1                      \
    -vlan                    1                      \
    -vlan_user_priority_step 0                      \
]
    
if {[keylget ethernet_1_status status] != $::SUCCESS} {
     $::ixnHLT_errorHandler [info script] $ethernet_1_status
}
set ethernet_1_handle [keylget ethernet_1_status ethernet_handle]
set ixnHLT(HANDLE,//topology:<1>/deviceGroup:<1>/ethernet:<1>) $ethernet_1_handle

set multivalue_2_status [::ixiangpf::multivalue_config \
    -pattern           counter                         \
    -nest_step         00.00.01.00.00.00               \
    -counter_direction increment                       \
    -counter_step      00.00.00.00.00.01               \
    -nest_enabled      1                               \
    -counter_start     00.12.01.00.00.01               \
    -nest_owner        $topology_2_handle              \
]

if {[keylget multivalue_2_status status] != $::SUCCESS} {
    $::ixnHLT_errorHandler [info script] $multivalue_2_status
}

set multivalue_2_handle [keylget multivalue_2_status multivalue_handle]
set ethernet_2_status [::ixiangpf::interface_config \
    -mtu                     1500                   \
    -src_mac_addr            $multivalue_2_handle   \
    -vlan_id                 1                      \
    -vlan_user_priority      0                      \
    -vlan_tpid               0x8100                 \
    -vlan_id_count           1                      \
    -protocol_handle         $deviceGroup_2_handle  \
    -protocol_name           {"{Ethernet 2}"}       \
    -vlan_id_step            1                      \
    -vlan                    1                      \
    -vlan_user_priority_step 0                      \
]

if {[keylget ethernet_2_status status] != $::SUCCESS} {
    $::ixnHLT_errorHandler [info script] $ethernet_2_status
}
set ethernet_2_handle [keylget ethernet_2_status ethernet_handle]
set ixnHLT(HANDLE,//topology:<2>/deviceGroup:<1>/ethernet:<1>) $ethernet_2_handle

################################################################################
# Configure IPv4                                                               #
################################################################################
set multivalue_3_status [::ixiangpf::multivalue_config \
    -pattern           counter                         \
    -nest_step         0.1.0.0                         \
    -counter_direction increment                       \
    -counter_step      1.0.0.0                         \
    -nest_enabled      1                               \
    -counter_start     12.0.0.1                        \
    -nest_owner        $topology_1_handle              \
]

if {[keylget multivalue_3_status status] != $::SUCCESS} {
    $::ixnHLT_errorHandler [info script] $multivalue_3_status
}
set multivalue_3_handle [keylget multivalue_3_status multivalue_handle]
set ipv4_1_status [::ixiangpf::interface_config   \
    -intf_ip_addr            $multivalue_3_handle \
    -ipv4_resolve_gateway    1                    \
    -gateway                 12.0.0.2             \
    -protocol_handle         $ethernet_1_handle   \
    -protocol_name           {"{IPv4 1}"}         \
    -gateway_step            1.0.0.0              \
    -netmask                 255.255.0.0          \
    -ipv4_manual_gateway_mac 00.00.00.00.00.01    \
]

if {[keylget ipv4_1_status status] != $::SUCCESS} {
    $::ixnHLT_errorHandler [info script] $ipv4_1_status
}
set ipv4_1_handle [keylget ipv4_1_status ipv4_handle]
set ixnHLT(HANDLE,//topology:<1>/deviceGroup:<1>/ethernet:<1>/ipv4:<1>) $ipv4_1_handle

set multivalue_4_status [::ixiangpf::multivalue_config \
    -pattern                   counter                 \
    -nest_step                 0.1.0.0                 \
    -counter_direction         increment               \
    -counter_step              1.0.0.0                 \
    -nest_enabled              1                       \
    -counter_start             12.0.0.2                \
    -nest_owner                $topology_2_handle      \
]
if {[keylget multivalue_4_status status] != $::SUCCESS} {
    $::ixnHLT_errorHandler [info script] $multivalue_4_status
}
set multivalue_4_handle [keylget multivalue_4_status multivalue_handle]

set ipv4_2_status [::ixiangpf::interface_config   \
    -intf_ip_addr            $multivalue_4_handle \
    -ipv4_resolve_gateway    1                    \
    -gateway                 12.0.0.1             \
    -protocol_handle         $ethernet_2_handle   \
    -protocol_name           {"{IPv4 2}"}         \
    -gateway_step            1.0.0.0              \
    -netmask                 255.255.0.0          \
    -ipv4_manual_gateway_mac 00.00.00.00.00.01    \
]

if {[keylget ipv4_2_status status] != $::SUCCESS} {
    $::ixnHLT_errorHandler [info script] $ipv4_2_status
}
set ipv4_2_handle [keylget ipv4_2_status ipv4_handle]
set ixnHLT(HANDLE,//topology:<2>/deviceGroup:<1>/ethernet:<1>/ipv4:<1>) $ipv4_2_handle

################################################################################
# Configure OSPFv2                                                             #
################################################################################
set multivalue_5_status [::ixiangpf::multivalue_config \
    -pattern                   counter                 \
    -nest_step                 0.1.0.0                 \
    -counter_direction         increment               \
    -counter_step              0.0.0.1                 \
    -nest_enabled              1                       \
    -counter_start             192.0.0.1               \
    -nest_owner                $topology_1_handle      \
]

if {[keylget multivalue_5_status status] != $::SUCCESS} {
    $::ixnHLT_errorHandler [info script] $multivalue_5_status
}
set multivalue_5_handle [keylget multivalue_5_status multivalue_handle]

set ospfv2_1_status [::ixiangpf::emulation_ospf_config                              \
    -support_reason_sw_reload_or_upgrade                       1                    \
    -handle                                                    $ipv4_1_handle       \
    -router_active                                             1                    \
    -md5_key_id                                                1                    \
    -te_enable                                                 0                    \
    -inter_flood_lsupdate_burst_gap                            33                   \
    -authentication_mode                                       null                 \
    -dead_interval                                             40                   \
    -lsa_discard_mode                                          0                    \
    -graceful_restart_enable                                   0                    \
    -neighbor_router_id                                        0.0.0.0              \
    -do_not_generate_router_lsa                                0                    \
    -support_reason_switch_to_redundant_processor_control      1                    \
    -oob_resync_breakout                                       0                    \
    -router_priority                                           2                    \
    -router_asbr                                               0                    \
    -enable_fast_hello                                         0                    \
    -graceful_restart_helper_mode_enable                       0                    \
    -support_reason_sw_restart                                 1                    \
    -te_max_bw                                                 0                    \
    -demand_circuit                                            0                    \
    -option_bits                                               0x02                 \
    -protocol_name                                             {"{OSPFv2-IF 1}"}    \
    -interface_cost                                            10                   \
    -te_unresv_bw_priority7                                    0                    \
    -te_unresv_bw_priority6                                    0                    \
    -te_unresv_bw_priority5                                    0                    \
    -te_unresv_bw_priority4                                    0                    \
    -te_unresv_bw_priority2                                    0                    \
    -hello_interval                                            10                   \
    -hello_multiplier                                          2                    \
    -network_type                                              ptop                 \
    -support_reason_unknown                                    1                    \
    -te_admin_group                                            0                    \
    -max_mtu                                                   1500                 \
    -lsa_refresh_time                                          1800                 \
    -te_unresv_bw_priority1                                    0                    \
    -te_unresv_bw_priority0                                    0                    \
    -lsa_retransmit_time                                       5                    \
    -area_id                                                   0.0.0.0              \
    -te_metric                                                 0                    \
    -te_max_resv_bw                                            0                    \
    -te_unresv_bw_priority3                                    0                    \
    -router_interface_active                                   1                    \
    -router_id                                                 $multivalue_5_handle \
    -strict_lsa_checking                                       1                    \
    -max_ls_updates_per_burst                                  1                    \
]
                                                 
if {[keylget ospfv2_1_status status] != $::SUCCESS} {
     $::ixnHLT_errorHandler [info script] $ospfv2_1_status
}
set ospfv2_1_handle [keylget ospfv2_1_status ospfv2_handle]
set ixnHLT(HANDLE,//topology:<1>/deviceGroup:<1>/ethernet:<1>/ipv4:<1>/ospfv2:<1>) $ospfv2_1_handle

set multivalue_6_status [::ixiangpf::multivalue_config \
    -pattern                counter                 \
    -nest_step              0.1.0.0                 \
    -counter_direction      increment               \
    -counter_step           0.0.0.1                 \
    -nest_enabled           1                       \
    -counter_start          193.0.0.1               \
    -nest_owner             $topology_2_handle      \
]
if {[keylget multivalue_6_status status] != $::SUCCESS} {
    $::ixnHLT_errorHandler [info script] $multivalue_6_status
}
set multivalue_6_handle [keylget multivalue_6_status multivalue_handle]

set ospfv2_2_status [::ixiangpf::emulation_ospf_config                              \
    -support_reason_sw_reload_or_upgrade                  1                         \
    -handle                                               $ipv4_2_handle            \
    -router_active                                        1                         \
    -md5_key_id                                           1                         \
    -te_enable                                            0                         \
    -inter_flood_lsupdate_burst_gap                       33                        \
    -authentication_mode                                  null                      \
    -dead_interval                                        40                        \
    -lsa_discard_mode                                     0                         \
    -graceful_restart_enable                              0                         \
    -neighbor_router_id                                   0.0.0.0                   \
    -do_not_generate_router_lsa                           0                         \
    -support_reason_switch_to_redundant_processor_control 1                         \
    -oob_resync_breakout                                  0                         \
    -router_priority                                      2                         \
    -router_asbr                                          0                         \
    -enable_fast_hello                                    0                         \
    -graceful_restart_helper_mode_enable                  0                         \
    -support_reason_sw_restart                            1                         \
    -te_max_bw                                            0                         \
    -demand_circuit                                       0                         \
    -option_bits                                          0x02                      \
    -protocol_name                                        {"{OSPFv2-IF 2}"}         \
    -interface_cost                                       10                        \
    -te_unresv_bw_priority7                               0                         \
    -te_unresv_bw_priority6                               0                         \
    -te_unresv_bw_priority5                               0                         \
    -te_unresv_bw_priority4                               0                         \
    -te_unresv_bw_priority2                               0                         \
    -hello_interval                                       10                        \
    -hello_multiplier                                     2                         \
    -network_type                                         ptop                      \
    -support_reason_unknown                               1                         \
    -te_admin_group                                       0                         \
    -max_mtu                                              1500                      \
    -lsa_refresh_time                                     1800                      \
    -te_unresv_bw_priority1                               0                         \
    -te_unresv_bw_priority0                               0                         \
    -lsa_retransmit_time                                  5                         \
    -area_id                                              0.0.0.0                   \
    -te_metric                                            0                         \
    -te_max_resv_bw                                       0                         \
    -te_unresv_bw_priority3                               0                         \
    -router_interface_active                              1                         \
    -router_id                                            $multivalue_6_handle      \
    -strict_lsa_checking                                  1                         \
    -max_ls_updates_per_burst                             1                         \
]

if {[keylget ospfv2_2_status status] != $::SUCCESS} {
    $::ixnHLT_errorHandler [info script] $ospfv2_2_status
}
set ospfv2_2_handle [keylget ospfv2_2_status ospfv2_handle]
set ixnHLT(HANDLE,//topology:<2>/deviceGroup:<1>/ethernet:<1>/ipv4:<1>/ospfv2:<1>) $ospfv2_2_handle

################################################################################
# wait till configuration gpes into the port                                   #
################################################################################
puts "wait for 5 seconds"
after 5000

################################################################################
# start protocol                                                               #
################################################################################
puts "starting protocol on topology 1"
::ixiangpf::emulation_ospf_control \
    -handle $ixnHLT(HANDLE,//topology:<1>)     \
    -mode start

puts "starting protocol on topology2"
::ixiangpf::emulation_ospf_control \
    -handle $ixnHLT(HANDLE,//topology:<2>)     \
    -mode start

puts "wait for 60 seconds"
after 60000


################################################################################
# check stats                                                                  #
################################################################################
puts "checking statistics ..."
catch {::ixiangpf::emulation_ospf_info\
    -handle $ixnHLT(HANDLE,//topology:<1>/deviceGroup:<1>/ethernet:<1>/ipv4:<1>/ospfv2:<1>)\
    -mode aggregate_stats} retVal
puts "$retVal"

################################################################################
# check learned info                                                           #
################################################################################

puts "checking learned info ..."
catch {::ixiangpf::emulation_ospf_info\
    -handle $ixnHLT(HANDLE,//topology:<1>/deviceGroup:<1>/ethernet:<1>/ipv4:<1>/ospfv2:<1>)\
    -mode learned_info} retVal
puts "$retVal"

################################################################################
# stop protocol                                                                #
################################################################################
puts "stopping protocol on topology 1"
::ixiangpf::emulation_ospf_control\
    -handle $ixnHLT(HANDLE,//topology:<1>)\
    -mode stop

puts "stopping protocol on topology 1"
::ixiangpf::emulation_ospf_control\
    -handle $ixnHLT(HANDLE,//topology:<2>)\
    -mode stop

