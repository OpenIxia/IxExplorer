################################################################################
# Version 1.0    $Revision: 1 $
# $Author: CCovaci $
#
#    Copyright © 1997 - 2008 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    07-25-2006 CCovaci
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
#    This sample configures one dhcp session using ATM cards.                  #
#    Then it configures a group using llc_eth_fcs                              #
#     encapsulation and writes it to hardware.                                 #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a ATM/POS 622  module.                           #
#                                                                              #
################################################################################

################################################################################
#  DUT configuration example:
#      conf t
#      ip dhcp pool cici
#      network 11.11.11.0 255.255.255.0
#      default-router 11.11.11.1
#      lease 0 0 10
#      service dhcp
#
#      interface Loopback1
#      ip address 11.11.11.1 255.255.255.0
#
#      interface ATM2/0
#      no ip address
#      no atm ilmi-keepalive
#      interface ATM2/0.34 point-to-point
#      ip unnumbered Loopback1
#      atm route-bridged ip
#      pvc 0/34
#      protocol ip 11.11.11.2 broadcast
#      encapsulation aal5snap
#      interface ATM2/0.35 point-to-point
#      ip unnumbered Loopback1
#      atm route-bridged ip
#      pvc 0/35
#      protocol ip 11.11.11.2 broadcast
#      encapsulation aal5snap
#
################################################################################

package require Ixia

set test_name [info script]

set chassisIP sylvester
set port_list [list 3/1]

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
###############################################################################
##############################################################################

set interface_status [::ixia::interface_config \
        -port_handle     $port_handle          \
        -intf_mode       atm                   \
        -tx_c2           13                    \
        -rx_c2           13                    \
        -speed           oc3                   ]
if {[keylget interface_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget interface_status log]"
}
#################################################
#  Configure DHCP on the interface 1/4/1        #
#################################################
set dhcp_portHandle_status [::ixia::emulation_dhcp_config  \
        -mode                        create                \
        -port_handle                 $port_handle          \
        -version                     ixaccess              \
        -lease_time                  33                    \
        -reset                                             \
        -no_write                                          ]
if {[keylget dhcp_portHandle_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcp_portHandle_status log]"
}

set session_handle [keylget dhcp_portHandle_status handle]

set dhcp_group_status [::ixia::emulation_dhcp_group_config \
        -mode          create                              \
        -handle        $session_handle                     \
        -mac_addr      00.00.00.00.22.11                   \
        -num_sessions  2                                   \
        -encap         llc_eth_fcs                         \
        -vpi           0                                   \
        -vci           34                                  \
        -vci_count     2                                   \
        -version       ixaccess                            ]
if {[keylget dhcp_group_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcp_group_status log]"
}

set group_handle [keylget dhcp_group_status handle]

set dhcp_stats_status [::ixia::emulation_dhcp_stats \
        -port_handle  $session_handle               \
        -version      ixaccess                      ]
if {[keylget dhcp_stats_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcp_stats_status log]"
}

after 35000

set session_num          [keylget dhcp_stats_status aggregate.currently_attempting]
set session_notbounded   [keylget dhcp_stats_status aggregate.currently_idle]
set addr_learned         [keylget dhcp_stats_status aggregate.currently_bound]
set succes_perc          [keylget dhcp_stats_status aggregate.success_percentage]
set discovered_mess      [keylget dhcp_stats_status aggregate.discover_tx_count]
set num_request          [keylget dhcp_stats_status aggregate.request_tx_count]
set num_release          [keylget dhcp_stats_status aggregate.release_tx_count]
set num_ack              [keylget dhcp_stats_status aggregate.ack_rx_count]
set num_nack             [keylget dhcp_stats_status aggregate.nak_rx_count]
set num_received_offer   [keylget dhcp_stats_status aggregate.offer_rx_count]

puts "DHCP STATISTICS"
puts "Total no of enabled interfaces = $session_num"
puts "Total no of interfaces not bounded = $session_notbounded"
puts "Total no of addresses learned = $addr_learned"
puts "Percent rate of addresses learned = $succes_perc"
puts "Total no of discovered messages sent = $discovered_mess"
puts "Total no of requests sent = $num_request"
puts "Total no of releases sent = $num_release"
puts "Total no of acks received = $num_ack"
puts "Total no of nacks received = $num_nack"
puts "Total no of offers received = $num_received_offer"

set dhcp_group_status [::ixia::emulation_dhcp_group_config \
        -mode          reset                               \
        -handle        $session_handle                     \
        -version       ixaccess                            \
        -no_write                                          ]
if {[keylget dhcp_group_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget dhcp_group_status log]"
}
return "SUCCESS - $test_name - [clock format [clock seconds]]"
