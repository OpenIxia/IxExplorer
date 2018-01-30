################################################################################
# Version 1.0    $Revision: 1 $
# $Author: DStanciu $
#
#    Copyright © 1997 - 2006 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    07-07-2006 Dstanciu
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
#    This sample configures 2 PPPoA tunnels with 2 sessions on 4 subports      #
#    between the first Ixia port and DUT , and 8 L2TP tunnels with 8 sessions  #
#    between DUT and the other Ixia port. Traffic is sent between the two      #
#    Ixia ports.                                                               #
#    Topology is the following:                                                #
#                                                                              #
#      Access      PPPoA               L2TPoA                   Destination    #
#      Network   -------- LAC (DUT)  ---------- LNS -----------   Network      #
#    (Ixia Port1)        (Cisco 7200)       (Ixia Port2)       (Ixia Port2)    #
#                                                                              #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a ATM 622 Multi-Rate module.                     #
#                                                                              #
################################################################################
# DUT configuration:
#
# conf t
#
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
# request-dialin
# protocol l2tp
# domain x0
# initiate-to ip 12.80.0.100
# local name lac
# l2tp tunnel password cisco
# l2tp tunnel timeout no-session 1
# exit
#
# vpdn-group x00001
# request-dialin
# protocol l2tp
# domain x1
# initiate-to ip 12.80.0.101
# local name lac
# l2tp tunnel password cisco
# l2tp tunnel timeout no-session 1
# exit
#
# vpdn-group x00002
# request-dialin
# protocol l2tp
# domain x2
# initiate-to ip 12.80.0.102
# local name lac
# l2tp tunnel password cisco
# l2tp tunnel timeout no-session 1
# exit
#
# vpdn-group x00003
# request-dialin
# protocol l2tp
# domain x3
# initiate-to ip 12.80.0.103
# local name lac
# l2tp tunnel password cisco
# l2tp tunnel timeout no-session 1
# exit
#
# vpdn-group x00004
# request-dialin
# protocol l2tp
# domain x4
# initiate-to ip 12.80.0.104
# local name lac
# l2tp tunnel password cisco
# l2tp tunnel timeout no-session 1
# exit
#
# vpdn-group x00005
# request-dialin
# protocol l2tp
# domain x5
# initiate-to ip 12.80.0.105
# local name lac
# l2tp tunnel password cisco
# l2tp tunnel timeout no-session 1
# exit
#
# vpdn-group x00006
# request-dialin
# protocol l2tp
# domain x6
# initiate-to ip 12.80.0.106
# local name lac
# l2tp tunnel password cisco
# l2tp tunnel timeout no-session 1
# exit
#
# vpdn-group x00007
# request-dialin
# protocol l2tp
# domain x7
# initiate-to ip 12.80.0.107
# local name lac
# l2tp tunnel password cisco
# l2tp tunnel timeout no-session 1
# exit
#
# vpdn-group x00008
# request-dialin
# protocol l2tp
# domain x8
# initiate-to ip 12.80.0.108
# local name lac
# l2tp tunnel password cisco
# l2tp tunnel timeout no-session 1
# exit
#
# vpdn-group x00009
# request-dialin
# protocol l2tp
# domain x9
# initiate-to ip 12.80.0.109
# local name lac
# l2tp tunnel password cisco
# l2tp tunnel timeout no-session 1
# exit
#
#
# interface Virtual-Template 2
# no logging event link-status
# no snmp trap link-status
# no keepalive
# ppp max-bad-auth 20
# ppp mtu adaptive
# ppp authentication pap chap
# ppp bridge ip
# ppp ipcp address accept
# ppp timeout retry 10
#
# ! bba-group pppoe dialin
# !  virtual-template 2
#
#
# interface ATM2/0
# no ip address
# no ip route-cache
# no ip mroute-cache
# no shut
# no atm ilmi-keepalive
# range pvc 1/32 1/39
# encapsulation aal5autoppp Virtual-Template2
# protocol ip inarp broadcast
#
#
# interface ATM3/0
# ip address 12.80.0.1 255.255.0.0
# no ip route-cache
# no ip mroute-cache
# no atm ilmi-keepalive
# no shut
# pvc 1/32
# protocol ip 12.80.0.100 broadcast
# encapsulation aal5snap
# pvc 1/33
# protocol ip 12.80.0.101 broadcast
# encapsulation aal5snap
# pvc 1/34
# protocol ip 12.80.0.102 broadcast
# encapsulation aal5snap
# pvc 1/35
# protocol ip 12.80.0.103 broadcast
# encapsulation aal5snap
# pvc 1/36
# protocol ip 12.80.0.104 broadcast
# encapsulation aal5snap
# pvc 1/37
# protocol ip 12.80.0.105 broadcast
# encapsulation aal5snap
# pvc 1/38
# protocol ip 12.80.0.106 broadcast
# encapsulation aal5snap
# pvc 1/39
# protocol ip 12.80.0.107 broadcast
# encapsulation aal5snap
# end
#
################################################################################

