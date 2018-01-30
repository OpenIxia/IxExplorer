################################################################################
# Version 1.0    $Revision: 1 $
# $Author: Daria Badea
#
#    Copyright © 1997 - 2008 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    03-18-2014 
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
#	 The script configures 2 VXLAN stacks and the chained device groups        #
#	 with DHCPv4 Client and DHCPv4 Server. Start protocols and get stats.      #
#																			   #
# Module:                                                                      #
#    The sample was tested on a FlexAP10G16S module.                   		   #
#                                                                              #
################################################################################

set port1 						8/4
set port2 						8/6
set test_name                   [info script]
set chassis_ip                  10.205.15.62
set ixnetwork_tcl_server        localhost
set port_list                   [list $port1 $port2]
set username                    tbadea

set PASSED 0
set FAILED 1

if {[catch {package require Ixia} retCode]} {
    puts "FAIL - $retCode"
    return $FAILED
}

set connect_status [::ixiangpf::connect \
        -reset                  1 \
        -device                 $chassis_ip \
        -username               $username \
        -port_list              $port_list \
        -ixnetwork_tcl_server   $ixnetwork_tcl_server \
        -tcl_server             $chassis_ip \
        -break_locks            1 \
        -connect_timeout        180 \
    ]
if {[keylget connect_status status] != $::SUCCESS} {
    puts "FAIL - [keylget connect_status log]"
    return $FAILED
}

set port_handle [list]
foreach port $port_list {
    if {![catch {keylget connect_status port_handle.$chassis_ip.$port} \
                temp_port]} {
        lappend port_handle $temp_port
    }
}

set i 0
puts "Ixia port handles are:"
foreach port $port_handle {
    set port_$i $port
    puts $port
    set interface_handles_$port ""
    incr i
}

proc show_stats var {
    set level [expr [info level] - 1]
    foreach key [keylkeys var] {
            if {$key == "status"} {continue}
            set indent [string repeat "    " $level] 
            puts -nonewline $indent 
            if {[catch {keylkeys var $key}]} {
                puts "$key: [keylget var $key]"
                continue
            } else {
                puts $key
                puts "$indent[string repeat "-" [string length $key]]"
            }
            show_stats [keylget var $key]
    }
}

# #############################################################################
# 								VTEP 1 CONFIG
# #############################################################################

# CREATE TOPOLOGY 1

set topology_1_status [::ixiangpf::topology_config					\
        -topology_name      {Topology 1}                            \
        -port_handle        $port_0								    \
    ]
if {[keylget topology_1_status status] != $::SUCCESS} {
    puts "FAIL - [keylget topology_1_status log]"
    return $FAILED
}

set topology_1_handle [keylget topology_1_status topology_handle]

# CREATE DEVICE GROUP 1

set device_group_1_status [::ixiangpf::topology_config      \
		-topology_handle              $topology_1_handle        \
		-device_group_multiplier      3                         \
		-device_group_enabled         1                         \
]
if {[keylget device_group_1_status status] != $::SUCCESS} {
    puts "FAIL - [keylget device_group_1_status log]"
    return $FAILED
}

set device_1_handle	[keylget device_group_1_status device_group_handle]

# CREATE ETHERNET STACK FOR VXLAN 1

set multivalue_1_status [::ixiangpf::multivalue_config \
    -pattern                counter                 \
    -counter_start          00.11.01.00.00.01       \
    -counter_step           00.00.00.00.00.01       \
    -counter_direction      increment               \
    -nest_step              00.00.01.00.00.00       \
    -nest_owner             $topology_1_handle      \
    -nest_enabled           1                       \
]
if {[keylget multivalue_1_status status] != $::SUCCESS} {
    puts "FAIL - $multivalue_1_status"
	return $FAILED
}
set multivalue_1_handle [keylget multivalue_1_status multivalue_handle]

set ethernet_1_status [::ixiangpf::interface_config \
    -protocol_name                {Ethernet 1}               \
    -protocol_handle              $device_1_handle           \
    -mtu                          1500                       \
    -src_mac_addr                 $multivalue_1_handle       \
    -vlan                         1                          \
    -vlan_id                      101                        \
    -vlan_id_step                 1                          \
    -vlan_id_count                1                          \
    -vlan_tpid                    0x8100                     \
    -vlan_user_priority           0                          \
    -vlan_user_priority_step      0                          \
    -use_vpn_parameters           0                          \
    -site_id                      0                          \
]
if {[keylget ethernet_1_status status] != $::SUCCESS} {
    puts "FAIL - $ethernet_1_status"
	return $FAILED
}
set ethernet_1_handle [keylget ethernet_1_status ethernet_handle]

