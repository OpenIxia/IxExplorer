#################################################################################
# Version 1.1    $Revision: 2 $
# $Author: MHasegan $
#
#    Copyright © 1997 - 2005 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    08-30-2006 MHasegan
#
#################################################################################

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

################################################################################
#                                                                              #
# Description:                                                                 #
#    This sample configures a PPPoA tunnel with 16 sessions.                   #
#    The sessions join multicast groups.                                       #
#    Statistics are beeing retreived.                                          #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a ATM/POS622-MultiRate-256Mb module.             #
#                                                                              #
################################################################################



################################################################################
# DUT configuration:
#
# vpdn enable
# 
# no aaa new-model
# 
# interface Loopback20
# ip address 21.0.0.1 255.255.0.0
# 
# ip multicast-routing
# ip local pool Pool20atm 21.0.0.2 21.0.255.254
# 
# interface Virtual-Template 20
# ip pim version 1
# ip pim dense-mode
# ip unnumbered Loopback20
# no logging event link-status
# no snmp trap link-status
# peer default ip address pool Pool20atm
# no keepalive
# ppp max-bad-auth 20
# ppp mtu adaptive
# ppp bridge ip
# ppp ipcp address accept
# ppp timeout retry 10
# exit
# 
# interface ATM4/0
# ip pim dense-mode
# ip igmp version 2
# no ip address
# no ip route-cache
# no ip mroute-cache
# no atm ilmi-keepalive
# no shutdown
# range pvc 1/32 1/51
# encapsulation aal5autoppp Virtual-Template20
# protocol ip inarp broadcast
# 
# interface ATM3/0
# ip pim dense-mode
# ip igmp version 2
# ip address 14.0.0.1 255.255.0.0
# no ip route-cache
# no ip mroute-cache
# no atm ilmi-keepalive
# no shutdown
# 
# pvc 1/32
# protocol ip 14.0.0.100 broadcast
# encapsulation aal5snap
# 
################################################################################

package require Ixia

set test_name [info script]

set chassisIP sylvester
set port_list [list 4/1 4/2]

set session_count 16
set sources_count 1

# Connect to the chassis, reset to factory defaults and take ownership
set connect_status [::ixia::connect \
        -reset                    \
        -device    $chassisIP     \
        -port_list $port_list     \
        -username  ixiaApiUser    ]
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

set port_msource [lindex $port_handle 0]
set port_mclients [lindex $port_handle 1]

puts "Ixia port handles are $port_handle "

########################################
# Configure SRC interface in the test  #
########################################
set interface_status [::ixia::interface_config \
        -port_handle      $port_mclients       \
        -speed            oc3                  \
        -intf_mode        atm                  \
        -tx_c2            13                   \
        -rx_c2            13                   ]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}

########################################
# Configure DST interface  in the test #
########################################
set interface_status [::ixia::interface_config \
        -port_handle       $port_msource       \
        -mode              config              \
        -speed             oc3                 \
        -intf_mode         atm                 \
        -tx_c2             13                  \
        -rx_c2             13                  \
        -atm_encapsulation LLCRoutedCLIP       \
        -vpi               1                   \
        -vci               32                  \
        -intf_ip_addr      14.0.0.100          \
        -gateway           14.0.0.1            \
        -netmask           255.255.0.0         ]        
if {[keylget interface_status status] != $::SUCCESS} {
   return "FAIL - $test_name - [keylget interface_status log]"
}

###############################################
# Configure session                           #
###############################################
set pppox_config_status [::ixia::pppox_config            \
        -port_handle                 $port_mclients    \
        -protocol                    pppoa             \
        -encap                       llcsnap           \
        -num_sessions                $session_count    \
        -l4_flow_number              10                \
        -vci                         32                \
        -vci_step                    1                 \
        -vci_count                   $session_count    \
        -pvc_incr_mode               vci               \
        -vpi                         1                 \
        -vpi_step                    1                 \
        -vpi_count                   1                 \
        -ppp_local_ip                21.0.0.2          \
        -ppp_local_ip_step           0.0.0.1           \
        -enable_multicast            1                 \
        -mc_group_id                 mcGroupId         \
        -start_group_ip              226.2.0.1         \
        -group_ip_count              5                 \
        -group_ip_step               0.1.0.1           \
        -igmp_version                IGMPv2            \
        -watch_duration              300               \
        -switch_duration              100 ]
