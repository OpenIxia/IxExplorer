#################################################################################
# Version 1.0    $Revision: 1 $
# $Author: DRusu $
#
#    Copyright � 1997 - 2005 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    06-06-2005 DRusu
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
#    This sample configures a cc group and a session group on the cc group.    #
#    Then it starts, stops, restarts and deletes the tunnels and pseudo-wires. #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a LM1000TXS4 module.                             #
#                                                                              #
################################################################################

package require Ixia

set test_name [info script]

set chassisIP sylvester
set port_list [list 2/3]

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

#################################################
#  Configure one L2TPv3 control connection      #
#  group containing two tunnels                 #
#################################################
set l2tpv3_cc_status [::ixia::l2tpv3_dynamic_cc_config \
        -action                      create          \
        -port_handle                 $port_handle    \
        -cc_src_ip                   101.100.100.11  \
        -cc_ip_mode                  increment       \
        -cc_src_ip_step              0.0.0.1         \
        -cc_ip_count                 1               \
        -cc_src_ip_subnet_mask       255.255.255.0   \
        -cc_dst_ip                   172.16.100.192  \
        -cc_dst_ip_step              0.0.0.0         \
        -gateway_ip                  101.100.100.1   \
        -gateway_ip_step             0.0.0.0         \
        -router_identification_mode  hostname        \
        -hostname                    ixia            \
        -hostname_suffix_start       1               \
        -router_id_min               1000            \
        -cookie_size                 4               \
        -retransmit_retries          15              \
        -retransmit_timeout_max      8               \
        -retransmit_timeout_min      1               \
        -hidden                      0               \
        -authentication              0               \
        -password                    ixia            \
        -hello_interval              15              \
        -l2tp_variant                cisco_variant   \
        -peer_host_name              7200            ]
if {[keylget l2tpv3_cc_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget l2tpv3_cc_status log]"
}
set cc_handle [keylget l2tpv3_cc_status handle]

#################################################
#  Configure a L2TPv3 session group with one    #
#  pseudo-wire on the control connection group  #
#################################################
set l2tpv3_session_status [::ixia::l2tpv3_session_config \
        -action                      create            \
        -cc_handle                   $cc_handle        \
        -vcid_start                  100               \
        -vcid_mode                   increment         \
        -vcid_step                   1                 \
        -num_sessions                1                 \
        -pw_type                     dot1q_ethernet    \
        -mac_src                     0000.2222.3333    \
        -mac_src_step                0000.0000.0001    \
        -mac_dst                     0000.5555.6666    \
        -mac_dst_step                0000.0000.0001    \
        -vlan_id                     20                ]
if {[keylget l2tpv3_session_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget l2tpv3_session_status log]"
}
set session_handle [keylget l2tpv3_session_status handle]


#################################################
#  Setup tunnels and pseudo-wires               #
#################################################
set l2tpv3_control_status [::ixia::l2tpv3_control \
        -action       start                     \
        -port_handle  $port_handle              ]

if {[keylget l2tpv3_control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget l2tpv3_control_status log]"
}


#################################################
#  Teardown tunnels and pseudo-wires            #
#################################################
set l2tpv3_control_status [::ixia::l2tpv3_control \
        -action       stop                      \
        -port_handle  $port_handle              ]

if {[keylget l2tpv3_control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget l2tpv3_control_status log]"
}


#################################################
#  Restart tunnels and pseudo-wires             #
#################################################
set l2tpv3_control_status [::ixia::l2tpv3_control \
        -action       restart                   \
        -port_handle  $port_handle              ]

if {[keylget l2tpv3_control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget l2tpv3_control_status log]"
}


#################################################
#  Clear all tunnels and pseudo-wires on port   #
#################################################
set l2tpv3_control_status [::ixia::l2tpv3_control \
        -action       delete_all                \
        -port_handle  $port_handle              ]

if {[keylget l2tpv3_control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget l2tpv3_control_status log]"
}



return "SUCCESS - $test_name - [clock format [clock seconds]]"

