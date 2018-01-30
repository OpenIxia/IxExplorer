################################################################################
# Version 1.0    $Revision: 1 $
#
#    Copyright © 1997 - 2006 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    3-09-2007 : Mircea Hasegan
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
#    This sample creates a HTTP client and server configuration.               #
#    The client and server networks are configured with IPv6                   #
#    Client is simulating a GET command.                                       #
#    HTTP traffic is sent from client side to server side.                     #
#    At the end statistics are being retrieved.                                #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a ALM1000T8 module.                              #
#                                                                              #
################################################################################

package require Ixia

set test_name [info script]

set chassisIP sylvester
set tclServer winston-400t
set port_list [list 4/1 4/2]

set error ""
catch {
set connect_status [::ixia::connect   \
        -reset                      \
        -device     $chassisIP      \
        -port_list  $port_list      \
        -username   ixiaApiUser     ]

if {[keylget connect_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget connect_status log]"
}

set client_port [keylget \
        connect_status port_handle.$chassisIP.[lindex $port_list 0]]
set server_port [keylget \
        connect_status port_handle.$chassisIP.[lindex $port_list 1]]

################################################################################
# Client network
################################################################################
set client_network [::ixia::L47_network                 \
        -target                         client          \
        -property                       network       \
        -mode                           add              \
        -port_handle                    $client_port  \
        -grat_arp_enable                0             ]
        
if {[keylget client_network status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget client_network log]"
}
set client_network_handle [keylget client_network network_handle]

################################################################################
# Client network pool
################################################################################
set client_network_range [::ixia::L47_network                     \
        -handle              $client_network_handle             \
        -property            network_pool                       \
        -mode                add                                \
        -np_first_ip         "::10:1"                           \
        -np_network_mask     96                                 \
        -np_ip_incr_step     "0:0:0:0:0:0:0:1"                  \
        -np_first_mac        "00:00:26:DF:F8:22"                \
        -np_mac_incr_step    "00:00:00:00:00:01"                \
        -np_ip_count         10                                 \
        -np_gateway          "::0"                              \
        -np_enable_stats     1                                  ]

if {[keylget client_network_range status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget client_network_range log]"
}
set client_network_range_handle [keylget client_network_range network_pool_handle]

################################################################################
# Server network
################################################################################
set server_network [::ixia::L47_network                   \
        -target                         server           \
        -property                       network           \
        -mode                           add                   \
        -port_handle                    $server_port      \
        -grat_arp_enable                0               ]


if {[keylget server_network status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget server_network log]"
}
set server_network_handle [keylget server_network network_handle]

################################################################################
# Server network pool
################################################################################
set server_network_range [::ixia::L47_network                    \
        -handle             $server_network_handle             \
        -property           network_pool                       \
        -mode               add                                \
        -np_first_ip        "::10:100"                         \
        -np_ip_count        1                                  \
        -np_network_mask    96                                 \
        -np_gateway         "::0"                              \
        -np_ip_incr_step    "0:0:0:0:0:0:0:1"                  \
        -np_first_mac       "00:00:88:AA:15:B6"                \
        -np_mac_incr_step   "00:00:00:00:00:01"                ]

if {[keylget server_network_range status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget server_network_range log]"
}
set server_network_range_handle [keylget server_network_range network_pool_handle]


################################################################################
# Create a traffic server and an HTTP agent
# Handles for the default web pages and cookies are returned here
################################################################################

set server_status [::ixia::L47_http_server              \
        -mode                      add                  \
        -property                  server               \
        -http_port                 80                   ]

if {[keylget server_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget server_status log]"
}

set server1 [keylget server_status server_handle]
set server_agent1  [keylget server_status agent_handle]

set wp_handle_list [keylget server_status web_page_handle]

set response_header_list [keylget server_status response_header_handle]

set cookie_handle_list  [keylget server_status cookie_handle]

set cookie_content_list1 [keylget server_status [lindex $cookie_handle_list 0]]
set cookie_content_list1 [keylget cookie_content_list1 cookie_content_handle]

set cookie_content_list2 [keylget server_status [lindex $cookie_handle_list 1]]
set cookie_content_list2 [keylget cookie_content_list2 cookie_content_handle]


################################################################################
# Remove default web pages
################################################################################
foreach wp $wp_handle_list {
    set server_status [::ixia::L47_http_server    \
        -mode                      remove         \
        -handle                    $wp            ]

    if {[keylget server_status status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget server_status log]"
    }
}

################################################################################
# Add three web pages
################################################################################
set server_status [::ixia::L47_http_server                          \
        -mode                      add                              \
        -property                  web_page                         \
        -handle                    $server_agent1                   \
        -wp_response               [lindex $response_header_list 0] \
        -wp_payload_size           "4096-4096"                      \
        -wp_payload_type           range                            \
        -wp_page                   "/4k.html"                       ]

if {[keylget server_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget server_status log]"
}
set web_page1 [keylget server_status web_page_handle]

set server_status [::ixia::L47_http_server                          \
        -mode                      add                              \
        -property                  web_page                         \
        -handle                    $server_agent1                   \
        -wp_response               [lindex $response_header_list 1] \
        -wp_payload_size           "8192-8192"                      \
        -wp_payload_type           range                            \
        -wp_page                   "/8k.html"                       ]

if {[keylget server_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget server_status log]"
}
set web_page2 [keylget server_status web_page_handle]

set wp_handle_list [list $web_page1 $web_page2]

################################################################################
# Create a traffic client and an HTTP agent
################################################################################
set status_http [::ixia::L47_http_client              \
        -mode                      add              \
        -property                  client           \
        -max_sessions              3                \
        -http_version              1.0              \
        -keep_alive                0                \
        -max_persistent_requests   3                \
        -follow_http_redirects     0                \
        -cookie_support_enable     0                \
        -http_proxy_enable         0                \
        -https_proxy_enable        0                \
        -browser_emulation         ie5              \
        -ip_preference             1                ]
        
if {[keylget status_http status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget status_http log]"
}
set client_handle1  [keylget status_http client_handle]
set client_agent1   [keylget status_http agent_handle]

################################################################################
# Add three actions to the http agent
################################################################################
foreach wp $wp_handle_list {
    set status_http [::ixia::L47_http_client              \
            -mode                      add              \
            -property                  action           \
            -handle                    $client_agent1   \
            -a_command                 get              \
            -a_destination             $server_agent1   \
            -a_page_handle             $wp              ]
    
    if {[keylget status_http status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget status_http log]"
    }
}

################################################################################
# Create client mapping
################################################################################
set map_status [::ixia::L47_client_mapping                         \
        -mode                           add                      \
        -client_network_handle          $client_network_handle   \
        -client_traffic_handle          $client_handle1          \
        -objective_type                 users                    \
        -objective_value                20                       \
        -ramp_up_value                  5                        \
        -sustain_time                   20                       \
        -ramp_down_time                 20                       ]

if {[keylget map_status status] != $::SUCCESS} {
    return "FAIL - map_status - [keylget map_status log]"
}
set client_map1 [keylget map_status handles]

################################################################################
# Create server mapping
################################################################################
set map_status [::ixia::L47_server_mapping                    \
        -mode                        add                    \
        -server_network_handle       $server_network_handle \
        -server_traffic_handle       $server1               \
        -match_client_total_time     1                      \
        ]

if {[keylget map_status status] != $::SUCCESS} {
    return "FAIL - map_status - [keylget map_status log]"
}
set server_map1 [keylget map_status handles]


################################################################################
# Test settings
################################################################################

set results_dir [pwd]/results/[clock seconds]
set control_status [::ixia::L47_test                  \
        -mode                           add           \
        -map_handle                     [list         \
                            $client_map1 $server_map1]\
        -force_ownership_enable         1             \
        -reset_ports_enable             1             \
        -stats_required                 0             \
        -results_dir_enable             1             \
        -results_dir                    $results_dir  ]

if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}
set test_handle [keylget control_status handles]

