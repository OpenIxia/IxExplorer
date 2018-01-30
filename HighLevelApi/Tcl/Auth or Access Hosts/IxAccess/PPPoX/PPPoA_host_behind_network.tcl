#################################################################################
# Version 1.0    $Revision: 1 $
# $Author: MHasegan $
#
#    Copyright © 1997 - 2005 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    12-22-2006 MHasegan
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
#    This sample configures a PPPoA tunnel with 5 sessions.                    #
#    Then it connects to the DUT(Cisco7206) and retrieves a few statistics.    #
#    Traffic is sent over the tunnel and the DUT sends                         #
#    it to the host behind the DST port. After that a few statistics are being #
#    retrieved.                                                                #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a ATM/POS622-MultiRate-256Mb module.             #
#                                                                              #
################################################################################



################################################################################
# DUT configuration:                                                            
# 
# configure terminal                                                                             
# ip route 200.200.200.0 255.255.255.0 195.0.0.100
#                                                                               
# vpdn enable                                                                    
#                                                                              
# interface Loopback100                                                            
#  ip address 199.0.0.1 255.255.255.0                                             
#                                                                              
# ip local pool Pool2atm 199.0.0.2 199.0.0.254                                 
#                                                                              
# interface Virtual-Template 100                                                 
#  ip unnumbered Loopback100                                                     
#  no logging event link-status                                                
#  no snmp trap link-status                                                    
#  peer default ip address pool Pool2atm                                       
#  no keepalive                                                                
#  ppp max-bad-auth 20                                                         
#  ppp mtu adaptive                                                            
#  ppp bridge ip                                                                
#  ppp ipcp address accept                                                     
#  ppp timeout retry 10                                                        
#                                                                              
#                                                                              
# bba-group pppoe dialin                                                       
#  virtual-template 100                                                          
#                                                                              
#                                                                              
# interface ATM4/0                                                             
#  no ip address                                                               
#  no ip route-cache                                                           
#  no ip mroute-cache                                                          
#  no atm ilmi-keepalive                                                       
#  no shut                                                                     
#  range pvc 1/32 1/51                                                         
#  encapsulation aal5autoppp Virtual-Template100                                 
#  protocol ip inarp broadcast                                                 
#                                                                              
# interface ATM3/0                                                             
#  ip address 195.0.0.1 255.255.255.0                                             
#  no ip route-cache                                                           
#  no ip mroute-cache                                                          
#  no atm ilmi-keepalive                                                        
#  no shut                                                                     
#                                                                              
#  pvc 1/32                                                                    
#   protocol ip 195.0.0.100 broadcast                                           
#   encapsulation aal5snap   
################################################################################

package require Ixia

set test_name [info script]

set chassisIP sylvester
set port_list [list 3/1 3/2]

set session_count 5

# Connect to the chassis, reset to factory defaults and take ownership
set connect_status [::ixia::connect \
        -reset                    \
        -device    $chassisIP     \
        -port_list $port_list     \
        -username  ixiaApiUser    \
        ]
        
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

set port_ac [lindex $port_handle 0]
set port_nw [lindex $port_handle 1]

puts "Ixia port handles are $port_handle "

########################################
# Configure SRC interface in the test  #
########################################
set interface_status [::ixia::interface_config \
        -port_handle      $port_ac             \
        -speed            oc3                  \
        -intf_mode        atm                  \
        -tx_c2            13                   \
        -rx_c2            13                   ]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}

########################################

########################################
# Configure DST interface  in the test #
########################################
set interface_status.1 [::ixia::interface_config \
        -port_handle      $port_nw             \
        -mode             config               \
        -speed            oc3                  \
        -intf_mode        atm                  \
        -tx_c2            13                   \
        -rx_c2            13                   \
        -atm_encapsulation LLCRoutedCLIP       \
        -vpi              1                    \
        -vci              32                   \
        -intf_ip_addr     195.0.0.100          \
        -gateway          195.0.0.1            \
        -netmask          255.255.255.0        \
        ]        

if {[keylget interface_status.1 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status.1 log]"
}


###############################################
# Configure session                           #
###############################################

set pppox_config_status [::ixia::pppox_config            \
        -port_handle                 $port_ac          \
        -protocol                    pppoa             \
        -encap                       llcsnap           \
        -num_sessions                $session_count    \
        -l4_flow_number              10                \
        -vci                         32                \
        -vci_step                    1                 \
        -vci_count                   $session_count    \
        -pvc_incr_mode               vci               \
        -vpi                         1                 \
        -vpi_step                    1                 \
        -vpi_count                   1                 \
        -ppp_local_ip                199.0.0.2         \
        -ppp_local_ip_step           0.0.0.1           \
        ]

if {[keylget pppox_config_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget pppox_config_status log]"
}

set pppox_handle [keylget pppox_config_status handle]

# ################################################
# #  Setup session                               #
# ################################################
set pppox_control_status [::ixia::pppox_control  \
        -handle                 $pppox_handle  \
        -action                 connect        \
        ]

if {[keylget pppox_control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget pppox_control_status log]"
}

after 15000

################################################
#  PPPoA Stats                                 #
################################################
set aggr_status [::ixia::pppox_stats \
        -handle $pppox_handle        \
        -mode   aggregate            ]
if {[keylget aggr_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget aggr_status log]"
}

set sess_num       [keylget aggr_status aggregate.num_sessions]
set sess_count_up  [keylget aggr_status aggregate.connected]
set sess_min_setup [keylget aggr_status aggregate.min_setup_time]
set sess_max_setup [keylget aggr_status aggregate.max_setup_time]
set sess_avg_setup [keylget aggr_status aggregate.avg_setup_time]