if {[keylget pppox_config_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget pppox_config_status log]"
}

set pppox_handle [keylget pppox_config_status handle]

################################################
#  Setup session                               #
################################################
set pppox_control_status [::ixia::pppox_control  \
        -handle                 $pppox_handle  \
        -action                 connect        ]
if {[keylget pppox_control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget pppox_control_status log]"
}

after 15000

################################################
#  PPPoA Stats                                 #
################################################
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

puts "Ixia Session Setup Test Results ... "
puts "        Number of sessions           = $sess_num "
puts "        Number of connected sessions = $sess_count_up "
puts "        Minimum Setup Time (ms)      = $sess_min_setup "
puts "        Maximum Setup Time (ms)      = $sess_max_setup "
puts "        Average Setup Time (ms)      = $sess_avg_setup "

#########################################
#  Clear streams                        #
#########################################
set traffic_status [::ixia::traffic_config         \
        -mode                 reset                \
        -port_handle          $port_msource        \
        -emulation_src_handle $pppox_handle        \
        -ip_src_mode          emulation            ]
if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}

set traffic_status [::ixia::traffic_config         \
        -mode                 reset                \
        -port_handle          $port_mclients       \
        -emulation_src_handle $pppox_handle        \
        -ip_src_mode          emulation            ]
if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}

#########################################
#  Configure bidirectional traffic      #
#########################################
set traffic_status [::ixia::traffic_config      \
        -mode                 create            \
        -port_handle          $port_msource     \
        -port_handle2         $port_mclients    \
        -bidirectional        0                 \
        -l3_protocol          ipv4              \
        -emulation_dst_handle $pppox_handle     \
        -ip_dst_mode          emulation         \
        -ip_dst_count         $session_count    \
        -ip_src_mode          fixed             \
        -ip_src_addr          14.0.0.100        \
        -transmit_mode        continuous        \
        -mac_dst_mode         discovery         \
        -ip_precedence        1                 \
        -ip_cost              0                 \
        -ip_delay             0                 \
        -ip_reliability       0                 \
        -ip_reserved          0                 \
        -ip_throughput        0                 \
        -rate_pps          50                \
        -duration             100               ]
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

puts "Setup traffic.."
set traffic_start_status [::ixia::traffic_stats     \
        -port_handle           $port_msource      \
        -mode                  add_atm_stats      \
        -vpi                   1          \
        -vci                   32          \
        -vci_count             $sources_count     \
        -vci_step              1                  \
        -atm_counter_vpi_type  fixed          \
        -atm_counter_vci_type  counter            \
        -atm_counter_vci_mode  incr               ]
if {[keylget traffic_start_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_start_status log]"
}

set traffic_start_status [::ixia::traffic_stats     \
        -port_handle           $port_mclients     \
        -mode                  add_atm_stats      \
        -vpi                   1                  \
        -vci                   32              \
        -vci_count             $session_count     \
        -vci_step              1                  \
        -atm_counter_vpi_type  fixed              \
        -atm_counter_vci_type  counter            \
        -atm_counter_vci_mode  incr               ]
if {[keylget traffic_start_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_start_status log]"
}

puts "Starting to transmit traffic over tunnels..."

