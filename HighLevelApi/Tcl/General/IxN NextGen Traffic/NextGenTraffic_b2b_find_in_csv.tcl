################################################################################
# Version 1.0    $Revision: 1 $
# $Author: Eduard Tutescu $
#
#    Copyright � 1997 - 2012 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    12-12-2012   Eduard Tutescu 
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
###############################################################################

################################################################################
#                                                                              #
# Description:                                                                 #
# This script creates a traffic item and runs traffic between 2 ports. It      #
# prints flow stats after filtering them through the use of the find_in_csv    #
# procedure.                                                                   #
# Module:                                                                      #
#    The sample was tested on an STXS4 module.                                 #
#                                                                              #
################################################################################

set env(IXIA_VERSION) HLTSET134
package require Ixia

set test_name                   [info script]
set chassis_ip                  10.205.16.98
set tcl_server                  10.205.16.98
set ixnetwork_tcl_server        localhost
set port_list                   [list 7/1 7/2]
set cfgErrors                   0

set connect_status [::ixia::connect                      \
        -reset                                           \
        -device                 $chassis_ip              \
        -port_list              $port_list               \
        -ixnetwork_tcl_server   $ixnetwork_tcl_server    \
        -tcl_server             $tcl_server              \
        ]
if {[keylget connect_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget connect_status log]"
}

set port_handle [list]
foreach port $port_list {
    if {![catch {keylget connect_status port_handle.$chassis_ip.$port} temp_port]} {
        lappend port_handle $temp_port
    }
}

set port_src_handle [lindex $port_handle 0]
set port_dst_handle [lindex $port_handle 1]

puts "Ixia port handles are $port_handle ..."

################################################################################
# Configure Protocol Interfaces on both ports                                  #
################################################################################
set interface_status [::ixia::interface_config  \
    -mode                   config              \
    -port_handle            $port_src_handle    \
    -transmit_clock_source  external            \
    -internal_ppm_adjust    0                   \
    -data_integrity         1                   \
    -intf_mode              ethernet            \
    -speed                  ether100            \
    -duplex                 full                \
    -autonegotiation        1                   \
    -phy_mode               copper              \
    -transmit_mode          advanced            \
    -port_rx_mode           capture_and_measure \
    -tx_gap_control_mode    fixed               \
]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}
set _result_ [::ixia::interface_config          \
    -mode                   config              \
    -port_handle            $port_dst_handle    \
    -transmit_clock_source  external            \
    -internal_ppm_adjust    0                   \
    -data_integrity         1                   \
    -intf_mode              ethernet            \
    -speed                  ether100            \
    -duplex                 full                \
    -autonegotiation        1                   \
    -phy_mode               copper              \
    -transmit_mode          advanced            \
    -port_rx_mode           capture_and_measure \
    -tx_gap_control_mode    fixed               \
]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}
set _result_ [::ixia::interface_config              \
    -mode                       modify              \
    -port_handle                $port_src_handle    \
    -vlan                       0                   \
    -l23_config_type            protocol_interface  \
    -mtu                        1500                \
    -gateway                    20.0.0.1            \
    -intf_ip_addr               20.0.0.2            \
    -netmask                    255.255.255.0       \
    -check_opposite_ip_version  0                   \
    -src_mac_addr               0000.0107.4232      \
    -arp_on_linkup              0                   \
    -ns_on_linkup               0                   \
    -single_arp_per_gateway     1                   \
    -single_ns_per_gateway      1                   \
]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}
set _result_ [::ixia::interface_config              \
    -mode                       modify              \
    -port_handle                $port_dst_handle    \
    -vlan                       0                   \
    -l23_config_type            protocol_interface  \
    -mtu                        1500                \
    -gateway                    20.0.0.2            \
    -intf_ip_addr               20.0.0.1            \
    -netmask                    255.255.255.0       \
    -check_opposite_ip_version  0                   \
    -src_mac_addr               0000.0107.4233      \
    -arp_on_linkup              0                   \
    -ns_on_linkup               0                   \
    -single_arp_per_gateway     1                   \
    -single_ns_per_gateway      1                   \
]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}
################################################################################
# Configure Traffic on ports                                                   #
################################################################################
puts "Configure Traffic..."
set traffic_status [::ixia::traffic_control             \
    -action                         reset               \
    -traffic_generator              ixnetwork_540       \
    -cpdp_convergence_enable        0                   \
    -delay_variation_enable         0                   \
    -packet_loss_duration_enable    0                   \
    -latency_bins                   3                   \
    -latency_values                 {1.5 3 6.8}         \
    -latency_control                store_and_forward   \
]
if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}
set ti_src ::ixNet::OBJ-/vport:1/protocols
set ti_dst ::ixNet::OBJ-/vport:2/protocols

