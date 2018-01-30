################################################################################
# Version 1.0    $Revision: 1 $
# $Author: MHasegan $
#
#    Copyright © 1997 - 2008 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    07-18-2006 MHasegan - created sample
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
#    This sample configures two dhcpV6 sessions and modifies the first one.    #
#    Then it resets the configurations.                                        #
#    Nothing is written to harware.                                            #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a 10/100/1000 STXS4-256Mb module.                #
#                                                                              #
################################################################################

################################################################################
#  DUT configuration example:
#     No Dut config is required. Nothing is written to hardware
# 
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

################################################################################
# Configure DHCP on the interface 
################################################################################
set dhcpv6_portHandle_status1 [::ixia::emulation_dhcpv6_config \
        -mode                        create                    \
        -port_handle                 $port_handle              \
        -renew_timer                 311                       \
        -reset                         ]
if {[keylget dhcpv6_portHandle_status1 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcpv6_portHandle_status1 log]"
}
set session_handle1 [keylget dhcpv6_portHandle_status1 handle]

set dhcpv6_portHandle_status2 [::ixia::emulation_dhcpv6_config \
        -mode                        create                    \
        -port_handle                 $port_handle              \
        -renew_timer                 312                       ]
if {[keylget dhcpv6_portHandle_status2 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcpv6_portHandle_status2 log]"
}
set session_handle2 [keylget dhcpv6_portHandle_status2 handle]

set dhcpv6_portHandle_status [::ixia::emulation_dhcpv6_config \
        -mode                        modify                   \
        -handle                      $session_handle1         \
        -renew_timer                 322                      ]
if {[keylget dhcpv6_portHandle_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcpv6_portHandle_status log]"
}

set dhcpv6_portHandle_status [::ixia::emulation_dhcpv6_config \
        -mode                        reset              \
        -port_handle                 $port_handle       ]

if {[keylget dhcpv6_portHandle_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcpv6_portHandle_status log]"
}

return "SUCCESS - $test_name - [clock format [clock seconds]]"
