#################################################################################
# Version 1.0    $Revision: 1 $
# $Author: LRaicea $
#
#    Copyright © 1997 - 2005 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    12-08-2005 LRaicea
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
#    This sample configures a PPPoE tunnel with 5 sessions.                    #
#    Then it connects to the DUT(Cisco7206) and retrieves a few statistics.    #
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
set port_list [list 4/1]

# Connect to the chassis, reset to factory defaults and take ownership
set connect_status [::ixia::connect \
        -reset                    \
        -device    $chassisIP     \
        -port_list $port_list     \
        -username  ixiaApiUser    ]
if {[keylget connect_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget connect_status log]"
}

set port_handle [keylget connect_status port_handle.$chassisIP.$port_list]

################################################
#  Configure session                           #
################################################
set pppox_config_status [::ixia::pppox_config        \
        -port_handle                 $port_handle  \
        -protocol                    pppoe         \
        -encap                       ethernet_ii   \
        -num_sessions                5             \
        -auth_req_timeout            10            \
        -auth_mode                   none          \
        ]

if {[keylget pppox_config_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget pppox_config_status log]"
}

set pppox_handle [keylget pppox_config_status handle]

################################################
#  Setup session                               #
################################################
set pppox_control_status [::ixia::pppox_control  \
        -handle                 $pppox_handle  \
        -action                 connect        \
        ]

if {[keylget pppox_control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget pppox_control_status log]"
}

after 10000

################################################
#  Stats                                       #
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
puts "Ixia Test Results ... "
puts "        Number of sessions           = $sess_num "
puts "        Number of connected sessions = $sess_count_up "
puts "        Minimum Setup Time (ms)      = $sess_min_setup "
puts "        Maximum Setup Time (ms)      = $sess_max_setup "
puts "        Average Setup Time (ms)      = $sess_avg_setup "

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

return "SUCCESS - $test_name - [clock format [clock seconds]]"

