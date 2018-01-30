################################################################################
# Version 1.0    $Revision: 1 $
#
#    Copyright © 1997 - 2006 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    3-30-2006 : L. Raicea
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
#    This sample creates a Telnet client and server basic configuration.       #
#    Telnet traffic is sent from clent side to server side.                    #
#    At the end statistics are being retrieved.                                #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a LM1000STXS4-256 module.                        #
#                                                                              #
################################################################################

package require Ixia

set test_name [info script]

set chassisIP sylvester
set tclServer winston-400t
set port_list [list 4/1 4/2]


################################################################################
# Connect to the chassis, reset to factory defaults and take ownership
################################################################################
set connect_status [::ixia::connect \
        -reset                    \
        -device     $chassisIP    \
        -port_list  $port_list    \
        -username   ixiaApiUser   \
        -tcl_server $tclServer    ]
if {[keylget connect_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget connect_status log]"
}

set port_handle1  [keylget connect_status \
        port_handle.$chassisIP.[lindex $port_list 0]]

set port_handle2  [keylget connect_status \
        port_handle.$chassisIP.[lindex $port_list 1]]

################################################################################
# Client network
################################################################################
set client_network [::ixia::emulation_telnet_config     \
        -target                         client           \
        -property                       telnet        \
        -mode                           add              \
        -port_handle                    $port_handle1 \
        -mac_mapping_mode               macip         \
        -source_port_from               1024          \
        -source_port_to                 65535         \
        -dns_cache_timeout              35000         \
        -grat_arp_enable                1             \
        -congestion_notification_enable 1             \
        -time_stamp_enable              1                \
        -keep_alive_time                9             \
        -keep_alive_probes              75            \
        -keep_alive_interval            9600          \
        -fin_timeout                    60            \
        -receive_buffer_size            4096          \
        -transmit_buffer_size           4096          \
        -syn_ack_retries                5             \
        -syn_retries                    5             \
        -retransmit_retries             15            ]

if {[keylget client_network status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget client_network log]"
}

set client_network_handle [keylget client_network handles]

################################################################################
# Client network range
################################################################################
set client_network_range [::ixia::emulation_telnet_config \
        -handle              $client_network_handle     \
        -property            network                    \
        -mode                add                           \
        -ip_address_start    20.0.1.1                   \
        -network_mask        255.255.0.0                \
        -ip_count            100                        \
        -ip_increment_step   0.0.0.1                    \
        -gateway             0.0.0.0                    \
        -mac_address_start   00.01.01.01.01.00          \
        -mac_increment_step  00.00.00.00.00.01          ]

if {[keylget client_network_range status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget client_network_range log]"
}

set client_network_range_handle [keylget client_network_range handles]


################################################################################
# Client DNS
################################################################################
set client_dns [::ixia::emulation_telnet_config \
        -handle     $client_network_handle      \
        -property   dns                         \
        -mode       add                         \
        -dns_server 20.0.2.1                    \
        -dns_suffix .ixiacom.com                ]

if {[keylget client_dns status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget client_dns log]"
}
set client_dns_handle1 [keylget client_dns handles]

################################################################################
# Client DNS
################################################################################
set client_dns [::ixia::emulation_telnet_config \
        -handle      $client_network_handle        \
        -property    dns                        \
        -mode        add                        \
        -dns_server  20.0.2.2                   \
        -dns_suffix  .ixiacom.com               ]

if {[keylget client_dns status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget client_dns log]"
}
set client_dns_handle2 [keylget client_dns handles]

################################################################################
# Server network
################################################################################
set server_network [::ixia::emulation_telnet_config       \
        -target                         server                \
        -property                       telnet                \
        -mode                           add                   \
        -port_handle                    $port_handle2      \
        -mac_mapping_mode               macip              \
        -source_port_from               1024               \
        -source_port_to                 65535              \
        -dns_cache_timeout              35000           \
        -grat_arp_enable                1               \
        -congestion_notification_enable 1               \
        -time_stamp_enable              1                  \
        -keep_alive_time                9               \
        -keep_alive_probes              75              \
        -keep_alive_interval            9600            \
        -fin_timeout                    60              \
        -receive_buffer_size            4096            \
        -transmit_buffer_size           4096            \
        -syn_ack_retries                5               \
        -syn_retries                    5               \
        -retransmit_retries             15              ]


if {[keylget server_network status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget server_network log]"
}

set server_network_handle [keylget server_network handles]