set vxlan_1_status [::ixiangpf::emulation_vxlan_config                          	\
		 -mode							create									\
		 -handle						$ethernet_1_handle						\
         -intf_ip_addr					23.0.0.1							\
         -intf_ip_addr_step				0.0.0.1						\
         -ip_num_sessions               2                        \
         -intf_ip_prefix_length			24					\
         -gateway						23.0.0.100								\
         -gateway_step					0.0.0.1							\
         -enable_resolve_gateway		1					\
         -vni							600									\
		 -create_ig						0								\
         -ipv4_multicast				225.3.0.9							\
		 -sessions_per_vxlan			1		\
         -ip_to_vxlan_multiplier					1								\
		]
if {[keylget vxlan_1_status status] != $::SUCCESS} {
    puts "FAIL - [keylget vxlan_1_status log]"
    return $FAILED
}

# #############################################################################
# 					    VTEP 1 CREATE ON THE SAME DG
# #############################################################################

set vxlan_1_1_status [::ixiangpf::emulation_vxlan_config                          	\
		 -mode							create									\
		 -handle						$device_1_handle						\
         -intf_ip_addr					40.0.0.1							\
         -intf_ip_addr_step				0.0.0.1						\
         -gateway						40.0.0.100								\
         -gateway_step					0.0.0.1							\
         -enable_resolve_gateway		1					\
         -vni							640									\
		 -create_ig						0								\
         -ipv4_multicast				225.3.0.40							\
		 -sessions_per_vxlan			1		\
         -ip_to_vxlan_multiplier					1								\
		]
if {[keylget vxlan_1_1_status status] != $::SUCCESS} {
    puts "FAIL - [keylget vxlan_1_1_status log]"
    return $FAILED
}

set vxlan_1_1_handle [lindex [keylget vxlan_1_1_status vxlan_handle] 0]

# #############################################################################
# 					    	  DELETE 2nd VTEP
# #############################################################################

set vxlan_1_delete_status [::ixiangpf::emulation_vxlan_config                          	\
		 -mode							delete									\
		 -handle						$vxlan_1_1_handle				\
		]
if {[keylget vxlan_1_delete_status status] != $::SUCCESS} {
    puts "FAIL - [keylget vxlan_1_delete_status log]"
    return $FAILED
}

if {[ixNet getList [keylget vxlan_1_1_status ipv4_handle] vxlan]!=""} {
	puts "FAIL - VXLAN stack not deleted!"
	return $FAILED
}

# #############################################################################
# 					    	  DESTROY TOPOLOGY 1
# #############################################################################

set destroy_status [::ixiangpf::topology_config      \
		-topology_handle              $topology_1_handle        \
		-mode 						  destroy 				\
]
if {[keylget device_group_1_status status] != $::SUCCESS} {
    puts "FAIL - [keylget device_group_1_status log]"
    return $FAILED
}

# #############################################################################
# 								VTEP 1 CONFIG
# #############################################################################

# CREATE TOPOLOGY 1

set topology_1_status [::ixiangpf::topology_config					\
        -topology_name      {Topology 1}                            \
        -port_handle        $port_0								    \
    ]
if {[keylget topology_1_status status] != $::SUCCESS} {
    puts "FAIL - [keylget topology_1_status log]"
    return $FAILED
}

set topology_1_handle [keylget topology_1_status topology_handle]

# CREATE DEVICE GROUP 1

set device_group_1_status [::ixiangpf::topology_config      \
		-topology_handle              $topology_1_handle        \
		-device_group_name            {VTEP 1}                      \
		-device_group_multiplier      3                         \
		-device_group_enabled         1                         \
]
if {[keylget device_group_1_status status] != $::SUCCESS} {
    puts "FAIL - [keylget device_group_1_status log]"
    return $FAILED
}

set device_1_handle	[keylget device_group_1_status device_group_handle]

# CREATE ETHERNET STACK FOR VXLAN 1

