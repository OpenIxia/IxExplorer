################################################################################
# Version 1.0    $Revision: 1 $
# $Author: DStanciu $
#
#    Copyright © 1997 - 2007 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    05-22-2007 LRaicea
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
################################################################################

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

set chassisIP   sylvester
set port_list   [list 1/1 1/2]
set sess_count  30
set sess_count2 100

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
        -is_last_subport  0                  \
        -port_handle      $port_src_handle   \
        -protocol         pppoe              \
        -encap            ethernet_ii        \
        -num_sessions     $sess_count        \
        -port_role        access             \
        -disconnect_rate  10                 \
        -redial           1                  \
        -redial_max       10                 \
        -redial_timeout      20                 \
        -ip_cp            ipv4_cp            \
        -ppp_local_mode   peer_only          ]
if {[keylget config_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget config_status log]"
}
set pppox_handle [keylget config_status handle]
puts "Ixia pppox_handle is $pppox_handle "

set config_status3 [::ixia::pppox_config   \
        -port_handle      $port_src_handle \
        -protocol         pppoe            \
        -encap            ethernet_ii      \
        -num_sessions     $sess_count2     \
        -port_role        access           \
        -disconnect_rate  10               \
        -redial           1                \
        -redial_max       10               \
        -redial_timeout      20               \
        -ip_cp            ipv4_cp          \
        -ppp_local_mode   peer_only        ]
if {[keylget config_status3 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget config_status3 log]"
}
set pppox_handle3 [keylget config_status3 handle]
puts "Ixia pppox_handle3 is $pppox_handle3 "

set config_status2 [::ixia::pppox_config     \
        -port_handle      $port_dst_handle   \
        -protocol         pppoe              \
        -encap            ethernet_ii        \
        -num_sessions     [expr $sess_count + $sess_count2] \
        -port_role        network            \
        -ip_cp            ipv4_cp            \
        -ppp_local_mode   local_only         \
        -ppp_local_ip     25.10.10.1         \
        -ppp_peer_mode    local_only         \
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
        -handle     $pppox_handle         \
        -action     connect               ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}
puts "PPPoE handle $pppox_handle started..."

set control_status [::ixia::pppox_control \
        -handle     $pppox_handle3        \
        -action     connect               ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}
puts "PPPoE handle $pppox_handle3 started..."

set control_status2 [::ixia::pppox_control \
        -handle     $pppox_handle2         \
        -action     connect                ]
if {[keylget control_status2 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status2 log]"
}
puts "PPPoE handle $pppox_handle2 started..."

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

set pppoe_attempts  0
set pppoe_sessions_up 0
while {($pppoe_attempts < 20) && ($pppoe_sessions_up < $sess_count2)} {
    after 10000
    set pppox_status [::ixia::pppox_stats \
            -handle   $pppox_handle3       \
            -mode     aggregate           ]
    if {[keylget pppox_status status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget pppox_status log]"
    }
    set  aggregate_stats   [keylget pppox_status aggregate]
    set  pppoe_sessions_up [keylget aggregate_stats sessions_up]
    puts "pppoe_sessions_up=$pppoe_sessions_up"
    incr pppoe_attempts
}

if {$pppoe_sessions_up < $sess_count2} {
    return "FAIL - $test_name - Not all sessions are up."
}

set pppox_status [::ixia::pppox_stats \
        -handle   $pppox_handle      \
        -mode     aggregate           ]
if {[keylget pppox_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget pppox_status log]"
}

puts $pppox_status
puts ""

set pppox_status [::ixia::pppox_stats \
        -handle   $pppox_handle3      \
        -mode     aggregate           ]
if {[keylget pppox_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget pppox_status log]"
}

puts $pppox_status
puts ""

set pppox_status [::ixia::pppox_stats \
        -handle   $pppox_handle2       \
        -mode     aggregate           ]
if {[keylget pppox_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget pppox_status log]"
}
puts $pppox_status
puts ""

##########################################
#  Configure traffic                     #
##########################################
set traffic_status [::ixia::traffic_config      \
        -mode                 create            \
        -port_handle          $port_src_handle  \
        -l3_protocol          ipv4              \
        -ip_src_mode          emulation         \
        -ip_src_count         $sess_count       \
        -emulation_src_handle $pppox_handle     \
        -emulation_dst_handle $pppox_handle2    \
        -ip_dst_mode          emulation         \
        -l3_length            100               \
        -rate_percent         5                 \
        -transmit_mode        continuous        \
        -mac_dst_mode         discovery         ]
if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}

set traffic_status [::ixia::traffic_config      \
        -mode                 create            \
        -port_handle          $port_src_handle  \
        -l3_protocol          ipv4              \
        -ip_src_mode          emulation         \
        -ip_src_count         $sess_count2      \
        -emulation_src_handle $pppox_handle3    \
        -emulation_dst_handle $pppox_handle2    \
        -ip_dst_mode          emulation         \
        -l3_length            100               \
        -rate_percent         5                 \
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

set interface_status [::ixia::interface_config \
        -port_handle  $port_handle             \
        -arp_send_req 1                           ]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}
#########################################
#  Start traffic                        #
#########################################
set control_status [::ixia::traffic_control \
        -port_handle $port_handle           \
        -action      run                    ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

after 12000

#########################################
#  Stop traffic                         #
#########################################
set control_status [::ixia::traffic_control \
        -port_handle $port_handle           \
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
set aggr_status [::ixia::pppox_stats \
        -handle $pppox_handle3       \
        -mode   aggregate            ]
if {[keylget aggr_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget aggr_status log]"
}
set sess_count_up [expr $sess_count_up + [keylget aggr_status aggregate.connected]]
set sess_num      [expr $sess_num      + [keylget aggr_status aggregate.num_sessions]]
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
           -handle $pppox_handle3        \
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
        -handle     $pppox_handle3        \
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

