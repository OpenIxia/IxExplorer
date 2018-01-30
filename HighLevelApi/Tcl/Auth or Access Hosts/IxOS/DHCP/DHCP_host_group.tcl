################################################################################
# Version 1.0    $Revision: 1 $
# $Author: MRidichie $
#
#    Copyright © 1997 - 2005 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    01-04-2006 MRidichie
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
#    The sample was tested on a LM100TXS8 module.                              #
#                                                                              #
################################################################################

package require Ixia

set test_name [info script]
 
set chassisIP 127.0.0.1
set port_list [list 10/1]

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
#  Configure DHCP on the interface 1/4/1        #
#################################################
set dhcp_portHandle_status [::ixia::emulation_dhcp_config \
        -mode                        create             \
        -port_handle                 $port_handle       \
        -lease_time                  100                \
        -max_dhcp_msg_size           1000               \
        -reset                                          ]        

if {[keylget dhcp_portHandle_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcp_portHandle_status log]"
} 

# Get the DHCP port handle from the keyed list (a session handle)
set dhcp_portHandle [keylget dhcp_portHandle_status handle] 

set dhcp_portHandle_status [::ixia::emulation_dhcp_config \
        -mode                        modify             \
        -handle                      $dhcp_portHandle   \
        -lease_time                  200                \
        -max_dhcp_msg_size           2000               ]

if {[keylget dhcp_portHandle_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcp_portHandle_status log]"
}

#####################################################################
#  Configure one group on each session on the interface 1/4/1       #
#####################################################################

# Set dhcp group
set dhcp_group_status [::ixia::emulation_dhcp_group_config \
        -mode          create                              \
        -mac_addr      00.10.95.22.11.09                   \
        -mac_addr_step 00.00.00.00.00.01                   \
        -num_sessions  10                                  \
        -handle        $dhcp_portHandle                    \
        -encap         vc_mux                              \
        -vci           0                                   \
        -vpi           32                                  \
        -vci_step      2                                   \
        -vpi_step      3                                   \
        -vci_count     5                                   \
        -vpi_count     10                                  \
        -sessions_per_vc 4                                 \
        -pvc_incr_mode vci                                 ]

if {[keylget dhcp_group_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcp_group_status log]"
}

# Get the group handle from keyed list
set dhcp_groupHandle [keylget dhcp_group_status handle]

set dhcp_group_status [::ixia::emulation_dhcp_group_config \
        -mode          modify                              \
        -handle        $dhcp_groupHandle                   \
        -vci           1                                   \
        -vpi           10                                  ]

if {[keylget dhcp_group_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcp_group_status log]"
}

######################
# START DHCP         #
######################
   
set dhcp_control_status [::ixia::emulation_dhcp_control \
        -port_handle    $dhcp_portHandle                \
        -action         bind                            \
        -handle         $dhcp_groupHandle               ]        

if {[keylget dhcp_control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcp_control_status log]"
}

# A delay is needed for seeing all the messages on the router
after 15000

set dhcp_control_status [::ixia::emulation_dhcp_control \
        -port_handle    $dhcp_portHandle                \
        -action         renew                           \
        -handle         $dhcp_groupHandle               ]        

if {[keylget dhcp_control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcp_control_status log]"
}

######################
# DHCP STATISTICS    #
######################

set dhcp_stats_status [::ixia::emulation_dhcp_stats \
        -port_handle  $dhcp_portHandle              \
        -handle       $dhcp_groupHandle             ]        

if {[keylget dhcp_control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcp_control_status log]"
}

if {![catch {keylget dhcp_stats_status aggregate} dhcp_aggregate_stats]} {
    ixPuts "dhcp aggregate stats = $dhcp_aggregate_stats"
}

if {![catch {keylget dhcp_stats_status group} dhcp_group_stats]} {
    ixPuts "dhcp group stats = $dhcp_group_stats"
}

set dhcp_stats_status [::ixia::emulation_dhcp_stats \
        -port_handle  $dhcp_portHandle              \
        -action       clear                         ]

if {[keylget dhcp_control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcp_control_status log]"
}

return "SUCCESS - $test_name - [clock format [clock seconds]]"

