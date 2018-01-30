#################################################################################
# Version 1.0    $Revision: 1 $
# $Author: LRaicea $
#
#    Copyright © 1997 - 2007 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    05-22-2007 LRaicea
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
#    SRC port and the DUT. The flapping of the sessions is started.            #
#    After that a few statistics are being retrieved.                          #
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
set port_list [list 4/3]
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

ixPuts "Ixia port handles are $port_handle "

################################################################################
# Configure source interface in the test
################################################################################
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

################################################################################
#  Configure PPPoE sessions
################################################################################
set flap_rate          [expr $sess_count / 2]
set flap_repeat_count  3
set flap_hold_time     30
set flap_cool_off_time 10
set config_status [::ixia::pppox_config        \
        -port_handle       $port_src_handle    \
        -protocol          pppoe               \
        -encap             ethernet_ii         \
        -num_sessions      $sess_count         \
        -auth_req_timeout  10                  \
        -disconnect_rate   $flap_rate          \
        -attempt_rate      $flap_rate          \
        -flap_rate         $flap_rate          \
        -flap_repeat_count $flap_repeat_count  \
        -hold_time         $flap_hold_time     \
        -cool_off_time     $flap_cool_off_time ]
if {[keylget config_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget config_status log]"
}
set pppox_handle [keylget config_status handle]
ixPuts "Ixia pppox_handle is $pppox_handle "

################################################################################
#  Start flapping sessions
################################################################################
set control_status [::ixia::pppox_control \
        -handle     $pppox_handle         \
        -action     start_flapping        ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

ixPuts "Sessions going up..."

set pppoe_attempts    0
set pppoe_sessions_up 0
set pppoe_retries     60
while {($pppoe_attempts < $pppoe_retries) && ($pppoe_sessions_up < $sess_count)} {
    set pppox_status [::ixia::pppox_stats     \
            -handle   $pppox_handle       \
            -mode     aggregate           ]
    
    if {[keylget pppox_status status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget pppox_status log]"
    }
    set  aggregate_stats   [keylget pppox_status aggregate]
    set  pppoe_sessions_up [keylget aggregate_stats sessions_up]
    ixPuts "Sessions up: $pppoe_sessions_up ..."
    after 1000
}

for {set num_flap 0} {$num_flap < $flap_repeat_count} {incr num_flap} {
    ixPuts ""
    ixPuts ""
    ixPuts "-------------------- Flap Iteration [expr $num_flap + 1] -------------------- "
    ixPuts "Hold sessions up for ${flap_hold_time} (s)..."
    set pppoe_attempts    0
    set pppoe_retries     60
    ixPuts -nonewline "Sessions up - $pppoe_sessions_up"
    while {($pppoe_attempts < $pppoe_retries) && ($pppoe_sessions_up >= $sess_count)} {
        set pppox_status [::ixia::pppox_stats     \
                -handle   $pppox_handle       \
                -mode     aggregate           ]
        
        if {[keylget pppox_status status] != $::SUCCESS} {
            return "FAIL - $test_name - [keylget pppox_status log]"
        }
        set  aggregate_stats   [keylget pppox_status aggregate]
        set  pppoe_sessions_up [keylget aggregate_stats sessions_up]
        ixPuts -nonewline " - $pppoe_sessions_up"
        after 500
    }
    ixPuts " sessions ..."
    ixPuts "Started to teardown sessions ..."
    set pppoe_attempts    0
    set pppoe_retries     60
    ixPuts  -nonewline "Sessions up - $pppoe_sessions_up"
    while {($pppoe_attempts < $pppoe_retries) && ($pppoe_sessions_up > 0)} {
        set pppox_status [::ixia::pppox_stats     \
                -handle   $pppox_handle       \
                -mode     aggregate           ]
        
        if {[keylget pppox_status status] != $::SUCCESS} {
            return "FAIL - $test_name - [keylget pppox_status log]"
        }
        set  aggregate_stats   [keylget pppox_status aggregate]
        set  pppoe_sessions_up [keylget aggregate_stats sessions_up]
        ixPuts  -nonewline " - $pppoe_sessions_up"
        after 500
    }
    ixPuts " sessions ..."
    ixPuts "Teardown successful ..."
    ixPuts "Hold sessions down for ${flap_cool_off_time} (s) ..."
    set pppoe_attempts    0
    set pppoe_retries     60
    ixPuts  -nonewline "Sessions up - $pppoe_sessions_up"
    while {($pppoe_attempts < $pppoe_retries) && ($pppoe_sessions_up < 1)} {
        set pppox_status [::ixia::pppox_stats     \
                -handle   $pppox_handle       \
                -mode     aggregate           ]
        
        if {[keylget pppox_status status] != $::SUCCESS} {
            return "FAIL - $test_name - [keylget pppox_status log]"
        }
        set  aggregate_stats   [keylget pppox_status aggregate]
        set  pppoe_sessions_up [keylget aggregate_stats sessions_up]
        ixPuts  -nonewline " - $pppoe_sessions_up"
        after 500
    }
    ixPuts " sessions ..."
    ixPuts "Started to setup sessions ..."
    set pppoe_attempts    0
    set pppoe_retries     60
    ixPuts  -nonewline "Sessions up - $pppoe_sessions_up"
    while {($pppoe_attempts < $pppoe_retries) && ($pppoe_sessions_up < $sess_count)} {
        set pppox_status [::ixia::pppox_stats \
                -handle   $pppox_handle       \
                -mode     aggregate           ]
        
        if {[keylget pppox_status status] != $::SUCCESS} {
            return "FAIL - $test_name - [keylget pppox_status log]"
        }
        set  aggregate_stats   [keylget pppox_status aggregate]
        set  pppoe_sessions_up [keylget aggregate_stats sessions_up]
        ixPuts  -nonewline " - $pppoe_sessions_up"
        after 500
    }
    ixPuts " sessions ..."
}

################################################################################
# Stop flapping
################################################################################
ixPuts "Disconnecting $pppoe_sessions_up sessions. "
set control_status [::ixia::pppox_control \
        -handle     $pppox_handle         \
        -action     stop_flapping         ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

::ixia::cleanup_session -port_handle $port_handle

return "SUCCESS - $test_name - [clock format [clock seconds]]"
