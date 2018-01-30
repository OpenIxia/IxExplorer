#################################################################################
# Version 1.0    $Revision: 1 $
# $Author: LRaicea $
#
#    Copyright © 1997 - 2006 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    03-23-2006 LRaicea
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
#    This sample creates two tunnels each having three sessions and sends      #
#    traffic from PE side to CE side.                                          #
#    The topology is the following:                                            #
#    Ixia(PE) -- Cisco(DUT) --- Ixia(CE)                                       #
#                                                                              #
# DUT configuration:                                                           #
#     ip routing
#     ip cef
# 
#     l2tp-class HLTControl
#      authentication
#      hello 30
#      password ixia
#      cookie size 4
# 
#     pseudowire-class HLTClass1
#      encapsulation l2tpv3
#      protocol l2tpv3 HLTControl
#      ip local interface FastEthernet0/0
# 
#     interface FastEthernet0/0
#      description DUT_Connection
#      ip address 10.205.11.217 255.255.255.0
#      no ip directed-broadcast
#      no ip route-cache cef
#      no ip route-cache
#      no ip mroute-cache
# 
#     interface FastEthernet3/0
#      description PE
#      ip address 100.100.100.1 255.255.255.0
#      no ip directed-broadcast
#      no ip route-cache cef
#      no ip route-cache
#      no ip mroute-cache
# 
#     interface GigabitEthernet2/0
#      ip address 5.5.5.1 255.255.255.0
#      no ip directed-broadcast
#      no ip route-cache cef
#      no ip route-cache
#      no ip mroute-cache
#      no cdp enable
# 
#     interface GigabitEthernet2/0.1
#      encapsulation dot1Q 1
#      no ip directed-broadcast
#      no ip route-cache
#      no cdp enable
#      xconnect 20.20.20.20 101 pw-class HLTClass1
# 
#     interface GigabitEthernet2/0.2
#      encapsulation dot1Q 2
#      no ip directed-broadcast
#      no ip route-cache
#      no cdp enable
#      xconnect 20.20.20.20 102 pw-class HLTClass1
# 
#     interface GigabitEthernet2/0.3
#      encapsulation dot1Q 3
#      no ip directed-broadcast
#      no ip route-cache
#      no cdp enable
#      xconnect 20.20.20.20 103 pw-class HLTClass1
# 
#     interface GigabitEthernet2/0.4
#      encapsulation dot1Q 4
#      no ip directed-broadcast
#      no ip route-cache
#      no cdp enable
#      xconnect 20.20.20.21 104 pw-class HLTClass1
# 
#     interface GigabitEthernet2/0.5
#      encapsulation dot1Q 5
#      no ip directed-broadcast
#      no ip route-cache
#      no cdp enable
#      xconnect 20.20.20.21 105 pw-class HLTClass1
# 
#     interface GigabitEthernet2/0.6
#      encapsulation dot1Q 6
#      no ip directed-broadcast
#      no ip route-cache
#      no cdp enable
#      xconnect 20.20.20.21 106 pw-class HLTClass1
# 
#     ip route 20.20.20.20 255.255.255.255 100.100.100.10
#     ip route 20.20.20.21 255.255.255.255 100.100.100.11
#     end
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a LM1000STXS4-256 module.                        #
#                                                                              #
################################################################################

package require Ixia

set test_name [info script]

set chassisIP         sylvester
set port_list         [list 4/1 4/2]

set src_ip            100.100.100.10
set src_mask          255.255.255.0
set src_ip_step       0.0.0.1
set dst_ip            10.205.11.217
set dst_ip_step       0.0.0.0
set gateway_ip        100.100.100.1
set gateway_ip_step   0.0.0.0
set unconnected_ip    20.20.20.20


set ce_ip             5.5.5.5
set ce_mask           255.255.255.0
set ce_gateway        5.5.5.1
set ce_mac            0000.abcd.abcd
set ce_port_autoneg   1

set tunnel_count       2
set vcid_start         101
set vcid_per_session   1
set session_count      3
set pkts_per_vcid      10
set pkts_per_burst     1000

set session_handles_list ""

