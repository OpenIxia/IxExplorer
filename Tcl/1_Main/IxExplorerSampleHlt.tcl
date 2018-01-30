#!/usr/bin/tclsh

# IxExplorer HLT Sample by: Hubert Gee
#
# Description
# 
#    This is an IxExplorer sample script to configure
#    IxRouter port for layer3 and L2/L3 traffic streams.
#  
#    Configuring IxRouter for layer3 is optional.  If
#    you do not want layer3, then don't include the 
#    layer3 parameters.
#
#    Connect two back-to-back Ixia ports together. You
#    could connect Ixia ports to your DUT, but to get
#    familiar with the HLT APIs, using back-to-back 
#    Ixia ports will be much easier to learn by avoiding
#    misconfigurations on the DUT. 
#
#    This sample script uses PGID, which is an Ixia 
#    signature on each packet.  
#
#    PGID is a unique number for each traffic stream.
#
#    Throughout this sample, there are notes before and
#    after each block of code to explain what it does
#    and how to get the status, as well as showing you
#    cut and paste status outputs of the HLT status.  
# 
#    You will need to write some code, preferably in Tcl
#    array format to map each PGID associated to the port
#    for traffic stat validation.
# 
#    Keep in mind that for each stream that you create
#    on the same port, the PGID number will increment.
#
#    This sample script comes with three statistic 
#

package req Ixia

set ixiaChassisIp 10.219.117.101
set userName hgee
set portList "1/1/1 1/1/2"
set port1 1/1/1
set port2 1/1/2