puts "Ixia Session Setup Test Results ... "
puts "        Number of sessions           = $sess_num "
puts "        Number of connected sessions = $sess_count_up "
puts "        Minimum Setup Time (ms)      = $sess_min_setup "
puts "        Maximum Setup Time (ms)      = $sess_max_setup "
puts "        Average Setup Time (ms)      = $sess_avg_setup "

#########################################
#  Clear streams                        #
#########################################
set traffic_status [::ixia::traffic_config         \
        -mode                 reset                \
        -port_handle          $port_ac     ]

if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}

set traffic_status [::ixia::traffic_config         \
        -mode                 reset                \
        -port_handle          $port_nw     ]

if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}

#########################################
#  Configure bidirectional traffic      #
#########################################
set traffic_status [::ixia::traffic_config      \
        -mode                 create            \
        -port_handle          $port_ac          \
        -port_handle2         $port_nw          \
        -bidirectional        1                 \
        -l3_protocol          ipv4              \
        -emulation_src_handle $pppox_handle     \
        -pkts_per_burst       10                \
        -burst_loop_count     10                \
        -ip_src_mode          emulation         \
        -ip_src_count         $session_count    \
        -ip_dst_mode          fixed             \
        -ip_dst_addr          195.0.0.100       \
        -l3_length            1000              \
        -rate_percent         5                 \
        -transmit_mode        continuous        \
        -mac_dst_mode         discovery         \
        -host_behind_network  200.200.200.200   \
        ]

if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
    }

#########################################
#  Clear traffic stats                  #
#########################################
set control_status [::ixia::traffic_control \
        -port_handle $port_handle           \
        -action      clear_stats            ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

puts "Setup traffic.."
set traffic_start_status [::ixia::traffic_stats      \
        -port_handle           $port_ac           \
        -mode                  add_atm_stats      \
        -vpi                   1                  \
        -vci                   32                  \
        -vci_count             $session_count     \
        -vci_step              1                  \
        -atm_counter_vpi_type  fixed              \
        -atm_counter_vci_type  counter            \
        -atm_counter_vci_mode  incr               \
        ]

if {[keylget traffic_start_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_start_status log]"
}

set traffic_start_status [::ixia::traffic_stats    \
        -port_handle           $port_nw         \
        -mode                  add_atm_stats    \
        -vpi                   1                \
        -vci                   32                \
        -vci_count             1                \
        -vci_step              1                \
        -atm_counter_vpi_type  fixed            \
        -atm_counter_vci_type  counter          \
        -atm_counter_vci_mode  incr             \
        ]

if {[keylget traffic_start_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_start_status log]"
}

puts "Starting to transmit traffic over tunnels..."

#########################################
#  Start traffic                        #
#########################################
set control_status [::ixia::traffic_control \
        -port_handle $port_handle           \
        -action      run                    \
        ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

after 20000

#########################################
#  Stop traffic                         #
#########################################
set control_status [::ixia::traffic_control \
        -port_handle $port_handle           \
        -action      stop                   ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}
puts "Stopped transmitting traffic over tunnels..."


#########################################
#  TX Stats                             #
#########################################

set aggregate_stats [::ixia::traffic_stats -port_handle $port_ac]
if {[keylget aggregate_stats status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget aggregate_stats log]"
}

for {set vpi 1} {$vpi <= 1} {incr vpi} {
     for {set vci 32} {$vci < [expr 32 + $session_count]} {incr vci} {
        puts ""
        puts "Aggregate TX stats on ATM port $port_ac:$vpi/$vci"
        puts "--------------------------------------------------"
        foreach statName [keylkeys \
                aggregate_stats    \
                ${port_ac}.aggregate.tx.${vpi}.${vci}] {            
            puts [format "%31s %-20s" "$statName" \
                    [keylget aggregate_stats      \
                    ${port_ac}.aggregate.tx.${vpi}.${vci}.${statName}]]
        }

        puts ""
        puts "Aggregate RX stats on ATM port $port_ac:$vpi/$vci"
        puts "--------------------------------------------------"
        foreach statName [keylkeys \
                aggregate_stats ${port_ac}.aggregate.rx.${vpi}.${vci}] {                    
            puts [format "%31s %-20s" "$statName" \
                    [keylget aggregate_stats      \
                    ${port_ac}.aggregate.rx.${vpi}.${vci}.${statName}]]
        }
    }
}

#########################################
#  RX Stats                             #
#########################################

set aggregate_stats [::ixia::traffic_stats -port_handle $port_nw]
if {[keylget aggregate_stats status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget aggregate_stats log]"
}

set vpi 1
set vci 32
puts ""
puts "Aggregate TX stats on ATM port $port_nw:$vpi/$vci"
puts "--------------------------------------------------"
foreach statName [keylkeys aggregate_stats \
        ${port_nw}.aggregate.tx.${vpi}.${vci}] {
    
    puts [format "%31s %-20s" "$statName" [keylget \
            aggregate_stats                        \
            ${port_nw}.aggregate.tx.${vpi}.${vci}.${statName}]]
}

puts ""
puts "Aggregate RX stats on ATM port $port_nw:$vpi/$vci"
puts "--------------------------------------------------"
foreach statName [keylkeys aggregate_stats \
        ${port_nw}.aggregate.rx.${vpi}.${vci}] {
    
    puts [format "%31s %-20s" "$statName"  \
            [keylget aggregate_stats       \
            ${port_nw}.aggregate.rx.${vpi}.${vci}.${statName}]]
}

::ixia::cleanup_session
return "SUCCESS - $test_name - [clock format [clock seconds]]"