################################################################################
# Server network range
################################################################################
set server_network_range [::ixia::emulation_telnet_config \
        -handle             $server_network_handle       \
        -property           network                      \
        -mode               add                          \
        -ip_address_start   20.0.3.1                     \
        -ip_count           1                            \
        -network_mask       255.255.0.0                  \
        -gateway            0.0.0.0                      \
        -ip_increment_step  0.0.0.1                      \
        -mac_address_start  00.03.03.03.03.00            \
        -mac_increment_step 00.00.00.00.00.01            \
        ]

if {[keylget server_network_range status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget server_network_range log]"
}

set server_network_range_handle [keylget server_network_range handles]

################################################################################
# Server traffic
################################################################################
set server_traffic [::ixia::emulation_telnet_traffic_config \
        -target   server  \
        -property traffic \
        -mode     add     ]

if {[keylget server_traffic status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget server_traffic log]"
}

set server_traffic_handle [keylget server_traffic handles]

################################################################################
# Server traffic agent
################################################################################
set server_agent [::ixia::emulation_telnet_traffic_config \
        -handle                $server_traffic_handle \
        -property              agent                  \
        -mode                  add                    \
        -server_close_command  exit                   \
        -server_command_prompt #                      \
        -echo_enable           1                      \
        -linemode_enable       1                      \
        -goahead_enable        0                      \
        -port                  23                     ]

if {[keylget server_agent status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget server_agent log]"
}

set server_agent_handle [keylget server_agent handles]

################################################################################
# Server traffic-network mapping
################################################################################
set server_map [::ixia::emulation_telnet_control_config     \
        -target                 server                   \
        -property               map                      \
        -mode                   add                      \
        -server_telnet_handle   $server_network_handle   \
        -server_traffic_handle  $server_traffic_handle   \
        -server_offline_time    10                       \
        -match_client_totaltime 1                        ]

if {[keylget server_map status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget server_map log]"
}

set server_map_handle [keylget server_map handles]

################################################################################
# Client traffic
################################################################################
set client_traffic [::ixia::emulation_telnet_traffic_config     \
        -target      client  \
        -property    traffic \
        -mode        add     ]


if {[keylget client_traffic status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget client_traffic log]"
}
set client_traffic_handle [keylget client_traffic handles]

################################################################################
# Client agent
################################################################################
set client_agent [::ixia::emulation_telnet_traffic_config \
        -handle                 $client_traffic_handle  \
        -property               agent                   \
        -mode                   add                     \
        -target                 client                  \
        -options_enable         1                       \
        -default_command_prompt #                       \
        -expect_timeout         10                      ]

if {[keylget client_agent status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget client_agent log]"
}
set client_agent_handle [keylget client_agent handles]

################################################################################
# Client commands
################################################################################
set command_1 [::ixia::emulation_telnet_traffic_config \
        -handle     $client_agent_handle \
        -property   action               \
        -mode       add                  \
        -target     client               \
        -command    open                 \
        -expect     login:               \
        -server_ip  20.0.3.1             ]

if {[keylget command_1 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget command_1 log]"
}
set command_handle1 [keylget command_1 handles]

set command_2 [::ixia::emulation_telnet_traffic_config \
        -handle    $client_agent_handle \
        -mode      add                  \
        -property  action               \
        -target    client               \
        -command   login                \
        -send      ixia                 \
        -expect    password:            ]

if {[keylget command_2 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget command_2 log]"
}
set command_handle2 [keylget command_2 handles]

