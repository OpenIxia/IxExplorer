#################################################################################
# Version 1.0    $Revision: 1 $
# $Author: LRaicea $
#
#    Copyright © 1997 - 2006 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    26-04-2006 LRaicea
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
#    This sample configures a PPPoE tunnel with 100 sessions between the       #
#    first Ixia port and DUT , and 10 L2TP tunnels each with 10 sessions       #
#    between DUT and the other Ixia port. Traffic is sent between the two Ixia #
#    ports.                                                                    #
#    Topology is the following:                                                #
#                                                                              #
#      Access      PPPoE               L2TPoE                   Destination    #
#      Network   -------- LAC (DUT)  ---------- LNS -----------   Network      #
#    (Ixia Port1)        (Cisco 7200)       (Ixia Port2)       (Ixia Port2)    #
#                                                                              #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a LM1000STXS4 module.                            #
#                                                                              #
################################################################################

################################################################################
# DUT configuration:                                                           #
#                                                                              #
# no service pad
# service timestamps debug uptime
# service timestamps log uptime
# no service password-encryption
# 
# aaa new-model
# 
# aaa authentication login telnet enable
# aaa session-id common
# ip subnet-zero
# no ip gratuitous-arps
# 
# ip cef
# vpdn enable
# vpdn ip udp ignore checksum
# vpdn search-order domain
# 
# vpdn-group x00000
#  request-dialin
#   protocol l2tp
#   domain x0
#  initiate-to ip 12.80.0.2
#  local name lac
#  l2tp tunnel password cisco
#  l2tp tunnel timeout no-session 1
#  exit
# 
# vpdn-group x00001
#  request-dialin
#   protocol l2tp
#   domain x1
#  initiate-to ip 12.80.0.3
#  local name lac
#  l2tp tunnel password cisco
#  l2tp tunnel timeout no-session 1
#  exit
# 
# vpdn-group x00002
#  request-dialin
#   protocol l2tp
#   domain x2
#  initiate-to ip 12.80.0.4
#  local name lac
#  l2tp tunnel password cisco
#  l2tp tunnel timeout no-session 1
#  exit
# 
# vpdn-group x00003
#  request-dialin
#   protocol l2tp
#   domain x3
#  initiate-to ip 12.80.0.5
#  local name lac
#  l2tp tunnel password cisco
#  l2tp tunnel timeout no-session 1
#  exit
# 
# vpdn-group x00004
#  request-dialin
#   protocol l2tp
#   domain x4
#  initiate-to ip 12.80.0.6
#  local name lac
#  l2tp tunnel password cisco
#  l2tp tunnel timeout no-session 1
# 
# vpdn-group x00005
#  request-dialin
#   protocol l2tp
#   domain x5
#  initiate-to ip 12.80.0.7
#  local name lac
#  l2tp tunnel password cisco
#  l2tp tunnel timeout no-session 1
#  exit
# 
# vpdn-group x00006
#  request-dialin
#   protocol l2tp
#   domain x6
#  initiate-to ip 12.80.0.8
#  local name lac
#  l2tp tunnel password cisco
#  l2tp tunnel timeout no-session 1
#  exit
# 
# vpdn-group x00007
#  request-dialin
#   protocol l2tp
#   domain x7
#  initiate-to ip 12.80.0.9
#  local name lac
#  l2tp tunnel password cisco
#  l2tp tunnel timeout no-session 1
# 
# vpdn-group x00008
#  request-dialin
#   protocol l2tp
#   domain x8
#  initiate-to ip 12.80.0.10
#  local name lac
#  l2tp tunnel password cisco
#  l2tp tunnel timeout no-session 1
#  exit
# 
# vpdn-group x00009
#  request-dialin
#   protocol l2tp
#   domain x9
#  initiate-to ip 12.80.0.11
#  local name lac
#  l2tp tunnel password cisco
#  l2tp tunnel timeout no-session 1
#  exit
# 
# bba-group pppoe global
#  virtual-template 1
#  exit
# 
# interface FastEthernet3/0
#  no ip address
#  no ip mroute-cache
#  duplex half
#  pppoe enable group global
#  no keepalive
#  no shutdown
#  exit
# 
# interface FastEthernet5/0
#  ip address 12.80.0.1 255.255.255.0
#  no ip mroute-cache
#  duplex half
#  no keepalive
#  no shutdown
#  exit
# 
# interface Virtual-Template1
#  mtu 1458
#  no ip address
#  no logging event link-status
#  no snmp trap link-status
#  no keepalive
#  ppp max-bad-auth 10
#  ppp mtu adaptive
#  ppp authentication chap pap
#  ppp timeout retry 15
#  ppp timeout authentication 15
#  exit
# 
# ip classless
# no ip http server
# 
# line vty 0 16
#  login authentication telnet
# 
# end
#                                                                              #
################################################################################

