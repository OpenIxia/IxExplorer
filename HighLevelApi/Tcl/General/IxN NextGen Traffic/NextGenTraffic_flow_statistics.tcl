################################################################################
# Version 1.0    $Revision: 1 $
# $Author: etutescu $
#
#    Copyright � 1997 - 2009 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    05-24-2013 etutescu
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
# prints flow stats.                                                           #
# Module:                                                                      #
#    The sample was tested on an STXS4 module.                                 #
#                                                                              #
################################################################################
package require Ixia

proc KeylPrint {keylist {space ""}} {
    upvar $keylist kl
    set result ""
    foreach key [keylkeys kl] {
    set value [keylget kl $key]
    if {[catch {keylkeys value}]} {
        append result "$space$key: $value\n"
    } else {
        set newspace "$space "
        append result "$space$key:\n[KeylPrint value $newspace]"
    }
    }
    return $result
}

set test_name [info script]
set chassis_ip ixro-hlt-xm2-06
set ixnetwork_tcl_server localhost
set username ixiaApiUser
set port_list [list 2/1 2/2]

set connectStatus [::ixia::connect                                   \
        -reset                                                       \
        -device                  $chassis_ip                         \
        -port_list               $port_list                          \
        -username                $username                           \
        -tcl_server              $chassis_ip                         \
        -ixnetwork_tcl_server    $ixnetwork_tcl_server               \
        ]

if {[keylget connectStatus status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget connectStatus log]"
}

set port_array [keylget connectStatus port_handle.$chassis_ip]

set port_0 [keylget port_array [lindex $port_list 0]]
set port_1 [keylget port_array [lindex $port_list 1]]

set interface_status1 [::ixia::interface_config  \
        -port_handle        $port_0              \
        -intf_ip_addr       172.16.31.1          \
        -gateway            172.16.31.2          \
        -netmask            255.255.255.0        \
        -op_mode            normal               \
        -vlan               $true                \
        -vlan_id            100                  \
        -vlan_user_priority 7                    \
        -port_rx_mode       capture_and_measure  \
        ]
