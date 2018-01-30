#!/usr/bin/tclsh

package req Ixia
source /home/hgee/MyIxiaWork/HLT/HltLib.tcl

set ixiaChassisIp 10.205.4.172
set userName hgee
set portList "1/1/1 1/1/2"
set port1 1/1/1
set port2 1/1/2


# NOTE!  Configuring TrafficConfig -stream_id must begin with
#        streamId 1
::ixHlt::ConnectToTrafficGenerator \
    -reset \
    -ixChassisIp $ixiaChassisIp \
    -ixosTclServerIp $ixiaChassisIp \
    -portList $portList \
    -userName $userName

# Uncomment these lines for debugging
#set ::ixia::debug 1
#set ::ixia::debug_file_name ixiaHltDebugLog.txt
#set ::ixia::logHltapiCommandsFlag 1
#set ::ixia::logHltapiCommandsFileName ixiaHltCommandsLog.txt

::ixHlt::InterfaceConfig \
    -mode config \
    -port_handle $port1 \
    -port_rx_mode "auto_detect_instrumentation" \
    -intf_ip_addr 1.1.1.1 \
    -gateway 1.1.1.254 \
    -netmask  255.255.255.0 \
    -sequence_checking 1 \
    -src_mac_addr [::ixHlt::GetMacAddrForPort $port1]

::ixHlt::InterfaceConfig \
    -mode config \
    -port_handle $port2 \
    -port_rx_mode "auto_detect_instrumentation" \
    -intf_ip_addr 2.2.2.1 \
    -gateway 2.2.2.254 \
    -netmask 255.255.255.0 \
    -sequence_checking 1 \
    -src_mac_addr [::ixHlt::GetMacAddrForPort $port2]


 # transmit_mode options: single_burst or continuous
::ixHlt::TrafficConfig \
    -mode create \
    -port_handle $port1 \
    -enable_auto_detect_instrumentation 1 \
    -stream_id 1 \
    -rate_percent 10 \
    -pkts_per_burst 10000 \
    -transmit_mode single_burst \
    -frame_size 100 \
    -mac_src [::ixHlt::GetMacAddrForPort $port1] \
    -mac_dst 00:01:01:02:00:01 \
    -ip_src_addr 1.1.1.1 \
    -ip_dst_addr 2.2.2.2 \
    -ethernet_type ethernetII \
    -ip_precedence 2 \
    -vlan_id 2 \
    -vlan_user_priority 7 \
    -igmp_type membership_query \
    -igmp_version 2 \
    -igmp_group_addr 224.1.1.3 \
    -igmp_group_mode increment \
    -igmp_group_count 3 \
    -igmp_max_response_time 97 \
    -l4_protocol igmp


# transmit_mode options: single_burst or continuous
::ixHlt::TrafficConfig \
    -mode create \
    -port_handle $port2 \
    -enable_auto_detect_instrumentation 1 \
    -stream_id 2 \
    -rate_percent 40 \
    -pkts_per_burst 20000 \
    -transmit_mode single_burst \
    -frame_size 90 \
    -mac_src [ixHlt::GetMacAddrForPort $port2] \
    -mac_dst 00:01:01:01:00:01 \
    -ip_src_addr 1.1.1.1 \
    -ip_dst_addr 2.2.2.2 \
    -ip_src_count 8 \
    -ethernet_type ethernetII \
    -ip_precedence 1 \
    -vlan_id 3 \
    -vlan_user_priority 2 \
    -igmp_type membership_query \
    -igmp_version 2 \
    -igmp_group_addr 224.1.1.3 \
    -igmp_group_mode increment \
    -igmp_group_count 3 \
    -igmp_max_response_time 97 \
    -l4_protocol igmp


#ClearPgidStatsHltIxia $portList
::ixHlt::StartTrafficHlt -txPort $portList

# Uncomment this if running continuous traffic
#GetRate $port2
#StopTraffic $port1

# Uncomment this for single burst traffic
#VerifyReceivedPktCount -txPorts $port1 -listeningPorts $port2 -expectedPorts $port2
::ixHlt::VerifyReceivedPktCount -txPorts $portList -listeningPorts $portList -expectedPorts $portList
#GetStats

#::ixHlt::DisconnectIxia