################################################################################
# Add statistics
################################################################################
set client_stats_list {
        http_bytes_sent
        http_bytes_received
}

set client_agg_list {
    sum
}

set http_client_stat [::ixia::L47_stats                                \
        -mode             add                                          \
        -aggregation_type $client_agg_list                             \
        -stat_name        $client_stats_list                           \
        -stat_type        client                                       \
        -protocol         http                                         ]

if {[keylget http_client_stat status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget http_client_stat log]"
}
set client_stat_handle [keylget http_client_stat handles]


################################################################################
# Start test
################################################################################
set control_status [::ixia::L47_test \
        -handle    $test_handle \
        -mode      start        ]

if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}

################################################################################
# Get statistics
################################################################################
set client_stats_result [::ixia::L47_stats \
        -mode   get                              \
        -handle $client_stat_handle              ]

if {[keylget client_stats_result status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget client_stats_result log]"
}

################################################################################
# Print client statistics
################################################################################

# The stat_required variable can be changed to print only one of the statistics
# e.g set stat_required packets_sent

set stat_required "all"
puts "CLIENT STATISTICS:"
foreach {stat_handle} [keylkeys client_stats_result] {
    if {$stat_handle != "status"} {
        set stat_handle_kl [keylget client_stats_result $stat_handle]
        foreach {stat_type} [keylkeys stat_handle_kl] {
            set stat_type_kl [keylget stat_handle_kl $stat_type]
            foreach {stat_name} [keylkeys stat_type_kl] {
                if {$stat_name != $stat_required && $stat_required != "all" } {
                        continue
                }
                set stat_name_kl [keylget stat_type_kl $stat_name]
                foreach {time_stamp} $stat_name_kl {
                    foreach {key value} $time_stamp {
                        if {$key == ""} { set key N/A }
                        if {$value == ""} { set value N/A }
                        puts  -nonewline [format \
                                "%10s %10s %40s" $stat_handle $stat_type $stat_name]
                        
                        puts [format "%15s %15s" $key $value]
                    }
                }                
            }
        }
    }
}

} error

::ixia::cleanup_session
if {$error != ""} {
    ixPuts $error
} else  {
    return "SUCCESS - $test_name - [clock format [clock seconds]]"
}
