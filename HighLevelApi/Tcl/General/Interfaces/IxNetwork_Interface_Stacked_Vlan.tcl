################################################################################
# Version 1.0    $Revision: 1 $
# $Author: Enache Adrian $
#
#    Copyright � 1997 - 2011 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
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
###############################################################################

################################################################################
#                                                                              #
# Description:                                                                 #
#    This sample configures a port using IxTclProtocol API having 3 stacked    #
#    vlans.                                                                    #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a 10/100/1000 STX4-256MB module.                 #
#                                                                              #
################################################################################

set env(IXIA_VERSION) HLTSET105
package require Ixia

#set ixia::debug 3
set test_name [info script]

set chassisIP sylvester
set port_list {2/1}

# Connect to the chassis, reset to factory defaults and take ownership
# When using P2NO HLTSET, for loading the IxTclNetwork package please 
# provide �ixnetwork_tcl_server parameter to ::ixia::connect
set connect_status [::ixia::connect \
        -reset                          \
        -device    $chassisIP           \
        -port_list $port_list           \
        -username  ixiaApiUser          ]
if {[keylget connect_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget connect_status log]"
}

set port_handle [keylget connect_status port_handle.$chassisIP.$port_list]

########################################
# Configure interface in the test      #
########################################
set interface_status [::ixia::interface_config \
        -mode config                         \
        -port_handle     $port_handle        \
        -autonegotiation 1                   \
        -duplex          full                \
        -speed           ether100            \
        -l23_config_type protocol_interface  \
        -gateway         8.0.0.2             \
        -intf_ip_addr    8.0.0.1             \
        -netmask         255.255.255.0       \
        -vlan            [list 1]            \
        -vlan_id         [list 400,500,600]  \
        -vlan_user_priority [list 2,3,4]     ]
        
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}
        
puts "SUCCESS - [info script] - [clock format [clock seconds]]"
return 1