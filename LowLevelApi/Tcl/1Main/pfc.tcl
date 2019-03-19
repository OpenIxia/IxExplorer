# Description:
#    Test sending PFC frames to the transmitting port to slow down the rate.
#
# This script allows scaling txPorts and rxPorts and you could create multiple streams for each port.
#     txPorts: These are ports sending continuous traffic.
#     rxPorts: These are ports sending PFC frames to the txPorts to throttle the sending rates.
#
#     User defined:
#        - Each stream must have a unique and incremental PGID number.
#          This is how you track from which PFC priority group
#
#        - Each txPort stream must have a PFC priority group number.
#              This is how the transmitting stream rate gets throttled.  
#              When the rxPort sends PFC frames, the quantas set in the PFC queue indicates which
#              pfc priority group to throttle.
#
#        - For the sendPfc port, the last element in the stream is the pause quantas.
#
# Sample stats:
#
#   Port     PortName             Transmitted     Received       RxFrom    crc  pfcGroup/Quantas
#   --------------------------------------------------------------------------------------------
#   1 1 2    txPort_stream_1      525077340       14265332       1/1/1     0    1 
#   1 1 2    txPort_stream_2      525077340       14265327       1/1/1     0    5 
#   1 1 1    pfcPort_stream_1     892036999223    528733         1/1/2     0    {0 0} {1 60} {0 0} {0 0} {0 0} {1 60} {0 0} {0 0}
#
# Tested with Novus-NP10/1GE8DP


package req IxTclHal
set tclServer 10.36.237.28
set username hgee

ixConnectToTclServer $tclServer
ixConnectToChassis $tclServer
set chassisId [chassis cget -id]

# txPort will send continuous packets. Each stream is an item in a list.
set port($chassisId/1/1,txPort) [list [list name=cos_0 pgid=0 srcMac=00:11:11:11:11:11 dstMac=00:33:33:33:33:33 srcIp=1.1.1.1 \
					   dstIp=1.1.1.10 pctLineRate=10 priorityGroup=0] \
				     [list name=cos_1 pgid=1 srcMac=00:22:22:22:22:22 dstMac=00:33:33:33:33:33 srcIp=1.1.1.2 \
					  dstIp=1.1.1.10 pctLineRate=10 priorityGroup=1] \
				     [list name=cos_2 pgid=2 srcMac=00:33:33:33:33:33 dstMac=00:33:33:33:33:33 srcIp=1.1.1.3 \
					  dstIp=1.1.1.10 pctLineRate=10 priorityGroup=2] \
				     [list name=cos_3 pgid=3 srcMac=00:44:44:44:44:44 dstMac=00:33:33:33:33:33 srcIp=1.1.1.4 \
					  dstIp=1.1.1.10 pctLineRate=10 priorityGroup=3] \
				     [list name=cos_4 pgid=4 srcMac=00:55:55:55:55:55 dstMac=00:33:33:33:33:33 srcIp=1.1.1.5 \
					  dstIp=1.1.1.10 pctLineRate=10 priorityGroup=4] \
				     [list name=cos_5 pgid=5 srcMac=00:66:66:66:66:66 dstMac=00:33:33:33:33:33 srcIp=1.1.1.6 \
					  dstIp=1.1.1.10 pctLineRate=10 priorityGroup=5] \
				     [list name=cos_6 pgid=6 srcMac=00:77:77:77:77:77 dstMac=00:33:33:33:33:33 srcIp=1.1.1.7 \
					  dstIp=1.1.1.10 pctLineRate=10 priorityGroup=6] \
				     [list name=cos_7 pgid=7 srcMac=00:88:88:88:88:88 dstMac=00:33:33:33:33:33 srcIp=1.1.1.8 \
					  dstIp=1.1.1.10 pctLineRate=10 priorityGroup=7] \
				    ]

# These sendPfc ports will send pause frames to the txPort
set port($chassisId/1/2,sendPfc) [list [list name=pfcPort_stream_1 pgid=8  srcMac=00:99:99:99:99:99 dstMac=01:80:C2:00:00:01 \
					    srcIp=1.1.1.10  dstIp=1.1.1.1 pctLineRate=1 \
					    [list {1 30} {1 40} {1 50} {1 60} {1 70} {1 80} {1 90} {1 65535}] \
					   ]]

