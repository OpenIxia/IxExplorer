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
#    This sample configures a PPPoE tunnel with 5 sessions between the         #
#    SRC port and the DUT. Traffic is sent over the tunnel and the DUT sends   #
#    it to the host behind the DST port. After that a few statistics are being #
#    retrieved.                                                                #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a LM1000STXS4 module.                            #
#                                                                              #
################################################################################

################################################################################
# DUT configuration:                                                           
#                                                                              
# configure terminal
# 
# ip route 200.200.200.0 255.255.255.0 180.0.0.180
#
# bba-group pppoe group180
#  virtual-template 180
#  sessions per-vc limit 1000
#  sessions per-mac limit 1000
# 
# interface Loopback180
#  ip address 100.100.100.1 255.255.255.0
# 
# interface FastEthernet1/0
#  no ip address
#  no ip route-cache cef
#  no ip route-cache
#  duplex half
#  speed auto
#  no shutdown
# 
# interface FastEthernet1/0.180
#  encapsulation dot1Q 180
#  no ip route-cache
#  pppoe enable group group180
# 
# interface FastEthernet1/1
#  no ip address
#  duplex auto
#  speed auto
#  no shutdown
# 
# interface FastEthernet1/1.180
#  encapsulation dot1Q 180
#  ip address 180.0.0.1 255.255.255.0
# 
# ip local pool pppoe180 100.100.100.2 100.100.100.254
# 
# interface Virtual-Template180
#  mtu 1492
#  ip unnumbered Loopback180
#  peer default ip address pool pppoe180
#  no keepalive
#  ppp max-bad-auth 20
#  ppp timeout retry 10
# 
################################################################################ 


package require Ixia

set test_name [info script]

set chassisIP sylvester
set port_list [list 1/1 1/2]
set sess_count 5

# Connect to the chassis, reset to factory defaults and take ownership
set connect_status [::ixia::connect \
        -reset                      \
        -device    $chassisIP       \
        -port_list $port_list       \
        -username  ixiaApiUser      ]
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

puts "Ixia port handles are $port_handle ..."

########################################
# Configure SRC interface in the test  #
########################################
set interface_status [::ixia::interface_config \
        -port_handle      $port_ac             \
        -mode             config               \
        -speed            ether100             \
        -duplex           half                 \
        -phy_mode         copper               \
        -autonegotiation  1                    ]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}


########################################
# Configure DST interface  in the test #
########################################
set interface_status [::ixia::interface_config \
        -port_handle      $port_nw             \
        -mode             config               \
        -speed            ether100             \
        -duplex           half                 \
        -phy_mode         copper               \
        -autonegotiation  1                    \
        -intf_ip_addr     180.0.0.180          \
        -gateway          180.0.0.1            \
        -netmask          255.255.255.0        \
        -vlan             1                    \
        -vlan_id          180                  ]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}

#########################################
#  Configure sessions                   #
#########################################
set config_status [::ixia::pppox_config     \
        -port_handle       $port_ac         \
        -protocol          pppoe            \
        -encap             ethernet_ii_vlan \
        -num_sessions      5                \
        -disconnect_rate   10               \
        -auth_req_timeout  10               \
        -vlan_id           180              \
        -vlan_id_count     1                ]
if {[keylget config_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget config_status log]"
}
set pppox_handle1 [keylget config_status handle]
puts "Ixia pppox_handle1 is $pppox_handle1 ..."

#########################################
#  Connect sessions                     #
#########################################
set control_status [::ixia::pppox_control \
        -handle     $pppox_handle1        \
        -action     connect               ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}
puts "Waiting for sessions to connect ..."

#########################################
#  Retrieve aggregate session stats     #
#########################################
set sess_count_up 0
set num_retries   20
while {($sess_count_up < $sess_count) && ($num_retries > 0)} {
    set aggr_status1 [::ixia::pppox_stats \
            -handle $pppox_handle1        \
            -mode   aggregate             ]
    if {[keylget aggr_status1 status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget aggr_status1 log]"
    }
    set sess_count_up [keylget aggr_status1 aggregate.connected]
    
    incr num_retries -1
    after 10000
}

