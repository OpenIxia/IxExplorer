################################################################################
# Version 1.0    $Revision: 2 $
# $Author: Lavinia Raicea $
#
#    Copyright � 1997 - 2005 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    26/5-2005 Lavinia Raicea
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
#    This sample creates three RIPng routers and add two route ranges to each  #
#    router.                                                                   #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a LM100TXS8 module.                              #
#                                                                              #
################################################################################

package require Ixia

set test_name [info script]

set chassisIP 127.0.0.1
set port_list 10/1

# Connect to the chassis, reset to factory defaults and take ownership
# When using P2NO HLTSET, for loading the IxTclNetwork package please 
# provide �ixnetwork_tcl_server parameter to ::ixia::connect
set connect_status [::ixia::connect \
        -reset                    \
        -device    $chassisIP     \
        -port_list $port_list     \
        -username  ixiaApiUser    ]
if {[keylget connect_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget connect_status log]"
}

set port_handle [keylget connect_status port_handle.$chassisIP.$port_list]

########################################
# Configure interface in the test      #
# IPv4                                 #
########################################
set interface_status [::ixia::interface_config \
        -port_handle     $port_handle        \
        -autonegotiation 1                   \
        -duplex          full                \
        -speed           ether100            ]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}

###################################################
#  Configure interfaces and create RIPng sessions #
###################################################
# Create first router
# This has the ixia option -reset in order to clear the existing RIP
# configuration for that port
set rip_status [::ixia::emulation_rip_config         \
        -port_handle                 $port_handle  \
        -mode                        create        \
        -reset                                     \
        -session_type                ripng         \
        -intf_ip_addr                30:30:30:1:0:0:0:2  \
        -intf_prefix_length          64            \
        -update_interval             28            \
        -update_interval_offset      2             \
        -update_mode                 no_horizon    \
        -receive_type                store         \
        -interface_metric            2             \
        -time_period                 100           \
        -num_routes_per_period       10            \
        -router_id                   20            \
        -mac_address_init            0000.0000.0001]
if {[keylget rip_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget rip_status log]"
}

set rip_routers [keylget rip_status handle]

# Create second router with vlan id 2
set rip_status [::ixia::emulation_rip_config         \
        -port_handle                 $port_handle  \
        -mode                        create        \
        -session_type                ripng         \
        -intf_ip_addr                30:30:30:2:0:0:0:2  \
        -intf_ip_addr_step           0:0:0:0:0:0:0:1     \
        -intf_prefix_length          64            \
        -update_interval             28            \
        -update_interval_offset      2             \
        -update_mode                 no_horizon    \
        -receive_type                store         \
        -interface_metric            2             \
        -time_period                 100           \
        -num_routes_per_period       10            \
        -router_id                   30            \
        -vlan_id                     2             \
        -mac_address_init            0000.0000.0002]
if {[keylget rip_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget rip_status log]"
}
set rip_routers [concat $rip_routers [keylget rip_status handle]]

# Create third router with vlan id 1500
set rip_status [::ixia::emulation_rip_config         \
        -port_handle                 $port_handle  \
        -mode                        create        \
        -session_type                ripng         \
        -intf_ip_addr                30:30:30:3:0:0:0:2  \
        -intf_ip_addr_step           0:0:0:0:0:0:0:1     \
        -intf_prefix_length          64            \
        -update_interval             28            \
        -update_interval_offset      2             \
        -update_mode                 no_horizon    \
        -receive_type                store         \
        -interface_metric            2             \
        -time_period                 100           \
        -num_routes_per_period       10            \
        -router_id                   40            \
        -vlan_id                     1500          \
        -mac_address_init            0000.0000.0003]
if {[keylget rip_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget rip_status log]"
}
set rip_routers [concat $rip_routers [keylget rip_status handle]]

set i 5
foreach rip_router $rip_routers {
    # Create first route range
    set rip_status [::ixia::emulation_rip_route_config            \
            -handle                      $rip_router            \
            -mode                        create                 \
            -reset                                              \
            -num_prefixes                5                      \
            -prefix_start                1$i:10:0:0:0:0:0:0     \
            -prefix_step                 0:0100:0:0:0:0:0:0     \
            -prefix_length               72                     \
            -metric                      2                      \
            -next_hop                    FE80:0:0:0:$i:$i:$i:$i \
            ]
    if {[keylget rip_status status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget rip_status log]"
    }
    
    # Create second route range
    set rip_status [::ixia::emulation_rip_route_config              \
            -handle                      $rip_router              \
            -mode                        create                   \
            -num_prefixes                5                        \
            -prefix_start                2$i:2$i:2$i:20:0:0:0:0   \
            -metric                      2                        \
            -route_tag                   100                      \
            -next_hop                    FE81:0:0:0:$i:$i:$i:$i   \
            ]
    if {[keylget rip_status status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget rip_status log]"
    }
    incr i
}

return "SUCCESS - $test_name - [clock format [clock seconds]]"