#########################################
#  Start traffic                        #
#########################################
set control_status [::ixia::traffic_control \
        -port_handle   $port_handle         \
        -action        run                  \
        -tx_ports_list $port_msource        \
        -rx_ports_list $port_mclients       ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

after 20000
puts "Ixia multicast stats ----------after 20 seconds-----------"

#########################################
#  Retrieve multicast stats             #
#########################################
set session_status [::ixia::emulation_igmp_info \
        -port_handle $port_mclients             \
        -mode        aggregate                  \
        -type        igmp_over_ppp              ]
if {[keylget session_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget session_status log]"
}

set key $port_mclients.igmpoppp.aggregate

set mc_groups_query_rx    [keylget session_status $key.rx.mc_groups_query]
set mc_groups_query_tx    [keylget session_status $key.tx.mc_groups_query]
set mc_groups_report_rx    [keylget session_status $key.rx.mc_groups_report]
set mc_groups_report_tx    [keylget session_status $key.tx.mc_groups_report]
set mc_groups_leave     [keylget session_status $key.tx.mc_groups_leave]

puts "\nIGMPoPPP aggregate statistics:"
puts "    Groups Query RX  = $mc_groups_query_rx"
puts "    Groups Query TX  = $mc_groups_query_tx"
puts "    Groups Report RX = $mc_groups_report_rx"
puts "    Groups Report TX = $mc_groups_report_tx"
puts "    Groups Leave     = $mc_groups_leave"

after 60000
puts "Ixia multicast stats ----------after 40 seconds-----------"

#########################################
#  Retrieve multicast stats             #
#########################################
set session_status [::ixia::emulation_igmp_info \
        -port_handle $port_mclients             \
        -mode        aggregate                  \
        -type        igmp_over_ppp              ]
if {[keylget session_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget session_status log]"
}

set key $port_mclients.igmpoppp.aggregate

set mc_groups_query_rx    [keylget session_status $key.rx.mc_groups_query]
set mc_groups_query_tx    [keylget session_status $key.tx.mc_groups_query]
set mc_groups_report_rx    [keylget session_status $key.rx.mc_groups_report]
set mc_groups_report_tx    [keylget session_status $key.tx.mc_groups_report]
set mc_groups_leave     [keylget session_status $key.tx.mc_groups_leave]

puts "\nIGMPoPPP aggregate statistics:"
puts "    Groups Query RX  = $mc_groups_query_rx"
puts "    Groups Query TX  = $mc_groups_query_tx"
puts "    Groups Report RX = $mc_groups_report_rx"
puts "    Groups Report TX = $mc_groups_report_tx"
puts "    Groups Leave     = $mc_groups_leave"

#########################################
#  Stop traffic                         #
#########################################
set control_status [::ixia::traffic_control \
        -port_handle $port_handle           \
        -action      stop                   ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}
puts "Stopped transmitting traffic over tunnels..."

#################################################################################

set aggr_stats [::ixia::traffic_stats -port_handle $port_mclients]
if {[keylget aggr_stats status] == $::FAILURE} {
    return "FAIL - $test_name - [keylget aggr_stats log]"
}

set aggr_tx [keylget aggr_stats $port_mclients.aggregate.tx.pkt_count ]
puts "Port $port_mclients Tx count Results = $aggr_tx frames "

set aggr2_stats [::ixia::traffic_stats \
        -port_handle $port_mclients \
        -mode igmp_over_ppp ]
if {[keylget aggr2_stats status] == $::FAILURE} {
    return "FAIL - $test_name - [keylget aggr2_stats log]"
}

set key $port_mclients.igmpoppp

set mc_total_bytes_rx  [keylget aggr2_stats $key.rx.mc_total_bytes]
set mc_total_bytes_tx  [keylget aggr2_stats $key.tx.mc_total_bytes]
set mc_total_frames_rx [keylget aggr2_stats $key.rx.mc_total_frames]
set mc_total_frames_tx [keylget aggr2_stats $key.tx.mc_total_frames]

puts "\nIGMPoPPP aggregate statistics $port_msource:"
puts "    Total Bytes RX  = $mc_total_bytes_rx"
puts "    Total Bytes TX  = $mc_total_bytes_tx"
puts "    Total Frames RX = $mc_total_frames_rx"
puts "    Total Frames TX = $mc_total_frames_tx"

############################################################################
# For best results, it is recomandable to use the entire port_handle.
# This is a requirement from IxAccess

set aggr_traffic_addr_stats [::ixia::traffic_stats \
    -port_handle         $port_handle       \
    -mode            multicast       \
    -multicast_aggregation    mc_address         ]
if {[keylget aggr_traffic_addr_stats status] == $::FAILURE} {
    return "FAIL - $test_name - [keylget aggr_traffic_addr_stats log]"
}

set aggr_traffic_group_stats [::ixia::traffic_stats \
    -port_handle         $port_handle        \
    -mode            multicast           \
    -multicast_aggregation    mc_group        ]
if {[keylget aggr_traffic_group_stats status] == $::FAILURE} {
    return "FAIL - $test_name - [keylget aggr_traffic_group_stats log]"
}

set aggr_traffic_tos_stats [::ixia::traffic_stats \
    -port_handle         $port_handle      \
    -mode            multicast         \
    -multicast_aggregation    tos              ]
if {[keylget aggr_traffic_tos_stats status] == $::FAILURE} {
    return "FAIL - $test_name - [keylget aggr_traffic_tos_stats log]"
}

puts "\n====Aggregate multicast stats by TOS====\n"
set tos_list [keylkeys aggr_traffic_tos_stats $port_mclients.multicast.rx]
puts [format "%15s %15s %15s %15s %15s %15s"  \
        "tos |"                              \
        "Packet count TX |"                   \
        "Packet count RX |"                   \
        "MIN delay (us)|"                     \
        "MAX delay (us)|"                     \
        "AVG delay (us)|"                     ]

foreach {_tos} $tos_list {
    set key_rx $port_mclients.multicast.rx.${_tos}
    set key_tx $port_msource.multicast.tx.${_tos}
    puts [format "%13s %10s %17s %20s %20s %18s"  \
            $_tos \
            [keylget aggr_traffic_tos_stats $key_tx.pkt_count] \
            [keylget aggr_traffic_tos_stats $key_rx.pkt_count] \
            [keylget aggr_traffic_tos_stats $key_rx.min_delay] \
            [keylget aggr_traffic_tos_stats $key_rx.max_delay] \
            [keylget aggr_traffic_tos_stats $key_rx.avg_delay] ]
}

puts "\n====Aggregate multicast stats by Multicast Group ID====\n"

set group_list [keylkeys aggr_traffic_group_stats $port_mclients.multicast.rx]

puts [format "%15s %15s %15s %15s %15s %15s" \
        "Group Id |"                     \
        "Packet count TX |"                 \
        "Packet count RX |"                  \
        "MIN delay (us)|"                    \
        "MAX delay (us)|"                    \
        "AVG delay (us)|"                    ]

foreach {_group} $group_list {
    set key_rx $port_mclients.multicast.rx.${_group}
    set key_tx $port_msource.multicast.tx.${_group}
    puts [format "%13s %11s %16s %20s %20s %18s"                 \
            $_group                                              \
            [keylget aggr_traffic_group_stats $key_tx.pkt_count] \
            [keylget aggr_traffic_group_stats $key_rx.pkt_count] \
            [keylget aggr_traffic_group_stats $key_rx.min_delay] \
            [keylget aggr_traffic_group_stats $key_rx.max_delay] \
            [keylget aggr_traffic_group_stats $key_rx.avg_delay] ]
}

puts "\n====Aggregate multicast stats by Multicast Address====\n"
set group_list [keylkeys aggr_traffic_addr_stats "$port_mclients.multicast.rx"]

puts [format "%13s %11s %13s %15s %15s %15s %15s" \
        "Group Id |"                              \
        "Address |"                          \
        "Packet count TX |"                       \
        "Packet count RX |"                       \
        "MIN delay (us)|"                         \
        "MAX delay (us)|"                         \
        "AVG delay (us)|"                         ]

foreach {_group} $group_list {
    set addr_list [keylkeys aggr_traffic_addr_stats \
            "$port_mclients.multicast.rx.$_group"]
    puts [format "%11s" $_group]
    foreach {_addr} $addr_list {
        set key_rx "$port_mclients.multicast.rx.$_group.${_addr}"
        set key_tx "$port_msource.multicast.tx.$_group.${_addr}"
        puts [format "%23s %11s %16s %20s %20s %18s"                  \
                $_addr                                                \
                [keylget aggr_traffic_addr_stats "$key_tx.pkt_count"] \
                [keylget aggr_traffic_addr_stats "$key_rx.pkt_count"] \
                [keylget aggr_traffic_addr_stats "$key_rx.min_delay"] \
                [keylget aggr_traffic_addr_stats "$key_rx.max_delay"] \
                [keylget aggr_traffic_addr_stats "$key_rx.avg_delay"] ]
    }
}

#################################################################################

set control_status [::ixia::pppox_control \
        -handle     $pppox_handle         \
        -action     disconnect            ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

::ixia::cleanup_session
return "SUCCESS - $test_name - [clock format [clock seconds]]"
