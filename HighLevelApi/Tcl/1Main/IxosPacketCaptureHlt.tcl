
################################################################################
#                                                                              #
# Description:                                                                 #
#    This sample creates two IPv4 stream with increasing frame length, one     #
#    having bad CRC errors.                                                    #
#    The trigger is set to bad CRC and the filter is set to a framesize range  #
#    uds1 is set to count frames with bad CRC, uds2 is set to count good       #
#    frames and uds5 (async_trigger1) is set to count all packets              #
#    Starts the capture then it starts the streams, collects statistics and    #
#    returns the capture buffer in the default filename.                       #
#
#It creates two files:
#1-5-2_HW.cap - for the Data Plane
#1-5-2_SW.cap - for the Control Plane

#Where 1-5-2 is the chassis-card-port.
 
                                                                             #
# Module:                                                                      #
#    The sample was tested on a LSM XMVR16 module.                             #
#                                                                              #
################################################################################

package require Ixia
set test_name                                   [info script]
set chassis_ip              10.200.120.117
set port_list               [list 5/1 5/2]
set ixnetwork_tcl_server    localhost

set ipV4_ixia_list    "1.1.1.2        1.1.1.1"
set ipV4_gateway_list "1.1.1.1        1.1.1.2"
set ipV4_netmask_list "255.255.255.0  255.255.255.0"
set ipV4_mac_list     "0000.debb.0001 0000.debb.0002"
set ipV4_version_list "4              4"
set ipV4_autoneg_list "1              1"
set ipV4_duplex_list  "full           full"
set ipV4_speed_list   "ether100       ether100"
set ipV4_port_rx_mode "capture        capture"

#################################################################################
#                              START TEST                                       #
#################################################################################

# Connect to the chassis, reset to factory defaults and take ownership
# When using P2NO HLTSET, for loading the IxTclNetwork package please 
# provide –ixnetwork_tcl_server parameter to ::ixia::connect
set connect_status [::ixia::connect  \
        -reset                     \
        -device    $chassis_ip      \
        -port_list $port_list \
        -username  ixiaApiUser     \
        -ixnetwork_tcl_server $ixnetwork_tcl_server ]
if {[keylget connect_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget connect_status log]"
    return 0
}

set port_handle_tx [keylget connect_status \
        port_handle.$chassis_ip.[lindex $port_list 0]]
set port_handle_rx [keylget connect_status \
        port_handle.$chassis_ip.[lindex $port_list 1]]
set port_handle [list $port_handle_tx $port_handle_rx]

########################################
# Configure interface in the test      #
# IPv4                                 #
########################################
set interface_status [::ixia::interface_config \
        -port_handle     $port_handle        \
        -intf_ip_addr    $ipV4_ixia_list     \
        -gateway         $ipV4_gateway_list  \
        -netmask         $ipV4_netmask_list  \
        -autonegotiation $ipV4_autoneg_list  \
        -duplex          $ipV4_duplex_list   \
        -src_mac_addr    $ipV4_mac_list      \
        -speed           $ipV4_speed_list    \
        -port_rx_mode    $ipV4_port_rx_mode  \
        ]
if {[keylget interface_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget interface_status log]"
    return 0
}

##################################
#  Configure streams on TX port  #
##################################

# Configure the streams on the first IpV4 port
set pkts_per_burst_2 2222
set traffic_status  [::ixia::traffic_config         \
        -mode                      create           \
        -port_handle               $port_handle_tx  \
        -l3_protocol               ipv4             \
        -ip_src_addr               12.1.1.1         \
        -ip_src_mode               increment        \
        -ip_src_step               0.0.0.1          \
        -ip_src_count              1                \
        -ip_dst_addr               13.1.1.1         \
        -ip_dst_mode               increment        \
        -ip_dst_step               0.0.0.1          \
        -ip_dst_count              1                \
        -l3_length                 42               \
        -rate_percent              100              \
        -pkts_per_burst            $pkts_per_burst_2\
        -transmit_mode             single_burst     \
        -mac_dst_mode              discovery        \
        -length_mode               increment        \
        -frame_size_min            20               \
        -frame_size_max            10000            \
        -frame_size_step           1                \
        ]
if {[keylget traffic_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget traffic_status log]"
    return 0
}

set pkts_per_burst_1 1111