package require Ixia

set test_name [info script]

set chassisIP sylvester
set port_list [list 4/2 4/4]

set session_count 100
set tunnel_count  10
set sessions_per_tunnel [expr $session_count / $tunnel_count]

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

set access_port  [lindex $port_handle 0]
set network_port [lindex $port_handle 1]

################################################################################
# Configure access interface in the test
################################################################################
set interface_status [::ixia::interface_config \
        -port_handle      $access_port         \
        -mode             config               \
        -speed            auto                 \
        -duplex           auto                 \
        -phy_mode         copper               \
        -autonegotiation  1                    ]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}

################################################################################
# Configure network interfaces in the test (one for each tunnel)
################################################################################
set port_handle_list  ""
set intf_ip_addr_list ""
set gateway_list      ""
set speed_list        ""
set duplex_list       ""
set auto_list         ""
set phy_mode_list     ""
set netmask_list      ""
set src_mac_addr_list ""

for {set i 2} {$i <= [expr $tunnel_count + 1]} {incr i} {
    lappend port_handle_list $network_port
    lappend intf_ip_addr_list 12.80.0.$i
    lappend gateway_list      12.80.0.1
    lappend speed_list        auto
    lappend duplex_list       auto
    lappend phy_mode_list     copper
    lappend auto_list         0
    lappend netmask_list      255.255.255.0
    lappend src_mac_addr_list  00cd.00cd.[format "%04x" $i]
}

set interface_status [::ixia::interface_config \
        -port_handle      $port_handle_list    \
        -mode             config               \
        -speed            $speed_list          \
        -duplex           $duplex_list         \
        -phy_mode         $phy_mode_list       \
        -autonegotiation  $auto_list           \
        -intf_ip_addr     $intf_ip_addr_list   \
        -gateway          $gateway_list        \
        -netmask          $netmask_list        \
        -src_mac_addr     $src_mac_addr_list]

if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}

################################################################################
# Configure PPPoE on access port
################################################################################
# Each tunnel will have a corresponding domain x0 - x9
# Users will be cisco@x1 - cisco@x9
set ppp_domain_group {{{x% 1 0 9 1} {}}}
set config_status [::ixia::pppox_config        \
        -port_handle        $access_port       \
        -protocol           pppoe              \
        -encap              ethernet_ii        \
        -num_sessions       $session_count     \
        -disconnect_rate    10                 \
        -auth_req_timeout   10                 \
        -auth_mode          chap               \
        -username           cisco              \
        -password           cisco              \
        -domain_group_map   $ppp_domain_group  ]
if {[keylget config_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget config_status log]"
}
set pppox_handle [keylget config_status handle]
puts "PPPoE handle is $pppox_handle "

