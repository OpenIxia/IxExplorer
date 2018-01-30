#################################################################################
# Version 1.0    $Revision: 1 $
# $Author: LRaicea $
#
#    Copyright © 1997 - 2008 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    06-09-2008 LRaicea - Created sample
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
#    This sample configures a PPPoE tunnel with 20 sessions between the        #
#    SRC port and the DUT. Traffic is sent over the tunnel and the DUT sends   #
#    it to the DST port. After that a few statistics are being retrieved.      #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a LM1000STXS4 module.                            #
#                                                                              #
################################################################################

################################################################################
# DUT configuration:                         
#                                            
# aaa new-model
# aaa authentication login default line
# aaa authentication enable default enable
# aaa authentication ppp default none
# aaa session-id common
# vpdn enable
# bba-group pppoe global
#  virtual-template 20
#  sessions per-vc limit 1000
#  sessions per-mac limit 1000
# 
# interface Loopback20
#  ip address 20.20.20.1 255.255.255.0
# 
# interface FastEthernet5/0
#  no ip address
#  no shutdown
# 
# interface FastEthernet5/0.1
#  encapsulation dot1Q 100 second-dot1Q 5
#  no ip route-cache
#  pppoe enable
# 
# interface GigabitEthernet6/0
#  ip address 21.21.21.1 255.255.255.0
#  no shutdown
# 
# interface Virtual-Template20
#  mtu 1492
#  ip unnumbered Loopback20
#  peer default ip address pool pppoe_vlan_pool
#  no keepalive
#  ppp max-bad-auth 20
#  ppp timeout retry 10
# 
# ip local pool pppoe_vlan_pool 20.20.20.2 20.20.20.254
#                                            
################################################################################
package require Ixia

set test_name [info script]
set chassisIP sylvester
set port_list [list 2/3 2/4]
set sess_count 20

# Connect to the chassis, reset to factory defaults and take ownership
set connect_status [::ixia::connect \
        -reset                      \
        -device    $chassisIP       \
        -port_list $port_list       \
        -username  ixiaApiUser      \
        ]
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

set port_0 [lindex $port_handle 0]
set port_1 [lindex $port_handle 1]

puts "Ixia port handles are $port_handle ..."

################################################################################
# Configure SRC interface in the test
################################################################################
set interface_status [::ixia::interface_config \
        -port_handle      $port_0              \
        -mode             config               \
        -duplex           auto                 \
        -speed            auto                 \
        -phy_mode         copper               \
        -autonegotiation  1                    \
        ]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}

################################################################################
# Configure DST interface in the test
################################################################################
set interface_status [::ixia::interface_config \
        -port_handle      $port_1              \
        -mode             config               \
        -duplex           auto                 \
        -speed            auto                 \
        -phy_mode         copper               \
        -autonegotiation  1                    \
        -intf_ip_addr     21.21.21.110         \
        -gateway          21.21.21.1           \
        -netmask          255.255.255.0        \
        ]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}

################################################################################
# Configure sessions 
################################################################################
set config_status [::ixia::pppox_config             \
        -port_handle             $port_0            \
        -protocol                pppoe              \
        -encap                   ethernet_ii_qinq   \
        -num_sessions            20                 \
        -disconnect_rate         10                 \
        -auth_req_timeout        10                 \
        -vlan_id                 5                  \
        -vlan_id_count           1                  \
        -vlan_id_outer           100                \
        -vlan_id_outer_count     1                  ]
if {[keylget config_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget config_status log]"
}
set pppox_handle [keylget config_status handle]
puts "Ixia pppox_handle is $pppox_handle "

################################################################################
# Connect sessions
################################################################################
set control_status [::ixia::pppox_control \
        -handle     $pppox_handle         \
        -action     connect               \
        ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}
puts "Sessions going up ..."

after 60000
set pppoe_attempts  0
set pppoe_sessions_up 0
while {($pppoe_attempts < 20) && ($pppoe_sessions_up < $sess_count)} {
    after 10000
    set pppox_status [::ixia::pppox_stats \
            -handle   $pppox_handle       \
            -mode     aggregate           \
            ]
    if {[keylget pppox_status status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget pppox_status log]"
    }
    set  aggregate_stats   [keylget pppox_status aggregate]
    set  pppoe_sessions_up [keylget aggregate_stats sessions_up]
    puts "PPPoE sessions up: $pppoe_sessions_up ..."
    incr pppoe_attempts
}
    
if {$pppoe_sessions_up < $sess_count} {
    return "FAIL - $test_name - Not all sessions are up."
}

