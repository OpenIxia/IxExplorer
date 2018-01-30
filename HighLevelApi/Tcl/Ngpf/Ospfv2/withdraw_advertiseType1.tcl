global chassis_ip
global port_list
proc ixnCPF_Configure {ixnHLTVarName} {
     global chassis_ip
global port_list
    upvar 1 $ixnHLTVarName ixnHLT
    #parray ixnHLT 

set port_1 [keylget ::connect_status port_handle.$chassis_ip.[lindex $port_list 0]]
set port_2 [keylget ::connect_status port_handle.$chassis_ip.[lindex $port_list 1]]
set port_handle [list $port_1 $port_2]

    ############################################################################
    # Add topology 1
    ############################################################################
    set topology_1_status [::ixiangpf::topology_config  \
        -port_handle        $port_1 \
        -topology_name      {{Topology 1}}              \
    ]

    if {[keylget topology_1_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $topology_1_status
    }
    set topology_1_handle [keylget topology_1_status topology_handle]
    set ixnHLT(HANDLE,//topology:<1>) $topology_1_handle
   
    ############################################################################
    # Add topology 2
    ############################################################################
    set topology_2_status [::ixiangpf::topology_config \
        -port_handle      $port_2  \
        -topology_name    {{Topology 2}}               \
    ]
    if {[keylget topology_2_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $topology_2_status
    }
    set topology_2_handle [keylget topology_2_status topology_handle]
    set ixnHLT(HANDLE,//topology:<2>) $topology_2_handle
   
    ############################################################################
    # Add topology 1/device group 1
    ############################################################################ 
    set device_group_1_status [::ixiangpf::topology_config \
        -device_group_enabled         1                       \
        -device_group_name            {Device Group 1}        \
        -device_group_multiplier      1                       \
        -topology_handle              $topology_1_handle      \
    ]
    if {[keylget device_group_1_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $device_group_1_status
    }
    set deviceGroup_1_handle [keylget device_group_1_status device_group_handle]
    set ixnHLT(HANDLE,//topology:<1>/deviceGroup:<1>) $deviceGroup_1_handle
   
    ############################################################################
    # Add topology 2/device group 1
    ############################################################################ 
    set device_group_2_status [::ixiangpf::topology_config \
        -device_group_enabled         1                       \
        -device_group_name            {Device Group 2}        \
        -device_group_multiplier      1                       \
        -topology_handle              $topology_2_handle      \
    ]
    if {[keylget device_group_2_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $device_group_2_status
    }
    set deviceGroup_2_handle [keylget device_group_2_status device_group_handle]
    set ixnHLT(HANDLE,//topology:<2>/deviceGroup:<1>) $deviceGroup_2_handle
    
    ############################################################################
    # Add topology 1/device group 1/ethernet 1
    ############################################################################ 
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
        -mtu                          1500                       \
        -src_mac_addr                 $multivalue_1_handle       \
        -vlan_id                      1                          \
        -vlan_user_priority           0                          \
        -vlan_tpid                    0x8100                     \
        -vlan_id_count                1                          \
        -protocol_handle              $deviceGroup_1_handle      \
        -protocol_name                {Ethernet 1}               \
        -vlan_id_step                 0                          \
        -vlan                         0                          \
        -vlan_user_priority_step      0                          \
    ]

    if {[keylget ethernet_1_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $ethernet_1_status
    }
    set ethernet_1_handle [keylget ethernet_1_status ethernet_handle]
    set ixnHLT(HANDLE,//topology:<1>/deviceGroup:<1>/ethernet:<1>) $ethernet_1_handle
   
    ############################################################################
    # Add topology 2/device group 1/ethernet 1
    ############################################################################  
    set multivalue_2_status [::ixiangpf::multivalue_config \
        -pattern                counter                 \
        -nest_step              00.00.01.00.00.00       \
        -counter_direction      increment               \
        -counter_step           00.00.00.00.00.01       \
        -nest_enabled           1                       \
        -counter_start          00.12.01.00.00.01       \
        -nest_owner             $topology_2_handle      \
    ]
    if {[keylget multivalue_2_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $multivalue_2_status
    }
    set multivalue_2_handle [keylget multivalue_2_status multivalue_handle]
    
    set ethernet_2_status [::ixiangpf::interface_config \
        -mtu                          1500                       \
        -src_mac_addr                 $multivalue_2_handle       \
        -vlan_id                      1                          \
        -vlan_user_priority           0                          \
        -vlan_tpid                    0x8100                     \
        -vlan_id_count                1                          \
        -protocol_handle              $deviceGroup_2_handle      \
        -protocol_name                {Ethernet 2}               \
        -vlan_id_step                 0                          \
        -vlan                         0                          \
        -vlan_user_priority_step      0                          \
    ]

    if {[keylget ethernet_2_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $ethernet_2_status
    }
    set ethernet_2_handle [keylget ethernet_2_status ethernet_handle]
    set ixnHLT(HANDLE,//topology:<2>/deviceGroup:<1>/ethernet:<1>) $ethernet_2_handle
   
    ############################################################################
    # Add topology 1/device group 1/ethernet 1/ipv4 1
    ############################################################################
    set multivalue_3_status [::ixiangpf::multivalue_config \
        -pattern                counter                 \
        -nest_step              0.1.0.0                 \
        -counter_direction      increment               \
        -counter_step           0.0.0.1                 \
        -nest_enabled           1                       \
        -counter_start          1.0.0.2                 \
        -nest_owner             $topology_1_handle      \
    ]
    if {[keylget multivalue_3_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $multivalue_3_status
    }
    set multivalue_3_handle [keylget multivalue_3_status multivalue_handle]
    
    set ipv4_1_status [::ixiangpf::interface_config \
        -intf_ip_addr                 $multivalue_3_handle      \
        -ipv4_resolve_gateway         1                         \
        -gateway                      1.0.0.1                   \
        -protocol_handle              $ethernet_1_handle        \
        -protocol_name                {IPv4 1}                  \
        -gateway_step                 0.0.0.1                   \
        -netmask                      255.255.255.0             \
        -ipv4_manual_gateway_mac      00.00.00.00.00.01         \
    ]
    if {[keylget ipv4_1_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $ipv4_1_status
    }
    set ipv4_1_handle [keylget ipv4_1_status ipv4_handle]
    set ixnHLT(HANDLE,//topology:<1>/deviceGroup:<1>/ethernet:<1>/ipv4:<1>) $ipv4_1_handle
   
    ############################################################################
    # Add topology 2/device group 1/ethernet 1/ipv4 1
    ############################################################################ 
    set multivalue_4_status [::ixiangpf::multivalue_config \
        -pattern                counter                 \
        -nest_step              0.1.0.0                 \
        -counter_direction      increment               \
        -counter_step           0.0.0.1                 \
        -nest_enabled           1                       \
        -counter_start          1.0.0.1                 \
        -nest_owner             $topology_2_handle      \
    ]
    if {[keylget multivalue_4_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $multivalue_4_status
    }
    set multivalue_4_handle [keylget multivalue_4_status multivalue_handle]
    
    set ipv4_2_status [::ixiangpf::interface_config \
        -intf_ip_addr                 $multivalue_4_handle      \
        -ipv4_resolve_gateway         1                         \
        -gateway                      1.0.0.2                   \
        -protocol_handle              $ethernet_2_handle        \
        -protocol_name                {IPv4 2}                  \
        -gateway_step                 0.0.0.1                   \
        -netmask                      255.255.255.0             \
        -ipv4_manual_gateway_mac      00.00.00.00.00.01         \
    ]
    if {[keylget ipv4_2_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $ipv4_2_status
    }
    set ipv4_2_handle [keylget ipv4_2_status ipv4_handle]
    set ixnHLT(HANDLE,//topology:<2>/deviceGroup:<1>/ethernet:<1>/ipv4:<1>) $ipv4_2_handle
   
    ############################################################################
    # Add topology 1/device group 1/ethernet 1/ipv4 1/ospfV2 1
    ############################################################################ 
    set multivalue_5_status [::ixiangpf::multivalue_config \
        -pattern                counter                 \
        -nest_step              0.1.0.0                 \
        -counter_direction      increment               \
        -counter_step           0.0.0.1                 \
        -nest_enabled           1                       \
        -counter_start          192.0.0.1               \
        -nest_owner             $topology_1_handle      \
    ]
    if {[keylget multivalue_5_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $multivalue_5_status
    }
    set multivalue_5_handle [keylget multivalue_5_status multivalue_handle]
    
    set ospfv2_1_status [::ixiangpf::emulation_ospf_config \
        -handle                                                    $ipv4_1_handle            \
        -router_active                                             1                         \
        -md5_key_id                                                1                         \
        -inter_flood_lsupdate_burst_gap                            33                        \
        -authentication_mode                                       null                      \
        -dead_interval                                             40                        \
        -lsa_discard_mode                                          0                         \
        -graceful_restart_enable                                   0                         \
        -neighbor_router_id                                        0.0.0.0                   \
        -do_not_generate_router_lsa                                0                         \
        -support_reason_switch_to_redundant_processor_control      1                         \
        -external_capabilities                                     1                         \
        -oob_resync_breakout                                       0                         \
        -router_priority                                           2                         \
        -router_asbr                                               0                         \
        -external_attribute                                        0                         \
        -enable_fast_hello                                         0                         \
        -multicast_capability                                      0                         \
        -graceful_restart_helper_mode_enable                       0                         \
        -nssa_capability                                           0                         \
        -support_reason_sw_reload_or_upgrade                       1                         \
        -router_id                                                 $multivalue_5_handle      \
        -te_admin_group                                            0                         \
        -te_max_bw                                                 0                         \
        -hello_interval                                            10                        \
        -demand_circuit                                            0                         \
        -protocol_name                                             {OSPFv2-IF 1}             \
        -interface_cost                                            10                        \
        -te_unresv_bw_priority7                                    0                         \
        -unused                                                    0                         \
        -te_unresv_bw_priority5                                    0                         \
        -te_unresv_bw_priority4                                    0                         \
        -te_unresv_bw_priority3                                    0                         \
        -te_unresv_bw_priority2                                    0                         \
        -te_unresv_bw_priority0                                    0                         \
        -hello_multiplier                                          2                         \
        -network_type                                              ptop                      \
        -type_of_service_routing                                   0                         \
        -support_reason_unknown                                    1                         \
        -mode                                                      create                    \
        -max_mtu                                                   1500                      \
        -te_unresv_bw_priority6                                    0                         \
        -lsa_refresh_time                                          1800                      \
        -te_unresv_bw_priority1                                    0                         \
        -support_reason_sw_restart                                 1                         \
        -lsa_retransmit_time                                       5                         \
        -area_id                                                   0.0.0.0                   \
        -te_metric                                                 0                         \
        -te_max_resv_bw                                            0                         \
        -te_enable                                                 0                         \
        -router_interface_active                                   1                         \
        -strict_lsa_checking                                       1                         \
        -max_ls_updates_per_burst                                  1                         \
        -opaque_lsa_forwarded                                      0                         \
    ]
    if {[keylget ospfv2_1_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $ospfv2_1_status
    }
    set ospfv2_1_handle [keylget ospfv2_1_status ospfv2_handle]
    set ixnHLT(HANDLE,//topology:<1>/deviceGroup:<1>/ethernet:<1>/ipv4:<1>/ospfv2:<1>) $ospfv2_1_handle
   
    ############################################################################
    # Add topology 2/device group 1/ethernet 1/ipv4 1/ospfV2 1
    ############################################################################ 
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
    
    set ospfv2_2_status [::ixiangpf::emulation_ospf_config \
        -handle                                                    $ipv4_2_handle            \
        -router_active                                             1                         \
        -md5_key_id                                                1                         \
        -inter_flood_lsupdate_burst_gap                            33                        \
        -authentication_mode                                       null                      \
        -dead_interval                                             40                        \
        -lsa_discard_mode                                          0                         \
        -graceful_restart_enable                                   0                         \
        -neighbor_router_id                                        0.0.0.0                   \
        -do_not_generate_router_lsa                                0                         \
        -support_reason_switch_to_redundant_processor_control      1                         \
        -external_capabilities                                     1                         \
        -oob_resync_breakout                                       0                         \
        -router_priority                                           2                         \
        -router_asbr                                               0                         \
        -external_attribute                                        0                         \
        -enable_fast_hello                                         0                         \
        -multicast_capability                                      0                         \
        -graceful_restart_helper_mode_enable                       0                         \
        -nssa_capability                                           0                         \
        -support_reason_sw_reload_or_upgrade                       1                         \
        -router_id                                                 $multivalue_6_handle      \
        -te_admin_group                                            0                         \
        -te_max_bw                                                 0                         \
        -hello_interval                                            10                        \
        -demand_circuit                                            0                         \
        -protocol_name                                             {OSPFv2-IF 2}             \
        -interface_cost                                            10                        \
        -te_unresv_bw_priority7                                    0                         \
        -unused                                                    0                         \
        -te_unresv_bw_priority5                                    0                         \
        -te_unresv_bw_priority4                                    0                         \
        -te_unresv_bw_priority3                                    0                         \
        -te_unresv_bw_priority2                                    0                         \
        -te_unresv_bw_priority0                                    0                         \
        -hello_multiplier                                          2                         \
        -network_type                                              ptop                      \
        -type_of_service_routing                                   0                         \
        -support_reason_unknown                                    1                         \
        -mode                                                      create                    \
        -max_mtu                                                   1500                      \
        -te_unresv_bw_priority6                                    0                         \
        -lsa_refresh_time                                          1800                      \
        -te_unresv_bw_priority1                                    0                         \
        -support_reason_sw_restart                                 1                         \
        -lsa_retransmit_time                                       5                         \
        -area_id                                                   0.0.0.0                   \
        -te_metric                                                 0                         \
        -te_max_resv_bw                                            0                         \
        -te_enable                                                 0                         \
        -router_interface_active                                   1                         \
        -strict_lsa_checking                                       1                         \
        -max_ls_updates_per_burst                                  1                         \
        -opaque_lsa_forwarded                                      0                         \
    ]
    if {[keylget ospfv2_2_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $ospfv2_2_status
    }
    set ospfv2_2_handle [keylget ospfv2_2_status ospfv2_handle]
    set ixnHLT(HANDLE,//topology:<2>/deviceGroup:<1>/ethernet:<1>/ipv4:<1>/ospfv2:<1>) $ospfv2_2_handle
 
    ############################################################################
    # Add topology 1/device group 1/ethernet 1/ipv4 1/ospfV2 1/network group 1
    ############################################################################    
    set multivalue_7_status [::ixiangpf::multivalue_config \
        -pattern                counter                                       \
        -nest_step              0.0.0.1,0.1.0.0                               \
        -counter_direction      increment                                     \
        -counter_step           0.0.0.1                                       \
        -nest_enabled           0,1                                           \
        -counter_start          100.1.0.1                                     \
        -nest_owner             $deviceGroup_1_handle,$topology_1_handle      \
    ]
    if {[keylget multivalue_7_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $multivalue_7_status
    }
    set multivalue_7_handle [keylget multivalue_7_status multivalue_handle]
    
    set multivalue_8_status [::ixiangpf::multivalue_config \
        -pattern                counter                                       \
        -nest_step              0.0.0.1,0.1.0.0                               \
        -counter_direction      increment                                     \
        -counter_step           0.0.1.0                                       \
        -nest_enabled           0,1                                           \
        -counter_start          1.0.0.1                                       \
        -nest_owner             $deviceGroup_1_handle,$topology_1_handle      \
    ]
    if {[keylget multivalue_8_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $multivalue_8_status
    }
    set multivalue_8_handle [keylget multivalue_8_status multivalue_handle]
    
    set multivalue_9_status [::ixiangpf::multivalue_config \
        -pattern                counter                                       \
        -nest_step              0.0.0.1,0.1.0.0                               \
        -counter_direction      increment                                     \
        -counter_step           0.0.1.0                                       \
        -nest_enabled           0,1                                           \
        -counter_start          1.0.0.2                                       \
        -nest_owner             $deviceGroup_1_handle,$topology_1_handle      \
    ]
    if {[keylget multivalue_9_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $multivalue_9_status
    }
    set multivalue_9_handle [keylget multivalue_9_status multivalue_handle]
    
    set multivalue_10_status [::ixiangpf::multivalue_config \
        -pattern                counter                                       \
        -nest_step              0.0.0.1,0.1.0.0                               \
        -counter_direction      increment                                     \
        -counter_step           0.1.0.0                                       \
        -nest_enabled           0,1                                           \
        -counter_start          201.1.0.0                                     \
        -nest_owner             $deviceGroup_1_handle,$topology_1_handle      \
    ]
    if {[keylget multivalue_10_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $multivalue_10_status
    }
    set multivalue_10_handle [keylget multivalue_10_status multivalue_handle]
    
    set multivalue_11_status [::ixiangpf::multivalue_config \
        -pattern                counter                                       \
        -nest_step              0.0.0.1,0.1.0.0                               \
        -counter_direction      increment                                     \
        -counter_step           0.1.0.0                                       \
        -nest_enabled           0,1                                           \
        -counter_start          203.1.0.0                                     \
        -nest_owner             $deviceGroup_1_handle,$topology_1_handle      \
    ]
    if {[keylget multivalue_11_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $multivalue_11_status
    }
    set multivalue_11_handle [keylget multivalue_11_status multivalue_handle]
    
    set multivalue_12_status [::ixiangpf::multivalue_config \
        -pattern                counter                                       \
        -nest_step              0.0.0.1,0.1.0.0                               \
        -counter_direction      increment                                     \
        -counter_step           0.1.0.0                                       \
        -nest_enabled           0,1                                           \
        -counter_start          204.1.0.0                                     \
        -nest_owner             $deviceGroup_1_handle,$topology_1_handle      \
    ]
    if {[keylget multivalue_12_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $multivalue_12_status
    }
    set multivalue_12_handle [keylget multivalue_12_status multivalue_handle]
    
    set multivalue_13_status [::ixiangpf::multivalue_config \
        -pattern                counter                                       \
        -nest_step              0.0.0.1,0.1.0.0                               \
        -counter_direction      increment                                     \
        -counter_step           0.1.0.0                                       \
        -nest_enabled           0,1                                           \
        -counter_start          205.1.0.0                                     \
        -nest_owner             $deviceGroup_1_handle,$topology_1_handle      \
    ]
    if {[keylget multivalue_13_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $multivalue_13_status
    }
    set multivalue_13_handle [keylget multivalue_13_status multivalue_handle]
    
    set network_group_1_status [::ixiangpf::emulation_ospf_network_group_config \
        -summary_prefix                        16                         \
        -link_te_unresv_bw_priority4           0                          \
        -link_te_unresv_bw_priority6           0                          \
        -grid_col                              2                          \
        -handle                                $ospfv2_1_handle           \
        -external2_network_address_step        0.0.0.0                    \
        -nssa_metric                           0                          \
        -summary_metric                        0                          \
        -nssa_network_address                  $multivalue_13_handle      \
        -link_te_unresv_bw_priority5           0                          \
        -external2_prefix                      16                         \
        -link_te_unresv_bw_priority7           0                          \
        -link_te_unresv_bw_priority1           0                          \
        -link_te_unresv_bw_priority0           0                          \
        -link_te_unresv_bw_priority3           0                          \
        -link_te_unresv_bw_priority2           0                          \
        -type                                  grid                       \
        -from_ip                               $multivalue_8_handle       \
        -router_asbr                           0                          \
        -stub_prefix                           16                         \
        -stub_number_of_routes                 1                          \
        -nssa_active                           1                          \
        -external1_number_of_routes            1                          \
        -summary_active                        1                          \
        -summary_network_address               $multivalue_11_handle      \
        -external2_number_of_routes            1                          \
        -router_id                             $multivalue_7_handle       \
        -link_metric                           10                         \
        -subnet_prefix_length                  24                         \
        -to_ip                                 $multivalue_9_handle       \
        -external2_active                      1                          \
        -multiplier                            1                          \
        -external1_active                      1                          \
        -external1_network_address             $multivalue_10_handle      \
        -summary_number_of_routes              1                          \
        -external2_network_address             202.1.0.0                  \
        -active_router_id                      1                          \
        -grid_include_emulated_device          1                          \
        -nssa_prefix                           16                         \
        -link_te_max_resv_bw                   0                          \
        -nssa_number_of_routes                 1                          \
        -stub_network_address                  $multivalue_12_handle      \
        -router_abr                            0                          \
        -enable_advertise_as_stub_network      0                          \
        -external2_metric                      0                          \
        -external1_prefix                      16                         \
        -stub_active                           1                          \
        -link_te_administrator_group           0                          \
        -grid_link_multiplier                  1                          \
        -link_te_max_bw                        0                          \
        -stub_metric                           0                          \
        -grid_row                              2                          \
        -external1_metric                      0                          \
        -link_te                               0                          \
        -link_te_metric                        0                          \
    ]
    set ::NG1 $network_group_1_status

    if {[keylget network_group_1_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $network_group_1_status
    }
    set networkGroup_1_handle [keylget network_group_1_status network_group_handle]
    set ixnHLT(HANDLE,//topology:<1>/deviceGroup:<1>/networkGroup:<1>) $networkGroup_1_handle
   
    ############################################################################
    # Add topology 2/device group 1/ethernet 1/ipv4 1/ospfV2 1/network group 1
    ############################################################################
    set multivalue_14_status [::ixiangpf::multivalue_config \
        -pattern                counter                                       \
        -nest_step              0.0.0.1,0.1.0.0                               \
        -counter_direction      increment                                     \
        -counter_step           0.0.0.1                                       \
        -nest_enabled           0,1                                           \
        -counter_start          101.1.0.1                                     \
        -nest_owner             $deviceGroup_2_handle,$topology_2_handle      \
    ]
    if {[keylget multivalue_14_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $multivalue_14_status
    }
    set multivalue_14_handle [keylget multivalue_14_status multivalue_handle]
    
    set multivalue_15_status [::ixiangpf::multivalue_config \
        -pattern                counter                                       \
        -nest_step              0.0.0.1,0.1.0.0                               \
        -counter_direction      increment                                     \
        -counter_step           0.0.1.0                                       \
        -nest_enabled           0,1                                           \
        -counter_start          2.0.0.1                                       \
        -nest_owner             $deviceGroup_2_handle,$topology_2_handle      \
    ]
    if {[keylget multivalue_15_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $multivalue_15_status
    }
    set multivalue_15_handle [keylget multivalue_15_status multivalue_handle]
    
    set multivalue_16_status [::ixiangpf::multivalue_config \
        -pattern                counter                                       \
        -nest_step              0.0.0.1,0.1.0.0                               \
        -counter_direction      increment                                     \
        -counter_step           0.0.1.0                                       \
        -nest_enabled           0,1                                           \
        -counter_start          2.0.0.2                                       \
        -nest_owner             $deviceGroup_2_handle,$topology_2_handle      \
    ]
    if {[keylget multivalue_16_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $multivalue_16_status
    }
    set multivalue_16_handle [keylget multivalue_16_status multivalue_handle]
    
    set multivalue_17_status [::ixiangpf::multivalue_config \
        -pattern                counter                                       \
        -nest_step              0.0.0.1,0.1.0.0                               \
        -counter_direction      increment                                     \
        -counter_step           0.1.0.0                                       \
        -nest_enabled           0,1                                           \
        -counter_start          102.1.0.0                                     \
        -nest_owner             $deviceGroup_2_handle,$topology_2_handle      \
    ]
    if {[keylget multivalue_17_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $multivalue_17_status
    }
    set multivalue_17_handle [keylget multivalue_17_status multivalue_handle]
    
    set multivalue_18_status [::ixiangpf::multivalue_config \
        -pattern                counter                                       \
        -nest_step              0.0.0.1,0.1.0.0                               \
        -counter_direction      increment                                     \
        -counter_step           0.1.0.0                                       \
        -nest_enabled           0,1                                           \
        -counter_start          103.1.0.0                                     \
        -nest_owner             $deviceGroup_2_handle,$topology_2_handle      \
    ]
    if {[keylget multivalue_18_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $multivalue_18_status
    }
    set multivalue_18_handle [keylget multivalue_18_status multivalue_handle]
    
    set multivalue_19_status [::ixiangpf::multivalue_config \
        -pattern                counter                                       \
        -nest_step              0.0.0.1,0.1.0.0                               \
        -counter_direction      increment                                     \
        -counter_step           0.1.0.0                                       \
        -nest_enabled           0,1                                           \
        -counter_start          103.1.0.0                                     \
        -nest_owner             $deviceGroup_2_handle,$topology_2_handle      \
    ]
    if {[keylget multivalue_19_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $multivalue_19_status
    }
    set multivalue_19_handle [keylget multivalue_19_status multivalue_handle]
    
    set multivalue_20_status [::ixiangpf::multivalue_config \
        -pattern                counter                                       \
        -nest_step              0.0.0.1,0.1.0.0                               \
        -counter_direction      increment                                     \
        -counter_step           0.1.0.0                                       \
        -nest_enabled           0,1                                           \
        -counter_start          104.1.0.0                                     \
        -nest_owner             $deviceGroup_2_handle,$topology_2_handle      \
    ]
    if {[keylget multivalue_20_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $multivalue_20_status
    }
    set multivalue_20_handle [keylget multivalue_20_status multivalue_handle]
    
    set multivalue_21_status [::ixiangpf::multivalue_config \
        -pattern                counter                                       \
        -nest_step              1,1                                           \
        -counter_direction      increment                                     \
        -counter_step           0                                             \
        -nest_enabled           0,0                                           \
        -counter_start          1                                             \
        -nest_owner             $deviceGroup_2_handle,$topology_2_handle      \
    ]
    if {[keylget multivalue_21_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $multivalue_21_status
    }
    set multivalue_21_handle [keylget multivalue_21_status multivalue_handle]
    
    set multivalue_22_status [::ixiangpf::multivalue_config \
        -pattern                counter                                       \
        -nest_step              0.0.0.1,0.1.0.0                               \
        -counter_direction      increment                                     \
        -counter_step           0.1.0.0                                       \
        -nest_enabled           0,1                                           \
        -counter_start          105.1.0.0                                     \
        -nest_owner             $deviceGroup_2_handle,$topology_2_handle      \
    ]
    if {[keylget multivalue_22_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $multivalue_22_status
    }
    set multivalue_22_handle [keylget multivalue_22_status multivalue_handle]
    
    set network_group_2_status [::ixiangpf::emulation_ospf_network_group_config \
        -summary_prefix                        16                         \
        -link_te_unresv_bw_priority4           0                          \
        -link_te_unresv_bw_priority6           0                          \
        -grid_col                              2                          \
        -handle                                $ospfv2_2_handle           \
        -nssa_metric                           0                          \
        -summary_metric                        0                          \
        -nssa_network_address                  $multivalue_22_handle      \
        -link_te_unresv_bw_priority5           0                          \
        -external2_prefix                      16                         \
        -link_te_unresv_bw_priority7           0                          \
        -link_te_unresv_bw_priority1           0                          \
        -link_te_unresv_bw_priority0           0                          \
        -link_te_unresv_bw_priority3           0                          \
        -link_te_unresv_bw_priority2           0                          \
        -type                                  grid                       \
        -from_ip                               $multivalue_15_handle      \
        -router_asbr                           0                          \
        -stub_prefix                           16                         \
        -stub_number_of_routes                 1                          \
        -nssa_active                           $multivalue_21_handle      \
        -external1_number_of_routes            1                          \
        -summary_active                        1                          \
        -summary_network_address               $multivalue_19_handle      \
        -external2_number_of_routes            1                          \
        -router_id                             $multivalue_14_handle      \
        -link_metric                           10                         \
        -subnet_prefix_length                  24                         \
        -to_ip                                 $multivalue_16_handle      \
        -external2_active                      1                          \
        -multiplier                            1                          \
        -external1_active                      1                          \
        -external1_network_address             $multivalue_17_handle      \
        -summary_number_of_routes              1                          \
        -external2_network_address             $multivalue_18_handle      \
        -active_router_id                      1                          \
        -grid_include_emulated_device          1                          \
        -nssa_prefix                           16                         \
        -link_te_max_resv_bw                   0                          \
        -nssa_number_of_routes                 1                          \
        -stub_network_address                  $multivalue_20_handle      \
        -router_abr                            0                          \
        -enable_advertise_as_stub_network      0                          \
        -external2_metric                      0                          \
        -external1_prefix                      16                         \
        -stub_active                           1                          \
        -link_te_administrator_group           0                          \
        -grid_link_multiplier                  1                          \
        -link_te_max_bw                        0                          \
        -stub_metric                           0                          \
        -grid_row                              2                          \
        -external1_metric                      0                          \
        -link_te                               0                          \
        -link_te_metric                        0                          \
    ]
    set ::NG2 $network_group_2_status

    if {[keylget network_group_2_status status] != $::SUCCESS} {
        $::ixnHLT_errorHandler [info script] $network_group_2_status
    }
    set networkGroup_2_handle [keylget network_group_2_status network_group_handle]
    set ixnHLT(HANDLE,//topology:<2>/deviceGroup:<1>/networkGroup:<1>) $networkGroup_2_handle
}

proc ixnHLT_RunTest {ixnHLTVarName} {
    upvar 1 $ixnHLTVarName ixnHLT
    $::ixnHLT_log "Waiting 5 seconds before starting protocol(s) .."
    after 5000

    parray ixnHLT

    catch {::ixiangpf::emulation_ospf_control\
        -handle $ixnHLT(HANDLE,//topology:<1>)\
        -mode start}

    catch {::ixiangpf::emulation_ospf_control\
        -handle $ixnHLT(HANDLE,//topology:<2>)\
        -mode start}

    $::ixnHLT_log {Waiting 60 after before starting protocol(s) ..}
    after 60000

    catch {::ixiangpf::emulation_ospf_info\
       -handle $ixnHLT(HANDLE,//topology:<1>/deviceGroup:<1>/ethernet:<1>/ipv4:<1>/ospfv2:<1>)\
       -mode learned_info} retVal1

    $::ixnHLT_log { with drawing  routes ...}

    #--------------------------------------------------------------------------#
    # external type 1                                                          #
    #--------------------------------------------------------------------------#
    set EX1 [keylget ::NG1 external1_handle]
    #- withdraw
    ::ixiangpf::emulation_ospf_control -handle $EX1 -mode withdraw
    #- advertise
    ::ixiangpf::emulation_ospf_control -handle $EX1 -mode advertise
    #--------------------------------------------------------------------------#
    catch {::ixiangpf::emulation_ospf_info\
       -handle $ixnHLT(HANDLE,//topology:<1>/deviceGroup:<1>/ethernet:<1>/ipv4:<1>/ospfv2:<1>)\
       -mode learned_info} retVal2

    #--------------------------------------------------------------------------#
    # external type 2                                                          #
    #--------------------------------------------------------------------------#
    set EX2 [keylget ::NG1 external2_handle]
    #- withdraw
    ::ixiangpf::emulation_ospf_control -handle $EX2 -mode withdraw
    #- advertise
    ::ixiangpf::emulation_ospf_control -handle $EX2 -mode advertise
    #--------------------------------------------------------------------------#

    #--------------------------------------------------------------------------#
    # summary route                                                            #
    #--------------------------------------------------------------------------#
    set S1 [keylget ::NG1 summary_handle]
    #- withdraw
    ::ixiangpf::emulation_ospf_control -handle $S1  -mode withdraw
    #- advertise                                          
    ::ixiangpf::emulation_ospf_control -handle $S1  -mode advertise
    #--------------------------------------------------------------------------#

    #--------------------------------------------------------------------------#
    # stub route                                                               #
    #--------------------------------------------------------------------------#
    #- withdraw
    set STUB1 [keylget ::NG1 stub_handle]
    ::ixiangpf::emulation_ospf_control -handle $STUB1 -mode withdraw
    #- advertise
    ::ixiangpf::emulation_ospf_control -handle $STUB1 -mode advertise
    #--------------------------------------------------------------------------#

    #--------------------------------------------------------------------------#
    # NSSA routes                                                              #
    #--------------------------------------------------------------------------#
    #- withdraw
    set NSSA [keylget ::NG1 nssa_handle]
    ::ixiangpf::emulation_ospf_control -handle $NSSA -mode withdraw
    #- advertise
    ::ixiangpf::emulation_ospf_control -handle $NSSA  -mode advertise
    #--------------------------------------------------------------------------#

    catch {::ixiangpf::emulation_ospf_info\
       -handle $ixnHLT(HANDLE,//topology:<1>/deviceGroup:<1>/ethernet:<1>/ipv4:<1>/ospfv2:<1>)\
       -mode learned_info} retVal2

    catch {::ixiangpf::emulation_ospf_control\
        -handle $ixnHLT(HANDLE,//topology:<1>)\
        -mode stop}

    catch {::ixiangpf::emulation_ospf_control\
        -handle $ixnHLT(HANDLE,//topology:<2>)\
        -mode stop}

    $::ixnHLT_log {packet_config_buffers stop sequence complete}
    set ::env(TEST_CASE_RETURN_VALUE) [list $retVal1 $retVal2]
}

if {[catch {package require Ixia} retCode]} {
    puts "FAIL - [info script] - $retCode"
    return 0
}

set test_name                   "OspfSampleScript"
set chassis_ip                  10.205.28.94
set tcl_server                  10.205.28.94
set ixnetwork_tcl_server        10.205.28.162:8074
set port_list                   [list 12/1 12/2]
set cfgErrors                   0
set vport_name_list {{{{Ethernet - 001}} {{Ethernet - 002}}}}

################################################################################
# Connect                                                                      #
################################################################################
set ::connect_status [::ixiangpf::connect                  \
        -reset                                           \
        -device                 $chassis_ip              \
        -port_list              $port_list               \
        -ixnetwork_tcl_server   $ixnetwork_tcl_server    \
        -tcl_server             $tcl_server              \
]


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

#set port_1 [keylget connect_status port_handle.$chassis_ip.[lindex $port_list 0]]
#set port_2 [keylget connect_status port_handle.$chassis_ip.[lindex $port_list 1]]
#set port_handle [list $port_1 $port_2]

#set ixnHLT(HANDLE,//vport:<1>) $port_1
#set ixnHLT(HANDLE,//vport:<2>) $port_2
ixnCPF_Configure ixnHLT
ixnHLT_RunTest   ixnHLT