set multivalue_1_status [::ixiangpf::multivalue_config \
    -pattern                counter                 \
    -counter_start          00.11.01.00.00.01       \
    -counter_step           00.00.00.00.00.01       \
    -counter_direction      increment               \
    -nest_step              00.00.01.00.00.00       \
    -nest_owner             $topology_1_handle      \
    -nest_enabled           1                       \
]
if {[keylget multivalue_1_status status] != $::SUCCESS} {
    puts "FAIL - $multivalue_1_status"
	return $FAILED
}
set multivalue_1_handle [keylget multivalue_1_status multivalue_handle]

set ethernet_1_status [::ixiangpf::interface_config \
    -protocol_name                {Ethernet 1}               \
    -protocol_handle              $device_1_handle           \
    -mtu                          1500                       \
    -src_mac_addr                 $multivalue_1_handle       \
    -vlan                         1                          \
    -vlan_id                      101                        \
    -vlan_id_step                 1                          \
    -vlan_id_count                1                          \
    -vlan_tpid                    0x8100                     \
    -vlan_user_priority           0                          \
    -vlan_user_priority_step      0                          \
    -use_vpn_parameters           0                          \
    -site_id                      0                          \
]
if {[keylget ethernet_1_status status] != $::SUCCESS} {
    puts "FAIL - $ethernet_1_status"
	return $FAILED
}
set ethernet_1_handle [keylget ethernet_1_status ethernet_handle]

set vxlan_1_status [::ixiangpf::emulation_vxlan_config                          	\
		 -mode							create									\
		 -handle						$ethernet_1_handle						\
         -intf_ip_addr					23.0.0.1							\
         -intf_ip_addr_step				0.0.0.1						\
         -ip_num_sessions               2                        \
         -intf_ip_prefix_length			24					\
         -gateway						23.0.0.100								\
         -gateway_step					0.0.0.1							\
         -enable_resolve_gateway		1					\
         -vni							600									\
		 -create_ig						0								\
         -ipv4_multicast				225.3.0.9							\
		 -sessions_per_vxlan			1		\
         -ip_to_vxlan_multiplier					1								\
		]
if {[keylget vxlan_1_status status] != $::SUCCESS} {
    puts "FAIL - [keylget vxlan_1_status log]"
    return $FAILED
}

set vxlan_1_handle [lindex [keylget vxlan_1_status vxlan_handle] 0]

# #############################################################################
# 								VTEP 2 CONFIG
# #############################################################################

# CREATE TOPOLOGY 2

set topology_2_status [::ixiangpf::topology_config					\
        -topology_name      {Topology 2}                            \
        -port_handle        $port_1								    \
    ]
if {[keylget topology_2_status status] != $::SUCCESS} {
    puts "FAIL - [keylget topology_2_status log]"
    return $FAILED
}

set topology_2_handle [keylget topology_2_status topology_handle]

# CREATE DEVICE GROUP 2

set device_group_2_status [::ixiangpf::topology_config      \
		-topology_handle              $topology_2_handle        \
		-device_group_name            {VTEP 2}                      \
		-device_group_multiplier      3                         \
		-device_group_enabled         1                         \
]
if {[keylget device_group_2_status status] != $::SUCCESS} {
    puts "FAIL - [keylget device_group_2_status log]"
    return $FAILED
}

set device_2_handle	[keylget device_group_2_status device_group_handle]

# CREATE ETHERNET STACK FOR VXLAN 2

set multivalue_2_status [::ixiangpf::multivalue_config \
    -pattern                counter                 \
    -counter_start          00.24.01.00.00.01       \
    -counter_step           00.00.00.00.00.01       \
    -counter_direction      increment               \
    -nest_step              00.00.01.00.00.00       \
    -nest_owner             $topology_2_handle      \
    -nest_enabled           1                       \
]
if {[keylget multivalue_2_status status] != $::SUCCESS} {
    puts "FAIL - $multivalue_2_status"
	return $FAILED
}
set multivalue_2_handle [keylget multivalue_2_status multivalue_handle]

set ethernet_2_status [::ixiangpf::interface_config \
    -protocol_name                {Ethernet 2}               \
    -protocol_handle              $device_2_handle           \
    -mtu                          1500                       \
    -src_mac_addr                 $multivalue_2_handle       \
    -vlan                         1                          \
    -vlan_id                      101                        \
    -vlan_id_step                 1                          \
    -vlan_id_count                1                          \
    -vlan_tpid                    0x8100                     \
    -vlan_user_priority           0                          \
    -vlan_user_priority_step      0                          \
    -use_vpn_parameters           0                          \
    -site_id                      0                          \
]
if {[keylget ethernet_1_status status] != $::SUCCESS} {
    puts "FAIL - $ethernet_1_status"
	return $FAILED
}
set ethernet_2_handle [keylget ethernet_2_status ethernet_handle]

