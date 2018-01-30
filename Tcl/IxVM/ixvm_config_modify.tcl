#################################################################################
# Version 1    $Revision: 1 $
# $Author: RCsutak $
#
#    Copyright © 1997 - 2014 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    11-20-2014 RCsutak - created sample
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
#   This sample connects to an IxNetwork client and, using the HL API,		   #	
#	adds cards to a virtual chassis and modifies some options or card 		   #	
#	configurations.														 	   #	
#                                                                              #
################################################################################


if {[catch {package require Ixia} retCode]} {
    puts "FAIL - [info script] - $retCode"
    return 0
}


################################################################################
# General script variables
################################################################################
set chassis_ip              10.205.23.219
set ixnetwork_tcl_server    localhost
set test_name               [info script]
set test_name_folder        [file dirname $test_name]
set virtual_chassis			10.205.23.219
set cards					[list 10.205.23.215 10.205.23.216 10.205.23.134 10.205.23.136 10.205.23.208 10.205.23.194]

################################################################################
# START - Connect to IxN client
################################################################################

set res [ixiangpf::connect                          \
	-reset											\
	-vport_count			1						\
    -ixnetwork_tcl_server 	$ixnetwork_tcl_server   \
]
if {[keylget res status] != $::SUCCESS} {
   puts "Connect failed: $res"
   return 0
}

puts "Deleting all cards from chassis ...\n"
set clear_chassis [::ixiangpf::ixvm_config				\
	-mode 				delete_all						\
	-virtual_chassis	$virtual_chassis				\
]
if {[keylget clear_chassis status] != $::SUCCESS} {
   puts "Delete failed: $clear_chassis"
   return 0
}

	puts "Creating first card, with 1 port ...\n"
	puts "====> CARD no 1\n"
	set keep_alive 250
	set mtu 2000
	set promisc_mode 1
	set virtual_intf_count 1
	set card_no 4
	set card4 [::ixiangpf::ixvm_config					\
		-mode						create				\
		-virtual_chassis			$chassis_ip			\
		-management_ip				[lindex $cards 3]	\
		-keep_alive					$keep_alive			\
		-mtu						$mtu				\
		-promiscuous_mode			$promisc_mode		\
		-virtual_interface_count 	$virtual_intf_count	\
		-card_no					$card_no			\
	]
	if {[keylget card4 status] != $::SUCCESS} {
	   puts "Card failed: $card4"
	   return 0
	}

		
	puts "Adding another 8 ports, using a list ...\n"
	set port_no [list 2 4 6 8 3 5 7]
	set mtu_list [list 1550 1660 2000]
	set add_ports [::ixiangpf::ixvm_config				\
		-mode						modify				\
		-virtual_chassis			$chassis_ip			\
		-port_action 				add					\
		-management_ip				[lindex $cards 3]	\
		-virtual_interface_count	[llength $port_no]	\
		-port_no					$port_no			\
		-card_no					$card_no			\
		-mtu						$mtu_list			\
		-promiscuous_mode			1					\
	]
	if {[keylget add_ports status] != $::SUCCESS} {
	   puts "Add ports FAILED: $add_ports"
	   return 0
	}
	
	puts "Creating card with virtual_interface_list, 5 ports ...\n"
	puts "====> CARD no 13\n"
	set keep_alive5 1500
	set mtu5 3000
	set promisc_mode5 0
	set intf_list [list eth1 eth2 eth3 eth7 eth9]
	set card_no5 13
	set card5 [::ixiangpf::ixvm_config								\
		-mode						create							\
		-virtual_chassis			$chassis_ip						\
		-management_ip				[lindex $cards 4]				\
		-keep_alive					$keep_alive5					\
		-mtu						$mtu5							\
		-promiscuous_mode			$promisc_mode5					\
		-virtual_interface_list 	$intf_list						\
		-card_no					$card_no5						\
	]
	if {[keylget card5 status] != $::SUCCESS} {
	   puts "Card failed: $card5"
	   return 0
	}
	
	
	
	puts "Modifying card by adding ports ...\n"
	set mtu5 [list 1550 1660 1770]
    set port_no5 [list 6 8 7]
	
	set add_ports [::ixiangpf::ixvm_config				\
		-mode						modify				\
		-virtual_chassis			$chassis_ip			\
		-port_action 				add					\
		-card_no					$card_no5			\
		-virtual_interface_count	3					\
		-port_no					$port_no5			\
		-mtu						$mtu5				\
	]
	if {[keylget add_ports status] != $::SUCCESS} {
	   puts "Add ports FAILED: $add_ports"
	   return 0
	}
	
	
	puts "Creating card with both virtual_interface_list and count ...\n"
	puts "====> CARD no 6\n"
	set mtu6 1800
	set promisc_mode6 1
	set intf_list6 [list eth1 eth3 eth5 eth7 eth8 eth9]
	set intf_count6 2
	set card6 [::ixiangpf::ixvm_config										\
		-mode						create									\
		-virtual_chassis			$chassis_ip								\
		-management_ip				[lindex $cards 5]						\
		-mtu						$mtu6									\
		-promiscuous_mode			$promisc_mode6							\
		-virtual_interface_list 	$intf_list6								\
		-virtual_interface_count	$intf_count6							\
	]
	if {[keylget card6 status] != $::SUCCESS} {
	   puts "Card failed: $card6"
	   return 0
	}
	
	

puts "Script has finished SUCCESSFULLY!\n"
return 1

