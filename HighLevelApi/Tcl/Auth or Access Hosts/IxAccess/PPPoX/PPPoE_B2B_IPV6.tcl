#################################################################################
# Version 1.0    $Revision: 1 $
# $Author: Mvasile $
#
#    Copyright © 1997 - 2005 by IXIA
#    All Rights Reserved.
#
#
#################################################################################


################################################################################
#                                                                              #
# Description:                                                                 #
#    This sample configures a PPPoE tunnel with 20 sessions between the        #
#    SRC port and the DUT. Traffic is sent over the tunnel and the DUT sends   #
#    it to the DST port. After that a few statistics are being retrieved.      #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a LM1000STXS4 module fiber mode.                 #
#                                                                              #
################################################################################


package require Ixia

set test_name [info script]

set chassisIP sylvester
set port_list [list 1/1 1/2]
set sess_count 20
# Connect to the chassis, reset to factory defaults and take ownership
set connect_status [::ixia::connect \
        -reset                      \
        -device    $chassisIP       \
        -port_list $port_list       \
        -username  ixiaApiUser      ]
if {[keylget connect_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget connect_status log]"
}

set port_handle [list]
foreach port $port_list {
    if {![catch {keylget connect_status port_handle.$chassisIP.$port} \
                temp_port]} {
        lappend port_handle $temp_port
    }
}

set port_src_handle [lindex $port_handle 0]
set port_dst_handle [lindex $port_handle 1]

puts "Ixia port handles are $port_handle "

########################################
# Configure SRC interface in the test  #
########################################
set interface_status [::ixia::interface_config \
        -port_handle      $port_src_handle     \
        -mode             config               \
        -speed            ether100             \
        -phy_mode         copper               \
        -autonegotiation  1                    ]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}


########################################
# Configure DST interface  in the test #
########################################
set interface_status [::ixia::interface_config \
        -port_handle      $port_dst_handle     \
        -mode             config               \
        -speed            ether100             \
        -phy_mode         copper               \
        -autonegotiation  1                    ]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}

#########################################
#  Configure sessions                   #
#########################################
set config_status [::ixia::pppox_config      \
        -port_handle      $port_src_handle   \
        -protocol         pppoe              \
        -encap            ethernet_ii    \
        -num_sessions     $sess_count        \
        -port_role           access                \
        -disconnect_rate  10                 \
        -redial                 1                        \
        -redial_max          10                    \
        -redial_timeout      20                    \
        -ip_cp            ipv6_cp            \
        -ppp_local_mode   peer_only ]
if {[keylget config_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget config_status log]"
}
set pppox_handle [keylget config_status handle]
puts "Ixia pppox_handle is $pppox_handle "

set config_status2 [::ixia::pppox_config     \
        -port_handle      $port_dst_handle   \
        -protocol         pppoe              \
        -encap            ethernet_ii        \
        -num_sessions     $sess_count        \
        -port_role           network                  \
        -ip_cp            ipv6_cp            \
        -ppp_local_mode   local_only         \
        -ppp_peer_mode    local_only         \
        -ppp_local_iid    "00 02 03 02 00 00 00 01" \
        -ppp_peer_iid     "00 02 03 02 00 10 00 01" \
        -ipv6_pool_prefix 0002:0003:0002:0000:: \
        -ipv6_pool_addr_prefix_len     64             \
        -ipv6_pool_prefix_len             48       \
        ]
if {[keylget config_status2 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget config_status2 log]"
}
set pppox_handle2 [keylget config_status2 handle]
puts "Ixia pppox_handle2 is $pppox_handle2 "
#########################################
#  Connect sessions                     #
#########################################
set control_status [::ixia::pppox_control \
        -handle     $pppox_handle         \
        -action     connect               ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}
set control_status2 [::ixia::pppox_control \
        -handle     $pppox_handle2         \
        -action     connect               ]
if {[keylget control_status2 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status2 log]"
}
puts "Sessions..."

after 60000
################################################################################
# Get PPPoE session aggregate statistics
################################################################################
 set pppoe_attempts  0
 set pppoe_sessions_up 0
 while {($pppoe_attempts < 20) && ($pppoe_sessions_up < $sess_count)} {
     after 10000
     set pppox_status [::ixia::pppox_stats \
             -handle   $pppox_handle       \
             -mode     aggregate           ]
     
     if {[keylget pppox_status status] != $::SUCCESS} {
         return "FAIL - $test_name - [keylget pppox_status log]"
     }
     set  aggregate_stats   [keylget pppox_status aggregate]
     set  pppoe_sessions_up [keylget aggregate_stats sessions_up]
     puts "pppoe_sessions_up=$pppoe_sessions_up"
     incr pppoe_attempts
 }
 
if {$pppoe_sessions_up < $sess_count} {
    return "FAIL - $test_name - Not all sessions are up."
}

set traffic_status [::ixia::traffic_config         \
        -mode                 reset                \
        -port_handle          $port_src_handle     \
        -emulation_src_handle $pppox_handle        \
        -ip_src_mode          emulation            ]

if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}
set traffic_status [::ixia::traffic_config          \
        -mode                 reset                 \
        -port_handle          $port_dst_handle      \
        -emulation_src_handle $pppox_handle2        \
        -ip_src_mode          emulation             ]

if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}

    
# #########################################
#  Configure traffic                    #
#########################################
set traffic_status [::ixia::traffic_config      \
        -mode                 create            \
        -bidirectional        1                 \
        -port_handle          $port_src_handle  \
        -port_handle2         $port_dst_handle  \
        -l3_protocol          ipv6              \
        -ip_src_mode          emulation         \
        -ip_src_count         $sess_count       \
        -emulation_src_handle $pppox_handle     \
        -emulation_dst_handle $pppox_handle2     \
        -ip_dst_mode          emulation          \
        -l3_length            100              \
        -rate_percent         5                 \
        -transmit_mode        continuous        \
        -mac_dst_mode         discovery       ]