set sess_count_up1  [keylget aggr_status1 aggregate.connected]

puts "Ixia Test Results ... "
puts "        Connected sessions subport 1 = $sess_count_up1 "

set traffic_status [::ixia::traffic_config         \
        -mode                 reset                \
        -port_handle          $port_ac             ]

if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}

#########################################
#  Configure traffic                    #
#########################################
set traffic_status [::ixia::traffic_config      \
        -mode                 create            \
        -port_handle          $port_ac          \
        -port_handle2         $port_nw          \
        -bidirectional        1                 \
        -l3_protocol          ipv4              \
        -ip_src_mode          emulation         \
        -ip_src_count         $sess_count_up1   \
        -emulation_src_handle $pppox_handle1    \
        -ip_dst_mode          fixed             \
        -ip_dst_addr          180.0.0.180       \
        -l3_length            1000              \
        -rate_percent         5                 \
        -transmit_mode        continuous        \
        -host_behind_network  200.200.200.200   \
        -mac_dst_mode         discovery         ]
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
puts "Starting to transmit traffic over tunnels..."

#########################################
#  Start traffic                        #
#########################################
set control_status [::ixia::traffic_control \
        -port_handle $port_handle           \
        -action      run                    ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

after 12000

#########################################
#  Stop traffic                         #
#########################################
set control_status [::ixia::traffic_control \
        -port_handle $port_handle           \
        -action      stop                   ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

#########################################
#  Procedure to print stats             #
#########################################
proc post_stats {port_handle label key_list stat_key {stream ""}} {
    puts -nonewline [format "%-30s" $label]
    
    foreach port $port_handle {
        if {$stream != ""} {
            set key $port.stream.$stream.$stat_key
        } else {
            set key $port.$stat_key
        }
        
        if {[llength [keylget key_list $key]] > 1} {
            puts -nonewline "[format "%-16s" N/A]"
        } else  {
            puts -nonewline "[format "%-16s" [keylget key_list $key]]"
        }
    }
    puts ""
}

#########################################
#  Retrieve aggregate traffic stats     #
#########################################
set aggregate_stats [::ixia::traffic_stats -port_handle $port_handle]
if {[keylget aggregate_stats status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget aggregate_stats log]"
}

puts "\n\n                  ----- Traffic statistics -----\n"
puts -nonewline "[format "%-30s" " "]"
foreach port $port_handle {
    puts -nonewline "[format "%-16s" $port]"
}
puts ""
puts -nonewline "[format "%-30s" " "]"
foreach port $port_handle {
    puts -nonewline "[format "%-16s" "-----"]"
}
puts ""


post_stats $port_handle "Raw Packets Tx" $aggregate_stats \
        aggregate.tx.raw_pkt_count

post_stats $port_handle "Raw Packets Rx" $aggregate_stats \
        aggregate.rx.raw_pkt_count

post_stats $port_handle "Collisions"     $aggregate_stats \
        aggregate.rx.collisions_count

post_stats $port_handle "Dribble Errors" $aggregate_stats \
        aggregate.rx.dribble_errors_count

post_stats $port_handle "CRCs"           $aggregate_stats \
        aggregate.rx.crc_errors_count

post_stats $port_handle "Oversizes"      $aggregate_stats \
        aggregate.rx.oversize_count

post_stats $port_handle "Undersizes"     $aggregate_stats \
        aggregate.rx.undersize_count


puts "\n--------------------------------------------------\n"


################################################################################
# If you want to clean up after this script, then take out the if 0 logic
# It is not called so that you can view the setup after the script executes
################################################################################
if {1} {
    #########################################
    #  Disconnect sessions                  #
    #########################################
    puts "Disconnecting $sess_count_up sessions. "
    set control_status [::ixia::pppox_control \
            -handle     $pppox_handle1        \
            -action     disconnect            ]
    if {[keylget control_status status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget control_status log]"
    }
    
    set cleanup_status [::ixia::cleanup_session ]
    
    if {[keylget cleanup_status status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget cleanup_status log]"
    }
}

return "SUCCESS - $test_name - [clock format [clock seconds]]"

