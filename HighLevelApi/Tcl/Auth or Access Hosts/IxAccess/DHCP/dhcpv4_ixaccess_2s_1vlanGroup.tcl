################################################################################
# Version 1.0    $Revision: 1 $
# $Author: MHasegan $
#
#    Copyright � 1997 - 2008 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    07-18-2006 MHasegan
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
#    This sample configures two dhcp sessions and modifies the first one.      #
#    Then it configures a group for the first sessions using ethernet_ii_vlan  #
#     encapsulation and writes it to hardware.                                 #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a 10/100/1000 STXS4-256Mb module.                #
#                                                                              #
################################################################################

################################################################################
#  DUT configuration example:
#        ip dhcp pool ixiaTest
#        network 200.200.141.0 255.255.255.0
#        exit
#        default interface g1/38
#        int g1/38
#        ip address 200.200.141.1 255.255.255.0
#        no shut
#        exit
#         ip dhcp pool ixia_vpn
#         network 200.200.142.0 255.255.255.0
#         exit
#         int g1/38.1
#         encapsulation dot1Q 2000
#         ip address 200.200.142.1 255.255.255.0
#         no shut
#        exit
#         service dhcp
# 
################################################################################

package require Ixia

set test_name [info script]

set chassisIP sylvester
set port_list [list 2/3]

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

#################################################
#  Configure DHCP on the interface 1/2/3        #
#################################################
set dhcp_portHandle_status1 [::ixia::emulation_dhcp_config \
        -mode           create              \
        -port_handle    $port_handle        \
        -lease_time     311                 \
        -version        ixaccess            \
        -reset                              \
        -no_write                           ]
if {[keylget dhcp_portHandle_status1 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcp_portHandle_status1 log]"
}
set session_handle1 [keylget dhcp_portHandle_status1 handle]

set dhcp_portHandle_status2 [::ixia::emulation_dhcp_config \
        -mode                        create                \
        -port_handle                 $port_handle          \
        -lease_time                  312                   \
        -max_dhcp_msg_size           1000                  \
        -version                     ixaccess              \
        -no_write                                          ]
if {[keylget dhcp_portHandle_status2 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcp_portHandle_status2 log]"
}
set session_handle2 [keylget dhcp_portHandle_status2 handle]

set dhcp_portHandle_status [::ixia::emulation_dhcp_config \
        -mode                        modify               \
        -handle                      $session_handle1     \
        -lease_time                  322                  \
        -version                     ixaccess             \
        -no_write                                         ]
if {[keylget dhcp_portHandle_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcp_portHandle_status log]"
}

set dhcp_group_status [::ixia::emulation_dhcp_group_config \
        -mode          create                              \
        -mac_addr      00.10.95.22.11.10                   \
        -mac_addr_step 1                                   \
        -num_sessions  4                                   \
        -handle        $session_handle1                    \
        -encap         ethernet_ii_vlan                    \
        -vlan_id       2000                                \
        -version       ixaccess                            ]
if {[keylget dhcp_group_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcp_group_status log]"
}

return "SUCCESS - $test_name - [clock format [clock seconds]]"
