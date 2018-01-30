#!/usr/bin/tclsh

package req Ixia
source /home/hgee/MyIxiaWork/HLT/HltLib.tcl

set ixiaChassisIp 10.205.4.172
set userName hgee
set portList "1/1 1/2"
set port1 1/1/1
set port2 1/1/2

# NOTE!  Configuring TrafficConfig -stream_id must begin with
#        streamId 1. Don't restart 1. Keep incrementing for 
#        each TrafficConfig

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
	        puts "StartTrafficHlt Error: No such parameter: $currentArg"
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
    
    # For IxExplorer...
    # sync_run works better on pgid packet group view.
    # If using just "run", it won't work.
    set trafficControlStatus [ixia::traffic_control \
				  -port_handle $portHandleList \
				  -action sync_run \
				 ]

    if {[keylget trafficControlStatus status] != $::SUCCESS} {
	puts "StartTrafficHlt Error: Ixia traffic failed to start on port $portHandleList"
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
	puts "Error: Failed to stop Ixia traffic on ports $port_handle_list\n[KeylPrint trafficControlStatus]"
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

# This Proc is not for multicast verification.
# You could use this as negative testing also by including
# all negative listening ports to the variable listening_ports and
# the variable expected_port will know which rx ports should received traffic.
proc VerifyReceivedPktCount { args } {
    after 3000 ;# allow some time for Rx ports to receive all packets

    set argIndex 0
    while {$argIndex < [llength $args]} {
	set currentArg [lindex $args $argIndex]
	switch -exact -- $currentArg {
	    -txPorts {
		set txPorts [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    -listeningPorts {
		set listeningPorts [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    -expectedPorts {
		set expectedRxPorts [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    -pctLossAllowed {
		set pctLossAllowed [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    default {
		puts "VerifyReceivedPktCount Error: No such parameter: $currentArg"
	    }
	}
    }

    set totalTransmittedPackets 0
    foreach txPort $txPorts {
	set packetsSent [ixia::traffic_stats \
			     -port_handle $txPort \
			     -mode aggregate \
			    ]
	set totalPktsSent [keylget packetsSent $txPort.aggregate.tx.total_pkts]
	set totalTransmittedPackets [mpexpr $totalTransmittedPackets + $totalPktsSent]
    }
    
    set errorList {}

    puts "\nAll Rx ports == $listeningPorts"
    puts "Expected Rx ports == $expectedRxPorts"

    puts "\nPorts      TrasnmittedPkts       ReceivedPkts"
    puts "-----------------------------------------------------"

    set totalReceivedPackets 0
    foreach rxPort $listeningPorts {
	set receivedPackets 0
	set pgidStatistics [ixia::traffic_stats \
				-port_handle $rxPort \
				-packet_group_id $::pgidCounter \
			       ]
	
	#xputs "\n[KeylPrint pgidStatistics]\n"
	
	# Look at all the PGID for each port to see all the true packets received.
	for {set pgidIndex 1} {$pgidIndex <= $::pgidCounter} {incr pgidIndex} {
	    set receivedPackets [mpexpr $receivedPackets + [keylget pgidStatistics $rxPort.pgid.rx.pkt_count.$pgidIndex]]
	    set totalReceivedPackets [mpexpr $totalReceivedPackets + $receivedPackets]
	}

	set transmittedPackets [keylget pgidStatistics $rxPort.aggregate.tx.pkt_count]
	set crcErrorCount [keylget pgidStatistics $rxPort.aggregate.rx.crc_errors_count]
	#set sequenceErrorCount [keylget pgidStatistics $rxPort.aggregate.rx.sequence_errors_count]


	if {$totalTransmittedPackets == 0} {
	    puts "Error: Tx port $txPorts failed to transmit packets"
	    return
	}

	puts "[format %6s $rxPort][format %19s $transmittedPackets][format %19s $receivedPackets]" 
	
	# If the receiving port is expected to receive packets and received 0 packets, then error.
	if {$totalReceivedPackets == 0 && [lsearch $expectedRxPorts $rxPort] != -1} {
	    lappend errorList "$rxPort expected to rx pkts, but rx'd 0 packets."
	}
	
	if {$receivedPackets > 0 && [lsearch $expectedRxPorts $rxPort] != -1 && $receivedPackets == $totalTransmittedPackets} {
	    # If the receiving port is expected to receive packets and it received > 0,
	    # then see if it received all the transmitted packets
	}
		
	if {$receivedPackets > 0 && [lsearch $expectedRxPorts $rxPort] == -1} {
	    # If this port should not expect pkts and it did received pkts, then it's an error
	    lappend errorList "$rxPort should not rx any pkts, but it rx'd $totalReceivedPackets pkts."
	}
	
	if {$receivedPackets == 0 && [lsearch $expectedRxPorts $rxPort] == -1} {
	    # If this port did not rx any packets and it wasn't expected to rx any pkts, then good!
	    #puts "Port $rxPort rx'd 0 pkt as expected.  Good!"
	}
    }
    
    if {$errorList != ""} {
	foreach errorItem $errorList {
	   puts "\nError: $errorItem"
	}
    }

    if {$totalReceivedPackets < $totalTransmittedPackets} {
	puts "\nError: Total transmitted pkts: $totalTransmittedPackets; Total received pkts: $totalReceivedPackets"
    }
    
    if {$totalReceivedPackets == $totalTransmittedPackets} {
	puts "\nTotal Tx packets: $totalTransmittedPackets"
	puts "Total Rx packets: $totalReceivedPackets"
    }
    puts \n
}

proc GetStats {} {
    puts "\n[format %6s Port][format %10s Tx][format %12s Rx]"
    puts "-----------------------------------"

    foreach port $::portList {
	set pgidStatistics [ixia::traffic_stats \
				    -port_handle $port \
				    -packet_group_id $::pgidCounter \
				   ]

	set totalTx [keylget pgidStatistics $port.aggregate.tx.pkt_count]
	set totalRx [keylget pgidStatistics $port.aggregate.rx.pkt_count]
	puts "[format %6s $port][format %13s $totalTx][format %12s $totalRx]"
    }
    puts \n
}

proc DisconnectIxia { } {
    puts "\nError: DisconnectIxia: Disconnecting from Ixia Chassis"
    ixia::cleanup_session
}

# Uncomment these lines for debugging
EnableHltDebug

set connectStatus [::ixia::connect \
		       -reset \
		       -device $ixiaChassisIp \
		       -tcl_server $ixiaChassisIp \
		       -username $userName \
		       -port_list $portList \
		      ]
if {[keylget connectStatus status] != $::SUCCESS} {
    puts "Error: [KeylPrint connectStatus]"
    exit
}


set interfaceStatus1 [::ixia::interface_config \
			  -mode config \
			  -port_handle $port1 \
			  -port_rx_mode auto_detect_instrumentation \
			 ]

if {[keylget interfaceStatus1 status] != $::SUCCESS} {
    puts "Error: Failed to config interface on $port1 \n[KeylPrint interfaceStatus1]"
    exit
}

set interfaceStatus2 [::ixia::interface_config \
			  -mode config \
			  -port_handle $port2 \
			  -port_rx_mode auto_detect_instrumentation \
			 ]

if {[keylget interfaceStatus2 status] != $::SUCCESS} {
    puts "Error: Failed to config interface on $port2 \n[KeylPrint interfaceStatus2]"
    exit
}

# transmit_mode options: single_burst or continuous
set trafficStatus1 [::ixia::traffic_config \
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
		       ]
if {[keylget trafficStatus1 status] != $::SUCCESS} {
    puts "Error: Failed to config traffic on $port1 \n[KeylPrint trafficStatus1]"
    exit
}
 
# To include Vlan with your traffic, add the following parameters:
#    -ethernet_type ethernetII
#    -vlan_id 3
#    -vlan_user_priority 2 

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
		       -mac_src [ixHlt::GetMacAddrForPort $port2] \
		       -mac_dst 00:01:01:01:00:01 \
		       -ip_src_addr 1.1.1.1 \
		       -ip_dst_addr 2.2.2.2 \
		      ]
if {[keylget trafficStatus2 status] != $::SUCCESS} {
    puts "Error: Failed to config traffic on $port2 \n[KeylPrint trafficStatus2]"
    exit
}

StartTrafficHlt -txPort "$port1 $port2"

# Uncomment this if running continuous traffic
#GetRate $port2
#StopTraffic $port1

# Uncomment this for single burst traffic
#::ixHlt::VerifyReceivedPktCount -txPorts $port1 -listeningPorts $port2 -expectedPorts $port2

VerifyReceivedPktCount -txPorts "$port1 $port2" -listeningPorts "$port1 $port2" -expectedPorts "$port1 $port2"

puts \n
# Look at GetStats example to just get aggregated stats
GetStats

DisconnectIxia