# Connect to the chassis, reset to factory defaults and take ownership
set connect_status [::ixia::connect \
        -reset                    \
        -device    $chassisIP     \
        -port_list $port_list     \
        -username  ixiaApiUser    ]
if {[keylget connect_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget connect_status log]"
}

set pe_port  [keylget connect_status \
        port_handle.$chassisIP.[lindex $port_list 0]]

set ce_port  [keylget connect_status \
        port_handle.$chassisIP.[lindex $port_list 1]]

################################################################################
# Configure CE interface
################################################################################
set interface_status [::ixia::interface_config \
        -port_handle     $ce_port            \
        -intf_ip_addr    $ce_ip              \
        -gateway         $ce_gateway         \
        -netmask         $ce_mask            \
        -src_mac_addr    $ce_mac             \
        -autonegotiation $ce_port_autoneg    ]

if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}

################################################################################
# Configure one L2TPv3 control connection group
################################################################################
set l2tpv3_cc_status [::ixia::l2tpv3_dynamic_cc_config  \
        -action                      create           \
        -port_handle                 $pe_port         \
        -cc_id_start                 10               \
        -cc_src_ip                   $src_ip          \
        -cc_src_ip_step              $src_ip_step     \
        -cc_ip_mode                  increment        \
        -cc_ip_count                 $tunnel_count    \
        -cc_src_ip_subnet_mask       $src_mask        \
        -cc_dst_ip                   $dst_ip          \
        -cc_dst_ip_step              $dst_ip_step     \
        -gateway_ip                  $gateway_ip      \
        -gateway_ip_step             $gateway_ip_step \
        -enable_unconnected_intf     1                \
        -base_unconnected_ip         $unconnected_ip  \
        -router_identification_mode  hostname         \
        -hostname                    ixia             \
        -hostname_suffix_start       1                \
        -router_id_min               1000             \
        -cookie_size                 4                \
        -hidden                      0                \
        -authentication              1                \
        -password                    ixia             \
        -hello_interval              30               \
        -l2tp_variant                cisco_variant    \
        -peer_host_name              Cisco7206        ]

if {[keylget l2tpv3_cc_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget l2tpv3_cc_status log]"
}
set cc_handle [keylget l2tpv3_cc_status handle]


################################################################################
# Configure L2TPv3 session groups on the control connection group
################################################################################
set vcid $vcid_start
set vlan_id_start 1
set vlan_id $vlan_id_start
for {set m 1} {$m <= $tunnel_count} {incr m} {
    for {set i 1} {$i <= $session_count} {incr i} {
        set j [format "%04x" $m]
        set k [format "%04x" $i]
        
        set l2tpv3_session_status [::ixia::l2tpv3_session_config \
                -action                      create            \
                -cc_handle                   $cc_handle        \
                -vcid_start                  $vcid             \
                -vcid_mode                   increment         \
                -vcid_step                   1                 \
                -num_sessions                $vcid_per_session \
                -sequencing_transmit         1                 \
                -pw_type                     dot1q_ethernet    \
                -mac_src                     0000.$j.$k        \
                -mac_src_step                0000.0000.0001    \
                -mac_dst                     0000.$j.$k        \
                -mac_dst_step                0000.0000.0001    \
                -vlan_id                     $vlan_id          \
                -vlan_id_step                1                 ]
        
        if {[keylget l2tpv3_session_status status] != $::SUCCESS} {
            return "FAIL - $test_name - [keylget l2tpv3_session_status log]"
        }
        lappend session_handles_list [keylget l2tpv3_session_status handle]
        
        incr vcid $vcid_per_session
        incr vlan_id
    }
}