# CREATE IPv4 STACK FOR VXLAN 2

set multivalue_2_status [::ixiangpf::multivalue_config \
    -pattern                counter                 \
    -counter_start          23.0.0.100              \
    -counter_step           0.0.0.1                 \
    -counter_direction      increment               \
    -nest_step              0.1.0.0                 \
    -nest_owner             $topology_1_handle      \
    -nest_enabled           1                       \
]
if {[keylget multivalue_2_status status] != $::SUCCESS} {
    puts "FAIL - $multivalue_2_status"
	return $FAILED
}
set multivalue_2_handle [keylget multivalue_2_status multivalue_handle]

set gw_multivalue_1_status [::ixiangpf::multivalue_config \
    -pattern                counter                 \
    -counter_start          23.0.0.1              \
    -counter_step           0.0.0.1                 \
    -counter_direction      increment               \
    -nest_step              0.1.0.0                 \
    -nest_owner             $topology_1_handle      \
    -nest_enabled           1                       \
]
if {[keylget gw_multivalue_1_status status] != $::SUCCESS} {
    puts "FAIL - $gw_multivalue_1_status"
	return $FAILED
}
set gw_multivalue_1_handle [keylget gw_multivalue_1_status multivalue_handle]

set ipv4_2_status [::ixiangpf::interface_config \
    -protocol_name                {IPv4 2}                  \
    -protocol_handle              $ethernet_2_handle        \
    -ipv4_resolve_gateway         1                         \
    -gateway                      $gw_multivalue_1_handle   \
    -intf_ip_addr                 $multivalue_2_handle      \
    -netmask                      255.255.255.0             \
]
if {[keylget ipv4_2_status status] != $::SUCCESS} {
    puts "FAIL - $ipv4_2_status"
	return $FAILED
}
set ipv4_2_handle [keylget ipv4_2_status ipv4_handle]

set vxlan_2_status [::ixiangpf::emulation_vxlan_config                         	\
		 -mode									create							\
		 -handle								$ipv4_2_handle					\
         -intf_ip_prefix_length					24								\
         -vni									600								\
		 -create_ig								1								\
         -ipv4_multicast						225.3.0.9						\
         -ip_to_vxlan_multiplier				1								\
         -ig_intf_ip_addr			            80.0.0.100			            \
         -ig_intf_ip_addr_step		            1.0.0.0			                \
         -ig_intf_ip_prefix_length				16								\
		 -ig_mac_address_init					00:67:22:33:00:00				\
	     -ig_mac_address_step					00:00:00:00:00:11				\
		 -ig_gateway							80.0.0.101						\
         -ig_gateway_step						1.0.0.0							\
		 -ig_enable_resolve_gateway				0								\
		 -sessions_per_vxlan					1								\
		]
if {[keylget vxlan_2_status status] != $::SUCCESS} {
    puts "FAIL - [keylget vxlan_2_status log]"
    return $FAILED
}

set inner_ipv4_2_handle [keylget vxlan_2_status ig_ipv4_handle]
set vxlan_2_handle [lindex [keylget vxlan_2_status vxlan_handle] 0]

# #############################################################################
# 								 DHCPv4 SERVER
# #############################################################################

set multivalue_pool [::ixiangpf::multivalue_config \
    -pattern                counter                 \
    -counter_start          80.0.0.1		       \
    -counter_step           1.0.0.0			       \
    -counter_direction      increment               \
    -nest_step              1.0.0.0				       \
    -nest_owner             $topology_2_handle      \
    -nest_enabled           1                       \
]
if {[keylget multivalue_pool status] != $::SUCCESS} {
    puts "FAIL - $multivalue_pool"
	return $FAILED
}
set multivalue_pool_handle [keylget multivalue_pool multivalue_handle]

set multivalue_prefix [::ixiangpf::multivalue_config \
    -pattern                counter                 \
	-counter_start			16					\
	-counter_step			0					\
	-counter_direction		increment					\
	-nest_step				0			\
    -nest_owner             $topology_2_handle      \
    -nest_enabled           1                       \
]
if {[keylget multivalue_prefix status] != $::SUCCESS} {
    puts "FAIL - $multivalue_prefix"
	return $FAILED
}
set multivalue_prefix_handle [keylget multivalue_prefix multivalue_handle]

