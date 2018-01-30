#################################################################################
# Version 1    $Revision: 1 $
# $Author: RCsutak $
#
#    Copyright © 1997 - 2014 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    08-20-2014 RCsutak - created sample
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
#   This sample connects to an IxNetwork client and to a virtual chassis.	   #
#	Using 18 virtual ports, the script sets different speeds from all the 	   #
#	options available in the documentation.									   #
#                                                                              #
################################################################################


if {[catch {package require Ixia} retCode]} {
    puts "FAIL - [info script] - $retCode"
    return 0
}
################################################################################
# General script variables
################################################################################
set chassis_ip              "ip of the vm chassis"
# use an 18 ports list
set port_list               [list 1/1 1/2 1/3 1/4 1/5 1/6 1/7 1/8 1/9 2/1 2/2 2/3 2/4 2/5 2/6 2/7 2/8 2/9]
set tcl_server              localhost
set ixnetwork_tcl_server    localhost
set test_name               [info script]
set test_name_folder        [file dirname $test_name]
set license_type            subscription_tier3
set license_server          "the ip/hostname of a server that has the appropriate license type"

################################################################################
# START - Connect to the chassis and Load IxNetwork config
################################################################################
	
set res [ixia::connect                          	\
    -ixnetwork_tcl_server $ixnetwork_tcl_server     \
    -tcl_server $tcl_server                         \
    -device $chassis_ip                             \
    -port_list $port_list                           \
    -reset      1                                   \
]
if {[keylget res status] != $::SUCCESS} {
   puts "connect failed: $res"
   return 0
}
puts stderr [::ixia::keylprint $res]
set port_list [keylget res vport_list]
 
set 100_port_list [lrange $port_list 0 3]
set 1000_port_list [lindex $port_list 4]  
set 2000_port_list [lindex $port_list 5]  
set 3000_port_list [lindex $port_list 6]  
set 4000_port_list [lindex $port_list 7]  
set 5000_port_list [lindex $port_list 8]  
set 6000_port_list [lindex $port_list 9]  
set 7000_port_list [lrange $port_list 10 12]  
set 8000_port_list [lindex $port_list 13]  
set 9000_port_list [lrange $port_list 14 16]  
set 10000_port_list [lindex $port_list 17]  
set final_list [list $100_port_list $1000_port_list $2000_port_list $3000_port_list $4000_port_list $5000_port_list $6000_port_list $7000_port_list $8000_port_list $9000_port_list $10000_port_list]
set speed_list [list ether100vm ether1000vm ether2000vm ether3000vm ether4000vm ether5000vm ether6000vm ether7000vm ether8000vm ether9000vm ether10000vm]
set final_list_no [llength $final_list]

foreach ports $final_list speed $speed_list {

	puts "Setting speed $speed on ports $ports\n"
    set port_speed_$speed [ixia::interface_config      \
        -port_handle        $ports              \
        -speed              $speed              \
        ]
      
    if {[keylget port_speed_$speed status] != $::SUCCESS} {
       puts "connect failed: $port_speed_$speed"
       return 0
    }
    puts "Passed!\n"
}

puts "SUCCESS - [clock format [clock seconds] -format {%D %X}]"
return 1