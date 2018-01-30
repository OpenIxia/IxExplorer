#################################################################################
# Version 1.0    $Revision: 2 $
# $Author: Mircea Hasegan $
#
#    Copyright © 1997 - 2005 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    05-04-2007 M. Hasegan - Created sample
#    09-23-2008 L. Raicea  - Reformatted sample, run against HLTSET38
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
#    This sample configures a PPPoA tunnel with 5 sessions.                    #
#    Then it connects to the DUT(Cisco7206) and retrieves a few statistics.    #
#    Traffic is sent over the tunnel and the DUT sends                         #
#    it to the DST port. After that a few statistics are being retrieved.      #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a ATM/POS622-MultiRate-256Mb module.             #
#                                                                              #
################################################################################

################################################################################
#                                                                              #
# Description:                                                                 #
#    This sample configures a PPPoA tunnel with 5 sessions.                    #
#    Then it connects to the DUT(Cisco7206) and retrieves a few statistics.    #
#    Traffic is sent over the tunnel and the DUT sends                         #
#    it to the DST port. After that a few statistics are being retrieved.      #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a ATM/POS622-MultiRate-256Mb module.             #
#                                                                              #
################################################################################

################################################################################
# DUT configuration:
#                                             
# configure terminal
# vpdn enable
# 
# interface Loopback50
#  ip address 22.0.0.1 255.255.0.0
# 
# ip local pool pppoaMircea 22.0.0.2 22.0.255.254
# 
# interface Virtual-Template 25
#  ip unnumbered Loopback50
#  no logging event link-status
#  no snmp trap link-status
#  peer default ip address pool pppoaMircea
#  no keepalive
#  ppp max-bad-auth 20
#  ppp mtu adaptive
#  ppp bridge ip
#  ppp ipcp address accept
#  ppp timeout retry 10
# 
# 
# interface ATM2/0
#  no ip address
#  no ip route-cache
#  no ip mroute-cache
#  no atm ilmi-keepalive
#  no shut
#  range pvc 1/32 1/51
#  encapsulation aal5autoppp Virtual-Template25
#  protocol ip inarp broadcast
# 
# interface ATM5/0
#  ip address 24.0.0.1 255.255.0.0
#  no ip route-cache
#  no ip mroute-cache
#  no atm ilmi-keepalive
#  no shut
# 
#  pvc 1/32
#   protocol ip 24.0.0.100 broadcast
#   encapsulation aal5snap
#
################################################################################
package require Ixia

set test_name     [info script]

set chassisIP     sylvester
set port_list     [list 15/1 15/2]
set session_count 5
################################################################################
# Connect to the chassis, reset to factory defaults and take ownership
################################################################################
set connect_status [::ixia::connect                                            \
        -reset                                                                 \
        -device                     $chassisIP                                 \
        -port_list                  $port_list                                 \
        -username                   ixiaApiUser                                \
        ]
        