# Define the port list
foreach currentPort [array name port] {
    #currentPort: rxPort,1/1/2
    #port: rxPort,1/1/2 {{3 1.1.1.3 1.1.1.1 50}}
    set currentPort [lindex [split $currentPort ,] 0]
    scan $currentPort "%d/%d/%d" chassis card portNumber
    lappend portList [list $chassis $card $portNumber]
}

ixLogin $username
ixTakeOwnership $portList

proc getBinary {byteList} {
    # If byteList = {{1 5} {0 0} {0 0} {1 32}     {0 0} {0 0} {0 0}   {1 60}}
    # p0, p3, p7 are set
    # This gives you 1001 = 9 (p0, p3)
    #                1000 = 8 (p7)
    # The vector is = 89

    set binary ""
    foreach byte [lreverse $byteList] {
	if {[lindex $byte 1] != 0} {
	    append binary 1
	} else {
	    append binary 0
	}
    }
    #return [expr "0b$binary"]
    # [expr "0b$binary] converts binary to decimal
    # [format %1.1x $decimal] converts to single digit hex (Ex: 15 -> f)
    return [format %1.1x [expr "0b$binary"]]
}

proc getParamValue {stream param} {
    set streamList ""
    foreach item $stream {
	append streamList "$item "
    }
    set index [lsearch -regexp $streamList $param]
    if {$index != -1} {
	set value [lindex [split [lindex $streamList $index] =] end]
    } else {
	return None
    }
    return $value
}

proc portConfig {portList} {
    foreach port $portList {
	scan $port "%d %d %d" chassisId cardId portId
	
	puts "portConfig: $port"
	port config -directedAddress                    "01 80 C2 00 00 01"
	port config -multicastPauseAddress              "01 80 C2 00 00 01"
	port config -transmitMode                       portTxModeAdvancedScheduler
	port config -receiveMode                        [expr $::portCapture|$::portRxDataIntegrity|$::portRxModeWidePacketGroup]
	port config -enableDataCenterMode               true
	port config -flowControl                        true
	port config -dataCenterMode                     eightPriorityTrafficMapping
	port config -flowControlType                    ieee8021Qbb
	port config -pfcEnableValueListBitMatrix        "{1 1} {1 2} {1 4} {1 8} {1 16} {1 32} {1 64} {1 128}"
	port config -pfcResponseDelayEnabled            0
	port config -pfcResponseDelayQuanta             1
	port config -operationModeList                  [list]
	port config -MacAddress                         "00 de bb 00 00 01"
	port config -DestMacAddress                     "00 de bb 00 00 02"
	port config -name                               ""
	port config -portCpuFlowControlDestAddr         "01 80 C2 00 00 01"
	port config -portCpuFlowControlSrcAddr          "00 00 01 00 02 00"
	port config -portCpuFlowControlPriority         "1 1 1 1 1 1 1 1"
	port config -portCpuFlowControlType             0

	port config -autonegotiate                      true
	#port config -advertise100FullDuplex             true
	#port config -advertise100HalfDuplex             false
	#port config -advertise10FullDuplex              true
	#port config -advertise10HalfDuplex              false
	#port config -advertise1000FullDuplex            true
	#port config -advertise5FullDuplex               false
	#port config -advertise2P5FullDuplex             false

	if {[port set $chassisId $cardId $portId]} {
	    puts "\nportConfig: Error calling port set $chassisId $cardId $portId"
	}
    }
}

