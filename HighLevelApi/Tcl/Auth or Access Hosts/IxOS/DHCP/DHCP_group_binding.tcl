################################################################################
# Version 1.0    $Revision: 1 $
# $Author: LRaicea $
#
#    Copyright © 1997 - 2007 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    06-12-2007 LRaicea
#
# Description:
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
#    This sample configures/modifies 1 group of DHCP subscribers on a port.    #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a LM622MR module.                                #
#                                                                              #
################################################################################

################################################################################
# 
# DUT configuration.
#
#  conf t
#  
#  ip dhcp pool dhcpPool
#    network 110.110.0.0 255.255.0.0
#    default-router 110.110.0.1
#    lease 40
#    service dhcp
# 
# interface Loopback110
#   ip address 110.110.0.1 255.255.0.0
# 
# interface ATM1/0
#   no ip address
#   no ip route-cache cef
#   no ip route-cache
#   atm clock INTERNAL
#   no atm ilmi-keepalive
#  
# interface ATM1/0.220 point-to-point
#   mtu 1500
#   ip unnumbered Loopback110
#   no ip route-cache
#   atm route-bridged ip
#   pvc 110/220
#     encapsulation aal5snap
#  
# interface ATM1/0.221 point-to-point
#   mtu 1500
#   ip unnumbered Loopback110
#   no ip route-cache
#   atm route-bridged ip
#   pvc 110/221
#     encapsulation aal5snap
# 
# interface ATM1/0.222 point-to-point
#   mtu 1500
#   ip unnumbered Loopback110
#   no ip route-cache
#   atm route-bridged ip
#   pvc 110/222
#     encapsulation aal5snap
#

package require Ixia

set test_name [info script]


set chassisIP   sylvester
set port_list   [list 16/1]
set numSessions 200

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

################################################################################
#  Configure layer 1-2 parameters for the interface in the test
################################################################################
set interface_status [::ixia::interface_config \
        -port_handle      $port_handle         \
        -mode             config               \
        -speed            oc3                  \
        -intf_mode        atm                  \
        -clocksource      loop                 \
        -tx_c2            13                   \
        -rx_c2            13                   ]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}

################################################################################
#  Configure DHCP parameters for the interface in the test
################################################################################
set dhcp_port_status [::ixia::emulation_dhcp_config \
        -reset                                          \
        -mode                        create             \
        -port_handle                 $port_handle       \
        -lease_time                  100                \
        -max_dhcp_msg_size           1000               ]        

if {[keylget dhcp_port_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcp_port_status log]"
}
set dhcp_portHandle [keylget dhcp_port_status handle]

################################################################################
#  Configure one DHCP group
################################################################################
set dhcp_group_status [::ixia::emulation_dhcp_group_config \
        -mode            create                            \
        -mac_addr        00.10.95.22.11.09                 \
        -mac_addr_step   00.00.00.00.00.01                 \
        -num_sessions    $numSessions                      \
        -handle          $dhcp_portHandle                  \
        -encap           llcsnap                           \
        -vci             220                               \
        -vpi             110                               \
        -vci_step        1                                 \
        -vpi_step        1                                 \
        -vci_count       3                                 \
        -vpi_count       1                                 \
        -sessions_per_vc 4                                 \
        -pvc_incr_mode   vci                               ]

if {[keylget dhcp_group_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcp_group_status log]"
}
set dhcp_groupHandle [keylget dhcp_group_status handle]

################################################################################
# Start DHCP binding
################################################################################
   
set dhcp_control_status [::ixia::emulation_dhcp_control \
        -port_handle    $dhcp_portHandle                \
        -action         bind                            \
        -handle         $dhcp_groupHandle               ]        

if {[keylget dhcp_control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcp_control_status log]"
}

################################################################################
# Retrieve DHCP stats
################################################################################

set numBounded 0
set numRetries 0
while {($numBounded < $numSessions) && ($numRetries < 10)} {
    set startTime [clock seconds]
    set stat_status [::ixia::emulation_dhcp_stats \
            -port_handle $dhcp_portHandle       \
            -handle      $dhcp_groupHandle      ]
    
    if {[keylget stat_status status] == $::FAILURE} {
        return "FAIL - $test_name - [keylget dhcp_control_status log]"
    }
    
    set stopTime [clock seconds]
    set totalTime [mpexpr $stopTime - $startTime]
    ixPuts "Retrieving stats took $totalTime seconds ..."
    ixPuts $stat_status
    set numBounded [keylget stat_status aggregate.currently_bound]
    incr numRetries
    after 1000
}

return "SUCCESS - $test_name - [clock format [clock seconds]]"

