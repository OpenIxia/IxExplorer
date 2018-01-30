################################################################################
# Version 1.0    $Revision: 1 $
#
#    Copyright © 1997 - 2006 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    4-28-2006 : D. Stanciu
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
#    This sample creates a HTTP client and server configuration with emulated  #
#    routers between emulated networks and port.Client is simulating a GET     #
#    command.                                                                  #
#    HTTP traffic is sent from clent side to server side.                      #
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
set port_list [list 4/3 4/4]

set error ""
catch {

################################################################################
# Connect to the chassis, reset to factory defaults and take ownership
################################################################################
set connect_status [::ixia::connect   \
        -reset                      \
        -device     $chassisIP      \
        -port_list  $port_list      \
        -username   ixiaApiUser     \
        -tcl_server $tclServer      ]

if {[keylget connect_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget connect_status log]"
}

set port_handle1 [keylget \
        connect_status port_handle.$chassisIP.[lindex $port_list 0]]

set port_handle2 [keylget \
        connect_status port_handle.$chassisIP.[lindex $port_list 1]]


################################################################################
# Configure HTTP client
################################################################################
set http_client_conf [::ixia::emulation_http_config \
        -target               client                 \
        -property             http                \
        -mode                 add                    \
        -port_handle          $port_handle1       \
        -mac_mapping_mode     macport             \
        -source_port_from     1024                \
        -source_port_to       65535               \
        -dns_cache_timeout    35000               \
        -grat_arp_enable      1                   \
        -congestion_notification_enable 1         \
        -time_stamp_enable    1                      \
        -keep_alive_time      9                   \
        -keep_alive_probes    75                  \
        -keep_alive_interval  9600                \
        -fin_timeout          60                  \
        -receive_buffer_size  4096                \
        -transmit_buffer_size 4096                \
        -syn_ack_retries      5                   \
        -syn_retries          5                   \
        -retransmit_retries   15                  ]


if {[keylget http_client_conf status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget http_client_conf log]"
}

################################################################################
# Adding a network range for http client configuration
################################################################################
set client_network_conf [::ixia::emulation_http_config \
        -handle  [keylget http_client_conf handles]  \
        -property           network                  \
        -mode               add                         \
        -ip_address_start   198.18.2.1               \
        -mac_address_start  90.a0.a5.22.c1.09        \
        -network_mask       255.255.0.0              \
        -gateway            0.0.0.0                  \
        -ip_count           100                      \
        -ip_increment_step  0.0.0.1                  \
        -mac_increment_step 00.00.00.00.00.01        ]

if {[keylget client_network_conf status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget client_network_conf log]"
}

################################################################################
# Adding two dns servers
################################################################################
set client_dns_conf1 [::ixia::emulation_http_config \
        -handle [keylget http_client_conf handles]     \
        -property   dns                             \
        -mode       add                             \
        -dns_server 198.18.2.254                    \
        -dns_suffix .ixiacom.com                    ]

if {[keylget client_dns_conf1 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget client_dns_conf1 log]"
}

set client_dns_conf2 [::ixia::emulation_http_config \
        -handle [keylget http_client_conf handles]     \
        -property   dns                             \
        -mode       add                             \
        -dns_server 198.18.2.253                    \
        -dns_suffix .ixiacom.com                    ]

if {[keylget client_dns_conf2 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget client_dns_conf2 log]"
}

################################################################################
# Ading emulated router router_address/macperport client
################################################################################
set emulated_gatewayc [::ixia::emulation_http_config \
        -handle [keylget http_client_conf handles] \
        -property                router_addr       \
        -mode                    add               \
        -emulated_router_gateway 155.0.0.2         \
        -emulated_router_subnet  255.255.0.0       \
        -pool_ip_address_start   155.0.0.1         \
        -pool_ip_count           1                 \
        -pool_mac_address_start  00.0b.0a.12.c1.12 \
        -pool_network            255.255.0.0       \
        -pool_vlan_enable        0                 ]
if {[keylget emulated_gatewayc status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget emulated_gatewayc log]"
}

################################################################################
# Configuring a http client traffic
################################################################################
set http_client_traffic [::ixia::emulation_http_traffic_config     \
        -target   client                                        \
        -property traffic                                       \
        -mode     add                                           ]

if {[keylget http_client_traffic status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget http_client_traffic log]"
}

################################################################################
# Client agent
################################################################################
set http_client_agent [::ixia::emulation_http_traffic_config           \
        -property                agent                                 \
        -handle                  [keylget http_client_traffic handles] \
        -mode                    add                                   \
        -max_sessions            3                                     \
        -http_version            1.0                                   \
        -keep_alive              0                                     \
        -max_persistent_requests 3                                     \
        -follow_http_redirects   0                                     \
        -cookie_support_enable   0                                     \
        -http_proxy_enable       0                                     \
        -https_proxy_enable      0                                     \
        -ssl_enable              0                                     \
        -browser_emulation       ie6                                   ]

if {[keylget http_client_agent status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget http_client_agent log]"
}

################################################################################
# Configure HTTP server
################################################################################
set http_server_conf [::ixia::emulation_http_config \
        -target               server                 \
        -property             http                      \
        -mode                 add                       \
        -port_handle          $port_handle2       \
        -mac_mapping_mode     macport                \
        -source_port_from     1024                   \
        -source_port_to       65535                  \
        -dns_cache_timeout    35000               \
        -grat_arp_enable      1                   \
        -congestion_notification_enable 1         \
        -time_stamp_enable    1                      \
        -keep_alive_time      9                   \
        -keep_alive_probes    75                  \
        -keep_alive_interval  9600                \
        -fin_timeout          60                  \
        -receive_buffer_size  4096                \
        -transmit_buffer_size 4096                \
        -syn_ack_retries      5                   \
        -syn_retries          5                   \
        -retransmit_retries   15                  ]


if {[keylget http_server_conf status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget http_server_conf log]"
}

################################################################################
# Adding a network range for this server configuration
################################################################################
set http_server_network [::ixia::emulation_http_config \
        -handle [keylget http_server_conf handles]   \
        -property           network                  \
        -mode               add                      \
        -ip_address_start   198.18.200.1             \
        -mac_address_start  00.04.04.04.98.00        \
        -gateway            0.0.0.0                  \
        -ip_count           1                        \
        -network_mask       255.255.0.0              \
        -ip_increment_step  0.0.0.1                  \
        -mac_increment_step 00.00.00.00.00.01        ]

if {[keylget http_server_network status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget http_server_network log]"
}

################################################################################
# Ading emulated router router_address/macperport server
################################################################################
set emulated_gateways [::ixia::emulation_http_config \
        -handle [keylget http_server_conf handles] \
        -property                router_addr       \
        -mode                    add               \
        -emulated_router_gateway 155.0.0.1         \
        -emulated_router_subnet  255.255.0.0       \
        -pool_ip_address_start   155.0.0.2         \
        -pool_ip_count           1                 \
        -pool_mac_address_start  00.0a.0b.12.f1.12 \
        -pool_network            255.255.0.0       \
        -pool_vlan_enable        0                 ]
if {[keylget emulated_gateways status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget emulated_gateways log]"
}

################################################################################
# Configuring a http server traffic
################################################################################
set http_server_traffic [::ixia::emulation_http_traffic_config \
        -target   server                                       \
        -property traffic                                      \
        -mode     add                                          ]

if {[keylget http_server_traffic status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget http_server_traffic log]"
}

################################################################################
# Adding an http server agent that will receive http client traffic
################################################################################
set http_server_agent [::ixia::emulation_http_traffic_config \
        -property     agent                                  \
        -handle       [keylget http_server_traffic handles]  \
        -mode         add                                    \
        -http_port    80                                     ]
        
if {[keylget http_server_agent status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget http_server_agent log]"
}

set serverPageHandles        [keylget http_server_agent page_handles]
set serverHeaderHandles      [keylget http_server_agent header_handles]
set serverCookieListHandles  [keylget http_server_agent cookielist_handles]
set serverCookieHandles1     [keylget http_server_agent \
            [lindex $serverCookieListHandles 0].cookie_handles]
set serverCookieHandles2     [keylget http_server_agent \
            [lindex $serverCookieListHandles 1].cookie_handles]

################################################################################
# Client traffic  agent action
################################################################################
set http_client_action [::ixia::emulation_http_traffic_type_config \
        -property      action                                      \
        -handle        [keylget http_client_agent handles]         \
        -mode          add                                         \
        -command       get                                         \
        -destination   [keylget http_server_agent handles]         \
        -page_handle   [lindex $serverPageHandles 5]               ]

if {[keylget http_client_action status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget http_client_action log]"
}

################################################################################
# Map http client configuration with http client traffic
################################################################################
set http_client_map [::ixia::emulation_http_control_config                    \
        -target                client                                \
        -property              map                                   \
        -mode                  add                                   \
        -client_iterations     1                                     \
        -client_http_handle    [keylget http_client_conf handles]    \
        -client_traffic_handle [keylget http_client_traffic handles] \
        -objective_type        users                                 \
        -objective_value       30                                    \
        -ramp_up_type          users_per_second                      \
        -ramp_up_value         10                                    \
        -client_sustain_time   43                                    \
        -port_map_policy       pairs                                 \
        -ramp_down_time        20                                    \
        -client_offline_time   2                                     \
        -client_total_time     43                                    \
        -client_standby_time   0                                     ]

if {[keylget http_client_map status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget http_client_map log]"
}

################################################################################
# Map http server configuration with server traffic
################################################################################
set http_server_map [::ixia::emulation_http_control_config                     \
        -target                 server                                \
        -property               map                                   \
        -mode                   add                                   \
        -server_http_handle     [keylget http_server_conf handles]       \
        -server_traffic_handle  [keylget http_server_traffic handles] \
        -match_client_totaltime 1                                     ]

if {[keylget http_server_map status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget http_server_map log]"
}

################################################################################
# Create statistics for client and server
################################################################################
set client_stats_list {
        http_transactions
        http_users_active
        http_bytes_sent
        http_bytes_received
        http_cookies_received
        http_cookies_sent
        http_cookies_rejected
        http_connect_time
        http_cookies_rejected_path
        http_cookies_rejected_domain
        http_cookies_rejected_overflow
        http_cookies_rejected_probabilistic
        http_connect_time
}

set http_client_stat [::ixia::emulation_http_stats                     \
        -mode             add                                          \
        -aggregation_type sum                                          \
        -stat_name        $client_stats_list                           \
        -stat_type        client                                       \
        -filter_type      port                                         \
        -filter_value     $port_handle1                                ]

if {[keylget http_client_stat status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget http_client_stat log]"
}
set server_stats_list {
        http_requests_received
        http_requests_successful
        http_requests_failed
        http_sessions_rejected
        http_session_timeouts
        http_transactions_active
        http_bytes_received
        http_bytes_sent
        http_cookies_received
        http_cookies_sent
}

set http_server_stat [::ixia::emulation_http_stats                     \
        -mode             add                                          \
        -aggregation_type sum                                          \
        -stat_name        $server_stats_list                           \
        -stat_type        server                                       \
        -filter_type      port                                         \
        -filter_value     $port_handle2                                ]

if {[keylget http_server_stat status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget http_server_stat log]"
}

################################################################################
# Create a control configuration for client and server mappings 
################################################################################
set http_control [::ixia::emulation_http_control        \
        -mode                   add                  \
        -map_handle             [list                \
        [keylget http_client_map handles]            \
        [keylget http_server_map handles]]           \
        -results_dir_enable     1                    \
        -results_dir            {http_results_dir}   \
        -force_ownership_enable 1                    \
        -release_config_afterrun_enable 1            \
        -reset_ports_enable     1                    \
        -stats_required         1                    ]

if {[keylget http_control status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget http_control log]"
}

################################################################################
# Start test
################################################################################
set http_control [::ixia::emulation_http_control \
        -handle [keylget http_control handles]   \
        -mode   start                            ]

if {[keylget http_control status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget http_control log]"
}

################################################################################
# Get statistics
################################################################################
set client_stats_result [::ixia::emulation_http_stats   \
        -mode   get                                     \
        -handle [keylget http_client_stat handles]      ]

if {[keylget client_stats_result status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget client_stats_result log]"
}

set server_stats_result [::ixia::emulation_http_stats   \
        -mode   get                                     \
        -handle [keylget http_server_stat handles]      ]

if {[keylget server_stats_result status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget server_stats_result log]"
}

################################################################################
# Print client statistics
################################################################################
ixPuts "CLIENT STATISTICS:"
foreach {stat_handle} [keylkeys client_stats_result] {
    if {$stat_handle != "status"} {
        set stat_handle_kl [keylget client_stats_result $stat_handle]
        foreach {stat_type} [keylkeys stat_handle_kl] {
            set stat_type_kl [keylget stat_handle_kl $stat_type]
            foreach {stat_name} [keylkeys stat_type_kl] {
                set stat_name_kl [keylget stat_type_kl $stat_name]
                ixPuts  -nonewline [format \
                        "%10s %10s %40s" $stat_handle $stat_type $stat_name]
                
                set timestamp [lindex [lsort -dictionary \
                        [keylkeys stat_name_kl]] end]
                
                ixPuts [format "%15s %15s" $timestamp \
                        [keylget stat_name_kl $timestamp]]
                
            }
        }
    }
}

################################################################################
# Print server statistics
################################################################################
ixPuts "SERVER STATISTICS:"
foreach {stat_handle} [keylkeys server_stats_result] {
    if {$stat_handle != "status"} {
        set stat_handle_kl [keylget server_stats_result $stat_handle]
        foreach {stat_type} [keylkeys stat_handle_kl] {
            set stat_type_kl [keylget stat_handle_kl $stat_type]
            foreach {stat_name} [keylkeys stat_type_kl] {
                set stat_name_kl [keylget stat_type_kl $stat_name]
                ixPuts  -nonewline [format \
                        "%10s %10s %40s" $stat_handle $stat_type $stat_name]
                
                set timestamp [lindex [lsort -dictionary \
                        [keylkeys stat_name_kl]] end]
                
                ixPuts [format "%15s %15s" $timestamp \
                        [keylget stat_name_kl $timestamp]]
                
            }
        }
    }
}

} error

################################################################################
# Disconnect and cleanup variables and sessions
################################################################################
::ixia::cleanup_session
if {$error != ""} {
    ixPuts $error
} else  {
    return "SUCCESS - $test_name - [clock format [clock seconds]]"
}
