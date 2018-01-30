#!/usr/bin/tclsh

package req Ixia

set ixiaChassisIp 10.205.4.172
set userName hgee
set portList "1/1/1 1/1/2"
set port1 1/1/1
set port2 1/1/2

proc StartTrafficHlt { args } {
    global allTxPorts

    set trafficDuration 0
    set checkTransmitDone 1

    set argIndex 0
    while {$argIndex < [llength $args]} {
	set currentArg [lindex $args $argIndex]
	switch -exact -- $currentArg {
	    -txPort {
		set txPorts [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    -allPorts {
		set allPortsInvolved [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    -trafficDuration {
		set trafficDuration [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    -checkTransmitDone {
		set checkTransmitDone [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    default {
		puts "StartTrafficHlt: No such parameter: $currentArg"
	    }
	}
    }

    # Setting variable allTxPorts for GetPgidStatsHlt to use.
    set allTxPorts $txPorts

    set portHandleList {}
    foreach pHandle $txPorts {
	lappend portHandleList $pHandle
    }

    set startTrafficFlag 0
    
    puts "Starting IxExplorer traffic ..."
    set trafficControlStatus [ixia::traffic_control \
				  -port_handle $portHandleList \
				  -action sync_run \
				 ]

    if {[keylget trafficControlStatus status] != $::SUCCESS} {
	puts "StartTrafficHlt: Ixia traffic failed to start on port $portHandleList"
	puts [KeylPrint trafficControlStatus]
	set startTrafficFlag 1
    } else {
	puts "StartTrafficHlt: Traffic started on port $portHandleList"
    }

    if {$startTrafficFlag == 0 } {
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
	    if {$checkTransmitDone == 1} {
		CheckPortTransmitDoneIxia $txPorts
		#puts "All ports $txPorts all done and stopped transmitting."
		after 2000
	    }
	} else {
	    after 2000
	}
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
proc GetStats {} {
    puts "\n[format %6s Port][format %10s Tx][format %12s Rx]"
    puts "-----------------------------------"
    
    # Example for: aggregated stats
    # -mode: options: aggregage | streams
    if 0 {
	foreach port $::portList  {
	    set pgidStatistics [ixia::traffic_stats \
				    -port_handle $port \
				    -mode aggregate \
				   ]
	}
	
	puts "\n[KeylPrint pgidStatistics]\n"
	set totalTx [keylget pgidStatistics $port.aggregate.tx.pkt_count]
	set totalRx [keylget pgidStatistics $port.aggregate.rx.pkt_count]
	puts "[format %6s $port][format %13s $totalTx][format %12s $totalRx]"
    }
    
    # Example for: stream
    
    # -mode: options: aggregate | streams
    set pgidStatistics [ixia::traffic_stats \
			    -port_handle $::portList \
			    -mode streams \
			   ]
    puts "\n[KeylPrint pgidStatistics]\n"
    
    foreach port $::portList  {	
	set totalTx [keylget pgidStatistics $port.stream.1.tx.total_pkts]
	set totalRx [keylget pgidStatistics $port.stream.1.rx.total_pkts]
	puts "[format %6s $port][format %13s $totalTx][format %12s $totalRx]"
    }
    
    # Example for PGID stats
    if 0 {
	foreach port $::portList {
	    set pgidStatistics [ixia::traffic_stats \
				    -port_handle $port \
				    -packet_group_id 2 \
				   ]
	    puts "\n[KeylPrint pgidStatistics]\n"
	    set totalTx [keylget pgidStatistics $port.aggregate.tx.pkt_count]
	    set totalRx [keylget pgidStatistics $port.aggregate.rx.pkt_count]
	    puts "[format %6s $port][format %13s $totalTx][format %12s $totalRx]"
	}
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

# NOTE!  Configuring TrafficConfig -stream_id must begin with
#        streamId 1

# Uncomment these lines for debugging
#set ::ixia::logHltapiCommandsFlag 1
#set ::ixia::logHltapiCommandsFileName ixiaHltCommandsLog.txt

set connectStatus [::ixia::connect \
		       -reset \
		       -device     $ixiaChassisIp \
		       -tcl_server $ixiaChassisIp \
		       -port_list  "1/1 1/2" \
		       -username   $userName
		   ]

puts "\nconnectStatus: $connectStatus"

# connectStatus: {port_handle {{10 {{205 {{4 {{172 {{1/1 1/1/1} {1/2 1/1/2}}}}}}}}}}} {status 1}

set interfaceStatus [::ixia::interface_config \
			 -mode config \
			 -port_handle $port1 \
			 -port_rx_mode auto_detect_instrumentation \
		     ]
puts "\ninterfaceStatus1: $interfaceStatus"
# interfaceStatus1: {status 1} {interface_handle intf1}

set interfaceStatus2 [::ixia::interface_config \
			  -mode config \
			  -port_handle $port2 \
			  -port_rx_mode auto_detect_instrumentation \
		      ]
puts "\nintefaceStatus2: $interfaceStatus2"
# intefaceStatus2: {status 1} {interface_handle intf2}


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
		       -mac_src 00:01:01:01:00:01 \
		       -mac_dst 00:01:01:02:00:02 \
		       -l3_protocol  ipv6\
		       -ipv6_src_addr  ff37::2\
		       -ipv6_src_mode  fixed\
		       -ipv6_dst_addr  ff37::1 \
		       -ipv6_dst_mode  fixed \
		       -ipv6_dst_count 10 \
		       -ipv6_dst_step 0::1 \
		       -l3_length    1300 \
		       -length_mode  fixed\
		   ]
puts "\ntrafficStatus1: $trafficStatus"
# trafficStatus1: {status 1} {stream_id 1}


# transmit_mode options: single_burst or continuous
set trafficStatus2 [::ixia::traffic_config \
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
			-l3_protocol  ipv6\
			-ipv6_src_addr  ff37::1\
			-ipv6_src_mode  fixed\
			-ipv6_dst_addr  ff37::2 \
			-ipv6_dst_mode fixed \
			-l3_length    1300 \
			-length_mode  fixed\
		    ]
puts "\ntrafficStatus2: $trafficStatus2"
# trafficStatus2: {status 1} {stream_id 2}


#ClearPgidStatsHltIxia $portList
StartTrafficHlt -txPort $portList

# Uncomment this if running continuous traffic
#GetRate $port2
#StopTraffic $port1

# Uncomment this for single burst traffic
#VerifyReceivedPktCount -txPorts $port1 -listeningPorts $port2 -expectedPorts $port2
#VerifyReceivedPktCount -txPorts $portList -listeningPorts $portList -expectedPorts $portList
GetStats

#::ixia::DisconnectIxia