################################################################################
# Configure L2TP on network port
################################################################################
# Each tunnel will have a corresponding domain x0 - x9
# Users will be cisco@x1 - cisco@x9
set l2tp_domain_group {{{x% 1 0 9 1} {}}}
set l2tp_status [::ixia::l2tp_config                     \
        -port_handle              $network_port          \
        -mode                     lns                    \
        -l2_encap                 ethernet_ii            \
        -num_tunnels              $tunnel_count          \
        -l2tp_src_addr            12.80.0.2              \
        -l2tp_dst_addr            12.80.0.1              \
        -sessions_per_tunnel      $sessions_per_tunnel   \
        -l2tp_src_count           $tunnel_count          \
        -l2tp_src_step            0.0.0.1                \
        -l2tp_dst_step            0.0.0.0                \
        -udp_src_port             1701                   \
        -udp_dst_port             1701                   \
        -tunnel_id_start          1                      \
        -session_id_start         1                      \
        -ppp_client_ip            54.0.0.2               \
        -ppp_client_step          0.0.0.1                \
        -ppp_server_ip            54.0.0.1               \
        -tun_auth                                        \
        -hostname                 lac                    \
        -secret                   cisco                  \
        -tun_distribution         next_tunnelfill_tunnel \
        -domain_group_map         $l2tp_domain_group     \
        -auth_mode                chap                   \
        -username                 cisco                  \
        -password                 cisco                  \
        -attempt_rate             10                     ]

if {[keylget l2tp_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget l2tp_status log]"
}
set l2tp_handle [keylget l2tp_status handle]
puts "L2TP handle is $l2tp_handle "

################################################################################
# Connect sessions
################################################################################
set control_status [::ixia::pppox_control \
        -handle     $pppox_handle         \
        -action     connect               ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

set control_status [::ixia::l2tp_control  \
        -handle     $l2tp_handle          \
        -action     connect               ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

puts "Waiting for sessions and tunnels to establish ..."

################################################################################
# Get PPPoE session aggregate statistics
################################################################################
set pppoe_attempts  0
set pppoe_sessions_up 0
while {($pppoe_attempts < 20) && ($pppoe_sessions_up < $session_count)} {
    after 10000
    set pppox_status [::ixia::pppox_stats \
            -handle   $pppox_handle       \
            -mode     aggregate           ]
    
    if {[keylget pppox_status status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget pppox_status log]"
    }
    set  aggregate_stats   [keylget pppox_status aggregate]
    set  pppoe_sessions_up [keylget aggregate_stats sessions_up]
    incr pppoe_attempts
}

set statList {
    idle
    connecting
    num_sessions
    connected
    connect_success
    sessions_up
    success_setup_rate
    min_setup_time
    max_setup_time
    avg_setup_time
}
puts "\n"
puts [format "%-41s" "[string repeat * 14] PPPoE STATS [string repeat * 14]"]
puts ""
puts [format "%-30s %-10s" Statistic Value]
puts [format "%-41s" [string repeat "-" 41]]
foreach {key} $statList {
    if {![catch {keylget aggregate_stats $key}]} {
        puts [format "%-30s %-10d" $key [keylget aggregate_stats $key]]
    }
    
}

################################################################################
# Get L2TP session/tunnel aggregate statistics
################################################################################
set l2tp_attempts   0
set l2tp_tunnels_up 0
while {($l2tp_attempts < 20) && ($l2tp_tunnels_up < $tunnel_count)} {
    after 10000
    set l2tp_status [::ixia::l2tp_stats \
            -handle  $l2tp_handle       \
            -mode    aggregate          ]
    
    if {[keylget l2tp_status status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget l2tp_status log]"
    }
    set  aggregate_stats [keylget l2tp_status aggregate]
    set  l2tp_tunnels_up [keylget aggregate_stats tunnels_up]
    incr l2tp_attempts
}

set statList {
    idle
    connecting
    num_sessions
    connected
    connect_success
    sessions_up
    tunnels_up
    tunnels_neg
    success_setup_rate
    min_setup_time
    max_setup_time
    avg_setup_time
}
puts "\n"
puts [format "%-41s" "[string repeat * 14] L2TPoE STATS [string repeat * 13]"]
puts ""
puts [format "%-30s %-10s" Statistic Value]
puts [format "%-41s" [string repeat "-" 41]]
foreach {key} $statList {
    if {![catch {keylget aggregate_stats $key}]} {
        puts [format "%-30s | %-10d" $key [keylget aggregate_stats $key]]
    }
    
}

################################################################################
# Configure bidirectional traffic on access and network ports
################################################################################
set traffic_status [::ixia::traffic_config      \
        -mode                 create            \
        -port_handle          $access_port      \
        -port_handle2         $network_port     \
        -bidirectional        1                 \
        -l3_protocol          ipv4              \
        -ip_src_mode          emulation         \
        -emulation_src_handle $pppox_handle     \
        -ip_src_count         $session_count    \
        -ip_dst_mode          emulation         \
        -emulation_dst_handle $l2tp_handle      \
        -ip_dst_count         $tunnel_count     \
        -l3_length            1000              \
        -rate_percent         5                 \
        -transmit_mode        continuous        ]

if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}

################################################################################
# Clear traffic stats
################################################################################
set control_status [::ixia::traffic_control \
        -port_handle $port_handle           \
        -action      clear_stats            ]

if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

################################################################################
# Start traffic 
################################################################################
set control_status [::ixia::traffic_control \
        -port_handle $port_handle           \
        -action      run                    ]

if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

after 60000

################################################################################
# Stop traffic
################################################################################
set control_status [::ixia::traffic_control \
        -port_handle $port_handle           \
        -action      stop                   ]

if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}