proc configTxStream {portArray} {
    upvar $portArray ports

    foreach currentPort [array name ports] {
	set typeOfPort [lindex [split $currentPort ,] 1]
	set currentPort [lindex [split $currentPort ,] 0]
	scan $currentPort "%d/%d/%d" chassis card portNumber

	foreach {portAndType streams} [array get ports $currentPort,*] {
	    set streamId 1

	    foreach stream $streams {
		puts "\nconfigTxStream: $currentPort stream: $stream"
		
		if {[port resetStreamProtocolStack $chassis $card $portNumber]} {
		    puts "configStream: Error calling port resetStreamProtocolStack $chassis $card $portNumber"
		}
		
		stream setDefault 
		stream config -name                               [getParamValue $stream name]
		stream config -sa                                 [getParamValue $stream srcMac]
		stream config -da                                 [getParamValue $stream dstMac]
		stream config -enable                             true
		stream config -numBursts                          1
		stream config -numFrames                          100
		stream config -percentPacketRate                  [getParamValue $stream pctLineRate].0
		stream config -rateMode                           streamRateModePercentRate
		stream config -framesize                          64
		stream config -frameSizeType                      sizeFixed
		stream config -enableTimestamp                    true
		stream config -fcs                                good
		stream config -dma                                contPacket
		if {$typeOfPort == "txPort"} {
		    stream config -priorityGroup                  [getParamValue $stream priorityGroup]                   
		}

		protocol setDefault 		
		if {$typeOfPort == "txPort"} {
		    protocol config -name                         ipV4
		}
		if {$typeOfPort == "sendPfc"} {
		    protocol config -name                         pauseControl
		}
		protocol config -appName                          noType
		protocol config -ethernetType                     ethernetII
		protocol config -enable802dot1qTag                vlanNone

		if {$typeOfPort == "sendPfc"} {
		    set pauseFrameList {}

		    foreach x [lindex $stream end] {
			if {[lindex $x 0] != 0} {
			    append pauseFrameList " 00 [format %02x [lindex $x 1]]"
			} else {
			    append pauseFrameList " 00 00"
			}
		    }

		    puts "pauseFrame: $pauseFrameList"
		    puts "pauseFrame Quanta: [lindex $stream end]"

		    # Get the vector
		    set leftByte [lrange [lindex $stream end] 0 3]
		    set rightByte [lrange [lindex $stream end] 4 end]
		    puts "leftByte: $leftByte  ;  rightByte: $rightByte"

		    set vector "[getBinary $rightByte][getBinary $leftByte]"
		    puts "vector: $vector"

		    pauseControl setDefault 
		    pauseControl config -da                                 "01 80 C2 00 00 01"
		    pauseControl config -pauseTime                          255
		    pauseControl config -pauseControlType                   ieee8021Qbb

		    pauseControl config -priorityEnableVector               0x$vector
		    pauseControl config -usePfcEnableValueList              0
		    #pauseControl config -pauseFrame                         "00 00 00 20 00 00 00 00 00 00 00 3C 00 00 00 00"
		    #pauseControl config -pfcEnableValueList                 "{0 0} {1 32} {0 0} {0 0} {0 0} {1 60} {0 0} {0 0}"
		    pauseControl config -pauseFrame                         "$pauseFrameList"
		    pauseControl config -pfcEnableValueList                 "[lindex $stream end]"

		    if {[pauseControl set $chassis $card $portNumber]} {
			puts "configPfcQueues: Error calling pauseControl set $chassis $card $portNumber"
		    }
		}

		ip setDefault 
		ip config -ipProtocol                         ipV4ProtocolReserved255
		ip config -sourceIpAddr                       [getParamValue $stream srcIp]
		ip config -sourceIpMask                       "255.255.255.0"
		ip config -destIpAddr                         [getParamValue $stream dstIp]
		ip config -destIpMask                         "255.255.255.0"
		if {[ip set $chassis $card $portNumber]} {
		    puts "\nconfigStream: Error calling ip set $chassis $card $portNumber"
		}

		if {[stream set $chassis $card $portNumber $streamId]} {
		    puts "\nconfigTxStream: Error: calling stream set $chassis $card $portNumber $streamId"
		}

		packetGroup setDefault 
		packetGroup config -signatureOffset                    48
		packetGroup config -signature                          "08 71 18 05"
		packetGroup config -insertSignature                    true
		packetGroup config -ignoreSignature                    false
		packetGroup config -enableInsertPgid                   true
		packetGroup config -groupId                            [getParamValue $stream pgid]
		packetGroup config -groupIdOffset                      52
		packetGroup config -enableGroupIdMask                  false
		packetGroup config -groupIdMode                        packetGroupCustom
		packetGroup config -groupIdMask                        4293918720
		packetGroup config -latencyControl                     cutThrough
		packetGroup config -measurementMode                    packetGroupModeLatency
		if {[packetGroup setTx $chassis $card $portNumber $streamId]} {
		    puts "\nconfigTxStream: Error: calling packetGroup setRx $chassis $card $portNumber $streamId"
		}
		
		autoDetectInstrumentation setDefault 
		autoDetectInstrumentation config -enableTxAutomaticInstrumentation   true
		autoDetectInstrumentation config -signature                          {87 73 67 49 42 87 11 80 08 71 18 05}
		if {[autoDetectInstrumentation setTx $chassis $card $portNumber $streamId]} {
		    puts "\nconfigStream: Error: calling autoDetectInstrumentation setTx $chassis $card $portNumber $streamId"
		}

		incr streamId
	    }
	}
    }
}