proc StartTrafficHlt { args } {
    # -txPort: one or more transmitting ports
    # -trafficDuration: Optionally, you can set a total amount of 
    #                   time in seconds to send the traffic

    set trafficDuration 0

    set argIndex 0
    while {$argIndex < [llength $args]} {
	set currentArg [lindex $args $argIndex]
	switch -exact -- $currentArg {
	    -txPort {
		set txPorts [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    -trafficDuration {
		set trafficDuration [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    default {
		puts "StartTrafficHlt: No such parameter: $currentArg"
	    }
	}
    }

    set portHandleList {}
    foreach pHandle $txPorts {
	lappend portHandleList $pHandle
    }

    puts "Starting IxExplorer traffic ..."
    set trafficControlStatus [ixia::traffic_control \
				  -port_handle $portHandleList \
				  -action sync_run \
				 ]

    if {[keylget trafficControlStatus status] != $::SUCCESS} {
	puts "StartTrafficHlt ERROR: Ixia traffic failed to start on port $portHandleList"
	puts [KeylPrint trafficControlStatus]
	return 1
    } else {
	puts "StartTrafficHlt: Traffic started on port $portHandleList"
    }
    
    if {$trafficDuration > 0} {
	puts "Traffic will run in the background for $trafficDuration seconds"	
	sleep $trafficDuration
	set trafficControlStatus [ixia::traffic_control \
				      -port_handle $portHandleList \
				      -action stop \
				     ]
	
	if {[keylget trafficControlStatus status] != $::SUCCESS} {
	    puts "Failed to stop Ixia traffic on ports $portHandleList"
	    puts [KeylPrint trafficControlStatus]
	}
	
	CheckPortTransmitDoneIxia $txPorts
	
    } else {
	after 2000
    }
}

proc StopTraffic { port_handle_list } {
    set trafficControlStatus [ixia::traffic_control \
				    -port_handle $port_handle_list \
				    -action stop
			       ]

    if {[keylget trafficControlStatus status] != $::SUCCESS} {
	puts "Failed to stop Ixia traffic on ports $port_handle_list\n[KeylPrint trafficControlStatus]"
    } else {
	puts "StopTraffic: Ixia traffic stopped on ports $port_handle_list"
    }
}

proc CheckPortTransmitDoneIxia { port_list } {
    foreach port $port_list {
	lappend portList "[split $port /]"
    }

    ixCheckTransmitDone portList
    puts "$port_list stopped transmitting."
}

# These stats are for IxExplorer stats. Not for IxNetwork stats.
proc GetStatsAggregate {} {
    # Example on getting aggregated port stats

    set aggregateStats [ixia::traffic_stats \
			    -port_handle $::portList \
			    -mode aggregate \
			   ]    
    if {[keylget aggregateStats status] != $::SUCCESS} {
	puts "Error: GetStatsAggregate: $aggregateStats"
	return 1
    }

    puts "\n[KeylPrint aggregateStats]\n"
    
    puts "\n[format %6s Port][format %10s Tx][format %12s Rx]"
    puts "-----------------------------------"
    
    foreach port $::portList  {
	set totalTx [keylget aggregateStats $port.aggregate.tx.pkt_count]
	set totalRx [keylget aggregateStats $port.aggregate.rx.pkt_count]
	puts "[format %6s $port][format %13s $totalTx][format %12s $totalRx]"
    }
}

proc GetStatsStream {} {
    # Example on getting stream Id stats

    set streamStats [ixia::traffic_stats \
			    -port_handle $::portList \
			    -mode stream \
			   ]
    puts "\n[KeylPrint streamStats]\n"
    
    puts "\n[format %6s Port][format %10s Tx][format %12s Rx]"
    puts "-----------------------------------"
    
    foreach port $::portList  {
	set totalTx [keylget streamStats $port.stream.1.tx.total_pkts]
	set totalRx [keylget streamStats $port.stream.1.rx.total_pkts]
	
	puts "[format %6s $port][format %13s $totalTx][format %12s $totalRx]"
    }
}

proc GetStatsPgid { {totalPgids 1} } {
    # Example for PGID stats
    # -packet_group_id:
    #     give a packet group ID, returns the statistics for all packet group ids
    #     from 0 to this value.  It also support a range. For example 7-9 means
    #     that return statistics for group 7, 8, and 9. Valid only IxOS.

    set pgidStatistics [ixia::traffic_stats \
			    -port_handle $::portList \
			    -packet_group_id $totalPgids \
			   ]
    puts "\n[KeylPrint pgidStatistics]\n"

    puts "\n[format %6s Port][format %10s Tx][format %12s Rx]"
    puts "-----------------------------------"
    
    foreach port $::portList {
	# $port.pgid.rx.pkt_count.2
	set totalTx [keylget pgidStatistics $port.aggregate.tx.pkt_count]
	set totalRx [keylget pgidStatistics $port.aggregate.rx.pkt_count]

	puts "[format %6s $port][format %10s $totalTx][format %12s $totalRx]"
    }
	
    puts \n
}


proc KeylPrint {keylist {space ""}} {
    upvar $keylist kl
    set result ""
    foreach key [keylkeys kl] {
	set value [keylget kl $key]
	if {[catch {keylkeys value}]} {
	    append result "$space$key: $value\n"
	} else {
	    set newspace "$space "
	    append result "$space$key:\n[KeylPrint value $newspace]"
	}
    }
    return $result
}

# Uncomment these lines for debugging.
# The following lines will generate a HLT debug file for debugging problems.
set ::ixia::logHltapiCommandsFlag 1
set ::ixia::logHltapiCommandsFileName ixiaHltDebug1.txt

puts "\nConnecting to Ixia chassis and ports ..."
set connectStatus [::ixia::connect \
		       -reset \
		       -device      $ixiaChassisIp \
		       -tcl_server  $ixiaChassisIp \
		       -port_list   "1/1 1/2" \
		       -username    $userName \
		       -break_locks 1 \
		   ]
if {[keylget connectStatus status] != 1} {
    puts "\nError: Failed to connect: $connectStatus"
    exit
}

puts "\nconnectStatus: $connectStatus"
# connectStatus: {port_handle {{10 {{205 {{4 {{172 {{1/1 1/1/1} {1/2 1/1/2}}}}}}}}}}} {status 1}


# If you do not want layer3, then do not include them.
# Only include -mode, -port_handle and -port_rx_mode
puts "\nConfiguring IxRouter on $port1 ..."
set interfaceStatus [::ixia::interface_config \
			 -mode config \
			 -port_handle $port1 \
			 -port_rx_mode auto_detect_instrumentation \
			 -intf_ip_addr 1.1.1.1 \
			 -gateway 1.1.1.2 \
			 -netmask  255.255.255.0 \
			 -src_mac_addr 00:01:01:01:00:01 \
			 -arp_send_req 1 \
			 -arp_req_retries 3 \
		     ]
if {[keylget interfaceStatus status] != 1} {
    puts "\nError: Configuring port $port1 interface_config"
    exit
}

puts "\ninterfaceStatus1: $interfaceStatus"
# interfaceStatus1: {status 1} {interface_handle intf1}

puts "\nConfiguring IxRouter on $port2 ..."
set interfaceStatus2 [::ixia::interface_config \
			  -mode config \
			  -port_handle $port2 \
			  -port_rx_mode auto_detect_instrumentation \
			  -intf_ip_addr 1.1.1.2 \
			  -gateway 1.1.1.1 \
			  -netmask 255.255.255.0 \
			  -src_mac_addr 00:01:01:02:00:01 \
			  -arp_send_req 1 \
			  -arp_req_retries 3 \
		      ]
if {[keylget interfaceStatus2 status] != 1} {
    puts "\nError: Configuring port $port2 interface_config"
    exit
}

puts "\nintefaceStatus2: $interfaceStatus2"
# {status 1} {interface_handle intf2} {1/1/2 {{router_solicitation_success 1} {arp_request_success 1}}}

# Example on how to send ARP on a port
set interfaceStatus [::ixia::interface_config \
			 -port_handle $port1 \
			 -arp_send_req 1 \
			 -arp_req_retries 3 \
		     ]

puts "\ninterfaceStatus1: $interfaceStatus"
# Here is the keyed list of arp results that you would use for passed/failed criteria...
# {status 1} {interface_handle intf2} {1/1/2 {{router_solicitation_success 1} {arp_request_success 1}}}


 # transmit_mode options: single_burst or continuous
set trafficStatus [::ixia::traffic_config \
		       -mode create \
		       -port_handle $port1 \
		       -enable_auto_detect_instrumentation 1 \
		       -rate_percent 10 \
		       -pkts_per_burst 10000 \
		       -transmit_mode single_burst \
		       -frame_size 100 \
		       -mac_src 00:01:01:01:00:01 \
		       -mac_dst 00:01:01:02:00:02 \
		       -ip_src_addr 1.1.1.1 \
		       -ip_dst_addr 1.1.1.2 \
		       -ethernet_type ethernetII \
		       -l3_protocol ipv4 \
		       -vlan_id 3 \
		       -vlan_user_priority 2 \
		      ]
if {[keylget trafficStatus status] != 1} {
    puts "\nError: Configuring port $port1 traffic stream: $trafficStatus"
    exit
}

set pgid(1) $port1

# transmit_mode options: single_burst or continuous
set trafficStatus2 [::ixia::traffic_config \
			-mode create \
			-port_handle $port2 \
			-enable_auto_detect_instrumentation 1 \
			-rate_percent 40 \
			-pkts_per_burst 20000 \
			-transmit_mode single_burst \
			-frame_size 90 \
			-mac_src 00:01:01:01:00:02 \
			-mac_dst 00:01:01:01:00:01 \
			-ip_src_addr 1.1.1.2 \
			-ip_dst_addr 1.1.1.1 \
			-ethernet_type ethernetII \
			-l3_protocol ipv4 \
			-vlan_id 3 \
			-vlan_user_priority 2 \
		    ]
if {[keylget trafficStatus2 status] != 1} {
    puts "\nError: Configuring port $port2 traffic stream: $trafficStatus2"
    exit
}

set pgid(2) $port1

# This is how to modify something on a port on a specific stream ID.
# Yes, you do need to keep track of ports mapping to Stream ID numbers
# as you are creating traffic_config.
set trafficStatus2 [::ixia::traffic_config \
			-mode modify \
			-port_handle $port2 \
			-frame_size 128 \
			-stream_id 2 \
			]

StartTrafficHlt -txPort $portList

#GetStatsAggregate
#GetStatsStream
GetStatsPgid 2


