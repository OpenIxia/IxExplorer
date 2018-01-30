################################################################################
# Version 1.0    $Revision: 1 $
#
#    Copyright © 1997 - 2006 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    02-26-2008 : Mircea Hasegan
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
#    This sample creates SIP client and server configurations                  #
#    using TCP and voice session.                                              #
#    Client is simulating an ORIGINATECALL scenario followed by a VOICESESSION #
#    scenario and ENDCALL sccenario.                                           #
#    At the end statistics are being retrieved.                                #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a ALM1000T8 module.                              #
#                                                                              #
################################################################################

package require Ixia

set test_name [info script]

set chassisIP sylvester
set tclServer sylvester
set port_list [list 2/3 2/4]

set error ""
catch {
set connect_status [::ixia::connect \
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
set client_network_range [::ixia::L47_network             \
        -handle              $client_network_handle     \
        -property            network_pool               \
        -mode                add                        \
        -np_first_ip         "196.18.0.1"               \
        -np_first_mac        "00:C4:12:00:01:00"        \
        -np_ip_count         5000                       ]

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
set server_network_range [::ixia::L47_network              \
        -handle             $server_network_handle       \
        -property           network_pool                 \
        -mode               add                          \
        -np_first_ip        "196.18.100.153"             \
        -np_ip_count        5000                         \
        -np_first_mac       "00:C4:12:64:99:00"          ]

if {[keylget server_network_range status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget server_network_range log]"
}
set server_network_range_handle [keylget server_network_range network_pool_handle]

################################################################################
# Server traffic agent
################################################################################
set server_agent [::ixia::L47_sip_server            \
        -mode                      add              \
        -property                  server           \
        -sz_auth_domain             "domain\[0000-\]"\
        -sz_transport               tcp             \
        -sz_auth_username           "user\[0000-\]" \
        -sz_auth_password           "password\[0000-\]"\
        -n_peer_dtmf_duration       100             \
        -sz_peer_codec_name         "G711ALaw"      \
	    -sz_peer_codec_details      "BF160PT20"     \
	    -sz_peer_dtmf_seq           "12345"         \
	    -sz_codec_descr             "ITU-T G.711 is a standard to represent 8  \
                                    bit compressed pulse code modulation (PCM) \
                                    samples for signals of voice frequencies, \
                                    sampled at the rate of 8000 samples/second. \
                                    G.711 encoder will create a 64 Kbps \
                                    bitstream. A-Law G.711 PCM encoder converts \
                                    13 bit linear PCM samples into 8 bit \
                                    compressed PCM (logarithmic form) samples, \
                                    and the decoder does the conversion vice \
                                    versa."                 \
	    -n_peer_dtmf_interdigits    40                      \
	    -sz_codec_details           "BF160PT20"             \
        -sz_contact                 "<sip:id\[00000-\]@IP>" \
    	-sz_from                    "<sip:id\[00000-\]@IP>" \
    	-sz_to                      "<sip:id\[50000-\]@IP>" \
    ]

if {[keylget server_agent status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget server_agent log]"
}

set server_traffic_handle [keylget server_agent server_handle]
set server_agent_handle [keylget server_agent agent_handle]
set audioClipsTable_server [lindex [keylget server_agent audioClipsTable_handles] 0]

set server_status [::ixia::L47_sip_server               \
        -mode                      add                  \
        -property                  scenarios            \
        -scenarios_id              RECEIVEUSING180      \
        -handle                    $server_agent_handle \
      ]
if {[keylget server_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget server_status log]"
    return
}

set scenario_0 [::ixia::L47_sip_server                  \
        -mode                      add                  \
        -property                  scenarios            \
        -handle                    $server_agent_handle \
        -scenarios_id              VOICESESSION         \
        -n_wav_duration            4800                 \
        -sz_audio_file             $audioClipsTable_server         \
        -vs_n_play_mode            0                    \
        -n_total_time              4800                 \
        -sz_total_time             "4 s, 800 ms"        \
    ]

if {[keylget scenario_0 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget scenario_0 log]"
}
set scenario_handle0 [keylget scenario_0 scenarios_handle]


################################################################################
# Client agent
################################################################################
set client_agent  [::ixia::L47_sip_client           \
        -mode                       add             \
        -property                   client          \
        -sz_auth_domain             "domain\[0000-\]"\
        -sz_transport               tcp             \
        -sz_auth_username           "user\[0000-\]" \
        -sz_auth_password           "password\[0000-\]"\
        -n_peer_dtmf_duration       100             \
        -sz_peer_codec_name         "G711ALaw"      \
	    -sz_peer_codec_details      "BF160PT20"     \
	    -sz_peer_dtmf_seq           "12345"         \
	    -sz_codec_descr             "ITU-T G.711 is a standard to represent 8  \
                                    bit compressed pulse code modulation (PCM) \
                                    samples for signals of voice frequencies, \
                                    sampled at the rate of 8000 samples/second. \
                                    G.711 encoder will create a 64 Kbps \
                                    bitstream. A-Law G.711 PCM encoder converts \
                                    13 bit linear PCM samples into 8 bit \
                                    compressed PCM (logarithmic form) samples, \
                                    and the decoder does the conversion vice \
                                    versa."                 \
	    -n_peer_dtmf_interdigits    40                      \
	    -sz_codec_details           "BF160PT20"             \
        -sz_contact                 "<sip:id\[00000-\]@IP>" \
    	-sz_from                    "<sip:id\[00000-\]@IP>" \
    	-sz_to                      "<sip:id\[50000-\]@IP>" \
    ]

if {[keylget client_agent status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget client_agent log]"
    return
}

set client_traffic_handle [keylget client_agent client_handle]
set client_agent_handle [keylget client_agent agent_handle]
set audioClipsTable_client [lindex [keylget client_agent audioClipsTable_handles] 0]

################################################################################
# Client scenarios
################################################################################
set scenario_1 [::ixia::L47_sip_client                  \
        -mode                      add                  \
        -property                  scenarios            \
        -scenarios_id              ORIGINATECALL        \
        -handle                    $client_agent_handle \
        -sym_destination           $server_agent_handle \
    ]

if {[keylget scenario_1 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget scenario_1 log]"
}
set scenario_handle1 [keylget scenario_1 scenarios_handle]


set scenario_2 [::ixia::L47_sip_client                  \
        -mode                      add                  \
        -property                  scenarios            \
        -handle                    $client_agent_handle \
        -scenarios_id              VOICESESSION         \
        -n_wav_duration            4800                 \
        -sz_audio_file             $audioClipsTable_client      \
        -vs_n_play_mode            0                    \
        -n_total_time              4800                 \
        -sz_total_time             "4 s, 800 ms"        \
    ]

if {[keylget scenario_2 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget scenario_2 log]"
}
set scenario_handle2 [keylget scenario_2 scenarios_handle]

set scenario_3 [::ixia::L47_sip_client                  \
        -mode                      add                  \
        -property                  scenarios            \
        -handle                    $client_agent_handle \
        -scenarios_id              ENDCALL              \
    ]

if {[keylget scenario_3 status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget scenario_3 log]"
}
set scenario_handle3 [keylget scenario_3 scenarios_handle]

################################################################################
# Client traffic-network mapping
################################################################################
set map_status [::ixia::L47_client_mapping                       \
        -mode                           add                      \
        -client_network_handle          $client_network_handle   \
        -client_traffic_handle          $client_traffic_handle   \
        -objective_type                 users                    \
        -objective_value                450                      \
        -standby_time                   30                       \
        -ramp_up_value                  50                       \
        -sustain_time                   900                      ]

if {[keylget map_status status] != $::SUCCESS} {
    return "FAIL - map_status - [keylget map_status log]"
}
set client_map1 [keylget map_status handles]

################################################################################
# Server traffic-network mapping
################################################################################
set map_status [::ixia::L47_server_mapping                    \
        -mode                        add                    \
        -server_network_handle       $server_network_handle \
        -server_traffic_handle       $server_traffic_handle \
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
# Client statistics
################################################################################
set client_stats_list {
    sip_calls_completed
    sip_calls_active
}
set stats_result [::ixia::L47_stats                \
        -mode                 add                  \
        -aggregation_type     sum                  \
        -stat_name            $client_stats_list   \
        -stat_type            client               \
        -protocol             sip                  ]

if {[keylget stats_result status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget stats_result log]"
}
set client_stat_handle [keylget stats_result handles]

################################################################################
# Server statitics
################################################################################
set server_stats_list {
    sip_calls_completed
    sip_calls_active
}

set stats_result [::ixia::L47_stats   \
        -mode                 add                  \
        -aggregation_type     sum                  \
        -stat_name            $server_stats_list   \
        -stat_type            server               \
        -protocol             sip                  ]

if {[keylget stats_result status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget stats_result log]"
}
set server_stat_handle [keylget stats_result handles]


################################################################################
# Start test
################################################################################
set control_status [::ixia::L47_test \
        -handle    $test_handle      \
        -mode      start             ]

if {[keylget control_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget control_status log]"
}


################################################################################
# Get statistics
################################################################################
set client_stats_result [::ixia::L47_stats       \
        -mode   get                              \
        -handle $client_stat_handle              ]

if {[keylget client_stats_result status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget client_stats_result log]"
}

set server_stats_result [::ixia::L47_stats \
        -mode   get                              \
        -handle $server_stat_handle              ]

if {[keylget server_stats_result status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget server_stats_result log]"
}

################################################################################
# Print client statistics
################################################################################

# The stat_required variable can be changed to print only one of the statistics
# e.g set stat_required telnet_active_conn

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


################################################################################
# Print server statistics
################################################################################
set stat_required "all"
puts "Server STATISTICS:"
foreach {stat_handle} [keylkeys server_stats_result] {
    if {$stat_handle != "status"} {
        set stat_handle_kl [keylget server_stats_result $stat_handle]
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
 
set cleanup_status [::ixia::cleanup_session ]

if {[keylget cleanup_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget cleanup_status log]"
}

return "SUCCESS - $test_name - [clock format [clock seconds]]"
