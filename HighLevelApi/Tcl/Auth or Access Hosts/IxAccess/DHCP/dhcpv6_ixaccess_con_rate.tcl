################################################################################
# Version 1.0    $Revision: 1 $
# $Author: RAntonescu $
#
#    Copyright © 1997 - 2008 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    07-19-2007 RAntonescu - created sample
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
#    This sample configures one dhcpV6 sessions and one group for that session #
#     with 10 clients, then it writes the config to hardware.                  #
#                                                                              #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a 10/100/1000 STXS4-256Mb module.                #
#                                                                              #
################################################################################

################################################################################
#  DUT configuration example:
#    ipv6 dhcp pool dhcp-pool
#        prefix-delegation pool client-prefix-pool1 lifetime 1800 600
#        dns-server 2001:0DB8:3000:3000::42
#        exit
#    interface Ethernet0/0
#         ipv6 address FEC0:240:104:2001::139/64
#         ipv6 dhcp server dhcp-pool
#         exit
#    ipv6 local pool client-prefix-pool1 2001:0DB8:1200::/40 48
#
################################################################################

package require Ixia

set test_name [info script]
set chassisIP sylvester
set port_list [list 3/3]

# Connect to the chassis, reset to factory defaults and take ownership
set connect_status [::ixia::connect \
        -reset                      \
        -device    $chassisIP       \
        -port_list $port_list       \
        -username  ixiaApiUser      ]
if {[keylget connect_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget connect_status log]"
}

set port_handle [keylget connect_status port_handle.$chassisIP.$port_list]

################################################################################
# Configure DHCP on the interface
################################################################################
set dhcpv6_portHandle_status [::ixia::emulation_dhcpv6_config \
        -mode                        create                   \
        -port_handle                 $port_handle             \
        -ia_type                     IAPD                     \
        -reset                                                ]
if {[keylget dhcpv6_portHandle_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcpv6_portHandle_status1 log]"
}

set session_handle [keylget dhcpv6_portHandle_status handle]

set dhcpv6_group_status [::ixia::emulation_dhcpv6_group_config \
        -mode           create                                 \
        -mac_addr       00.10.95.22.11.09                      \
        -mac_addr_step  1                                      \
        -num_sessions   10                                     \
        -handle         $session_handle                        \
        -target_subport 0                                      \
        -vlan_id        2000                                   ]
if {[keylget dhcpv6_group_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcpv6_group_status log]"
}

set dhcp_control_status [::ixia::emulation_dhcpv6_control \
        -port_handle    $port_handle                      \
        -bind           bind                              \
        -request_rate   1                                 ]
if {[keylget dhcp_control_status status] != $::SUCCESS} {
    return [keylget dhcp_control_status log]
}

return "SUCCESS - $test_name - [clock format [clock seconds]]"