package require Ixia

set test_name [info script]

set chassisIP sylvester
set port_list [list 3/1 3/2]

set session_count 8
set tunnel_count  8
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
# Configuring access port interface
################################################################################
set interface_status [::ixia::interface_config \
        -port_handle      $access_port         \
        -speed            oc3                  \
        -intf_mode        atm                  \
        -tx_c2            13                   \
        -rx_c2            13                   \
        -autonegotiation  1                    ]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}

################################################################################
# Configure network interfaces in the test (one for each tunnel)
################################################################################
for {set id 0} {$id < $session_count} {incr id} {
    set interface_status.${id} [::ixia::interface_config  \
            -port_handle       $network_port              \
            -mode              config                     \
            -speed             oc3                        \
            -intf_mode         atm                        \
            -tx_c2             13                         \
            -rx_c2             13                         \
            -atm_encapsulation LLCRoutedCLIP              \
            -vpi               1                          \
            -vci               [expr 32 + $id]            \
            -intf_ip_addr      [format "12.80.0.%d" [expr 100 + $id]] \
            -gateway           12.80.0.1                  \
            -netmask           255.255.0.0                ]
    if {[keylget interface_status.${id} status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget interface_status.${id} log]"
    }
}

################################################################################
# Configure PPPoA on access port
################################################################################
# Each tunnel will have a corresponding domain x0 - x1
# Users will be cisco@x0 - cisco@x1
set ppp_domain_group {{{x% 1 0 1 1} {}}}
set pppox_config_status [::ixia::pppox_config                    \
        -is_last_subport             0                         \
        -port_handle                 $access_port              \
        -protocol                    pppoa                     \
        -encap                       llcsnap                   \
        -num_sessions                [expr $session_count / 4] \
        -l4_flow_number              10                        \
        -vci                         32                        \
        -vci_step                    1                         \
        -vci_count                   [expr $session_count / 4] \
        -pvc_incr_mode               vci                       \
        -vpi                         1                         \
        -vpi_step                    1                         \
        -vpi_count                   1                         \
        -ppp_local_ip                11.0.0.2                  \
        -ppp_local_ip_step           0.0.0.1                   \
        -auth_req_timeout            10                        \
        -auth_mode                   chap                      \
        -username                    cisco                     \
        -password                    cisco                     \
        -domain_group_map            $ppp_domain_group         ]

if {[keylget pppox_config_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget pppox_config_status log]"
}

set pppox_handle [keylget pppox_config_status handle]
puts "PPPoA handle is $pppox_handle "
################################################################################
# Subort 2
################################################################################
# Each tunnel will have a corresponding domain x2 - x3
# Users will be cisco@x2 - cisco@x3
set ppp_domain_group {{{x% 1 2 3 1} {}}}
set pppox_config_status2 [::ixia::pppox_config                   \
        -is_last_subport             0                         \
        -port_handle                 $access_port              \
        -protocol                    pppoa                     \
        -encap                       llcsnap                   \
        -num_sessions                [expr $session_count / 4] \
        -l4_flow_number              10                        \
        -vci                         34                        \
        -vci_step                    1                         \
        -vci_count                   [expr $session_count / 4] \
        -pvc_incr_mode               vci                       \
        -vpi                         1                         \
        -vpi_step                    1                         \
        -vpi_count                   1                         \
        -ppp_local_ip                11.0.0.4                  \
        -ppp_local_ip_step           0.0.0.1                   \
        -auth_req_timeout            10                        \
        -auth_mode                   chap                      \
        -username                    cisco                     \
        -password                    cisco                     \
        -domain_group_map            $ppp_domain_group         ]

if {[keylget pppox_config_status2 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget pppox_config_status2 log]"
}

