#################################################################################
# Version 1.0    $Revision: 1 $
# $Author: MHasegan $
#
#    Copyright © 1997 - 2005 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    06-18-2008 Mircea Hasegan
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
#    This sample configures a PPPoE tunnel with 10000 sessions having setup    #
#    throttling enabled and 100 max outstanding sessions.                      #
#    Then it connects to the DUT(Cisco7206) and retrieves  statistics showing  #
#    that the number of queued sessions doesn't exceed 100. Otherwise an error #
#    is returned.                                                              #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a LM1000STXS4 module.                            #
#                                                                              #
#    This sample works only with IxAccess.                                     #
#                                                                              #
################################################################################

################################################################################
# DUT configuration:                                                           
#                                                                              
# vpdn enable
# 
# bba-group pppoe group1
#  virtual-template 1
#  sessions per-vc limit 10000
#  sessions per-mac limit 10000
# 
# interface Loopback1
#  ip address 10.10.0.1 255.255.0.0
# 
# ip local pool pppoe1 10.10.0.2 10.10.255.254
# 
# interface gi 0/2
#  no ip address
#  no ip route-cache cef
#  no ip route-cache
#  pppoe enable group group1
#  duplex full
#  no shut
# 
# interface Virtual-Template1
#  mtu 1492
#  ip unnumbered Loopback1
#  peer default ip address pool pppoe1
#  no keepalive
#  ppp max-bad-auth 20
#  ppp timeout retry 10
#                                                                              
###############################################################################

package require Ixia

set test_name [info script]

set chassisIP sylvester
set port_list [list 2/1]

set sess_count 5000

# Connect to the chassis, reset to factory defaults and take ownership
set connect_status [::ixia::connect                                            \
        -reset                                                                 \
        -device                     $chassisIP                                 \
        -port_list                  $port_list                                 \
        -username                   ixiaApiUser                                \
        ]
if {[keylget connect_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget connect_status log]"
}

set port_handle [keylget connect_status port_handle.$chassisIP.$port_list]
################################################################################
# Configure access interfaces in the test (one for each tunnel)
################################################################################
set interface_status [::ixia::interface_config                                 \
        -port_handle                $port_handle                               \
        -mode                       config                                     \
        -speed                      auto                                       \
        -duplex                     auto                                       \
        -phy_mode                   copper                                     \
        -autonegotiation            1                                          \
        ]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}
################################################################################
# Configure PPP sessions
################################################################################
set pppox_config_status [::ixia::pppox_config                                  \
        -port_handle                $port_handle                               \
        -protocol                   pppoe                                      \
        -encap                      ethernet_ii                                \
        -num_sessions               $sess_count                                \
        -enable_setup_throttling    1                                          \
        -max_outstanding            100                                        \
        ]

if {[keylget pppox_config_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget pppox_config_status log]"
}

set pppox_handle1 [keylget pppox_config_status handle]

################################################################################
# Setup session 
################################################################################
set pppox_control_status [::ixia::pppox_control                                \
        -handle                     $pppox_handle1                             \
        -action                     connect                                    \
        ]

if {[keylget pppox_control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget pppox_control_status log]"
}

################################################################################
# Stats 
################################################################################
set retry_count          500
set retry_iteration_time 500
for {set i 0} {$i < $retry_count} {incr i} {
    # Stats for subport 1
    set aggr_status [::ixia::pppox_stats \
            -handle $pppox_handle1       \
            -mode   aggregate            ]
    if {[keylget aggr_status status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget aggr_status log]"
    }
    set sess_total           [keylget aggr_status aggregate.num_sessions]
    set sess_count_up1       [keylget aggr_status aggregate.connected]
    set sess_connecting1     [keylget aggr_status aggregate.connecting]
    
    puts "\nIxia Test Results - retry $i... "
    puts [format "%30s %30s %30s" "Number of connected sessions" "Number of sessions connecting" \
                                            "Total number of sessions"]
    puts [string repeat "-" 90]
    puts [format "%30d %30d %30d" $sess_count_up1 $sess_connecting1 $sess_total]
    
    if {$sess_count_up1 == $sess_count} {
        break
    }
    
    if {[keylget aggr_status aggregate.connecting] > 100} {
        return "FAIL - $test_name - Throttling max outstanding value 100 was exceeded. \
                Out of range value is [keylget aggr_status aggregate.connecting]"
    }
    
    update idletasks
    
    after $retry_iteration_time
}

if {$i >= $retry_count} {
    return "FAIL - $test_name - Failed to bring up all sessions"
}

################################################################################
# Disconnect sessions 
################################################################################
set pppox_control_status [::ixia::pppox_control                                \
        -handle                     $pppox_handle1                             \
        -action                     disconnect                                 \
        ]

if {[keylget pppox_control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget pppox_control_status log]"
}

set cleanup_status [::ixia::cleanup_session                                    \
        -port_handle                $port_handle                               \
        -reset                      1                                          \
        ]
if {[keylget cleanup_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget cleanup_status log]"
}

return "SUCCESS - $test_name - [clock format [clock seconds]]"