set traffic_result [::ixia::traffic_config                      \
    -mode                                       create          \
    -traffic_generator                          ixnetwork_540   \
    -endpointset_count                          1               \
    -emulation_src_handle                       $ti_src         \
    -emulation_dst_handle                       $ti_dst         \
    -global_dest_mac_retry_count                1               \
    -global_dest_mac_retry_delay                5               \
    -enable_data_integrity                      1               \
    -global_enable_dest_mac_retry               1               \
    -global_enable_min_frame_size               0               \
    -global_enable_staggered_transmit           0               \
    -global_enable_stream_ordering              0               \
    -global_stream_control                      continuous      \
    -global_stream_control_iterations           1               \
    -global_large_error_threshhold              2               \
    -global_enable_mac_change_on_fly            0               \
    -global_max_traffic_generation_queries      500             \
    -global_mpls_label_learning_timeout         30              \
    -global_refresh_learned_info_before_apply   0               \
    -global_use_tx_rx_sync                      1               \
    -global_wait_time                           1               \
    -global_display_mpls_current_label_value    0               \
    -frame_sequencing                           disable         \
    -frame_sequencing_mode                      rx_threshold    \
    -src_dest_mesh                              one_to_one      \
    -route_mesh                                 one_to_one      \
    -bidirectional                              0               \
    -allow_self_destined                        0               \
    -enable_dynamic_mpls_labels                 0               \
    -hosts_per_net                              1               \
    -name                                       Traffic_Item_1  \
    -source_filter                              all             \
    -destination_filter                         all             \
    -merge_destinations                         1               \
    -circuit_endpoint_type                      ipv4            \
    -egress_tracking                            none            \
]
if {[keylget traffic_result status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_result log]"
}
set current_config_element [keylget traffic_result traffic_item]
set stack_handle [lindex [keylget traffic_result $current_config_element.headers] 0]

set traffic_result [::ixia::traffic_config                  \
    -mode                           modify                  \
    -traffic_generator              ixnetwork_540           \
    -stream_id                      $current_config_element \
    -preamble_size_mode             auto                    \
    -preamble_custom_size           8                       \
    -data_pattern                   {}                      \
    -data_pattern_mode              incr_byte               \
    -enforce_min_gap                0                       \
    -rate_percent                   10                      \
    -frame_rate_distribution_port   apply_to_all            \
    -frame_rate_distribution_stream split_evenly            \
    -frame_size                     64                      \
    -length_mode                    fixed                   \
    -tx_mode                        advanced                \
    -transmit_mode                  continuous              \
    -pkts_per_burst                 1                       \
    -tx_delay                       0                       \
    -tx_delay_unit                  bytes                   \
    -number_of_packets_per_stream   1                       \
    -loop_count                     1                       \
    -min_gap_bytes                  12                      \
]
if {[keylget traffic_result status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_result log]"
}
set traffic_result [::ixia::traffic_config  \
    -mode               modify              \
    -traffic_generator  ixnetwork_540       \
    -stream_id          $stack_handle       \
    -l2_encap           ethernet_ii         \
    -mac_dst_mode       fixed               \
    -mac_dst            00:00:00:00:00:00   \
    -mac_dst_tracking   0                   \
    -mac_src_mode       fixed               \
    -mac_src            00:00:00:00:00:00   \
    -mac_src_tracking   0                   \
]
if {[keylget traffic_result status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_result log]"
}
set traffic_result [::ixia::traffic_config                              \
    -mode                   modify                                      \
    -traffic_generator      ixnetwork_540                               \
    -stream_id              $stack_handle                               \
    -track_by               {sourceDestEndpointPair0 trackingenabled0}  \
    -transmit_distribution  endpoint_pair                               \
]
if {[keylget traffic_result status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_result log]"
}

puts "Running Traffic..."
set run_traffic [::ixia::traffic_control  -action run  -traffic_generator ixnetwork_540]
if {[keylget run_traffic status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget run_traffic log]"
}

after 20000

puts "Stopping Traffic..."
set stop_traffic [::ixia::traffic_control -action stop  -traffic_generator ixnetwork_540]
if {[keylget stop_traffic status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget stop_traffic log]"
}
set flow_traffic_status  [::ixia::traffic_stats     \
    -traffic_generator              ixnetwork_540   \
    -mode                           all             \
    -return_method                  csv             \
]
if {[keylget flow_traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget flow_traffic_status log]"
}

set csv_files [keylget flow_traffic_status csv_file]

set find_in_csv [::ixia::find_in_csv        \
    -file_name  [lindex $csv_files 1]       \
    -column1    "Tx Frames"                 \
    -column2    "Rx Frames"                 \
    -condition  "!="                        \
    ]

# check the row_count return key
if {[keylget find_in_csv row_count] != 2} {
    incr cfgErrors
}

keylprint find_in_csv

if {$cfgErrors != 0} {
    puts "FAIL - $test_name - Incorrect number of flows returned by find_in_csv procedure"
    return 0
}

return "SUCCESS - $test_name - [clock format [clock seconds]]"