set dhcp_server_config_status1 [::ixiangpf::emulation_dhcp_server_config                     \
        -mode                                        create                                  \
		-handle										 $inner_ipv4_2_handle  					\
		-lease_time									 84600							\
		-ipaddress_count							 100		                          \
		-ipaddress_pool								 $multivalue_pool_handle                         \
		-ipaddress_pool_prefix_length 				 $multivalue_prefix_handle                            \
        -ip_version                                  4                                       \
        ]
if {[keylget dhcp_server_config_status1 status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget dhcp_server_config_status1 log]"
    return $FAILED
}

set dhcp_server_handle [keylget dhcp_server_config_status1 dhcpv4server_handle]

# #############################################################################
# 								 DHCPv4 CLIENT
# #############################################################################

set device_group_chained_status_1 [::ixiangpf::topology_config      \
		-device_group_multiplier      5                         \
		-device_group_handle          $device_1_handle      \
		]
if {[keylget device_group_chained_status_1 status] != $::SUCCESS} {
    puts "FAIL - [keylget device_group_chained_status_1 log]"
    return $FAILED
}

set chained_dg_1_handle [keylget device_group_chained_status_1 device_group_handle]

set dhcp_status [::ixiangpf::emulation_dhcp_group_config \
		-handle							$chained_dg_1_handle    \
		-dhcp_range_ip_type				ipv4						 \
		-dhcp_range_renew_timer			2							 \
		-use_rapid_commit				0							 \
		]
if {[keylget dhcp_status status] != $::SUCCESS} {
     puts "FAIL - $test_name - [keylget dhcp_status log]"
     return $FAILED
}

set dhcp_client_handle [keylget dhcp_status dhcpv4client_handle]

# #############################################################################
# 								START PROTOCOLS
# #############################################################################

puts "Start VXLAN ..."

set control_status_1 [::ixiangpf::emulation_vxlan_control \
        -handle      	  $vxlan_1_handle                    \
        -action           start                      \
        ]
if {[keylget control_status_1 status] != $::SUCCESS} {
    puts "FAIL - [keylget control_status_1 log]"
    return $FAILED
}

set control_status_2 [::ixiangpf::emulation_vxlan_control \
        -handle      	  $vxlan_2_handle              \
        -action           start                     \
        ]
if {[keylget control_status_2 status] != $::SUCCESS} {
    puts "FAIL - [keylget control_status_2 log]"
    return $FAILED
}

while {[lindex [ixNet getA $vxlan_1_handle -stateCounts] 3]!="3" || [lindex [ixNet getA $vxlan_2_handle -stateCounts] 3]!="3"} {
	after 1000
	puts "Waiting for VXLAN to go up..."
}
puts "VXLAN stacks are up!"

puts "Start DHCP server..."
set control_status [::ixiangpf::emulation_dhcp_server_control  \
	-dhcp_handle 			$dhcp_server_handle 		\
	-action 				collect								\
]
if {[keylget control_status status] != $::SUCCESS} {
    puts "FAIL - [keylget control_status log]"
    return $FAILED
}

puts "Start DHCP clients..."
set control_status [::ixiangpf::emulation_dhcp_control  \
	-handle 				$dhcp_client_handle \
	-action 				bind							\
]
if {[keylget control_status status] != $::SUCCESS} {
    puts "FAIL - [keylget control_status log]"
    return $FAILED
}

while {[lindex [ixNet getA $dhcp_client_handle -stateCounts] 3]!="15"} {
	after 1000
	puts "Waiting for DHCP Clients to go up..."
}
puts "DHCP sessions are up!"

after 10000

# #############################################################################
# 								STATISTICS
# #############################################################################

# CLIENT
	
set vxlan_stats_2 [::ixiangpf::emulation_vxlan_stats      \
        -port_handle 			$port_0                                   \
		-mode 				aggregate_stats				                                   \
        -execution_timeout  30                                              \
	]
if {[keylget vxlan_stats_2 status] != $::SUCCESS} {
    puts "FAIL - [keylget vxlan_stats_2 log]"
    return $FAILED
}	
	
