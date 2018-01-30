#################################################################################
# Version 1    $Revision: 3 $
# $Author: Abhijit Dhar $
#
#    Copyright © 1997 - 20134 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    08-15-2014 adhar@ixiacom.com - created sample
#
################################################################################

################################################################################
#                                                                              #
#                                LEGAL  NOTICE:                                #
#                                ==============                                #
# The following code and documentation (hereinafter "the script") is an        #
# example script for demonstration purposes only.                              #
# The script is not a standard commercial product offered by Ixia and have     #
# been developed and is being provided for use only as indicated herein. The   #
# script [and all modifications, enhancements and updates thereto (whether     #
# made by Ixia and/or by the user and/or by a third party)] shall at all times #
# remain the property of Ixia.                                                 #
#                                                                              #
# Ixia does not warrant (i) that the functions contained in the script will    #
# meet the user's requirements or (ii) that the script will be without         #
# omissions or error-free.                                                     #
# THE SCRIPT IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, AND IXIA        #
# DISCLAIMS ALL WARRANTIES, EXPRESS, IMPLIED, STATUTORY OR OTHERWISE,          #
# INCLUDING BUT NOT LIMITED TO ANY WARRANTY OF MERCHANTABILITY AND FITNESS FOR #
# A PARTICULAR PURPOSE OR OF NON-INFRINGEMENT.                                 #
# THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SCRIPT  IS WITH THE #
# USER.                                                                        #
# IN NO EVENT SHALL IXIA BE LIABLE FOR ANY DAMAGES RESULTING FROM OR ARISING   #
# OUT OF THE USE OF, OR THE INABILITY TO USE THE SCRIPT OR ANY PART THEREOF,   #
# INCLUDING BUT NOT LIMITED TO ANY LOST PROFITS, LOST BUSINESS, LOST OR        #
# DAMAGED DATA OR SOFTWARE OR ANY INDIRECT, INCIDENTAL, PUNITIVE OR            #
# CONSEQUENTIAL DAMAGES, EVEN IF IXIA HAS BEEN ADVISED OF THE POSSIBILITY OF   #
# SUCH DAMAGES IN ADVANCE.                                                     #
# Ixia will not be required to provide any software maintenance or support     #
# services of any kind (e.g., any error corrections) in connection with the    #
# script or any part thereof. The user acknowledges that although Ixia may     #
# from time to time and in its sole discretion provide maintenance or support  #
# services for the script, any such services are subject to the warranty and   #
# damages limitations set forth herein and will not obligate Ixia to provide   #
# any additional maintenance or support services.                              #
#                                                                              #
################################################################################
package require Ixia
################################################################################
# General script variables
################################################################################
set test_name [info script]

set chassis1  10.205.28.94
set card1     12
set port1     15

set chassis2  10.205.28.94
set card2     12
set port2     16

set client    10.205.28.37:8071
#-------------------------------------------------------------------------------
# initialize a global array
#-------------------------------------------------------------------------------
catch {unset ixnHLT}
array set ixnHLT {}

