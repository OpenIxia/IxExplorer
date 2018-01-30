#!/usr/bin/tclsh

package req Ixia

set ixiaChassisIp 10.205.4.35
set userName hgee
set portList "1/1/1 1/1/2"
set port1 1/1/1
set port2 1/1/2

set allPorts {}
# port_list format   = 1/1.  Not 1/1/1	
# port_handle format = 1/1/1.  Not 1/1
foreach port $portList {
    lappend allPorts [string range $port 2 end]
}

# NOTE!  Configuring TrafficConfig -stream_id must begin with
#        streamId 1
set connectionStatus [::ixia::connect \
			  -reset \
			  -device $ixiaChassisIp \
			  -port_list $allPorts \
			  -username $userName \
			 ]

if {[keylget connectionStatus status] != $::SUCCESS} {
    puts "\nConnection error! $connectionStatus\n"
    exit
}


# Uncomment these lines for debugging
#set ::ixia::debug 1
#set ::ixia::debug_file_name ixiaHltDebugLog.txt
#set ::ixia::logHltapiCommandsFlag 1
#set ::ixia::logHltapiCommandsFileName ixiaHltCommandsLog.txt


# auto_detect_instrumentation sequence_checking"
set interfaceStatus [::ixia::interface_config \
			 -mode config \
			 -port_handle $port1 \
			 -port_rx_mode auto_detect_instrumentation \
			 -sequence_checking 1 \
			 -intf_ip_addr 1.1.1.1 \
			 -gateway 1.1.1.254 \
			 -netmask  255.255.255.0 \
			 -src_mac_addr 00:01:01:01:00:01 \
		    ]
if {[keylget interfaceStatus status] != $::SUCCESS} {
    puts "\nInterfaceStatus error on $port1! $interfaceStatus\n"
    exit
}

set interfaceStatus [::ixia::interface_config \
			 -mode config \
			 -port_handle $port2 \
			 -port_rx_mode auto_detect_instrumentation \
			 -sequence_checking 1 \
			 -data_integrity 1 \
			 -intf_ip_addr 2.2.2.1 \
			 -gateway 2.2.2.254 \
			 -netmask 255.255.255.0 \
			 -src_mac_addr 00:01:01:02:00:01 \
		    ]
if {[keylget interfaceStatus status] != $::SUCCESS} {
    puts "\nInterfaceStatus error on $port2! $interfaceStatus\n"
    exit
}

 # transmit_mode options: single_burst or continuous
set trafficStatus [::ixia::traffic_config \
		       -mode create \
		       -port_handle $port1 \
		       -enable_auto_detect_instrumentation 1 \
		       -stream_id 1 \
		       -rate_percent 10 \
		       -pkts_per_burst 10000 \
		       -transmit_mode single_burst \
		       -frame_size 100 \
		       -mac_src 00:01:01:02:00:01 \
		       -mac_dst 00:01:01:02:00:02 \
		       -ip_src_addr 1.1.1.1 \
		       -ip_dst_addr 2.2.2.2 \
		       -ethernet_type ethernetII \
	      ]
if {[keylget trafficStatus status] != $::SUCCESS} {
    puts "\nTrafficStatus error on $port1! $trafficStatus\n"
    exit
}



# transmit_mode options: single_burst or continuous
set trafficStatus [::ixia::traffic_config \
		       -mode create \
		       -port_handle $port2 \
		       -enable_auto_detect_instrumentation 1 \
		       -stream_id 2 \
		       -rate_percent 40 \
		       -pkts_per_burst 20000 \
		       -transmit_mode single_burst \
		       -frame_size 90 \
		       -mac_src 00:01:01:01:00:02 \
		       -mac_dst 00:01:01:01:00:01 \
		       -ip_src_addr 1.1.1.1 \
		       -ip_dst_addr 2.2.2.2 \
		       ]
if {[keylget trafficStatus status] != $::SUCCESS} {
    puts "\nTraffic Status error on $port2! $trafficStatus\n"
    exit
}
