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
#    This sample creates a FTP client and server basic configuration.          #
#    FTP traffic is sent from client side to server side.                      #
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
set port_list [list 1/3 1/4]

set error ""
catch {
    #####
    # Connect to the chassis, reset to factory defaults and take ownership
    #####
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
    
    
#####################
# Client FTP config #
#####################
set ftp_client_conf [::ixia::emulation_ftp_config \
        -property             ftp                 \
        -mode                 add                 \
        -target               client              \
        -port_handle          $port_handle1       \
        -mac_mapping_mode     macip               \
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

if {[keylget ftp_client_conf status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget ftp_client_conf log]"
}

####################
# Sever FTP config #
####################
set ftp_server_conf [::ixia::emulation_ftp_config \
        -property         ftp                     \
        -mode             add                     \
        -target           server                  \
        -port_handle      $port_handle2           \
        -mac_mapping_mode macip                   ]

if {[keylget ftp_server_conf status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget ftp_server_conf log]"
}

#########################
# Client network config #
#########################
set client_network_conf [::ixia::emulation_ftp_config         \
        -property           network                           \
        -mode               add                               \
        -handle             [keylget ftp_client_conf handles] \
        -ip_address_start   198.18.0.1                        \
        -network_mask       255.255.0.0                       \
        -ip_count           1                                 \
        -ip_increment_step  0.0.0.1                           \
        -gateway            0.0.0.0                           \
        -mac_address_start  00:C6:12:00:01:00                 \
        -mac_increment_step 00:00:00:00:01:00                 \
        -grat_arp_enable    1                                 \
        -mss_enable         1                                 \
        -mss                1460                              ]

if {[keylget client_network_conf status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget client_network_conf log]"
}

#########################
# Server network config #
#########################
set server_network_conf [::ixia::emulation_ftp_config        \
        -property          network                           \
        -mode              add                               \
        -handle            [keylget ftp_server_conf handles] \
        -ip_address_start  198.18.0.101                      \
        -network_mask      255.255.0.0                       \
        -ip_count          10                                \
        -ip_increment_step 0.0.0.1                           \
        -grat_arp_enable   1                                 \
        -mss_enable        1                                 \
        -mss               1460                              ]

if {[keylget server_network_conf status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget server_network_conf log]"
}

#########################
# Client traffic config #
#########################
set ftp_client_traffic [::ixia::emulation_ftp_traffic_config \
        -property      traffic                               \
        -mode          add                                   \
        -target        client                                ]

if {[keylget ftp_client_traffic status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget ftp_client_traffic log]"
}

#########################
# Server traffic config #
#########################
set ftp_server_traffic [::ixia::emulation_ftp_traffic_config \
        -property      traffic                               \
        -mode          add                                   \
        -target        server                                ]

if {[keylget ftp_server_traffic status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget ftp_server_traffic log]"
}

#######################
# Server agent config #
#######################
set ftp_server_agent [::ixia::emulation_ftp_traffic_config \
        -property    agent                                 \
        -mode        add                                   \
        -handle      [keylget ftp_server_traffic handles]  \
        -target      server                                ]

if {[keylget ftp_server_agent status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget ftp_server_agent log]"
}

#######################
# Client agent config #
#######################
set ftp_client_agent [::ixia::emulation_ftp_traffic_config \
        -property    agent                                 \
        -mode        add                                   \
        -handle      [keylget ftp_client_traffic handles]  \
        -target      client                                ]

if {[keylget ftp_client_agent status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget ftp_client_agent log]"
}

########################
# Client action config #
########################

### LOGIN ###
set ftp_client_action [::ixia::emulation_ftp_traffic_config \
        -property      action                               \
        -mode          add                                  \
        -handle        [keylget ftp_client_agent handles]   \
        -command       "login"                              \
        -destination   198.18.0.101                         \
        -user_name     root                                 \
        -password      noreply@ixiacom.com                  \
        -agent_handler [keylget ftp_server_agent handles]   ]

if {[keylget ftp_client_action status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget ftp_client_action log]"
}

### THINK ###
set ftp_client_action  [::ixia::emulation_ftp_traffic_config \
        -property      action                                \
        -mode          add                                   \
        -handle        [keylget ftp_client_agent handles]    \
        -command       "think"                               \
        -arguments     5000                                  \
        -agent_handler [keylget ftp_server_agent handles]    ]

if {[keylget ftp_client_action status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget ftp_client_action log]"
}

### QUIT ###
set ftp_client_action [::ixia::emulation_ftp_traffic_config \
        -property      action                               \
        -mode          add                                  \
        -command       "quit"                               \
        -handle        [keylget ftp_client_agent handles]   \
        -agent_handler [keylget ftp_server_agent handles]   ]

if {[keylget ftp_client_action status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget ftp_client_action log]"
}

############################
# Client map configuration #
############################
set ftp_client_map [::ixia::emulation_ftp_control_config            \
        -property              map                                  \
        -mode                  add                                  \
        -client_iterations     1                                    \
        -target                client                               \
        -client_ftp_handle     [keylget ftp_client_conf handles]    \
        -client_traffic_handle [keylget ftp_client_traffic handles] \
        -objective_type        users                                \
        -ramp_up_type          users_per_second                     \
        -objective_value       10                                   \
        -ramp_up_value         10                                   \
        -client_sustain_time   43                                   \
        -port_map_policy       pairs                                \
        -ramp_down_time        20                                   \
        -client_offline_time   3                                    \
        -client_total_time     64                                   \
        -client_standby_time   0                                    ]
        
if {[keylget ftp_client_map status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget ftp_client_map log]"
}

############################
# Server map configuration #
############################
set ftp_server_map [::ixia::emulation_ftp_control_config             \
        -property               map                                  \
        -mode                   add                                  \
        -target                 server                               \
        -server_ftp_handle      [keylget ftp_server_conf handles]    \
        -server_traffic_handle  [keylget ftp_server_traffic handles] \
        -server_sustain_time    65                                   \
        -server_total_time      65                                   \
        -server_iterations      1                                    \
        -match_client_totaltime 1                                    ]

if {[keylget ftp_server_map status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget ftp_server_map log]"
}

set client_stats_list {
            ftp_simulated_users                      \
            ftp_concurrent_sessions                  \
            ftp_connections                          \
            ftp_transactions                         \
            ftp_bytes                                \
            ftp_control_conn_requested               \
            ftp_control_conn_established             \
            ftp_control_conn_failed                  \
            ftp_control_conn_failed_rejected         \
            ftp_control_conn_failed_other            \
            ftp_control_conn_active                  \
            ftp_data_conn_established                \
            ftp_data_conn_established_active_mode    \
            ftp_data_conn_requested_passive_mode     \
            ftp_data_conn_established_passive_mode   \
            ftp_data_conn_failed_passive_mode        \
            ftp_file_uploads_requested               \
            ftp_file_uploads_successful              \
            ftp_file_uploads_failed                  \
            ftp_file_downloads_requested             \
            ftp_file_downloads_successful            \
            ftp_file_downloads_failed                \
            ftp_data_bytes_sent                      \
            ftp_data_bytes_received                  \
            ftp_control_connection_latency           \
            ftp_data_connection_latency_passive_mode \
            ftp_data_connection_latency_passive_mode \
}

#####################
# Client statistics #
#####################
set ftp_client_stats [::ixia::emulation_ftp_stats \
        -mode                add                  \
        -aggregation_type    sum                  \
        -stat_name           $client_stats_list   \
        -stat_type           client               ]

if {[keylget ftp_client_stats status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget ftp_client_stats log]"
}

set server_stats_list {
            ftp_control_conn_received         \
            ftp_control_conn_established      \
            ftp_control_conn_rejected         \
            ftp_control_conn_active           \
            ftp_data_conn_established         \
            ftp_data_conn_requested_active    \
            ftp_data_conn_established_active  \
            ftp_data_conn_failed_active       \
            ftp_data_conn_established_passive \
            ftp_data_conn_active              \
            ftp_file_uploads_requested        \
            ftp_file_uploads_successful       \
            ftp_file_uploads_failed           \
            ftp_file_downloads_requested      \
            ftp_file_downloads_successful     \
            ftp_file_downloads_failed         \
            ftp_data_bytes_sent               \
            ftp_data_bytes_received           \
            ftp_control_bytes_sent            \
            ftp_control_bytes_received        \
            ftp_data_conn_latency             \
}

#####################
# Server statistics #
#####################
set ftp_server_stats [::ixia::emulation_ftp_stats \
        -mode             add                     \
        -aggregation_type sum                     \
        -stat_name        $server_stats_list      \
        -stat_type        server                  ]

if {[keylget ftp_server_stats status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget ftp_server_stats log]"
}

#########################
# Control configuration #
#########################
set ftp_control [::ixia::emulation_ftp_control                                      \
        -mode                   add                                      \
        -map_handle             [list [keylget ftp_client_map handles]   \
        [keylget ftp_server_map handles]]                                \
        -results_dir_enable     1                                        \
        -results_dir            {/home/testuser/ftp_results_dir}         \
        -force_ownership_enable 1                                        \
        -release_config_afterrun_enable 1                                \
        -reset_ports_enable     1                                        \
        -stats_required         1                                        ]

if {[keylget ftp_control status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget ftp_control log]"
}

###############
# Start test
###
set ftp_control [::ixia::emulation_ftp_control \
        -handle [keylget ftp_control handles]  \
        -mode   start                          ]

if {[keylget ftp_control status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget ftp_control log]"
}

###################
# Get statistics
###
set client_stats_result [::ixia::emulation_ftp_stats    \
        -mode   get                                     \
        -handle [keylget ftp_client_stats handles]      ]

if {[keylget client_stats_result status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget client_stats_result log]"
}

set server_stats_result [::ixia::emulation_ftp_stats    \
        -mode   get                                     \
        -handle [keylget ftp_server_stats handles]      ]

if {[keylget server_stats_result status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget server_stats_result log]"
}

###########################
# Print client statistics #
###########################
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

###########################
# Print server statistics #
###########################
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

##################################################
# Disconnect and cleanup variables and sessions
###
::ixia::cleanup_session
if {$error != ""} {
    ixPuts $error
} else  {
    return "SUCCESS - $test_name - [clock format [clock seconds]]"
}
