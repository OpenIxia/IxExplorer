#################################################################################
# Version 1.0    $Revision: 1 $
# $Author: LRaicea $
#
#    Copyright © 1997 - 2005 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    12-09-2005 LRaicea
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
# DUT configuration:                                                           #
#                                                                              #
# aaa new-model                                                                #
# aaa authentication ppp default none                                          #
# aaa session-id common                                                        #
#                                                                              #
# vpdn enable                                                                  #
#                                                                              #
# bba-group pppoe global                                                       #
#  virtual-template 1                                                          #
#  sessions per-vc limit 1000                                                  #
#  sessions per-mac limit 1000                                                 #
#                                                                              #
# interface Loopback1                                                          #
#  ip address 10.10.10.1 255.255.255.0                                         #
#                                                                              #
# ip local pool pppoe 10.10.10.2 10.10.10.254                                  #
#                                                                              #
# interface FastEthernet1/0                                                    #
#  no ip address                                                               #
#  no ip route-cache cef                                                       #
#  no ip route-cache                                                           #
#  duplex half                                                                 #
#  pppoe enable                                                                #
#  no shut                                                                     #
#                                                                              #
# interface FastEthernet3/0                                                    #
#  ip address 11.11.11.1 255.255.255.0                                         #
#  duplex half                                                                 #
#  no shut                                                                     #
#                                                                              #
# interface Virtual-Template1                                                  #
#  mtu 1492                                                                    #
#  ip unnumbered Loopback1                                                     #
#  peer default ip address pool pppoe                                          #
#  no keepalive                                                                #
#  ppp max-bad-auth 20                                                         #
#  ppp timeout retry 10                                                        #
#                                                                              #
################################################################################

package require Ixia

set test_name [info script]

set chassisIP sylvester
set port_list [list 4/1 4/2]
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
        -speed            auto                 \
        -duplex           auto                 \
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
        -duplex           full                 \
        -phy_mode         copper               \
        -autonegotiation  1                    \
        -intf_ip_addr     11.11.11.110         \
        -gateway          11.11.11.1           \
        -netmask          255.255.255.0        ]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}

#########################################
#  Configure sessions                   #
#########################################
set config_status [::ixia::pppox_config     \
        -port_handle     $port_src_handle   \
        -protocol        pppoe              \
        -encap           ethernet_ii        \
        -num_sessions    $sess_count        \
        -disconnect_rate 10                 \
        -auth_req_timeout        10         ]
if {[keylget config_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget config_status log]"
}
set pppox_handle [keylget config_status handle]
puts "Ixia pppox_handle is $pppox_handle "

#########################################
#  Connect sessions                     #
#########################################
set control_status [::ixia::pppox_control \
        -handle     $pppox_handle         \
        -action     connect               ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}
puts "Sessions going up..."

after 60000
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

#########################################
#  Configure traffic                    #
#########################################
set traffic_status [::ixia::traffic_config      \
        -mode                 create            \
        -port_handle          $port_src_handle  \
        -port_handle2         $port_dst_handle  \
        -l3_protocol          ipv4              \
        -ip_src_mode          emulation         \
        -ip_src_count         $sess_count       \
        -emulation_src_handle $pppox_handle     \
        -ip_dst_mode          fixed             \
        -ip_dst_addr          11.11.11.110      \
        -l3_length            1000              \
        -rate_percent         100               \
        -transmit_mode        continuous        \
        -mac_dst_mode         discovery         ]
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

#########################################
#  Start traffic                        #
#########################################
set control_status [::ixia::traffic_control \
        -port_handle $port_src_handle       \
        -action      run                    ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

after 12000

#########################################
#  Stop traffic                         #
#########################################
set control_status [::ixia::traffic_control \
        -port_handle $port_src_handle       \
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

set aggr_rx [keylget aggr_stats $port_dst_handle.aggregate.rx.raw_pkt_count ]
puts "Port $port_dst_handle Rx count Results = $aggr_rx frames "

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

return "SUCCESS - $test_name - [clock format [clock seconds]]"