proc getStats {portList portArray} {
    upvar $portArray ports

    # Create a relational DB to get the port from the PGID number.
    set totalPgid 0
    foreach {portAndType streams} [array get ports *,*] {
	set currentPort [lindex [split $portAndType ,] 0]
	foreach stream $streams {
	    incr totalPgid
	    if {[getParamValue $stream priorityGroup] != "None"} {
		set portPgid([getParamValue $stream pgid]) "$currentPort [getParamValue $stream name] [getParamValue $stream priorityGroup]"
	    } else {
		set portPgid([getParamValue $stream pgid]) "$currentPort [getParamValue $stream name] [list [lindex $stream end]]"
	    }
	}
    }
    puts [parray portPgid]

    set isThereAnyError {}
    
    #puts "\n[format "%-8s %-20s %-15s %-14s %-9s %-6s %-10s" Port PortName Transmitted Received RxFrom crc pfcGroup/Quantas]"
    puts "\n[format "%-8s %-20s %-8s %-20s %-20s %-10s" Port Transmitted RxFrom RxFromPortName Received pfcGroup/Quantas]"
    puts "-----------------------------------------------------------------------------------------------------"

    foreach port $portList {
	scan $port "%d %d %d" chassis card portNumber

	stat get statAllStats $chassis $card $portNumber
	stat cget -transmitState
	set framesSent [stat cget -framesSent]
	set crcError [stat cget -fcsErrors]
	set portRxZeroPkt 0

	for {set pgid 0} {$pgid <= $totalPgid} {incr pgid} {
	    packetGroupStats get $chassis $card $portNumber $pgid $pgid	    
	    packetGroupStats getGroup $pgid
	    set framesReceived [packetGroupStats cget -totalFrames]
	    
	    if {$framesReceived > 0} {
		puts "[format "%-8s %-20s %-8s %-20s %-20s %-10s" $port $framesSent [lindex $portPgid($pgid) 0] [lindex $portPgid($pgid) 1] $framesReceived [lindex $portPgid($pgid) 2]]"
		set portRxZeroPkt 1
	    }
	}
	
	if {$portRxZeroPkt == 0} {
	    # Even though the port received 0 pkets, we still want to display
	    # its total transmitted packets
	    puts "[format "%-10s %-15s %-14s %-9s %-6s" $port $framesSent 0 {} $crcError]"
	}

	if {$crcError > 0} {
	    lappend isThereAnyErrors "ERROR: $port received $crcError crcErrors"
	}
    }

    if {$isThereAnyError != ""} {
	puts \n
	foreach errorMsg $isThereAnyError {
	    puts $errorMsg
	}
    }
    puts \n
}

portConfig $portList
configTxStream port
ixWritePortsToHardware portList

ixClearPacketGroups portList
if {[ixStartPacketGroups portList]} {
    puts "Failed to start packet group capture"
}

ixStartTransmit portList
after 3000

if {[ixStopPacketGroups portList]} {
    puts "Failed to stop packet group capture"
}

getStats $portList port

# Cleanup the ports after test end
#ixStopTransmit portList
#ixStopPacketGroups portList

#ixClearOwnership $portList