set command_3 [::ixia::emulation_telnet_traffic_config \
        -handle     $client_agent_handle  \
        -mode       add                   \
        -property   action                \
        -target     client                \
        -command    password              \
        -send       ixia                  \
        -expect     #                     ]

if {[keylget command_3 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget command_3 log]"
}
set command_handle3 [keylget command_3 handles]

set command_4 [::ixia::emulation_telnet_traffic_config \
        -handle        $client_agent_handle  \
        -mode          add                   \
        -target        client                \
        -property      action                \
        -command       think                 \
        -max_interval  10000                 \
        -min_interval  10000                 ]

if {[keylget command_4 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget command_4 log]"
}
set command_handle4 [keylget command_4 handles]

set command_5 [::ixia::emulation_telnet_traffic_config \
        -handle    $client_agent_handle \
        -mode      add                  \
        -property  action               \
        -target    client               \
        -command   exit                 \
        -send      exit                 ]

if {[keylget command_5 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget command_5 log]"
}
set command_handle5 [keylget command_5 handles]

################################################################################
# Client traffic-network mapping
################################################################################
set client_map [::ixia::emulation_telnet_control_config \
        -target                 client                  \
        -property               map                     \
        -mode                   add                     \
        -client_iterations      1                       \
        -client_telnet_handle   $client_network_handle  \
        -client_traffic_handle  $client_traffic_handle  \
        -objective_type         users                   \
        -objective_value        100                     \
        -ramp_up_type           users_per_second        \
        -ramp_up_value          1                       \
        -client_sustain_time    20                      \
        -port_map_policy        pairs                   \
        -ramp_down_time         20                      \
        -client_offline_time    0                       \
        -client_total_time      140                     \
        -client_standby_time    0                       ]

if {[keylget client_map status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget client_map log]"
}
set client_map_handle [keylget client_map handles]

################################################################################
# Client and server mapping
################################################################################
set results_dir [pwd]/results/[clock seconds]
set control_status [::ixia::emulation_telnet_control     \
        -mode                           add           \
        -map_handle                     [list         \
        $client_map_handle $server_map_handle]        \
        -force_ownership_enable         1             \
        -release_config_afterrun_enable 1             \
        -reset_ports_enable             1             \
        -stats_required                 1             \
        -results_dir_enable             1             \
        -results_dir                    $results_dir  ]

if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

set test_handle [keylget control_status handles]

################################################################################
# Client statistics
################################################################################
set client_stats_list {
    telnet_active_conn
    telnet_total_conn_requested
    telnet_total_conn_succeeded
    telnet_total_conn_failed
    telnet_total_bytes_sent
    telnet_total_bytes_received
    telnet_total_bytes_sent_and_received
}
set stats_result [::ixia::emulation_telnet_stats   \
        -mode                 add                  \
        -aggregation_type     sum                  \
        -stat_name            $client_stats_list   \
        -stat_type            client               ]

if {[keylget stats_result status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget stats_result log]"
}
set client_stat_handle [keylget stats_result handles]

################################################################################
# Server statitics
################################################################################
set server_stats_list {
    telnet_active_conn
    telnet_total_accepted_conn
    telnet_total_bytes_sent
    telnet_total_bytes_received
}

set stats_result [::ixia::emulation_telnet_stats   \
        -mode                 add                  \
        -aggregation_type     sum                  \
        -stat_name            $server_stats_list   \
        -stat_type            server               ]

if {[keylget stats_result status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget stats_result log]"
}
set server_stat_handle [keylget stats_result handles]

################################################################################
# Start test
################################################################################
set control_status [::ixia::emulation_telnet_control \
        -handle    $test_handle \
        -mode      start        ]

if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}


################################################################################
# Get statistics
################################################################################
set client_stats_result [::ixia::emulation_telnet_stats \
        -mode   get                              \
        -handle $client_stat_handle              ]

if {[keylget client_stats_result status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget client_stats_result log]"
}

set server_stats_result [::ixia::emulation_telnet_stats \
        -mode   get                              \
        -handle $server_stat_handle              ]

if {[keylget server_stats_result status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget server_stats_result log]"
}

################################################################################
# Print client statistics
################################################################################
puts "CLIENT STATISTICS:"
foreach {stat_handle} [keylkeys client_stats_result] {
    if {$stat_handle != "status"} {
        set stat_handle_kl [keylget client_stats_result $stat_handle]
        foreach {stat_type} [keylkeys stat_handle_kl] {
            set stat_type_kl [keylget stat_handle_kl $stat_type]
            foreach {stat_name} [keylkeys stat_type_kl] {
                set stat_name_kl [keylget stat_type_kl $stat_name]
                puts  -nonewline [format \
                        "%10s %10s %40s" $stat_handle $stat_type $stat_name]
                
                set timestamp [lindex [lsort -dictionary \
                        [keylkeys stat_name_kl]] end]
                
                puts [format "%15s %15s" $timestamp \
                        [keylget stat_name_kl $timestamp]]
                
            }
        }
    }
}

################################################################################
# Print server statistics
################################################################################
puts "SERVER STATISTICS:"
foreach {stat_handle} [keylkeys server_stats_result] {
    if {$stat_handle != "status"} {
        set stat_handle_kl [keylget server_stats_result $stat_handle]
        foreach {stat_type} [keylkeys stat_handle_kl] {
            set stat_type_kl [keylget stat_handle_kl $stat_type]
            foreach {stat_name} [keylkeys stat_type_kl] {
                set stat_name_kl [keylget stat_type_kl $stat_name]
                puts  -nonewline [format \
                        "%10s %10s %40s" $stat_handle $stat_type $stat_name]
                
                set timestamp [lindex [lsort -dictionary \
                        [keylkeys stat_name_kl]] end]
                
                puts [format "%15s %15s" $timestamp \
                        [keylget stat_name_kl $timestamp]]
                
            }
        }
    }
}

set cleanup_status [::ixia::cleanup_session ]

if {[keylget cleanup_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget cleanup_status log]"
}

return "SUCCESS - $test_name - [clock format [clock seconds]]"