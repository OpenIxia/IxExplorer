#################################################################################
# Version 1.0    $Revision: 1 $
# $Author: T. Kong $
#
# $Workfile: OSPFv3_topology_config_summary.tcl $
#
#    Copyright � 1997 - 2005 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
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
#    This sample creates two OSPFv3 routers on two different ports. Then on    #
#    the first router it configures a pool of summary routes.                  #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a LM100TXS8 module.                              #
#                                                                              #
################################################################################

package require Ixia

set test_name [info script]

set chassisIP 127.0.0.1
set port_list [list 10/1 10/2]

# Connect to the chassis, reset to factory defaults and take ownership
# When using P2NO HLTSET, for loading the IxTclNetwork package please 
# provide �ixnetwork_tcl_server parameter to ::ixia::connect
set connect_status [::ixia::connect \
        -reset                \
        -device    $chassisIP \
        -port_list $port_list \
        -username  ixiaApiUser]

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

set port_tx [lindex $port_handle 0]
set port_rx [lindex $port_handle 1]

########################################
# Configure interface in the test      #
#                                      #
########################################
set interface_status [::ixia::interface_config \
        -port_handle     $port_handle \
        -autonegotiation 1            \
        -duplex          full         \
        -speed           ether1000]

if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}

#################################################
#                                               #
#  Configure n OSPFv3 neighbors                 #
#                                               #
#################################################

#### TX Port ####
set ospf_neighbor_status [::ixia::emulation_ospf_config \
        -port_handle                $port_tx         \
        -reset                                       \
        -session_type               ospfv3           \
        -mode                       create           \
        -count                      1                \
        -mac_address_init           1000.0000.0001   \
        -intf_ip_addr               4000:0:0:1::1    \
        -intf_ip_addr_step          0:0:0:1::0       \
        -router_id                  30.1.1.1         \
        -router_id_step             0.0.1.0          \
        -area_id                    0.0.0.1          \
        -area_id_step               0.0.0.1          \
        -area_type                  external-capable \
        -authentication_mode        null             \
        -dead_interval              222              \
        -hello_interval             10               \
        -interface_cost             55               \
        -lsa_discard_mode           1                \
        -mtu                        670              \
        -network_type               ptop             \
        -demand_circuit             1]

if {[keylget ospf_neighbor_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget ospf_neighbor_status log]"
}

set session_handle [keylget ospf_neighbor_status handle]

#######################################################
#                                                     #
#  Configure a summary routes behind a session router #
#                                                     #
#######################################################
set route_config_status [::ixia::emulation_ospf_topology_route_config\
        -mode           create                  \
        -handle         $session_handle         \
        -type           summary_routes          \
        -summary_number_of_prefix  10           \
        -summary_prefix_start      2500:0:0:1::1\
        -summary_prefix_length     32           \
        -summary_prefix_metric     5            \
        -summary_prefix_step       2            \
        ]

if {[keylget route_config_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget route_config_status log]"
}


#### RX Port ####
set ospf_neighbor_status [::ixia::emulation_ospf_config \
        -port_handle                $port_rx         \
        -reset                                       \
        -session_type               ospfv3           \
        -mode                       create           \
        -count                      1                \
        -mac_address_init           1000.0000.0002   \
        -intf_ip_addr               4000:0:0:2::1    \
        -intf_ip_addr_step          0:0:0:1::0       \
        -router_id                  30.1.1.2         \
        -router_id_step             0.0.1.0          \
        -area_id                    0.0.0.1          \
        -area_id_step               0.0.0.0          \
        -area_type                  ppp              \
        -dead_interval              222              \
        -hello_interval             10               \
        -interface_cost             15               \
        -mtu                        1500             \
        -network_type               ptop             \
        -demand_circuit             1]

if {[keylget ospf_neighbor_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget ospf_neighbor_status log]"
}

return "SUCCESS - $test_name - [clock format [clock seconds]]"