set dhcp_client_stats [::ixiangpf::emulation_dhcp_stats  \
        -port_handle $port_0                    \
		-mode aggregate_stats  \
        -execution_timeout  30                                              \
    ]
if {[keylget dhcp_client_stats status] != $::SUCCESS} {
    puts "FAIL - $test_name -[keylget dhcp_client_stats log]"
    return $FAILED
}

puts "\n\n------------------DHCP Client stats------------------"
show_stats $dhcp_client_stats
puts "\n\n------------------VXLAN stats------------------------"
show_stats $vxlan_stats_2

# SERVER

set vxlan_stats_1 [::ixiangpf::emulation_vxlan_stats      \
        -port_handle 			$port_1                                   \
		-mode 				aggregate_stats				                                   \
        -execution_timeout  30                                              \
	]
if {[keylget vxlan_stats_1 status] != $::SUCCESS} {
    puts "FAIL - [keylget vxlan_stats_1 log]"
    return $FAILED
}	
	
set dhcp_server_stats [::ixiangpf::emulation_dhcp_server_stats  \
        -port_handle $port_1                    \
		-action collect  \
        -execution_timeout  30                                              \
    ]
if {[keylget dhcp_server_stats status] != $::SUCCESS} {
    puts "FAIL - $test_name -[keylget dhcp_server_stats log]"
    return $FAILED
}

puts "\n\n------------------DHCP Server stats------------------"
show_stats $dhcp_server_stats
puts "\n\n------------------VXLAN stats------------------------"
show_stats $vxlan_stats_1 

puts "\n\nVXLAN Sessions up:"
puts "Port 1: [keylget vxlan_stats_2 $port_0.aggregate.sessions_up] VXLAN sessions up !"
puts "Port 2: [keylget vxlan_stats_1 $port_1.aggregate.sessions_up] VXLAN sessions up !"

puts "\n\nDHCP Server sessions up:"
puts "Port 1: [keylget dhcp_server_stats aggregate.$port_1.sessions_up] DHCP server sessions up !"	

puts "\n\nDHCP Client sessions up:"
puts "Port 2: [keylget dhcp_client_stats $port_0.aggregate.currently_bound] DHCP client sessions up !"	

if {[keylget dhcp_client_stats $port_0.aggregate.currently_bound] < 15} {
	puts "FAIL - Not all DHCP Clients are up!"
	return $FAILED
}

if {[keylget dhcp_server_stats aggregate.$port_1.sessions_up] < 1 || [keylget dhcp_server_stats aggregate.$port_1.total_leases_allocated] < 15} {
	puts "FAIL - Not all DHCP Servers are up or not all leases are allocated!"
	return $FAILED
}

# #############################################################################
# 								STOP VXLAN
# #############################################################################

set vxlan_1_handle [lindex [keylget vxlan_1_status vxlan_handle] 0]
set vxlan_2_handle [lindex [keylget vxlan_2_status vxlan_handle] 0]

set control_status_0 [::ixiangpf::emulation_vxlan_control \
        -handle      	  $vxlan_1_handle                    \
        -action           stop                      \
        ]
if {[keylget control_status_0 status] != $::SUCCESS} {
    puts "FAIL - [keylget control_status_0 log]"
    return $FAILED
}

set control_status_1 [::ixiangpf::emulation_vxlan_control \
        -handle      	  $vxlan_2_handle              \
        -action           stop                     \
        ]
if {[keylget control_status_1 status] != $::SUCCESS} {
    puts "FAIL - [keylget control_status_1 log]"
    return $FAILED
}

while {[lindex [ixNet getA $vxlan_1_handle -stateCounts] 1]!="3" || [lindex [ixNet getA $vxlan_2_handle -stateCounts] 1]!="3"} {
	after 1000
	puts "Waiting for VXLAN to stop..."
}
puts "VXLAN stacks are stopped!"

while {[lindex [ixNet getA $dhcp_client_handle -stateCounts] 1]!="15" || [lindex [ixNet getA $dhcp_server_handle -stateCounts] 1]!="3"} {
	after 1000
	puts "Waiting for DHCP to stop..."
}
puts "DHCP is stopped!"

after 10000

set cleanup [::ixia::cleanup_session -reset]
if {[keylget cleanup status] != $::SUCCESS} {
	puts "FAIL - [keylget cleanup log]"
	return $FAILED
}

puts "Done... IxNetwork session is closed..."
puts ""
puts "!!! PASSED !!!"
return $PASSED