###############################################################################
#   Retrieve aggregate stats after traffic stopped
###############################################################################
set aggregate_stats [::ixia::traffic_stats -port_handle $port_handle]
if {[keylget aggregate_stats status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget aggregate_stats log]"
}

proc post_stats {port_handle label key_list stat_key {stream ""}} {
    puts -nonewline [format "%-16s" $label]
    
    foreach port $port_handle {
        if {$stream != ""} {
            set key $port.stream.$stream.$stat_key
        } else {
            set key $port.$stat_key
        }
        
        puts -nonewline "[format "%-16s" [keylget key_list $key]]"
    }
    puts ""
}


puts "\n******************* TX/RX STATS **********************"
puts "\t\t$access_port\t\t$network_port"
puts "\t\t-----\t\t-----"

post_stats $port_handle "Elapsed Time"   $aggregate_stats \
        aggregate.tx.elapsed_time
post_stats $port_handle "Packets Tx"     $aggregate_stats aggregate.tx.pkt_count
post_stats $port_handle "Raw Packets Tx" $aggregate_stats \
        aggregate.tx.raw_pkt_count
post_stats $port_handle "Bytes Tx"       $aggregate_stats \
        aggregate.tx.pkt_byte_count
post_stats $port_handle "Bits Tx"        $aggregate_stats \
        aggregate.tx.pkt_bit_count
post_stats $port_handle "Packets Rx"     $aggregate_stats aggregate.rx.pkt_count
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
post_stats $port_handle "RX PCKTS TOS0"  $aggregate_stats aggregate.rx.qos0_count
post_stats $port_handle "RX PCKTS TOS1"  $aggregate_stats aggregate.rx.qos1_count
post_stats $port_handle "RX PCKTS TOS2"  $aggregate_stats aggregate.rx.qos2_count
post_stats $port_handle "RX PCKTS TOS3"  $aggregate_stats aggregate.rx.qos3_count
post_stats $port_handle "RX PCKTS TOS4"  $aggregate_stats aggregate.rx.qos4_count
post_stats $port_handle "RX PCKTS TOS5"  $aggregate_stats aggregate.rx.qos5_count
post_stats $port_handle "RX PCKTS TOS6"  $aggregate_stats aggregate.rx.qos6_count
post_stats $port_handle "RX PCKTS TOS7"  $aggregate_stats aggregate.rx.qos7_count
puts "******************************************************\n"


################################################################################
# Disconnect sessions
################################################################################
puts "Disconnecting sessions ... "
set control_status [::ixia::pppox_control \
        -handle     $pppox_handle         \
        -action     disconnect            ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}
set control_status [::ixia::pppox_control \
        -handle     $l2tp_handle          \
        -action     disconnect            ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

set cleanup_status [::ixia::cleanup_session ]

if {[keylget cleanup_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget cleanup_status log]"
}

return "SUCCESS - $test_name - [clock format [clock seconds]]"
