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

set env(IXIA_VERSION) HLTSET26
package require Ixia

set test_name [info script]

set chassisIP 10.205.19.147
set port_list [list 3/1 3/2]
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
        -ip_cp            ipv4_cp            \
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
        -ip_cp            ipv4_cp            \
        -ppp_local_mode   local_only         \
        -ppp_local_ip     25.10.10.1         \
        -ppp_peer_mode    local_only          \
        -ppp_peer_ip      25.10.10.2         \
        -ppp_peer_ip_step 0.0.0.1            ]
if {[keylget config_status2 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget config_status2 log]"
}
set pppox_handle2 [keylget config_status2 handle]
puts "Ixia pppox_handle2 is $pppox_handle2 "
#########################################
#  Connect sessions                     #
#########################################
set control_status [::ixia::pppox_control \
        -handle     [list $pppox_handle $pppox_handle2]        \
        -action     connect               ]
if {[keylget control_status status] != $::SUCCESS} {
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

return "SUCCESS - $test_name - [clock format [clock seconds]]"

