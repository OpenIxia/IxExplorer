#################################################################################
# Version 1.0    $Revision: 1 $
# $Author: MRidichie $
#
#    Copyright © 1997 - 2005 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    06-07-2006 MRidichie
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
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a ATM/POS622-MultiRate-256Mb module.             #
#                                                                              #
################################################################################

################################################################################
# DUT configuration:                                                           # 
#                                                                              #
# vpdn enable                                                                  #
#                                                                              #
#aaa new-model
#
#aaa authentication login default line none
#aaa authentication enable default line none
#aaa authentication ppp default local
#
#username ixia132 password pwd132
#username ixia133 password pwd133
#username ixia134 password pwd134
#username ixia135 password pwd135
#username ixia136 password pwd136
#
#interface Loopback 2
# ip address 11.0.0.1 255.255.0.0    
#
#ip local pool Pool2atm 11.0.0.2 11.0.255.254
#
#interface Virtual-Template 2
# ip unnumbered Loopback2
# no logging event link-status
# no snmp trap link-status
# peer default ip address pool Pool2atm
# no keepalive
# ppp max-bad-auth 20
# ppp mtu adaptive
# ppp bridge ip
# ppp authentication pap 
# ppp ipcp address accept
# ppp timeout retry 10
#
#bba-group pppoe dialin
# virtual-template 2
#
#interface ATM1/0
# no ip address
# no ip route-cache
# no ip mroute-cache
# no atm ilmi-keepalive
# range pvc 1/32 1/36
# encapsulation aal5autoppp Virtual-Template2
# protocol ip inarp broadcast
# no shut                                                                      #
################################################################################

package require Ixia

set test_name [info script]

set chassisIP sylvester
set port_list [list 3/1]

# Connect to the chassis, reset to factory defaults and take ownership
set connect_status [::ixia::connect \
        -device    $chassisIP     \
        -port_list $port_list     \
        -username  ixiaApiUser    ]
if {[keylget connect_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget connect_status log]"
}

set port_handle [keylget connect_status port_handle.$chassisIP.$port_list]

# Configure the interface to atm oc3
set interface_status [::ixia::interface_config \
        -port_handle $port_handle \
        -intf_mode   atm          \
        -speed       oc3          \
        -framing     sonet        \
        -rx_c2       13           \
        -tx_c2       13           ]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}

###############################################
# Configure session                           #
###############################################
set pppox_config_status [::ixia::pppox_config        \
        -port_handle                 $port_handle  \
        -protocol                    pppoa         \
        -encap                       llcsnap       \
        -auth_mode                   pap           \
        -num_sessions                5             \
        -l4_flow_number              2             \
        -vci                         32            \
        -vci_step                    1             \
        -vci_count                   5             \
        -pvc_incr_mode               vci           \
        -vpi                         1             \
        -vpi_step                    1             \
        -vpi_count                   1             \
        -ppp_local_ip                11.0.0.2      \
        -ppp_local_ip_step           0.0.0.1       \
        -username                    "ixia#?"      \
        -password                    "pwd#?"       \
        -username_wildcard           1               \
        -password_wildcard         1                \
        -wildcard_pound_start         1             \
        -wildcard_pound_end         1             \
        -wildcard_question_start     32               \
        -wildcard_question_end       36            \
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

return "SUCCESS - $test_name - [clock format [clock seconds]]"