if {[keylget connect_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget connect_status log]"
    return
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

puts "Ixia port handles are $port_handle "

################################################################################
# Configure Access/PPP interface in the test
################################################################################
set interface_status [::ixia::interface_config                                 \
        -port_handle                $port_0                                    \
        -speed                      oc3                                        \
        -intf_mode                  atm                                        \
        -tx_c2                      13                                         \
        -rx_c2                      13                                         \
        ]
if {[keylget interface_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget interface_status log]"
    return
}

################################################################################
# Configure Network/IP interface in the test
################################################################################
set interface_status [::ixia::interface_config                                 \
        -port_handle                $port_1                                    \
        -mode                       config                                     \
        -speed                      oc3                                        \
        -intf_mode                  atm                                        \
        -tx_c2                      13                                         \
        -rx_c2                      13                                         \
        -atm_encapsulation          LLCRoutedCLIP                              \
        -vpi                        1                                          \
        -vci                        32                                         \
        -intf_ip_addr               24.0.0.100                                 \
        -gateway                    24.0.0.1                                   \
        -netmask                    255.255.0.0                                \
        ]

if {[keylget interface_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget interface_status log]"
    return
}

################################################################################
# Configure PPP emulation
################################################################################
set pppox_config_status [::ixia::pppox_config                                  \
        -port_handle                $port_0                                    \
        -protocol                   pppoa                                      \
        -encap                      llcsnap                                    \
        -num_sessions               $session_count                             \
        -l4_flow_number             10                                         \
        -vci                        32                                         \
        -vci_step                   1                                          \
        -vci_count                  $session_count                             \
        -pvc_incr_mode              vci                                        \
        -vpi                        1                                          \
        -vpi_step                   1                                          \
        -vpi_count                  1                                          \
        -ppp_local_ip               22.0.0.2                                   \
        -ppp_local_ip_step          0.0.0.1                                    \
        ]

if {[keylget pppox_config_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget pppox_config_status log]"
    return
}

set pppox_handle [keylget pppox_config_status handle]

################################################################################
# Start PPP
################################################################################
set pppox_control_status [::ixia::pppox_control                                \
        -handle                     $pppox_handle                              \
        -action                     connect                                    \
        ]

if {[keylget pppox_control_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget pppox_control_status log]"
    return
}

after 15000

################################################################################
# PPPoA Stats 
################################################################################
set retries       10
set sess_count_up 0
while {$retries && ($sess_count_up < $session_count )} {
    set aggr_status [::ixia::pppox_stats                                       \
            -handle                 $pppox_handle                              \
            -mode                   aggregate                                  \
            ]
    if {[keylget aggr_status status] != $::SUCCESS} {
        puts "FAIL - $test_name - [keylget aggr_status log]"
        return
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
    
    after 10000
    incr retries -1
}
if {$sess_count_up < $session_count} {
    puts "FAIL - $test_name - Not all sessions are up."
    return
}

################################################################################
# Clear streams 
################################################################################
set traffic_status [::ixia::traffic_config                                     \
        -mode                       reset                                      \
        -port_handle                $port_0                                    \
        ]

if {[keylget traffic_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget traffic_status log]"
    return
}

set traffic_status [::ixia::traffic_config                                     \
        -mode                       reset                                      \
        -port_handle                $port_1                                    \
        ]

if {[keylget traffic_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget traffic_status log]"
    return
}

################################################################################
# Configure bidirectional traffic
################################################################################
set traffic_status [::ixia::traffic_config                                     \
        -mode                       create                                     \
        -traffic_generator          ixos                                       \
        -port_handle                $port_0                                    \
        -port_handle2               $port_1                                    \
        -bidirectional              1                                          \
        -transmit_mode              continuous                                 \
        -pkts_per_burst             10                                         \
        -burst_loop_count           10                                         \
        -l3_protocol                ipv4                                       \
        -ip_src_mode                emulation                                  \
        -emulation_src_handle       $pppox_handle                              \
        -ip_src_count               $session_count                             \
        -ip_dst_mode                fixed                                      \
        -ip_dst_addr                24.0.0.100                                 \
        -l3_length                  1000                                       \
        -rate_percent               1                                          \
        ]

if {[keylget traffic_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget traffic_status log]"
    return
}

################################################################################
# Clear traffic stats 
################################################################################
set control_status [::ixia::traffic_control                                    \
        -port_handle                $port_handle                               \
        -action                     clear_stats                                \
        ]
if {[keylget control_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget control_status log]"
    return
}

puts "Setup traffic.."
set traffic_start_status [::ixia::traffic_stats                                \
        -port_handle                $port_0                                    \
        -mode                       add_atm_stats                              \
        -vpi                        1                                          \
        -vci                        32                                         \
        -vci_count                  $session_count                             \
        -vci_step                   1                                          \
        -atm_counter_vpi_type       fixed                                      \
        -atm_counter_vci_type       counter                                    \
        -atm_counter_vci_mode       incr                                       \
        ]

if {[keylget traffic_start_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget traffic_start_status log]"
    return
}

set traffic_start_status [::ixia::traffic_stats                                \
        -port_handle                $port_1                                    \
        -mode                       add_atm_stats                              \
        -vpi                        1                                          \
        -vci                        32                                         \
        -atm_counter_vpi_type       fixed                                      \
        -atm_counter_vci_type       fixed                                      \
        ]

if {[keylget traffic_start_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget traffic_start_status log]"
    return
}

puts "Starting to transmit traffic over tunnels..."

################################################################################
# Start traffic 
################################################################################
set control_status [::ixia::traffic_control                                    \
        -port_handle                $port_handle                               \
        -action                     run                                        \
        ]
if {[keylget control_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget control_status log]"
    return
}

after 20000

################################################################################
# Stop traffic 
################################################################################
set control_status [::ixia::traffic_control                                    \
        -port_handle                $port_handle                               \
        -action                     stop                                       \
        ]
if {[keylget control_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget control_status log]"
    return
}
puts "Stopped transmitting traffic over tunnels..."


################################################################################
# TX Stats 
################################################################################
set aggregate_stats [::ixia::traffic_stats -port_handle $port_0]
if {[keylget aggregate_stats status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget aggregate_stats log]"
    return
}

for {set vpi 1} {$vpi <= 1} {incr vpi} {
     for {set vci 32} {$vci < [expr 32 + $session_count]} {incr vci} {
        puts ""
        puts "Aggregate TX stats on ATM port $port_0:$vpi/$vci"
        puts "--------------------------------------------------"
        foreach statName [keylkeys \
                aggregate_stats    \
                ${port_0}.aggregate.tx.${vpi}.${vci}] {            
            puts [format "%31s %-20s" "$statName" \
                    [keylget aggregate_stats      \
                    ${port_0}.aggregate.tx.${vpi}.${vci}.${statName}]]
        }

        puts ""
        puts "Aggregate RX stats on ATM port $port_0:$vpi/$vci"
        puts "--------------------------------------------------"
        foreach statName [keylkeys \
                aggregate_stats ${port_0}.aggregate.rx.${vpi}.${vci}] {                    
            puts [format "%31s %-20s" "$statName" \
                    [keylget aggregate_stats      \
                    ${port_0}.aggregate.rx.${vpi}.${vci}.${statName}]]
        }
    }
}

################################################################################
#  RX Stats 
################################################################################
set aggregate_stats [::ixia::traffic_stats -port_handle $port_1]
if {[keylget aggregate_stats status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget aggregate_stats log]"
    return
}

set vpi 1
set vci 32

puts ""
puts "Aggregate TX stats on ATM port $port_1:$vpi/$vci"
puts "--------------------------------------------------"
foreach statName [keylkeys aggregate_stats \
        ${port_1}.aggregate.tx.${vpi}.${vci}] {
    
    puts [format "%31s %-20s" "$statName" [keylget \
            aggregate_stats                        \
            ${port_1}.aggregate.tx.${vpi}.${vci}.${statName}]]
}

puts ""
puts "Aggregate RX stats on ATM port $port_1:$vpi/$vci"
puts "--------------------------------------------------"
foreach statName [keylkeys aggregate_stats \
        ${port_1}.aggregate.rx.${vpi}.${vci}] {
    
    puts [format "%31s %-20s" "$statName"  \
            [keylget aggregate_stats       \
            ${port_1}.aggregate.rx.${vpi}.${vci}.${statName}]]
}


################################################################################
# Disconnect sessions 
################################################################################
puts "Disconnecting $sess_count_up sessions. "
set control_status [::ixia::pppox_control \
        -handle     $pppox_handle         \
        -action     disconnect            ]
if {[keylget control_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget control_status log]"
    return
}

::ixia::cleanup_session -port_handle $port_handle -reset
return "SUCCESS - $test_name - [clock format [clock seconds]]"