set pppox_handle2 [keylget pppox_config_status2 handle]
puts "PPPoA handle is $pppox_handle2 "
################################################################################
# Subort 3
################################################################################
# Each tunnel will have a corresponding domain x4 - x5
# Users will be cisco@x4 - cisco@x5
set ppp_domain_group {{{x% 1 4 5 1} {}}}
set pppox_config_status3 [::ixia::pppox_config                   \
        -is_last_subport             0                         \
        -port_handle                 $access_port              \
        -protocol                    pppoa                     \
        -encap                       llcsnap                   \
        -num_sessions                [expr $session_count / 4] \
        -l4_flow_number              10                        \
        -vci                         36                        \
        -vci_step                    1                         \
        -vci_count                   [expr $session_count / 4] \
        -pvc_incr_mode               vci                       \
        -vpi                         1                         \
        -vpi_step                    1                         \
        -vpi_count                   1                         \
        -ppp_local_ip                11.0.0.6                  \
        -ppp_local_ip_step           0.0.0.1                   \
        -auth_req_timeout            10                        \
        -auth_mode                   chap                      \
        -username                    cisco                     \
        -password                    cisco                     \
        -domain_group_map            $ppp_domain_group         ]

if {[keylget pppox_config_status3 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget pppox_config_status3 log]"
}

set pppox_handle3 [keylget pppox_config_status3 handle]
puts "PPPoA handle is $pppox_handle3 "
################################################################################
# Subort 4
################################################################################
# Each tunnel will have a corresponding domain x6 - x7
# Users will be cisco@x6 - cisco@x7
set ppp_domain_group {{{x% 1 6 7 1} {}}}
set pppox_config_status4 [::ixia::pppox_config                   \
        -port_handle                 $access_port              \
        -protocol                    pppoa                     \
        -encap                       llcsnap                   \
        -num_sessions                [expr $session_count / 4] \
        -l4_flow_number              10                        \
        -vci                         38                        \
        -vci_step                    1                         \
        -vci_count                   [expr $session_count / 4] \
        -pvc_incr_mode               vci                       \
        -vpi                         1                         \
        -vpi_step                    1                         \
        -vpi_count                   1                         \
        -ppp_local_ip                11.0.0.8                  \
        -ppp_local_ip_step           0.0.0.1                   \
        -auth_req_timeout            10                        \
        -auth_mode                   chap                      \
        -username                    cisco                     \
        -password                    cisco                     \
        -domain_group_map            $ppp_domain_group         ]

if {[keylget pppox_config_status4 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget pppox_config_status4 log]"
}

set pppox_handle4 [keylget pppox_config_status4 handle]
puts "PPPoA handle is $pppox_handle4 "