set traffic_status  [::ixia::traffic_config         \
        -mode                      create           \
        -port_handle               $port_handle_tx  \
        -l3_protocol               ipv4             \
        -ip_src_addr               12.1.1.1         \
        -ip_src_mode               increment        \
        -ip_src_step               0.0.0.1          \
        -ip_src_count              1                \
        -ip_dst_addr               12.1.1.1         \
        -ip_dst_mode               increment        \
        -ip_dst_step               0.0.0.1          \
        -ip_dst_count              1                \
        -l3_length                 42               \
        -pkts_per_burst            $pkts_per_burst_1\
        -transmit_mode             single_burst     \
        -rate_percent              100              \
        -mac_dst_mode              discovery        \
        -fcs                       1                \
        -fcs_type                  bad_CRC          \
        -length_mode               increment        \
        -frame_size_min            20               \
        -frame_size_max            10000            \
        -frame_size_step           1                \
        ]
if {[keylget traffic_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget traffic_status log]"
    return 0
}

set interface_status [::ixia::interface_config  \
        -port_handle     $port_handle_tx        \
        -arp_send_req    1                      ]
if {[keylget interface_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget interface_status log]"
    return 0
}

after 1000

set interface_status [::ixia::interface_config  \
        -port_handle     $port_handle_rx        \
        -arp_send_req    1                      ]
if {[keylget interface_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget interface_status log]"
    return 0
}

# Clear stats before sending traffic
set clear_stats_status [::ixia::traffic_control \
        -port_handle    $port_handle            \
        -action         clear_stats             \
        ]
if {[keylget clear_stats_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget clear_stats_status log]"
    return 0
}

after 10000

####################################
#  Configure triggers and filters  #
####################################

set config_status [::ixia::packet_config_buffers \
    -port_handle    $port_handle_rx              \
    -capture_mode    trigger                     \
    ]
if {[keylget config_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget config_status log]"
    return 0
}

set config_status [::ixia::packet_config_filter \
    -port_handle $port_handle_rx                \
    ]
if {[keylget config_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget config_status log]"
    return 0
}

set error_trigger errBadCRC
set no_error      errGoodFrame

set config_status [::ixia::packet_config_triggers \
        -port_handle                        $port_handle_rx   \
        -capture_filter                     1                 \
        -capture_filter_framesize           1                 \
        -capture_filter_framesize_from      500               \
        -capture_filter_framesize_to        510               \
        -capture_trigger                    1                 \
        -capture_trigger_error              $error_trigger    \
        -uds1                               1                 \
        -uds1_error                         $error_trigger    \
        -uds2                               1                 \
        -uds2_error                         $no_error         \
        -async_trigger1                     1                 \
    ]
if {[keylget config_status status] == $::FAILURE} {
    puts "FAIL - $test_name - [keylget config_status log]"
    return 0
}

#########################
# Start capture on port #
#########################
after 1000
puts "Starting capture.."

set start_status [::ixia::packet_control \
        -port_handle $port_handle_rx     \
        -action      start               \
    ]
if {[keylget start_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget start_status log]"
    return 0
}

puts "Capturing...."

#########################
# Start traffic on port #
#########################

set traffic_control_status [::ixia::traffic_control \
        -port_handle $port_handle_tx                \
        -action      run                            ]
if {[keylget traffic_control_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget traffic_control_status log]"
    return 0
}

after 5000

#########################
# Stop traffic on port  #
#########################
puts "Stopped"

set traffic_control_status [::ixia::traffic_control \
        -port_handle $port_handle_tx                \
        -action      stop                           ]
if {[keylget traffic_control_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget traffic_control_status log]"
    return 0
}

puts "waiting traffic to stop"
puts "traffic stopped"

#########################
# Stop capture on port  #
#########################

after 10000
puts "Stopping capture..."

set stop_status [::ixia::packet_control \
        -port_handle $port_handle_rx    \
        -action      stop               \
    ]
if {[keylget stop_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget stop_status log]"
    return 0
}

after 5000

#############################################
# Get capture and statistics to keyed list  #
#############################################

set stats_status [::ixia::packet_stats \
        -port_handle $port_handle_rx   \
        -format      cap               \
        -dirname     "d:/SR/2014/sep/vipul_628440"\
    ]
if {[keylget stats_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget stats_status log]"
    return 0
}

#########################
# Print aggregate stats #
#########################
puts "Aggregate capture stats on port $port_handle_rx:"

set key $port_handle_rx.aggregate
set aggregate_keys [keylkeys stats_status $key]

foreach aggregate_key $aggregate_keys {
    puts [format "%5s %20s" $aggregate_key [keylget stats_status \
            $key.$aggregate_key]]
}

return "SUCCESS - $test_name - [clock format [clock seconds]]"