if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}

#########################################
#  Clear traffic stats                  #
#########################################
set control_status [::ixia::traffic_control \
        -port_handle $port_handle           \
        -action      clear_stats            ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}
puts "Starting to transmit traffic over tunnels..."



set interface_status [::ixia::interface_config \
        -port_handle      $port_handle     \
        -arp_send_req      1         ]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}
#########################################
#  Start traffic                        #
#########################################
set control_status [::ixia::traffic_control \
        -port_handle $port_handle       \
        -action      run                    ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

after 12000

#########################################
#  Stop traffic                         #
#########################################
set control_status [::ixia::traffic_control \
        -port_handle $port_handle       \
        -action      stop                   ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

#########################################
#  Retrieve SRC aggregate traffic stats #
#########################################
set aggr_stats [::ixia::traffic_stats -port_handle $port_src_handle]
if {[keylget aggr_stats status] == $::FAILURE} {
    return "FAIL - $test_name - [keylget aggr_stats log]"
}

set aggr_tx [keylget aggr_stats $port_src_handle.aggregate.tx.pkt_count ]
puts "Port $port_src_handle Tx count Results = $aggr_tx frames "

#########################################
#  Retrieve DST aggregate traffic stats #
#########################################
set aggr_stats [::ixia::traffic_stats -port_handle $port_dst_handle]
if {[keylget aggr_stats status] == $::FAILURE} {
    return "FAIL - $test_name - [keylget aggr_stats log]"
}

set aggr_rx [keylget aggr_stats $port_dst_handle.aggregate.rx.pkt_count ]
puts "Port $port_dst_handle Rx count Results = $aggr_rx frames "
#########################################
#  Procedure to print raw traffic stats #
#########################################
proc post_stats {port_handle label key_list stat_key {stream ""}} {
    puts -nonewline [format "%-30s" $label]
    
    foreach port $port_handle {
        if {$stream != ""} {
            set key $port.stream.$stream.$stat_key
        } else {
            set key $port.$stat_key
        }
        
        if {[llength [keylget key_list $key]] > 1} {
            puts -nonewline "[format "%-16s" N/A]"
        } else  {
            puts -nonewline "[format "%-16s" [keylget key_list $key]]"
        }
    }
    puts ""
}
#########################################
#  Retrieve raw traffic stats         #
#########################################

set aggregate_stats [::ixia::traffic_stats -port_handle $port_handle]
if {[keylget aggregate_stats status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget aggregate_stats log]"
}

puts "\n\n                  ----- Traffic statistics -----\n"
puts -nonewline "[format "%-30s" " "]"
foreach port $port_handle {
    puts -nonewline "[format "%-16s" $port]"
}
puts ""
puts -nonewline "[format "%-30s" " "]"
foreach port $port_handle {
    puts -nonewline "[format "%-16s" "-----"]"
}
puts ""


post_stats $port_handle "Raw Packets Tx" $aggregate_stats \
        aggregate.tx.raw_pkt_count

post_stats $port_handle "Raw Packets Rx" $aggregate_stats \
        aggregate.rx.raw_pkt_count
puts "\n--------------------------------------------------\n"
#########################################
#  Retrieve aggregate session stats     #
#########################################
set aggr_status [::ixia::pppox_stats \
        -handle $pppox_handle        \
        -mode   aggregate            ]
if {[keylget aggr_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget aggr_status log]"
}

set sess_num       [keylget aggr_status aggregate.num_sessions]
set sess_count_up  [keylget aggr_status aggregate.connected]
set sess_min_setup [keylget aggr_status aggregate.min_setup_time]
set sess_max_setup [keylget aggr_status aggregate.max_setup_time]
set sess_avg_setup [keylget aggr_status aggregate.avg_setup_time]
puts "Ixia Test Results ... "
puts "        Number of sessions           = $sess_num "
puts "        Number of connected sessions = $sess_count_up "
puts "        Minimum Setup Time (ms)      = $sess_min_setup "
puts "        Maximum Setup Time (ms)      = $sess_max_setup "
puts "        Average Setup Time (ms)      = $sess_avg_setup "

#########################################
#  Retrieve per session stats           #
#########################################
set session_status [::ixia::pppox_stats \
           -handle $pppox_handle        \
           -mode   session              ]
if {[keylget session_status status] != $::SUCCESS} {
   return "FAIL - $test_name - [keylget session_status log]"
}
set sessionIdList [keylkeys session_status session]

puts "Ixia per session stats ... "
foreach sessid $sessionIdList {
    if {![catch {set per_sess_ipcp_cfg_req_tx \
            [keylget session_status           \
            session.${sessid}.ipcp_cfg_req_tx]}]} {
        puts "Session $sessid IPCP CFG ReQ Tx Count =\
                $per_sess_ipcp_cfg_req_tx "
    } else  {
        puts "Session $sessid IPCP CFG ReQ Tx Count = N/A "
    }
} 
#########################################
#  Disconnect sessions                  #
#########################################
puts "Disconnecting $sess_count_up sessions. "
set control_status [::ixia::pppox_control \
        -handle     $pppox_handle         \
        -action     disconnect            ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}
set control_status [::ixia::pppox_control \
        -handle     $pppox_handle2        \
        -action     disconnect            ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

return "SUCCESS - $test_name - [clock format [clock seconds]]"