################################################################################
# Configure traffic for the L2TPv3 session groups
################################################################################
set i 0
foreach {session_handle} $session_handles_list {
    set l2tpv3_session_traffic_status [::ixia::traffic_config \
            -mode                     create                \
            -port_handle              $pe_port              \
            -emulation_src_handle     $session_handle       \
            -length_mode              fixed                 \
            -l3_length                128                   \
            -rate_percent             10                    \
            -transmit_mode            single_burst          \
            -pkts_per_burst           $pkts_per_burst       \
            -ip_src_addr              5$i.5$i.5$i.5$i       \
            -ip_src_mode              increment             \
            -ip_src_step              0.0.0.1               \
            -ip_dst_addr              7$i.7$i.7$i.7$i       \
            -ip_dst_mode              increment             \
            -ip_dst_step              0.0.0.1               ]
    
    if {[keylget l2tpv3_session_traffic_status status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget l2tpv3_session_traffic_status log]"
    }
    incr i
}

################################################################################
# Setup tunnels
################################################################################
set l2tpv3_control_status [::ixia::l2tpv3_control \
        -action       start                     \
        -port_handle  $pe_port                  ]

if {[keylget l2tpv3_control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget l2tpv3_control_status log]"
}

after 90000

################################################################################
# Clear stats before sending traffic
################################################################################
set port_handle [list $pe_port $ce_port]
set clear_stats_status [::ixia::traffic_control \
        -port_handle $port_handle             \
        -action      clear_stats              ]

if {[keylget clear_stats_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget clear_stats_status log]"
}

################################################################################
# Start traffic
################################################################################
set l2tpv3_traffic_status [::ixia::traffic_control \
        -action       run                        \
        -port_handle  $pe_port                   ]

if {[keylget l2tpv3_traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget l2tpv3_traffic_status log]"
}

after 60000

################################################################################
# Stop traffic
################################################################################
set l2tpv3_traffic_status [::ixia::traffic_control \
        -action       stop                       \
        -port_handle  $pe_port                   ]

if {[keylget l2tpv3_traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget l2tpv3_traffic_status log]"
}


################################################################################
# Get statistics
################################################################################
set aggregate_stats [::ixia::l2tpv3_stats  \
        -mode       aggregate              \
        -cc_handle  $cc_handle             ]

if {[keylget aggregate_stats status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget aggregate_stats log]"
}


set cc_stats [::ixia::l2tpv3_stats         \
        -mode       control_connection     \
        -cc_handle  $cc_handle             \
        -cc_id      10                     ]

if {[keylget cc_stats status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget cc_stats log]"
}

set session_stats [::ixia::l2tpv3_stats    \
        -mode       session                \
        -cc_handle  $cc_handle             \
        -vcid       $vcid_start            ]

if {[keylget session_stats status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget session_stats log]"
}

puts "\n\n                 ----- Aggregate statistics -----\n"
foreach statName [keylkeys aggregate_stats aggregate] {
    set statValue [keylget aggregate_stats aggregate.$statName]
    puts [format "%31s        %-20s" "aggregate.$statName" $statValue]
}

puts "\n\n            ----- Control connection statistics -----\n"
foreach ccId [keylkeys cc_stats cc] {
    foreach statName [keylkeys cc_stats cc.$ccId] {
        set statValue [keylget cc_stats cc.$ccId.$statName]
        puts [format "%31s        %-20s" "cc.$ccId.$statName" $statValue]
    }
}

puts "\n\n                  ----- Session statistics -----\n"
foreach vcid [keylkeys session_stats session] {
    foreach statName [keylkeys session_stats session.$vcid] {
        set statValue [keylget session_stats session.$vcid.$statName]
        puts [format "%31s        %-20s" "session.$vcid.$statName" $statValue]
    }
}


# Procedure to print stats
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

###############################################################################
#   Retrieve stats after stopped
###############################################################################
# Get aggregrate stats for all ports
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

post_stats $port_handle "Collisions"     $aggregate_stats \
        aggregate.rx.collisions_count

post_stats $port_handle "Dribble Errors" $aggregate_stats \
        aggregate.rx.dribble_errors_count

post_stats $port_handle "CRCs"           $aggregate_stats \
        aggregate.rx.crc_errors_count

post_stats $port_handle "Oversizes"      $aggregate_stats \
        aggregate.rx.oversize_count

post_stats $port_handle "Undersizes"     $aggregate_stats \
        aggregate.rx.undersize_count


puts "\n--------------------------------------------------\n"

return "SUCCESS - $test_name - [clock format [clock seconds]]"