################################################################################
# Configure L2TPoA on network port
################################################################################
# Each tunnel will have a corresponding domain x0 - x9
# Users will be cisco@x0 - cisco@x9
set l2tp_domain_group {{{x% 1 0 9 1} {}}}
set l2tp_status [::ixia::l2tp_config                     \
        -port_handle              $network_port          \
        -mode                     lns                    \
        -l2_encap                 atm_snap               \
        -num_tunnels              $tunnel_count          \
        -l2tp_src_addr            12.80.0.100            \
        -l2tp_dst_addr            12.80.0.1              \
        -sessions_per_tunnel      $sessions_per_tunnel   \
        -l2tp_src_count           $tunnel_count          \
        -l2tp_src_step            0.0.0.1                \
        -l2tp_dst_step            0.0.0.0                \
        -udp_src_port             1701                   \
        -udp_dst_port             1701                   \
        -tunnel_id_start          1                      \
        -vci                      32                     \
        -vci_step                 1                      \
        -vci_count                $session_count         \
        -pvc_incr_mode            vci                    \
        -vpi                      1                      \
        -vpi_step                 1                      \
        -vpi_count                1                      \
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

set control_status [::ixia::pppox_control \
        -handle     $pppox_handle2        \
        -action     connect               ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

set control_status [::ixia::pppox_control \
        -handle     $pppox_handle3        \
        -action     connect               ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

set control_status [::ixia::pppox_control \
        -handle     $pppox_handle4        \
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
while {($pppoe_attempts < 20) && ($pppoe_sessions_up < \
            [expr $session_count / 4])} {
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
if {$pppoe_sessions_up < [expr $session_count / 4]} {
    return "FAIL - $test_name - No of sessions less than required for \
            subport 1: $pppoe_sessions_up."
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

# subport 2
set pppoe_attempts  0
set pppoe_sessions_up 0
while {($pppoe_attempts < 20) && ($pppoe_sessions_up < \
            [expr $session_count / 4])} {
    after 10000
    set pppox_status [::ixia::pppox_stats \
            -handle   $pppox_handle2       \
            -mode     aggregate           ]
    
    if {[keylget pppox_status status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget pppox_status log]"
    }
    set  aggregate_stats   [keylget pppox_status aggregate]
    set  pppoe_sessions_up [keylget aggregate_stats sessions_up]
    incr pppoe_attempts
}
if {$pppoe_sessions_up < [expr $session_count / 4]} {
    return "FAIL - $test_name - No of sessions less than required for subport \
            2: $pppoe_sessions_up."
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
# subport 3
set pppoe_attempts  0
set pppoe_sessions_up 0
while {($pppoe_attempts < 20) && ($pppoe_sessions_up < \
            [expr $session_count / 4])} {
    after 10000
    set pppox_status [::ixia::pppox_stats \
            -handle   $pppox_handle3       \
            -mode     aggregate           ]
    
    if {[keylget pppox_status status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget pppox_status log]"
    }
    set  aggregate_stats   [keylget pppox_status aggregate]
    set  pppoe_sessions_up [keylget aggregate_stats sessions_up]
    incr pppoe_attempts
}
if {$pppoe_sessions_up < [expr $session_count / 4]} {
    return "FAIL - $test_name - No of sessions less than required for subport \
            3: $pppoe_sessions_up."
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
# subport 4
set pppoe_attempts  0
set pppoe_sessions_up 0
while {($pppoe_attempts < 20) && ($pppoe_sessions_up < \
            [expr $session_count / 4])} {
    after 10000
    set pppox_status [::ixia::pppox_stats \
            -handle   $pppox_handle4       \
            -mode     aggregate           ]
    
    if {[keylget pppox_status status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget pppox_status log]"
    }
    set  aggregate_stats   [keylget pppox_status aggregate]
    set  pppoe_sessions_up [keylget aggregate_stats sessions_up]
    incr pppoe_attempts
}
if {$pppoe_sessions_up < [expr $session_count / 4]} {
    return "FAIL - $test_name - No of sessions less than required for subport \
            4: $pppoe_sessions_up."
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
puts "Setup traffic.."
################################################################################
# Configure bidirectional traffic on access and network ports
################################################################################
# Reset traffic
################################################################################
set traffic_status [::ixia::traffic_config         \
        -mode                 reset                \
        -port_handle          $access_port         \
        -emulation_src_handle $pppox_handle        \
        -ip_src_mode          emulation            ]

if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}
set traffic_status [::ixia::traffic_config          \
        -mode                 reset                 \
        -port_handle          $network_port         \
        -emulation_src_handle $l2tp_handle          \
        -ip_src_mode          emulation             ]

if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}
################################################################################
# Creating traffic
################################################################################
# Subport 1
################################################################################
set traffic_status [::ixia::traffic_config               \
        -mode                 create                     \
        -port_handle          $access_port               \
        -port_handle2         $network_port              \
        -bidirectional        1                          \
        -l3_protocol          ipv4                       \
        -ip_src_mode          emulation                  \
        -emulation_src_handle $pppox_handle              \
        -ip_src_count         [expr $session_count / 4 ] \
        -ip_dst_mode          emulation                  \
        -emulation_dst_handle $l2tp_handle               \
        -ip_dst_count         [expr $tunnel_count / 4]   \
        -l3_length            1000                       \
        -rate_percent         5                          \
        -transmit_mode        continuous                 ]

if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}
################################################################################
# Subport 2 traffic
################################################################################
set traffic_status [::ixia::traffic_config               \
        -mode                 create                     \
        -port_handle          $access_port               \
        -port_handle2         $network_port              \
        -bidirectional        1                          \
        -l3_protocol          ipv4                       \
        -ip_src_mode          emulation                  \
        -emulation_src_handle $pppox_handle2             \
        -ip_src_count         [expr $session_count / 4 ] \
        -ip_dst_mode          emulation                  \
        -emulation_dst_handle $l2tp_handle               \
        -ip_dst_count         [expr $tunnel_count / 4]   \
        -l3_length            1000                       \
        -rate_percent         5                          \
        -transmit_mode        continuous                 ]

if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}
################################################################################
# Subport 3 traffic
################################################################################
set traffic_status [::ixia::traffic_config               \
        -mode                 create                     \
        -port_handle          $access_port               \
        -port_handle2         $network_port              \
        -bidirectional        1                          \
        -l3_protocol          ipv4                       \
        -ip_src_mode          emulation                  \
        -emulation_src_handle $pppox_handle3             \
        -ip_src_count         [expr $session_count / 4 ] \
        -ip_dst_mode          emulation                  \
        -emulation_dst_handle $l2tp_handle               \
        -ip_dst_count         [expr $tunnel_count / 4]   \
        -l3_length            1000                       \
        -rate_percent         5                          \
        -transmit_mode        continuous                 ]

if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}
################################################################################
# Subport 4
################################################################################
set traffic_status [::ixia::traffic_config               \
        -mode                 create                     \
        -port_handle          $access_port               \
        -port_handle2         $network_port              \
        -bidirectional        1                          \
        -l3_protocol          ipv4                       \
        -ip_src_mode          emulation                  \
        -emulation_src_handle $pppox_handle4             \
        -ip_src_count         [expr $session_count / 4 ] \
        -ip_dst_mode          emulation                  \
        -emulation_dst_handle $l2tp_handle               \
        -ip_dst_count         [expr $tunnel_count / 4]   \
        -l3_length            1000                       \
        -rate_percent         5                          \
        -transmit_mode        continuous                 ]

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
puts "Setup stats..."
################################################################################
# Adding ATM statistics
################################################################################
set traffic_start_status [::ixia::traffic_stats   \
        -port_handle           $access_port     \
        -mode                  add_atm_stats    \
        -vpi                   1                \
        -vci                   32               \
        -vci_count             $session_count   \
        -vci_step              1                \
        -atm_counter_vpi_type  fixed            \
        -atm_counter_vci_type  counter          \
        -atm_counter_vci_mode  incr             ]

if {[keylget traffic_start_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_start_status log]"
}

set traffic_start_status [::ixia::traffic_stats \
        -port_handle           $network_port  \
        -mode                  add_atm_stats  \
        -vpi                   1              \
        -vci                   32             \
        -vci_count             $session_count \
        -vci_step              1              \
        -atm_counter_vpi_type  fixed          \
        -atm_counter_vci_type  counter        \
        -atm_counter_vci_mode  incr           \
        ]

if {[keylget traffic_start_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_start_status log]"
}

puts "Starting to transmit traffic over tunnels..."
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
puts "AFTER STOP"

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
post_stats $port_handle "RX PCKTS TOS0" $aggregate_stats aggregate.rx.qos0_count
post_stats $port_handle "RX PCKTS TOS1" $aggregate_stats aggregate.rx.qos1_count
post_stats $port_handle "RX PCKTS TOS2" $aggregate_stats aggregate.rx.qos2_count
post_stats $port_handle "RX PCKTS TOS3" $aggregate_stats aggregate.rx.qos3_count
post_stats $port_handle "RX PCKTS TOS4" $aggregate_stats aggregate.rx.qos4_count
post_stats $port_handle "RX PCKTS TOS5" $aggregate_stats aggregate.rx.qos5_count
post_stats $port_handle "RX PCKTS TOS6" $aggregate_stats aggregate.rx.qos6_count
post_stats $port_handle "RX PCKTS TOS7" $aggregate_stats aggregate.rx.qos7_count
puts "******************************************************\n"


###############################################################################
# Disconnect sessions
###############################################################################
puts "Disconnecting sessions ... "
set control_status [::ixia::pppox_control \
        -handle     $pppox_handle         \
        -action     disconnect            ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}
set control_status [::ixia::pppox_control \
        -handle     $pppox_handle2        \
        -action     disconnect            ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}
set control_status [::ixia::pppox_control \
        -handle     $pppox_handle3        \
        -action     disconnect            ]
if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}
set control_status [::ixia::pppox_control \
        -handle     $pppox_handle4        \
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

set cleanup_status [::ixia::cleanup_session -port_handle $port_handle]
if {[keylget cleanup_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget cleanup_status log]"
}

return "SUCCESS - $test_name - [clock format [clock seconds]]"