################################################################################
# Reset traffic
################################################################################
set traffic_status [::ixia::traffic_config         \
        -mode                 reset                \
        -port_handle          $port_0              \
        ]
if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}

set traffic_status [::ixia::traffic_config         \
        -mode                 reset                \
        -port_handle          $port_1              \
        ]
if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}

################################################################################
# Configure traffic
################################################################################
set traffic_status [::ixia::traffic_config      \
        -mode                 create            \
        -traffic_generator    ixos              \
        -bidirectional        1                 \
        -rate_percent         1                 \
        -transmit_mode        continuous        \
        -port_handle          $port_0           \
        -port_handle2         $port_1           \
        -emulation_src_handle $pppox_handle     \
        -emulation_src_vlan_protocol_tag_id {88a8 8100} \
        -l3_protocol          ipv4              \
        -l3_length            1000              \
        -ip_src_mode          emulation         \
        -ip_src_count         $sess_count       \
        -ip_dst_mode          fixed             \
        -ip_dst_addr          21.21.21.110      \
        -mac_src_mode         emulation         \
        -mac_dst_mode         discovery         \
        ]
if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}

################################################################################
# Send ARP request
################################################################################
set interface_status [::ixia::interface_config \
        -port_handle     $port_0               \
        -arp_send_req    1                     \
        ]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}

set interface_status [::ixia::interface_config \
        -port_handle     $port_1               \
        -arp_send_req    1                     \
        ]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}

################################################################################
# Clear traffic stats
################################################################################
set control_status [::ixia::traffic_control \
        -port_handle $port_handle           \
        -action      clear_stats            \
        ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}
puts "Starting to transmit traffic over tunnels ..."

################################################################################
# Start traffic 
################################################################################
set control_status [::ixia::traffic_control \
        -port_handle $port_handle           \
        -action      run                    \
        ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

after 12000

################################################################################
# Stop traffic 
################################################################################
set control_status [::ixia::traffic_control \
        -port_handle $port_handle           \
        -action      stop                   \
        ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

################################################################################
#  Command to print raw traffic stats
################################################################################
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
################################################################################
# Retrieve aggregate traffic stats
################################################################################
set aggregate_stats [::ixia::traffic_stats -port_handle $port_handle]
if {[keylget aggregate_stats status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget aggregate_stats log]"
}
puts "\n\nTraffic Statistics ... "
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

################################################################################
# Retrieve aggregate PPPoE session stats
################################################################################
set aggr_status [::ixia::pppox_stats \
        -handle $pppox_handle        \
        -mode   aggregate            \
        ]
if {[keylget aggr_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget aggr_status log]"
}

set sess_num       [keylget aggr_status aggregate.num_sessions]
set sess_count_up  [keylget aggr_status aggregate.connected]
set sess_min_setup [keylget aggr_status aggregate.min_setup_time]
set sess_max_setup [keylget aggr_status aggregate.max_setup_time]
set sess_avg_setup [keylget aggr_status aggregate.avg_setup_time]
puts "\n\nSessions Aggregate Statistics ... "
puts "        Number of sessions           = $sess_num "
puts "        Number of connected sessions = $sess_count_up "
puts "        Minimum Setup Time (ms)      = $sess_min_setup "
puts "        Maximum Setup Time (ms)      = $sess_max_setup "
puts "        Average Setup Time (ms)      = $sess_avg_setup "

################################################################################
# Retrieve per session stats
################################################################################
set session_status [::ixia::pppox_stats \
           -handle $pppox_handle        \
           -mode   session              \
           ]
if {[keylget session_status status] != $::SUCCESS} {
   return "FAIL - $test_name - [keylget session_status log]"
}
set sessionIdList [keylkeys session_status session]

puts "\n\nPer Session Statistics ... "
foreach sessid $sessionIdList {
    if {![catch {set per_sess_ipcp_cfg_req_tx \
            [keylget session_status           \
            session.${sessid}.ipcp_cfg_req_tx]}]} {
        puts "        Session $sessid IPCP CFG ReQ Tx Count =\
                $per_sess_ipcp_cfg_req_tx "
    } else  {
        puts "        Session $sessid IPCP CFG ReQ Tx Count = N/A "
    }
}

################################################################################
# Disconnect sessions
################################################################################
puts "Disconnecting $sess_count_up sessions ... "
set control_status [::ixia::pppox_control \
        -handle     $pppox_handle         \
        -action     disconnect            \
        ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

set control_status [::ixia::cleanup_session -port_handle $port_handle]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

return "SUCCESS - $test_name - [clock format [clock seconds]]"