if {[keylget interface_status1 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}
set intf_h0 [keylget interface_status1 interface_handle]

set interfaceStatus2 [::ixia::interface_config    \
        -port_handle        $port_1               \
        -intf_ip_addr       172.16.31.2           \
        -gateway            172.16.31.1           \
        -netmask            255.255.255.0         \
        -op_mode            normal                \
        -vlan               $true                 \
        -vlan_id            100                   \
        -vlan_user_priority 7                     \
        -port_rx_mode       capture_and_measure   \
        ]
if {[keylget interfaceStatus2 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interfaceStatus2 log]"
}

set intf_h1 [keylget interfaceStatus2 interface_handle]

set trafficStatus1 [::ixia::traffic_config              \
        -circuit_endpoint_type  ipv4                    \
        -mode                   create                  \
        -emulation_src_handle   $intf_h0                \
        -emulation_dst_handle   $intf_h1                \
        -l3_protocol            ipv4                    \
        -qos_type_ixn           custom                  \
        -qos_value_ixn          5                       \
        -qos_value_ixn_mode     incr                    \
        -qos_value_ixn_step     2                       \
        -qos_value_ixn_count    2                       \
        -qos_value_ixn_tracking 1                       \
        -track_by "flowGroup0 ethernet_ii_pfc_queue"    \
        ]

if {[keylget trafficStatus1 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget trafficStatus1 log]"
}

set trafficStatus2 [::ixia::traffic_config      \
        -circuit_endpoint_type  ipv4            \
        -mode                   create          \
        -emulation_src_handle   $intf_h0        \
        -emulation_dst_handle   $intf_h1        \
        -l3_protocol            ipv4            \
        -qos_type_ixn           tos             \
        -ip_precedence          {0 3}           \
        -ip_precedence_mode     list            \
        -ip_precedence_tracking 1               \
        -track_by "flowGroup0 ipv4_precedence"  \
        ]

if {[keylget trafficStatus2 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget trafficStatus2 log]"
}


set trafficStatus3 [::ixia::traffic_config      \
        -circuit_endpoint_type  ipv4            \
        -mode                   create          \
        -emulation_src_handle   $intf_h0        \
        -emulation_dst_handle   $intf_h1        \
        -l3_protocol            ipv4            \
        -qos_type_ixn           dscp            \
        -qos_value_ixn          dscp_default    \
        -ip_dscp                60              \
        -ip_dscp_mode           decr            \
        -ip_dscp_count          3               \
        -ip_dscp_step           10              \
        -ip_dscp_tracking       1               \
        -track_by "flowGroup0 default_phb"      \
        ]

if {[keylget trafficStatus3 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget trafficStatus3 log]"
}

set trafficStatus4 [::ixia::traffic_config                                              \
        -circuit_endpoint_type  ipv4                                                    \
        -mode                   create                                                  \
        -emulation_src_handle   $intf_h0                                                \
        -emulation_dst_handle   $intf_h1                                                \
        -l3_protocol            ipv4                                                    \
        -qos_type_ixn           dscp                                                    \
        -qos_value_ixn          {af_class1_low_precedence af_class2_high_precedence}    \
        -qos_value_ixn_mode     list                                                    \
        -qos_value_ixn_tracking 1                                                       \
        -track_by               "flowGroup0 assured_forwarding_phb"                     \
           ]

if {[keylget trafficStatus4 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget trafficStatus4 log]"
}


set trafficStatus5 [::ixia::traffic_config                              \
        -circuit_endpoint_type  ipv4                                    \
        -mode                   create                                  \
        -emulation_src_handle   $intf_h0                                \
        -emulation_dst_handle   $intf_h1                                \
        -l3_protocol            ipv4                                    \
        -qos_type_ixn           dscp                                    \
        -qos_value_ixn          {cs_precedence1  cs_precedence2}        \
        -qos_value_ixn_mode     list                                    \
        -qos_value_ixn_tracking 1                                       \
        -track_by               "flowGroup0 class_selector_phb"         \
        ]

if {[keylget trafficStatus5 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget trafficStatus5 log]"
}

set item [keylget trafficStatus5 traffic_item]

set trafficStatus [::ixia::traffic_control          \
        -action              run                    \
        -traffic_generator   ixnetwork              \
        ]
if {[keylget trafficStatus status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget trafficStatus log]"
    return 0
}

after 5000


################################################################################
# Stop the traffic                                                             #
################################################################################
set traffic_status [::ixia::traffic_control     \
        -action             stop                \
        -traffic_generator  ixnetwork           \
        ]

if {[keylget traffic_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget traffic_status log]"
    return 0
}

set flow_traffic_status [::ixia::traffic_stats  \
        -mode               flow                \
        -traffic_generator  ixnetwork           \
        ]
if {[keylget flow_traffic_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget flow_traffic_status log]"
    return 0
}

################################################################################
# Wait for the traffic to stop                                                 #
################################################################################
after 30000

set flow_results [list                                                                      \
        "Tracking Name"                                  tracking_name                      \
        "Tracking Value"                                 tracking_value                     \
        ]

set flows [keylget flow_traffic_status flow]
foreach flow [keylkeys flows] {
    set flow_key [keylget flow_traffic_status flow.$flow]
    puts "\tFlow $flow: [keylget flow_traffic_status flow.$flow.flow_name]"
    puts "\t\tTracking Count: [keylget flow_traffic_status flow.$flow.tracking.count]"
    for {set index 1} {$index <= [keylget flow_traffic_status flow.$flow.tracking.count]} {incr index} {
        puts "\t\tTracking item $index"
        foreach {name key} [subst $[subst flow_results]] {
            puts "\t\t\t$name: [keylget flow_traffic_status flow.$flow.tracking.$index.$key]"
        }
    }
}

puts "SUCCESS - $test_name - [clock format [clock seconds]]"
return 1