#-------------------------------------------------------------------------------
# proc for printing a keyedlist
#-------------------------------------------------------------------------------
proc keylprint {var_ref} {
    upvar 1 $var_ref var
    set level [expr [info level] - 1]
    foreach key [keylkeys var] {
        set indent [string repeat "    " $level]
        puts -nonewline $indent
        if {[catch {keylkeys var $key} catch_rval] ||\
            [llength $catch_rval] == 0} {
            puts "$key: [keylget var $key]"
            continue
        } else {
            puts $key
            puts "$indent[string repeat "-" [string length $key]]"
        }
        set rec_key [keylget var $key]
        keylprint rec_key
        puts ""
    }
}
#-------------------------------------------------------------------------------
# Configuration procedure
#------------------------------------------------------------------------------- 
proc configure_pim_v4_router {ixnHLTVarName} {
    upvar 1 $ixnHLTVarName ixnHLT
   
    #---------------------------------------------------------------------------
    # add topology 1
    #---------------------------------------------------------------------------    
    set topology_1_status [::ixiangpf::topology_config        \
        -topology_name      {Topology 1}                      \
        -port_handle        "$ixnHLT(PORT-HANDLE,//vport:<1>)"\
    ]
    if {[keylget topology_1_status status] != $::SUCCESS} {
        puts [info script] $topology_1_status
    }
    set topology_1_handle [keylget topology_1_status topology_handle]
    set ixnHLT(HANDLE,//topology:<1>) $topology_1_handle
   
    #---------------------------------------------------------------------------
    # add device group 1
    #--------------------------------------------------------------------------- 
    set device_group_1_status [::ixiangpf::topology_config\
        -topology_handle              $topology_1_handle  \
        -device_group_name            {Device Group 1}    \
        -device_group_multiplier      10                  \
        -device_group_enabled         1                   \
    ]
    if {[keylget device_group_1_status status] != $::SUCCESS} {
        puts [info script] $device_group_1_status
    }
    set deviceGroup_1_handle [keylget device_group_1_status device_group_handle]
    set ixnHLT(HANDLE,//topology:<1>/deviceGroup:<1>) $deviceGroup_1_handle
   
    #---------------------------------------------------------------------------
    # create an ethernet multivalue object
    #--------------------------------------------------------------------------- 
    set ethernet1_multivalue_status [::ixiangpf::multivalue_config \
        -pattern                counter                    \
        -counter_start          00.11.01.00.00.01          \
        -counter_step           00.00.00.00.00.01          \
        -counter_direction      increment                  \
        -nest_step              00.00.01.00.00.00          \
        -nest_owner             $topology_1_handle         \
        -nest_enabled           1                          \
    ]
    if {[keylget ethernet1_multivalue_status status] != $::SUCCESS} {
        puts [info script] $ethernet1_multivalue_status
    }
    set ethernet1_multivalue_handle [keylget ethernet1_multivalue_status\
        multivalue_handle]

    #---------------------------------------------------------------------------
    # create an ethernet stack ethernet_1
    #--------------------------------------------------------------------------- 
    set ethernet_1_status [::ixiangpf::interface_config           \
        -protocol_name                {Ethernet 1}                \
        -protocol_handle              $deviceGroup_1_handle       \
        -mtu                          1500                        \
        -src_mac_addr                 $ethernet1_multivalue_handle\
        -vlan                         0                           \
        -vlan_id                      1                           \
        -vlan_id_step                 0                           \
        -vlan_id_count                1                           \
        -vlan_tpid                    0x8100                      \
        -vlan_user_priority           0                           \
        -vlan_user_priority_step      0                           \
        -use_vpn_parameters           0                           \
        -site_id                      0                           \
    ]
    if {[keylget ethernet_1_status status] != $::SUCCESS} {
        puts [info script] $ethernet_1_status
    }
    set ethernet_1_handle [keylget ethernet_1_status ethernet_handle]
    set ixnHLT(HANDLE,//topology:<1>/deviceGroup:<1>/ethernet:<1>) $ethernet_1_handle

    #---------------------------------------------------------------------------
    # create an IPv4 gateway multivalue
    #--------------------------------------------------------------------------- 
    set ipv4_gateway1_multivalue_status [::ixiangpf::multivalue_config                                                              \
        -pattern                 single_value                                                                                       \
        -single_value            10.10.10.1                                                                                         \
        -nest_step               0.0.0.1                                                                                            \
        -nest_owner              $topology_1_handle                                                                                 \
        -nest_enabled            0                                                                                                  \
        -overlay_value           10.10.10.2,10.10.10.3,10.10.10.4,10.10.10.5,10.10.10.6,10.10.10.7,10.10.10.8,10.10.10.9,10.10.10.10\
        -overlay_value_step      10.10.10.2,10.10.10.3,10.10.10.4,10.10.10.5,10.10.10.6,10.10.10.7,10.10.10.8,10.10.10.9,10.10.10.10\
        -overlay_index           2,3,4,5,6,7,8,9,10                                                                                 \
        -overlay_index_step      0,0,0,0,0,0,0,0,0                                                                                  \
        -overlay_count           1,1,1,1,1,1,1,1,1                                                                                  \
    ]
    if {[keylget ipv4_gateway1_multivalue_status status] != $::SUCCESS} {
        puts [info script] $ipv4_gateway1_multivalue_status
    }
    set ipv4_gateway1_multivalue_handle [keylget ipv4_gateway1_multivalue_status multivalue_handle]
   
    #--------------------------------------------------------------------------- 
    # create an Ipv4 interface address multivalue
    #--------------------------------------------------------------------------- 
    set ipv4_intf_addr1_multivalue_status [::ixiangpf::multivalue_config                                                                             \
        -pattern                 single_value                                                                                                        \
        -single_value            10.10.10.101                                                                                                        \
        -nest_step               0.0.0.1                                                                                                             \
        -nest_owner              $topology_1_handle                                                                                                  \
        -nest_enabled            0                                                                                                                   \
        -overlay_value           10.10.10.102,10.10.10.103,10.10.10.104,10.10.10.105,10.10.10.106,10.10.10.107,10.10.10.108,10.10.10.109,10.10.10.110\
        -overlay_value_step      10.10.10.102,10.10.10.103,10.10.10.104,10.10.10.105,10.10.10.106,10.10.10.107,10.10.10.108,10.10.10.109,10.10.10.110\
        -overlay_index           2,3,4,5,6,7,8,9,10                                                                                                  \
        -overlay_index_step      0,0,0,0,0,0,0,0,0                                                                                                   \
        -overlay_count           1,1,1,1,1,1,1,1,1                                                                                                   \
    ]
    if {[keylget ipv4_intf_addr1_multivalue_status status] != $::SUCCESS} {
        puts [info script] $ipv4_intf_addr1_multivalue_status
    }
    set ipv4_intf_addr1_multivalue_handle [keylget ipv4_intf_addr1_multivalue_status multivalue_handle]
   
    #---------------------------------------------------------------------------
    # create an IPv4 interface Ipv4 interface 1
    #--------------------------------------------------------------------------- 
    set ipv4_1_status [::ixiangpf::interface_config                          \
        -protocol_name                     {IPv4 1}                          \
        -protocol_handle                   $ethernet_1_handle                \
        -ipv4_resolve_gateway              1                                 \
        -ipv4_manual_gateway_mac           00.00.00.00.00.01                 \
        -ipv4_manual_gateway_mac_step      00.00.00.00.00.00                 \
        -gateway                           $ipv4_intf_addr1_multivalue_handle\
        -intf_ip_addr                      $ipv4_gateway1_multivalue_handle  \
        -netmask                           255.255.255.0                     \
    ]
    if {[keylget ipv4_1_status status] != $::SUCCESS} {
        puts [info script] $ipv4_1_status
    }
    set ipv4_1_handle [keylget ipv4_1_status ipv4_handle]
    set ixnHLT(HANDLE,//topology:<1>/deviceGroup:<1>/ethernet:<1>/ipv4:<1>) $ipv4_1_handle

    #--------------------------------------------------------------------------
    # create an PIMv4 router + interface
    #--------------------------------------------------------------------------   
    set pim_v4_interface_1_status [::ixiangpf::emulation_pim_config\
        -mode                           create                     \
        -handle                         $ipv4_1_handle             \
        -ip_version                     4                          \
        -bootstrap_enable               1                          \
        -bootstrap_support_unicast      1                          \
        -bootstrap_hash_mask_len        30                         \
        -bootstrap_interval             60                         \
        -bootstrap_priority             64                         \
        -bootstrap_timeout              130                        \
        -learn_selected_rp_set          1                          \
        -discard_learnt_rp_info         0                          \
        -auto_pick_neighbor             1                          \
        -neighbor_intf_ip_addr          0.0.0.0                    \
        -bidir_capable                  0                          \
        -hello_interval                 30                         \
        -hello_holdtime                 105                        \
        -prune_delay_enable             0                          \
        -prune_delay                    500                        \
        -override_interval              2500                       \
        -generation_id_mode             constant                   \
        -prune_delay_tbit               0                          \
        -send_generation_id             1                          \
        -interface_name                 {PIMv4 IF 1}               \
        -interface_active               1                          \
        -triggered_hello_delay          5                          \
        -disable_triggered_hello        0                          \
        -force_semantic                 0                          \
        -join_prunes_count              1                          \
        -sources_count                  1                          \
        -crp_ranges_count               1                          \
    ]
    if {[keylget pim_v4_interface_1_status status] != $::SUCCESS} {
        puts [info script] $pim_v4_interface_1_status
    }

    #--------------------------------------------------------------------------
    # store the pim 4 interface handle in a global array
    #--------------------------------------------------------------------------
    set pimV4Interface_1_handle [keylget pim_v4_interface_1_status pim_v4_interface_handle]
    set ixnHLT(HANDLE,//topology:<1>/deviceGroup:<1>/ethernet:<1>/ipv4:<1>/pimV4Interface:<1>)\
        $pimV4Interface_1_handle
   
    #--------------------------------------------------------------------------
    # create an multivalue for ipv4 join/prune group address pool
    #-------------------------------------------------------------------------- 
    set ipv4_join_prune_group1_multivalue_status [::ixiangpf::multivalue_config                                           \
        -pattern                 single_value                                                                             \
        -single_value            225.0.0.0                                                                                \
        -nest_step               0.0.0.1                                                                                  \
        -nest_owner              $topology_1_handle                                                                       \
        -nest_enabled            0                                                                                        \
        -overlay_value           225.0.0.1,225.0.0.2,225.0.0.3,225.0.0.4,225.0.0.5,225.0.0.6,225.0.0.7,225.0.0.8,225.0.0.9\
        -overlay_value_step      225.0.0.1,225.0.0.2,225.0.0.3,225.0.0.4,225.0.0.5,225.0.0.6,225.0.0.7,225.0.0.8,225.0.0.9\
        -overlay_index           2,3,4,5,6,7,8,9,10                                                                       \
        -overlay_index_step      0,0,0,0,0,0,0,0,0                                                                        \
        -overlay_count           1,1,1,1,1,1,1,1,1                                                                        \
    ]
    if {[keylget ipv4_join_prune_group1_multivalue_status status] != $::SUCCESS} {
        puts [info script] $ipv4_join_prune_group1_multivalue_status
    }
    set ipv4_join_prune_group1_multivalue_handle [keylget ipv4_join_prune_group1_multivalue_status\
         multivalue_handle]
   
    #---------------------------------------------------------------------------
    # create ipv4 pim join/prune group address pool
    #--------------------------------------------------------------------------- 
    set pim_v4_join_prune_list_1_status [::ixiangpf::emulation_multicast_group_config\
        -mode               create                                                   \
        -ip_addr_start      $ipv4_join_prune_group1_multivalue_handle                \
        -num_groups         1                                                        \
        -active             1                                                        \
    ]
    if {[keylget pim_v4_join_prune_list_1_status status] != $::SUCCESS} {
        puts [info script] $pim_v4_join_prune_list_1_status
    }
    #--------------------------------------------------------------------------
    # store the pim join/prune group address pool handle in a global array
    #--------------------------------------------------------------------------
    set pimV4JoinPruneList_1_handle [keylget pim_v4_join_prune_list_1_status multicast_group_handle]
    set ixnHLT(HANDLE,//topology:<1>/deviceGroup:<1>/ethernet:<1>/ipv4:<1>/pimV4Interface:<1>/pimV4JoinPruneList)\
        $pimV4JoinPruneList_1_handle
   
    #--------------------------------------------------------------------------
    # create an multivalue for ipv4 pim source address pool
    #--------------------------------------------------------------------------
    set pim_v4_join_prune_source1_status [::ixiangpf::multivalue_config                                                        \
        -pattern            single_value                                                                                       \
        -single_value       10.10.10.1                                                                                         \
        -nest_step          0.0.0.1                                                                                            \
        -nest_owner         $topology_1_handle                                                                                 \
        -nest_enabled       0                                                                                                  \
        -overlay_value      10.10.10.2,10.10.10.3,10.10.10.4,10.10.10.5,10.10.10.6,10.10.10.7,10.10.10.8,10.10.10.9,10.10.10.10\
        -overlay_value_step 10.10.10.2,10.10.10.3,10.10.10.4,10.10.10.5,10.10.10.6,10.10.10.7,10.10.10.8,10.10.10.9,10.10.10.10\
        -overlay_index      2,3,4,5,6,7,8,9,10                                                                                 \
        -overlay_index_step 0,0,0,0,0,0,0,0,0                                                                                  \
        -overlay_count      1,1,1,1,1,1,1,1,1                                                                                  \
    ]
    if {[keylget pim_v4_join_prune_source1_status status] != $::SUCCESS} {
        puts [info script] $pim_v4_join_prune_source1_status
    }
    set pim_v4_join_prune_source1_handle [keylget pim_v4_join_prune_source1_status multivalue_handle]
   
    #--------------------------------------------------------------------------
    # create ipv4 pim source address pool
    #--------------------------------------------------------------------------
    set pim_v4_sources_list_1_status [::ixiangpf::emulation_multicast_source_config\
        -mode               create                                                 \
        -ip_addr_start      $pim_v4_join_prune_source1_handle                      \
        -num_sources        1                                                      \
        -active             1                                                      \
    ]
    if {[keylget pim_v4_sources_list_1_status status] != $::SUCCESS} {
        puts [info script] $pim_v4_sources_list_1_status
    }
    #--------------------------------------------------------------------------
    # store the pim join/prune source address pool handle in a global array
    #--------------------------------------------------------------------------
    set pimV4SourcesList_1_handle [keylget pim_v4_sources_list_1_status multicast_source_handle]
    set ixnHLT(HANDLE,//topology:<1>/deviceGroup:<1>/ethernet:<1>/ipv4:<1>/pimV4Interface:<1>/pimV4SourcesList)\
        $pimV4SourcesList_1_handle
    
    #--------------------------------------------------------------------------
    # create ipv4 pim join prune range
    #-------------------------------------------------------------------------- 
    set pim_v4_join_prune_list_1_status [::ixiangpf::emulation_pim_group_config\
        -mode                          create                                  \
        -session_handle                $pimV4Interface_1_handle                \
        -group_pool_handle             $pimV4JoinPruneList_1_handle            \
        -source_pool_handle            $pimV4SourcesList_1_handle              \
        -rp_ip_addr                    10.10.10.101                            \
        -group_pool_mode               send                                    \
        -join_prune_aggregation_factor 1                                       \
        -flap_interval                 60                                      \
        -register_stop_trigger_count   10                                      \
        -source_group_mapping          fully_meshed                            \
        -switch_over_interval          5                                       \
        -group_range_type              startogroup                             \
        -enable_flap_info              false                                   \
    ]
    if {[keylget pim_v4_join_prune_list_1_status status] != $::SUCCESS} {
        puts [info script] $pim_v4_join_prune_list_1_status
    }
   
    #---------------------------------------------------------------------------
    # create ipv4 pim candidate rp range
    #--------------------------------------------------------------------------- 
    set pim_v4_candidate_r_ps_list_1_status [::ixiangpf::emulation_pim_group_config\
        -mode                       create                                         \
        -session_handle             $pimV4Interface_1_handle                       \
        -group_pool_handle          $pimV4JoinPruneList_1_handle                   \
        -source_pool_handle         $pimV4SourcesList_1_handle                     \
        -adv_hold_time              150                                            \
        -back_off_interval          3                                              \
        -crp_ip_addr                0.0.0.1                                        \
        -group_pool_mode            candidate_rp                                   \
        -periodic_adv_interval      60                                             \
        -pri_change_interval        60                                             \
        -pri_type                   same                                           \
        -pri_value                  192                                            \
        -router_count               1                                              \
        -source_group_mapping       fully_meshed                                   \
        -trigger_crp_msg_count      3                                              \
    ]
    if {[keylget pim_v4_candidate_r_ps_list_1_status status] != $::SUCCESS} {
        puts [info script] $pim_v4_candidate_r_ps_list_1_status
    }
   
    #---------------------------------------------------------------------------
    # create ipv4 pim source range
    #--------------------------------------------------------------------------- 
    set pim_v4_sources_list_1_status [::ixiangpf::emulation_pim_group_config\
        -mode                               create                          \
        -session_handle                     $pimV4Interface_1_handle        \
        -group_pool_handle                  $pimV4JoinPruneList_1_handle    \
        -source_pool_handle                 $pimV4SourcesList_1_handle      \
        -rp_ip_addr                         0.0.0.0                         \
        -group_pool_mode                    register                        \
        -register_tx_iteration_gap          60000                           \
        -register_udp_destination_port      3000                            \
        -register_udp_source_port           3000                            \
        -switch_over_interval               0                               \
        -send_null_register                 0                               \
        -discard_sg_join_states             true                            \
        -multicast_data_length              64                              \
        -supression_time                    60                              \
        -register_probe_time                5                               \
    ]
    if {[keylget pim_v4_sources_list_1_status status] != $::SUCCESS} {
        puts [info script] $pim_v4_sources_list_1_status
    }
   
    #---------------------------------------------------------------------------
    # add topology 2
    #--------------------------------------------------------------------------- 
    set topology_2_status [::ixiangpf::topology_config        \
        -topology_name      {Topology 2}                      \
        -port_handle        "$ixnHLT(PORT-HANDLE,//vport:<2>)"\
    ]
    if {[keylget topology_2_status status] != $::SUCCESS} {
        puts [info script] $topology_2_status
    }

    #---------------------------------------------------------------------------
    # store topology 2 handle in a global array
    #---------------------------------------------------------------------------
    set topology_2_handle [keylget topology_2_status topology_handle]
    set ixnHLT(HANDLE,//topology:<2>) $topology_2_handle
   
    #---------------------------------------------------------------------------
    # add device group 2
    #--------------------------------------------------------------------------- 
    set device_group_2_status [::ixiangpf::topology_config\
        -topology_handle              $topology_2_handle  \
        -device_group_name            {Device Group 2}    \
        -device_group_multiplier      10                  \
        -device_group_enabled         1                   \
    ]
    if {[keylget device_group_2_status status] != $::SUCCESS} {
        puts [info script] $device_group_2_status
    }

    #---------------------------------------------------------------------------
    # store device group 2 in a global array
    #--------------------------------------------------------------------------- 
    set deviceGroup_2_handle [keylget device_group_2_status device_group_handle]
    set ixnHLT(HANDLE,//topology:<2>/deviceGroup:<1>) $deviceGroup_2_handle

    #---------------------------------------------------------------------------
    # create an ethernet multivalue object
    #--------------------------------------------------------------------------- 
    set ethernet2_multivalue_status [::ixiangpf::multivalue_config\
        -pattern           counter                                \
        -counter_start     00.12.01.00.00.01                      \
        -counter_step      00.00.00.00.00.01                      \
        -counter_direction increment                              \
        -nest_step         00.00.01.00.00.00                      \
        -nest_owner        $topology_2_handle                     \
        -nest_enabled      1                                      \
    ]
    if {[keylget ethernet2_multivalue_status status] != $::SUCCESS} {
        puts [info script] $ethernet2_multivalue_status
    }
    set ethernet2_multivalue_handle [keylget ethernet2_multivalue_status multivalue_handle]

    #---------------------------------------------------------------------------
    # create another ethernet stack
    #---------------------------------------------------------------------------    
    set ethernet_2_status [::ixiangpf::interface_config      \
        -protocol_name           {Ethernet 2}                \
        -protocol_handle         $deviceGroup_2_handle       \
        -mtu                     1500                        \
        -src_mac_addr            $ethernet2_multivalue_handle\
        -vlan                    0                           \
        -vlan_id                 1                           \
        -vlan_id_step            0                           \
        -vlan_id_count           1                           \
        -vlan_tpid               0x8100                      \
        -vlan_user_priority      0                           \
        -vlan_user_priority_step 0                           \
        -use_vpn_parameters      0                           \
        -site_id                 0                           \
    ]
    if {[keylget ethernet_2_status status] != $::SUCCESS} {
        puts [info script] $ethernet_2_status
    }

    #---------------------------------------------------------------------------
    # store the ethernet stack handle in a golbal array
    #--------------------------------------------------------------------------- 
    set ethernet_2_handle [keylget ethernet_2_status ethernet_handle]
    set ixnHLT(HANDLE,//topology:<2>/deviceGroup:<1>/ethernet:<1>) $ethernet_2_handle
   
    #---------------------------------------------------------------------------
    # create an IPv4 interface multivalue
    #--------------------------------------------------------------------------- 
    set ipv4_intf_addr2_multivalue_status [::ixiangpf::multivalue_config \
        -pattern            single_value                                                                                                        \
        -single_value       10.10.10.101                                                                                                        \
        -nest_step          0.0.0.1                                                                                                             \
        -nest_owner         $topology_2_handle                                                                                                  \
        -nest_enabled       0                                                                                                                   \
        -overlay_value      10.10.10.102,10.10.10.103,10.10.10.104,10.10.10.105,10.10.10.106,10.10.10.107,10.10.10.108,10.10.10.109,10.10.10.110\
        -overlay_value_step 10.10.10.102,10.10.10.103,10.10.10.104,10.10.10.105,10.10.10.106,10.10.10.107,10.10.10.108,10.10.10.109,10.10.10.110\
        -overlay_index      2,3,4,5,6,7,8,9,10                                                                                                  \
        -overlay_index_step 0,0,0,0,0,0,0,0,0                                                                                                   \
        -overlay_count      1,1,1,1,1,1,1,1,1                                                                                                   \
    ]
    if {[keylget ipv4_intf_addr2_multivalue_status status] != $::SUCCESS} {
        puts [info script] $ipv4_intf_addr2_multivalue_status
    }
    set ipv4_intf_addr2_multivalue_handle [keylget ipv4_intf_addr2_multivalue_status multivalue_handle]
   
    #---------------------------------------------------------------------------
    # create an IPv4 gateway multivalue
    #--------------------------------------------------------------------------- 
    set ipv4_gateway1_multivalue_status [::ixiangpf::multivalue_config                                                              \
        -pattern                 single_value                                                                                       \
        -single_value            10.10.10.1                                                                                         \
        -nest_step               0.0.0.1                                                                                            \
        -nest_owner              $topology_2_handle                                                                                 \
        -nest_enabled            0                                                                                                  \
        -overlay_value           10.10.10.2,10.10.10.3,10.10.10.4,10.10.10.5,10.10.10.6,10.10.10.7,10.10.10.8,10.10.10.9,10.10.10.10\
        -overlay_value_step      10.10.10.2,10.10.10.3,10.10.10.4,10.10.10.5,10.10.10.6,10.10.10.7,10.10.10.8,10.10.10.9,10.10.10.10\
        -overlay_index           2,3,4,5,6,7,8,9,10                                                                                 \
        -overlay_index_step      0,0,0,0,0,0,0,0,0                                                                                  \
        -overlay_count           1,1,1,1,1,1,1,1,1                                                                                  \
    ]
    if {[keylget ipv4_gateway1_multivalue_status status] != $::SUCCESS} {
        puts [info script] $ipv4_gateway1_multivalue_status
    }
    set ipv4_gateway1_multivalue_handle [keylget ipv4_gateway1_multivalue_status multivalue_handle]
   
    #---------------------------------------------------------------------------
    # add another IPv4 stack 
    #---------------------------------------------------------------------------
    set ipv4_2_status [::ixiangpf::interface_config                     \
        -protocol_name                {IPv4 2}                          \
        -protocol_handle              $ethernet_2_handle                \
        -ipv4_resolve_gateway         1                                 \
        -ipv4_manual_gateway_mac      00.00.00.00.00.01                 \
        -ipv4_manual_gateway_mac_step 00.00.00.00.00.00                 \
        -gateway                      $ipv4_gateway1_multivalue_handle  \
        -intf_ip_addr                 $ipv4_intf_addr2_multivalue_handle\
        -netmask                      255.255.255.0                     \
    ]
    if {[keylget ipv4_2_status status] != $::SUCCESS} {
        puts [info script] $ipv4_2_status
    }

    #---------------------------------------------------------------------------
    # store the ipv4 stack handle in a global array
    #---------------------------------------------------------------------------
    set ipv4_2_handle [keylget ipv4_2_status ipv4_handle]
    set ixnHLT(HANDLE,//topology:<2>/deviceGroup:<1>/ethernet:<1>/ipv4:<1>)\
        $ipv4_2_handle
   
    #---------------------------------------------------------------------------
    # add another pimv4 router and interface
    #---------------------------------------------------------------------------
    set pim_v4_interface_2_status [::ixiangpf::emulation_pim_config \
        -mode                           create              \
        -handle                         $ipv4_2_handle      \
        -ip_version                     4                   \
        -bootstrap_enable               1                   \
        -bootstrap_support_unicast      1                   \
        -bootstrap_hash_mask_len        30                  \
        -bootstrap_interval             60                  \
        -bootstrap_priority             20                  \
        -bootstrap_timeout              130                 \
        -learn_selected_rp_set          1                   \
        -discard_learnt_rp_info         0                   \
        -auto_pick_neighbor             1                   \
        -neighbor_intf_ip_addr          0.0.0.0             \
        -bidir_capable                  0                   \
        -hello_interval                 30                  \
        -hello_holdtime                 105                 \
        -prune_delay_enable             0                   \
        -prune_delay                    500                 \
        -override_interval              2500                \
        -generation_id_mode             constant            \
        -prune_delay_tbit               0                   \
        -send_generation_id             1                   \
        -interface_name                 {PIMv4 IF 2}        \
        -interface_active               1                   \
        -triggered_hello_delay          5                   \
        -disable_triggered_hello        0                   \
        -force_semantic                 0                   \
        -join_prunes_count              1                   \
        -sources_count                  1                   \
        -crp_ranges_count               1                   \
    ]
    if {[keylget pim_v4_interface_2_status status] != $::SUCCESS} {
        puts [info script] $pim_v4_interface_2_status
    }
 
    #---------------------------------------------------------------------------
    # store pimv4 router/interface handle in a global array
    #---------------------------------------------------------------------------
    set pimV4Interface_2_handle [keylget pim_v4_interface_2_status pim_v4_interface_handle]
    set ixnHLT(HANDLE,//topology:<2>/deviceGroup:<1>/ethernet:<1>/ipv4:<1>/pimV4Interface:<1>)\
        $pimV4Interface_2_handle
   
    #--------------------------------------------------------------------------
    # create an multivalue for ipv4 join prune group pool
    #--------------------------------------------------------------------------
    set ipv4_join_prune_group2_multivalue_status [::ixiangpf::multivalue_config \
        -pattern                 single_value                                                                             \
        -single_value            226.0.0.0                                                                                \
        -nest_step               0.0.0.1                                                                                  \
        -nest_owner              $topology_2_handle                                                                       \
        -nest_enabled            0                                                                                        \
        -overlay_value           226.0.0.1,226.0.0.2,226.0.0.3,226.0.0.4,226.0.0.5,226.0.0.6,226.0.0.7,226.0.0.8,226.0.0.9\
        -overlay_value_step      226.0.0.1,226.0.0.2,226.0.0.3,226.0.0.4,226.0.0.5,226.0.0.6,226.0.0.7,226.0.0.8,226.0.0.9\
        -overlay_index           2,3,4,5,6,7,8,9,10                                                                       \
        -overlay_index_step      0,0,0,0,0,0,0,0,0                                                                        \
        -overlay_count           1,1,1,1,1,1,1,1,1                                                                        \
    ]
    if {[keylget ipv4_join_prune_group2_multivalue_status status] != $::SUCCESS} {
        puts [info script] $ipv4_join_prune_group2_multivalue_status
    }
    set ipv4_join_prune_group2_multivalue_handle [keylget ipv4_join_prune_group2_multivalue_status multivalue_handle]
   
    #---------------------------------------------------------------------------
    # create an pim v4 join prune object
    #--------------------------------------------------------------------------- 
    set pim_v4_join_prune_list_2_status [::ixiangpf::emulation_multicast_group_config\
        -mode               create                                                   \
        -ip_addr_start      $ipv4_join_prune_group2_multivalue_handle                \
        -num_groups         1                                                        \
        -active             1                                                        \
    ]
    if {[keylget pim_v4_join_prune_list_2_status status] != $::SUCCESS} {
        puts [info script] $pim_v4_join_prune_list_2_status
    }
    #---------------------------------------------------------------------------
    # store pim v4 join prune object in a global array
    #---------------------------------------------------------------------------
    set pimV4JoinPruneList_2_handle [keylget pim_v4_join_prune_list_2_status multicast_group_handle]
    set ixnHLT(HANDLE,//topology:<2>/deviceGroup:<1>/ethernet:<1>/ipv4:<1>/pimV4Interface:<1>/pimV4JoinPruneList)\
        $pimV4JoinPruneList_2_handle
   
    #--------------------------------------------------------------------------
    # create an multivalue for pim v4 source address
    #-------------------------------------------------------------------------- 
    set pim_v4_source_address_multivalue_status [::ixiangpf::multivalue_config                                                                  \
        -pattern            single_value                                                                                                        \
        -single_value       10.10.10.101                                                                                                        \
        -nest_step          0.0.0.1                                                                                                             \
        -nest_owner         $topology_2_handle                                                                                                  \
        -nest_enabled       0                                                                                                                   \
        -overlay_value      10.10.10.102,10.10.10.103,10.10.10.104,10.10.10.105,10.10.10.106,10.10.10.107,10.10.10.108,10.10.10.109,10.10.10.110\
        -overlay_value_step 10.10.10.102,10.10.10.103,10.10.10.104,10.10.10.105,10.10.10.106,10.10.10.107,10.10.10.108,10.10.10.109,10.10.10.110\
        -overlay_index      2,3,4,5,6,7,8,9,10                                                                                                  \
        -overlay_index_step 0,0,0,0,0,0,0,0,0                                                                                                   \
        -overlay_count      1,1,1,1,1,1,1,1,1                                                                                                   \
    ]
    if {[keylget pim_v4_source_address_multivalue_status status] != $::SUCCESS} {
        puts [info script] $pim_v4_source_address_multivalue_status
    }
    set pim_v4_source_address_multivalue_handle [keylget pim_v4_source_address_multivalue_status multivalue_handle]
   
    #---------------------------------------------------------------------------
    # create a pim v4 source object
    #--------------------------------------------------------------------------- 
    set pim_v4_sources_list_2_status [::ixiangpf::emulation_multicast_source_config\
        -mode               create                                                 \
        -ip_addr_start      $pim_v4_source_address_multivalue_handle               \
        -num_sources        1                                                      \
        -active             1                                                      \
    ]
    if {[keylget pim_v4_sources_list_2_status status] != $::SUCCESS} {
        puts [info script] $pim_v4_sources_list_2_status
    }
    #---------------------------------------------------------------------------
    # store pim v4 join prune object handle in a global array
    #---------------------------------------------------------------------------
    set pimV4SourcesList_2_handle [keylget pim_v4_sources_list_2_status multicast_source_handle]
    set ixnHLT(HANDLE,//topology:<2>/deviceGroup:<1>/ethernet:<1>/ipv4:<1>/pimV4Interface:<1>/pimV4SourcesList)\
         $pimV4SourcesList_2_handle
    
    #---------------------------------------------------------------------------
    # create a pim v4 rp-address multivalue
    #--------------------------------------------------------------------------- 
    set pim_v4_rp_multivalue_status [::ixiangpf::multivalue_config                                                                  \
        -pattern                 single_value                                                                                       \
        -single_value            10.10.10.1                                                                                         \
        -nest_step               0.0.0.1                                                                                            \
        -nest_owner              $topology_2_handle                                                                                 \
        -nest_enabled            0                                                                                                  \
        -overlay_value           10.10.10.2,10.10.10.3,10.10.10.4,10.10.10.5,10.10.10.6,10.10.10.7,10.10.10.8,10.10.10.9,10.10.10.10\
        -overlay_value_step      10.10.10.2,10.10.10.3,10.10.10.4,10.10.10.5,10.10.10.6,10.10.10.7,10.10.10.8,10.10.10.9,10.10.10.10\
        -overlay_index           2,3,4,5,6,7,8,9,10                                                                                 \
        -overlay_index_step      0,0,0,0,0,0,0,0,0                                                                                  \
        -overlay_count           1,1,1,1,1,1,1,1,1                                                                                  \
    ]
    if {[keylget pim_v4_rp_multivalue_status status] != $::SUCCESS} {
        puts [info script] $pim_v4_rp_multivalue_status
    }
    set pim_v4_rp_multivalue_handle [keylget pim_v4_rp_multivalue_status multivalue_handle]
   
    #---------------------------------------------------------------------------
    # add pim v4 join prune group range
    #--------------------------------------------------------------------------- 
    set pim_v4_join_prune_list_2_status [::ixiangpf::emulation_pim_group_config\
        -mode                          create                                  \
        -session_handle                $pimV4Interface_2_handle                \
        -group_pool_handle             $pimV4JoinPruneList_2_handle            \
        -source_pool_handle            $pimV4SourcesList_2_handle              \
        -rp_ip_addr                    $pim_v4_rp_multivalue_handle            \
        -group_pool_mode               send                                    \
        -join_prune_aggregation_factor 1                                       \
        -flap_interval                 60                                      \
        -register_stop_trigger_count   10                                      \
        -source_group_mapping          fully_meshed                            \
        -switch_over_interval          5                                       \
        -group_range_type              startogroup                             \
        -enable_flap_info              false                                   \
    ]
    if {[keylget pim_v4_join_prune_list_2_status status] != $::SUCCESS} {
        puts [info script] $pim_v4_join_prune_list_2_status
    }
   
    #---------------------------------------------------------------------------
    # add pim v4 join candidate rp range
    #--------------------------------------------------------------------------- 
    set pim_v4_candidate_r_ps_list_2_status [::ixiangpf::emulation_pim_group_config\
        -mode                  create                                              \
        -session_handle        $pimV4Interface_2_handle                            \
        -group_pool_handle     $pimV4JoinPruneList_2_handle                        \
        -source_pool_handle    $pimV4SourcesList_2_handle                          \
        -adv_hold_time         150                                                 \
        -back_off_interval     3                                                   \
        -crp_ip_addr           0.0.0.1                                             \
        -group_pool_mode       candidate_rp                                        \
        -periodic_adv_interval 60                                                  \
        -pri_change_interval   60                                                  \
        -pri_type              same                                                \
        -pri_value             192                                                 \
        -router_count          1                                                   \
        -source_group_mapping  fully_meshed                                        \
        -trigger_crp_msg_count 3                                                   \
    ]
    if {[keylget pim_v4_candidate_r_ps_list_2_status status] != $::SUCCESS} {
        puts [info script] $pim_v4_candidate_r_ps_list_2_status
    }
   
    #---------------------------------------------------------------------------
    # add pim v4 join source range
    #---------------------------------------------------------------------------
    set pim_v4_sources_list_2_status [::ixiangpf::emulation_pim_group_config\
        -mode                          create                               \
        -session_handle                $pimV4Interface_2_handle             \
        -group_pool_handle             $pimV4JoinPruneList_2_handle         \
        -source_pool_handle            $pimV4SourcesList_2_handle           \
        -rp_ip_addr                    0.0.0.0                              \
        -group_pool_mode               register                             \
        -register_tx_iteration_gap     60000                                \
        -register_udp_destination_port 3000                                 \
        -register_udp_source_port      3000                                 \
        -switch_over_interval          0                                    \
        -send_null_register            0                                    \
        -discard_sg_join_states        true                                 \
        -multicast_data_length         64                                   \
        -supression_time               60                                   \
        -register_probe_time           5                                    \
    ]
    if {[keylget pim_v4_sources_list_2_status status] != $::SUCCESS} {
        puts [info script] $pim_v4_sources_list_2_status
    }
}

proc execute_pim_v4_test {ixnHLTVarName} {
    upvar 1 $ixnHLTVarName ixnHLT
    
    puts {Waiting 5 seconds before starting protocol(s) ...}
    after 5000

    #--------------------------------------------------------------------------
    # start phase of the test
    #--------------------------------------------------------------------------
    puts {Starting all protocol(s) ...}
    set r [::ixia::test_control -action start_all_protocols]
    if {[keylget r status] != $::SUCCESS} {
        puts [info script] $r
    }
   
    puts {protocol started waiting for 30 seconds} 
    after 30000

    set pim_linfo [::ixiangpf::emulation_pim_info \
        -handle $ixnHLT(HANDLE,//topology:<1>/deviceGroup:<1>/ethernet:<1>/ipv4:<1>/pimV4Interface:<1>)\
        -mode learned_crp]
    puts $pim_linfo

    keylprint pim_linfo
 
    set pim_stat [::ixiangpf::emulation_pim_info \
        -handle $ixnHLT(HANDLE,//topology:<1>/deviceGroup:<1>)\
        -mode  stats_per_device_group]

    keylprint pim_stat
                    
    #--------------------------------------------------------------------------
    # stop all protocol
    #--------------------------------------------------------------------------
    puts {Stopping all protocol(s) ...}
    set r [::ixia::test_control -action stop_all_protocols]
    if {[keylget r status] != $::SUCCESS} {
        puts [info script] $r
    }
}

#------------------------------------------------------------------------------
# create port-list, initialize, vport names etc. 
#------------------------------------------------------------------------------
set chassis           $chassis1
set port_list         [list [list $card1/$port1 $card2/$port2]]
set ixnHLT(path_list) {{//vport:<1> //vport:<2>}}
set vport_name_list   [list [list "Port1" "Port2"]]

#------------------------------------------------------------------------------
# connect to chassis
#------------------------------------------------------------------------------
set _result_ [::ixiangpf::connect   \
    -reset                1         \
    -device               $chassis  \
    -port_list            $port_list\
    -ixnetwork_tcl_server $client   \
    -tcl_server           $chassis  \
]

#-------------------------------------------------------------------------------
# Check connection status
#-------------------------------------------------------------------------------
if {[keylget _result_ status] != $::SUCCESS} {
  puts [info script] $_result_
}

#-------------------------------------------------------------------------------
# 1. populate ixnHLT array
# 2. extract vport_info
#-------------------------------------------------------------------------------
foreach {port_list_elem} $port_list        \
        {name_list_elem} $vport_name_list  \
        {path_list_elem} $ixnHLT(path_list)\
        {chassis_elem}   $chassis {

    set ch_vport_list [list]
    foreach {port} $port_list_elem {path} $path_list_elem {
        if {[catch {keylget _result_ port_handle.$chassis_elem.$port} _port_handle]} {
            error "connection status: $_result_: $_port_handle"
        }
        set ixnHLT(PORT-HANDLE,$path) $_port_handle
        lappend ch_vport_list $_port_handle
    }

    set vpinfo_rval [::ixia::vport_info\
        -mode set_info                 \
        -port_list $ch_vport_list      \
        -port_name_list $name_list_elem\
    ]
    if {[keylget vpinfo_rval status] != $::SUCCESS} {
        puts [info script] $vpinfo_rval
    }
}
#-------------------------------------------------------------------------------
# configure pim
#-------------------------------------------------------------------------------
configure_pim_v4_router ixnHLT
#-------------------------------------------------------------------------------
# execute pim get learned info and stats
#-------------------------------------------------------------------------------
execute_pim_v4_test ixnHLT
