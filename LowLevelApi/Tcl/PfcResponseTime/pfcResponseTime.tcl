
# This script demonstrates how to calculate PFC pause response time with the current HW/SW/API abiity. This is done for Novus 100G.
# 04/26/2017
# Written by Hasmik Shakaryan and pseudo code by Dwayne Hunnicutt
# Solution: Tested on IxOS 8.20 EA
# Use a “tracer packet”
# For this solution we send a packet (or packets) before the pause traffic and have it routed to another Ixia port so we can get the Tx time of the packet before the pause frames and thus know the Tx time of the pause frame.
# This solution can be done today, we have all the features and hooks.  The main issue with this feature is if the DUT drops the stream traffic packet sent before the pause frames this will introduce a measurement error. We could mitigate this by having the DUT prioritize this traffic or send on the control PFC queue.

# NOTE
# Make sure the NOVUS card resource mode is in capture for both of the below ports.

# Pseudo-code:
# 1)	Load pfc_pause_frames.prt on Port A
# 2)	Load pfc_stream_traffic.prt on Port B
# 3)    Clear time stamps on Port A and Port B
# 4)	Start PG stats on Port A
# 5)	Start Capture on Port B
# 6)	Start traffic on Port A & Port B
# 7)	View Capture on Port B and identify and analyze the last packet of the pre-pause frames from Port A
# 8)	Extract the sequence # and timestamp from the captured pre-pause packet
# 9)	Calculate the timestamp of the first pause packet:
# 	a.	Pause Frame Timestamp = extracted timestamp + 6.72*(pre-pause count – sequence # + 1)
# 10)	Get last timestamp from Port A (pfcPauseFramePort) PG stats
# 11)	Calculate PFC response time:
# 	a.	Response Time = (PG Stats timestamp – Pause Frame Timestamp)
# 12)   Calculate the number of packets received after the PFC pause frame is sent.  It will require enhancements to the scripts.  Here are the basic ideas:
#	a.	Enable capture on PortA.  Set a trigger event that will never occur (like matching a DA to F0F0_F0F0_F0F0) , and configure the capture engine to
#		capture all packets before the trigger event.
#	b.	Start capture on PortA (the port that will send the pause frame).
#	c.	Add 5.12 ns (the duration of a 64B packet) to the pause packet timestamp calculated above to account for when the packet was fully received by the DUT.
#	f.	Iterate through the captured packets on PortA in reverse order (last to first), and extract the Tx timestamp embedded in each packet.
#		Identify the packet whose Tx timestamp is just under the timestamp of the pause packet.  This identifies the last packet to have been received before the pause packet was sent.
#	g.	Subtract this packet number from the total packets received.  This yields the number of packets received after the pause packet was sent.

# NOTE:
# We do not recommend calculating all priorities at the same time.  For each additional priority added to the test, will decrease the accuracy of the calculated reaction time.
# Estimated time running this test using port to port connection time {source pfcResponseTime.tcl} 17428037 microseconds per iteration, or 20956247 microseconds per iteration
# We expect the PFC Response time and Rx number of packets may vary for each test run

#Steps to run the script: pfcResponseTime.tcl

#1.	Modify script to point to your chassis, hostname
#2.	Modify the script to point to the location of the port files in the attached zip file. Note that this are Novus ports. If you choose to run on a different port, you need to create new port files with the same configuration
#   You can use usePortFile flag to either load the .prt file or configure the ports using the script.
#3.	Source pfcResponseTime.tcl from the IxOS wish console.

package req IxTclHal
set hostName loopback
#set hostName 10.200.104.50
#set hostName 10.200.120.20
#set hostName 10.200.120.117
set retCode $::TCL_OK


ixConnectToChassis $hostName
set chassId [chassis cget -id]

set cardId 1
set pfcPauseFramePort		7
set pfcStreamTrafficPort 	8

set portList [list [list $chassId $cardId $pfcPauseFramePort ] [list $chassId $cardId $pfcStreamTrafficPort]]
set pfcPauseFrameList [list [list $chassId $cardId $pfcPauseFramePort ] ]
set pfcStreamTrafficPortList [list [list $chassId $cardId $pfcStreamTrafficPort]]

ixLogin Dwayne
ixTakeOwnership $portList

# Unexposed feature enum
set portFeatureResourceGroupEx 479

set usePortFile 0

if {$usePortFile } {
	#set prtFilePath "C:/Program Files (x86)/Ixia/Tcl/8.5.17.0/bin/MySamples"
	set prtFilePath "C:/Program Files (x86)/Ixia/IxOS/8.21-EA/TclScripts/bin/MySamples"

	set pfcPauseFramePortFile $prtFilePath/100G_PFC_pause.prt
	set pfcStreamTrafficPortFile $prtFilePath/100G_PFC_trafficStream.prt
}

if {[port isCapableFeature $chassId $cardId $pfcPauseFramePort $::portFeaturePFC] && [port isCapableFeature $chassId $cardId $pfcStreamTrafficPort $::portFeaturePFC]} {
	set resourcePortListArray($chassId,$cardId,$pfcPauseFramePort) [list [list $chassId $cardId 2] [list $chassId $cardId 9] [list $chassId $cardId 10] [list $chassId $cardId 11] [list $chassId $cardId 12]]
	set resourcePortListArray($chassId,$cardId,$pfcStreamTrafficPort) [list [list $chassId $cardId 2] [list $chassId $cardId 13] [list $chassId $cardId 14] [list $chassId $cardId 15] [list $chassId $cardId 16]]
}

foreach port $portList {
	scan $port "%d %d %d" chassId cardId portId

	if {[port isCapableFeature $chassId $cardId $portId $::portFeaturePFC] } {

		if {[card isValidFeature $chassId $cardId $portFeatureResourceGroupEx] } {

			# Because port file doesn't enable the capture at the port level, we need to do at the resource group
			resourceGroupEx get $chassId $cardId $portId
			set resourceGroupPortList [list [list $chassId $cardId $portId]]
			resourceGroupEx config -activeCapturePortList              $resourceGroupPortList
			resourceGroupEx config -activePortList                     $resourceGroupPortList
			resourceGroupEx config -resourcePortList                   $resourcePortListArray($chassId,$cardId,$pfcStreamTrafficPort)
			#resourceGroupEx config -ppm                                ""
			resourceGroupEx config -mode                               100000
			if {[resourceGroupEx  set $chassId $cardId $portId]} {
				ixPuts "IXIA - Error calling resourceGroupEx  set on $chassId $cardId $portId"
				set retCode $::TCL_ERROR
			}
			if {[resourceGroupEx write $chassId $cardId $portId]} {
				ixPuts "IXIA - Error calling resourceGroupEx  write on $chassId $cardId $portId"
				set retCode $::TCL_ERROR
			}
		}

	} else {
		ixPuts "IXIA - Error portFeaturePFC is not supported on $chassId $cardId $portId"
		set retCode $::TCL_ERROR
	}
}

if {$retCode == $::TCL_ERROR} {
	ixPuts "IXIA - ERROR Will not be able to calculate the PFS Response Time. Exiting."
	return $retCode
}

if {$usePortFile } {
	# 1)Load pfc_pause_frames.prt on Port A
	if {[port import $pfcPauseFramePortFile $chassId $cardId $pfcPauseFramePort]} {
		ixPuts "IXIA - Error import $pfcPauseFramePortFile $chassId $cardId $pfcPauseFramePort"
		set retCode $::TCL_ERROR
	}

	# 2)	Load pfc_stream_traffic.prt on Port B
	if {[port import $pfcStreamTrafficPortFile $chassId $cardId $pfcStreamTrafficPort]} {
		ixPuts "IXIA - Error import $pfcStreamTrafficPortFile $chassId $cardId $pfcStreamTrafficPort"
		set retCode $::TCL_ERROR
	}
} else {

	ixPuts "IXIA - Pause Frame Port and Pre-Pause/Pause streams on $chassId $cardId $pfcStreamTrafficPort"
	foreach port $pfcPauseFrameList {
		scan $port "%d %d %d" chassId cardId portId

		ixPuts "IXIA - Pause Frame Port and Pre-Pause/Pause streams on $chassId $cardId $portId"

		port setFactoryDefaults $chassId $cardId $portId
		port config -transmitMode                       portTxModeAdvancedScheduler
		port config -receiveMode                        [expr $::portCapture|$::portRxDataIntegrity|$::portRxSequenceChecking|$::portRxModeWidePacketGroup]
		port config -flowControl                        true
		port config -enableDataCenterMode               true
		port config -dataCenterMode                     eightPriorityTrafficMapping
		port config -flowControlType                    ieee8021Qbb
		port config -pfcEnableValueListBitMatrix        "{1 1} {1 2} {1 4} {1 8} {1 16} {1 32} {1 64} {1 128}"
		port config -pfcResponseDelayEnabled            0
		port config -pfcResponseDelayQuanta             1
		port config -autoDetectInstrumentationMode      portAutoInstrumentationModeFloating
		port config -operationModeList                  [list $::portOperationModeStream]
		port config -ieeeL1Defaults                     0

		if {[port set $chassId $cardId $portId]} {
			ixPuts "IXIA - Error calling port set $chassId $cardId $portId"
			set retCode $::TCL_ERROR
		}

		autoDetectInstrumentation setDefault
		autoDetectInstrumentation config -startOfScan                        0
		autoDetectInstrumentation config -signature                          {87 73 67 49 42 87 11 80 08 71 18 05}
		autoDetectInstrumentation config -enableSignatureMask                false
		autoDetectInstrumentation config -signatureMask                      {00 00 00 00 00 00 00 00 00 00 00 00}
		if {[autoDetectInstrumentation setRx $chassId $cardId $portId]} {
			ixPuts "IXIA - Error calling autoDetectInstrumentation setRx $chassId $cardId $portId"
			set retCode $::TCL_ERROR
		}


		filter setDefault
		filter config -captureTriggerDA                   addr1
		filter config -captureFilterDA                    anyAddr
		if {[filter set $chassId $cardId $portId]} {
			ixPuts "IXIA - Error calling filter set $chassId $cardId $portId"
			set retCode $::TCL_ERROR
		}


		filterPallette setDefault
		filterPallette config -DA1                                "F0 F0 F0 F0 F0 F0"
		filterPallette config -DAMask1                            "00 00 00 00 00 00"
		if {[filterPallette set $chassId $cardId $portId]} {
			ixPuts "IXIA - Error calling filterPallette set $chassId $cardId $portId"
			set retCode $::TCL_ERROR
		}

		capture setDefault
		capture config -fullAction                         lock
		capture config -sliceSize                          65536
		capture config -sliceOffset                        0
		capture config -captureMode                        captureTriggerMode
		capture config -continuousFilter                   0
		capture config -beforeTriggerFilter                captureBeforeTriggerAll
		capture config -afterTriggerFilter                 captureAfterTriggerFilter
		if {[capture set $chassId $cardId $portId]} {
			ixPuts "IXIA - Error calling capture set $chassId $cardId $portId"
			set retCode $::TCL_ERROR
		}


		# Build the Pre-Pause stream now.
		#  Stream 1
		set streamId 1
		stream setDefault
		stream config -name                               "Pre-Pause"
		stream config -enable                             true
		stream config -numFrames                          100
		stream config -percentPacketRate                  100.0
		stream config -rateMode                           streamRateModePercentRate
		stream config -sa                                 "00 00 00 00 01 3C"
		stream config -da                                 "00 00 00 00 01 38"
		stream config -framesize                          64
		stream config -frameSizeType                      sizeFixed
		stream config -dma                                stopStream
		stream config -loopCount                          1
		stream config -returnToId                         1
		stream config -priorityGroup                      priorityGroup0

		protocol setDefault
		protocol config -name                               mac
		protocol config -appName                            noType
		protocol config -ethernetType                       ethernetII

		udf setDefault
		udf config -enable                             true
		udf config -continuousCount                    true
		udf config -offset                             40
		udf config -counterMode                        udfCounterMode
		udf config -bitOffset                          0
		udf config -udfSize                            32
		udf config -updown                             uuuu
		udf config -initval                            {FF 00 00 00}
		udf config -repeat                             1
		udf config -step                               1
		if {[udf set 1]} {
			ixPuts "IXIA - Error calling udf set 1"
			set retCode $::TCL_ERROR
		}

		udf setDefault
		udf config -enable                             true
		udf config -continuousCount                    false
		udf config -offset                             44
		udf config -counterMode                        udfCounterMode
		udf config -chainFrom                          udfNone
		udf config -udfSize                            32
		udf config -updown                             uuuu
		udf config -initval                            {01 16 19 68}
		udf config -repeat                             1
		udf config -step                               1
		if {[udf set 2]} {
			ixPuts "IXIA - Error calling udf set 2"
			set retCode $::TCL_ERROR
		}

		if {[stream set $chassId $cardId $portId $streamId]} {
			ixPuts "IXIA - Error calling stream set $chassId $cardId $portId $streamId"
			set retCode $::TCL_ERROR
		}

		autoDetectInstrumentation setDefault
		autoDetectInstrumentation config -enableTxAutomaticInstrumentation   true
		autoDetectInstrumentation config -signature                          {87 73 67 49 42 87 11 80 08 71 18 05}
		if {[autoDetectInstrumentation setTx $chassId $cardId $portId $streamId]} {
			ixPuts "IXIA - Error calling autoDetectInstrumentation setTx $chassId $cardId $portId $streamId"
			set retCode $::TCL_ERROR
		}

		incr streamId
		# Build the Pause (Q0) stream now.
		#  Stream 2
		stream setDefault
		stream config -name                               "Pause (Q0)"
		stream config -enable                             true
		stream config -numBursts                          1
		stream config -numFrames                          1
		stream config -ifg                                0.96
		stream config -ifgType                            gapFixed
		stream config -ifgMIN                             1.92
		stream config -ifgMAX                             2.56
		stream config -gapUnit                            gapNanoSeconds
		stream config -percentPacketRate                  100.0
		stream config -rateMode                           streamRateModePercentRate
		stream config -sa                                 "00 00 00 00 01 3C"
		stream config -da                                 "01 80 C2 00 00 01"
		stream config -framesize                          64
		stream config -frameSizeType                      sizeFixed
		stream config -frameType                          "88 08"
		stream config -dma                                contPacket
		stream config -loopCount                          1
		stream config -returnToId                         1
		stream config -enableStatistic                    true
		stream config -startTxDelayUnit                   4
		stream config -startTxDelay                       8384.0                   ; # This delay sends the first Pause packet immediately after the last pre-pause packet
		stream config -priorityGroup                      priorityGroup0

		protocol setDefault
		protocol config -name                               pauseControl
		protocol config -appName                            noType
		protocol config -ethernetType                       ethernetII

		pauseControl setDefault
		pauseControl config -da                                 "01 80 C2 00 00 01"
		pauseControl config -pauseTime                          255
		#pauseControl config -pauseControlType                   ieee8023x
		pauseControl config -pauseControlType                   ieee8021Qbb
		pauseControl config -priorityEnableVector               0x01
		pauseControl config -usePfcEnableValueList              1
		pauseControl config -pauseFrame                         "00 FF 00 00 00 00 00 00 00 00 00 00 00 00 00 00"
		pauseControl config -pfcEnableValueList                 "{1 255} {0 0} {0 0} {0 0} {0 0} {0 0} {0 0} {0 0}"
		if {[pauseControl set $chassId $cardId $portId]} {
			ixPuts "IXIA - Error calling pauseControl set $chassId $cardId $portId"
			set retCode $::TCL_ERROR
		}

		if {[stream set $chassId $cardId $portId $streamId]} {
			ixPuts "IXIA - Error calling stream set $chassId $cardId $portId $streamId"
			set retCode $::TCL_ERROR
		}

	}
	foreach port $pfcStreamTrafficPortList {
		scan $port "%d %d %d" chassId cardId portId

		ixPuts "IXIA - PFC traffic port and traffic streams on $chassId $cardId $portId"

		port setFactoryDefaults $chassId $cardId $portId
		port config -transmitMode                       portTxModeAdvancedScheduler
		port config -receiveMode                        [expr $::portCapture|$::portRxDataIntegrity|$::portRxSequenceChecking|$::portRxModeWidePacketGroup]
		port config -flowControl                        true
		port config -dataCenterMode                     eightPriorityTrafficMapping
		port config -enableDataCenterMode               true
		port config -flowControlType                    ieee8021Qbb
		port config -pfcEnableValueListBitMatrix        "{1 1} {1 2} {1 4} {1 8} {1 16} {1 32} {1 64} {1 128}"
		port config -pfcResponseDelayEnabled            0
		port config -pfcResponseDelayQuanta             1
		port config -autoDetectInstrumentationMode      portAutoInstrumentationModeFloating
		port config -operationModeList                  [list $::portOperationModeStream]
		port config -ieeeL1Defaults                     0

		if {[port set $chassId $cardId $portId]} {
			ixPuts "IXIA - Error calling port set $chassId $cardId $portId"
			set retCode $::TCL_ERROR
		}

		autoDetectInstrumentation setDefault
		autoDetectInstrumentation config -startOfScan                        0
		autoDetectInstrumentation config -signature                          {87 73 67 49 42 87 11 80 08 71 18 05}
		autoDetectInstrumentation config -enableSignatureMask                false
		autoDetectInstrumentation config -signatureMask                      {00 00 00 00 00 00 00 00 00 00 00 00}
		if {[autoDetectInstrumentation setRx $chassId $cardId $portId]} {
			ixPuts "IXIA - Error calling autoDetectInstrumentation setRx $chassId $cardId $portId"
			set retCode $::TCL_ERROR
		}

		filter setDefault
		filter config -captureTriggerPattern              pattern1
		filter config -captureTriggerError                errAnyFrame
		filter config -captureFilterPattern               pattern1
		filter config -captureFilterError                 errAnyFrame
		if {[filter set $chassId $cardId $portId]} {
			ixPuts "IXIA - Error calling filter set $chassId $cardId $portId"
			set retCode $::TCL_ERROR
		}


		filterPallette setDefault
		filterPallette config -pattern1                           "01 16 19 68"
		filterPallette config -patternMask1                       "00 00 00 00"
		filterPallette config -patternOffset1                     44
		filterPallette config -matchType1                         matchUser
		filterPallette config -patternOffsetType1                 filterPalletteOffsetStartOfFrame

		if {[filterPallette set $chassId $cardId $portId]} {
			ixPuts "IXIA - Error calling filterPallette set $chassId $cardId $portId"
			set retCode $::TCL_ERROR
		}

		capture setDefault
		capture config -fullAction                         lock
		capture config -sliceSize                          65536
		capture config -sliceOffset                        0
		capture config -captureMode                        captureTriggerMode
		capture config -continuousFilter                   0
		capture config -beforeTriggerFilter                captureBeforeTriggerNone
		capture config -afterTriggerFilter                 captureAfterTriggerFilter
		if {[capture set $chassId $cardId $portId]} {
			ixPuts "IXIA - Error calling capture set $chassId $cardId $portId"
			set retCode $::TCL_ERROR
		}

		#  Stream 1
		set streamId 1
		stream setDefault
		stream config -name                               "PFC Traffic Queue 0"
		stream config -enable                             true
		stream config -numFrames                          100
		stream config -percentPacketRate                  100.0
		stream config -rateMode                           streamRateModePercentRate
		stream config -sa                                 "00 00 00 00 01 38"
		stream config -saStep                             1
		stream config -da                                 "00 00 00 00 01 3C"
		stream config -daStep                             1
		stream config -framesize                          64
		stream config -frameSizeType                      sizeFixed
		stream config -frameSizeStep                      1
		stream config -enableTimestamp                    true
		stream config -fcs                                good
		stream config -patternType                        incrByte
		stream config -dataPattern                        x00010203
		stream config -pattern                            "00 01 02 03"
		stream config -frameType                          "08 00"
		stream config -dma                                contPacket
		stream config -enableStatistic                    true
		stream config -priorityGroup                      priorityGroup0

		protocol setDefault
		protocol config -name                               mac
		protocol config -appName                            noType
		protocol config -ethernetType                       ethernetII

		if {[stream set $chassId $cardId $portId $streamId]} {
			ixPuts "IXIA - Error calling stream set $chassId $cardId $portId $streamId"
			set retCode $::TCL_ERROR
		}

		autoDetectInstrumentation setDefault
		autoDetectInstrumentation config -enableTxAutomaticInstrumentation   true
		autoDetectInstrumentation config -signature                          {87 73 67 49 42 87 11 80 08 71 18 05}
		if {[autoDetectInstrumentation setTx $chassId $cardId $portId $streamId]} {
			ixPuts "IXIA - Error calling autoDetectInstrumentation setTx $chassId $cardId $portId $streamId"
			set retCode $::TCL_ERROR
		}


	}

}


ixWritePortsToHardware portList
after 2000
if {[ixCheckLinkState portList]} {
	ixPuts "IXIA - Error ixCheckLinkState"
	return $::TCL_ERROR
}

stream get $chassId $cardId $pfcPauseFramePort 1
set numFramesTx [stream cget -numFrames]
udf get 2
set sequenceOffset [expr [udf cget -offset] -1]

# 3)Clear time stamps on Port A and Port B
ixClearTimeStamp portList

# 4) Start PG stats on Port A
ixStartPacketGroups pfcPauseFrameList

# 5) Start Capture on Port B (port that has traffic) and Port A (port that sends Pause Frames)
#ixStartCapture pfcStreamTrafficPortList
ixStartCapture portList


# 6) Start traffic on Port A and B
ixStartTransmit portList
after 3000

#7)	View Capture on Port B and identify and analyze the last packet of the pre-pause frames from Port A

ixPuts "IXIA Retrieving captured data on $chassId $cardId $pfcStreamTrafficPort....\n"
ixPuts "================================================\n"


if {[capture get $chassId $cardId $pfcStreamTrafficPort ]} {
	ixPuts "IXIA - ERROR getting capture $chassId $cardId $pfcStreamTrafficPort"
	set retCode $::TCL_ERROR
}

set numCapFrames [capture cget -nPackets]

# We expect to capture only the pre-pause packets.  We've also configured the StartTxDelay of the pause packets such that pause packets will begin immediately after the last pre-pause packet.
if {$numCapFrames < $numFramesTx } {
	ixPuts "IXIA - ERROR: Not all packets are captured: $numCapFrames packets out of $numFramesTx on port $chassId $cardId $pfcStreamTrafficPort"
} elseif {$numCapFrames > $numFramesTx } {
	ixPuts "IXIA - ERROR: captured more packets then expected on port $chassId $cardId $pfcStreamTrafficPort check filters"
	set retCode $::TCL_ERROR
} else {
	ixPuts "IXIA - Captured all the packets: $numCapFrames on port $chassId $cardId $pfcStreamTrafficPort"
}

if {[captureBuffer get $chassId $cardId $pfcStreamTrafficPort 1 $numCapFrames ]} {
	ixPuts "IXIA - ERROR getting captureBuffer $chassId $cardId $pfcStreamTrafficPort"
	set retCode $::TCL_ERROR
}

if {$retCode == $::TCL_ERROR} {
	ixPuts "IXIA - ERROR: Will not be able to calculate the PFS Response Time. Exiting"
	return $retCode
}


# 8) Identify the last packet of the pre-pause frames from Port A and
# extracting the timestamp from the captured pre-pause packet
ixPuts "IXIA - Analyzing captured data, extracting the sequence # and timestamp from this packet....."
captureBuffer getframe $numCapFrames
set frame [captureBuffer cget -frame]
ixPuts "IXIA - Frame: $frame\n"


# Extract the sequence # the captured pre-pause packet
set sequenceNumber [lindex $frame $sequenceOffset]

proc hexlist2Value { hexlist } \
{
   set retValue 0
   foreach byte $hexlist {
      set retValue [expr ($retValue << 8) | 0x$byte]
   }
   return $retValue
}
set sequenceNumber [hexlist2Value $sequenceNumber]

# Get the timestamp
#set rxTimeStamp [captureBuffer cget -timestamp]
#ixPuts "IXIA - Packet rx: $rxTimeStamp\n"
set lastPrePausePacketRxTimeStamp [captureBuffer cget -fir]
ixPuts "IXIA - Last Pre-Pause Packet Rx TimeStamp : $lastPrePausePacketRxTimeStamp in nanoseconds\n"

# 9) Calculate the timestamp of the first pause packet:
#    Since the sequence number started from 0, we needed to add 1 to make it equal to the total number of pre-pause frames
#    then we add one more to account for the first pause frame
#    time from beginning of one packet to beginning of next packet at line rate = 6.72ns
# 	a.	Pause Frame Timestamp = extracted timestamp + 6.72*(pre-pause count – (sequence # + 1) +1)
if {$lastPrePausePacketRxTimeStamp != 0 } {
	set pauseFrameTimestamp [expr $lastPrePausePacketRxTimeStamp + 6.72]
	ixPuts "IXIA - Formula for Pause Frame Timestamp: $lastPrePausePacketRxTimeStamp + 6.72"
} else {
	ixPuts "IXIA - ERROR invalid lastPrePausePacketRxTimeStamp : $lastPrePausePacketRxTimeStamp."
	return FAIL
}
#ixPuts "IXIA - PFC Frame Timestamp: $pauseFrameTimestamp"


# Check when traffic is stopped, then get the packet group stats
ixRequestStats pfcPauseFrameList
while {[statList getRate $chassId $cardId $pfcPauseFramePort] != 1 && [statList cget -framesReceived] != 0} {
	#ixPuts "$chassId $cardId $pfcPauseFramePort framesReceived rate: [statList cget -framesReceived]"
	ixRequestStats pfcPauseFrameList
}

# 10)	Get last timestamp from Port A (pfcPauseFramePort) PG stats

set totalGroups 1
set pgLastTimeStamp 0

if {![packetGroupStats get $chassId $cardId $pfcPauseFramePort 0 $totalGroups]} {
	if {![packetGroupStats getGroup 1]}  {
		set pgLastTimeStamp [packetGroupStats cget -lastTimeStamp]
        #ixPuts "IXIA - Packet last TimeStamp $pgLastTimeStamp"
    } else {
		ixPuts "IXIA - ERROR Invalid packet stats group."
		set retCode $::TCL_ERROR
	}
} else {
	ixPuts "IXIA - ERROR Unable to get the packet group $chassId $cardId $pfcPauseFramePort\n"
	set retCode $::TCL_ERROR
}

if {$retCode == $::TCL_ERROR} {
	ixPuts "IXIA - ERROR Will not be able to calculate the PFS Response Time. Exiting"
	return $retCode
}

# 11)	Calculate PFC response time:
# 	a.	Response Time = (PG Stats timestamp – Pause Frame Timestamp)
#
ixPuts "IXIA - PFC Frame Timestamp: $pauseFrameTimestamp"
ixPuts "IXIA - Traffic Packet last TimeStamp $pgLastTimeStamp"
set responseTime [expr $pgLastTimeStamp - $pauseFrameTimestamp]
ixPuts "IXIA - PFC Response Time = ($pgLastTimeStamp - $pauseFrameTimestamp): $responseTime"


# ##############
# 12 calculate the number of packets received after the PFC pause frame is sent.  It will require enhancements to the scripts.

# Add 5.12 ns (the duration of a 64B packet) to this pause packet timestamp to account for when the packet was fully received by the DUT.


# Check when traffic is stopped, then get the packet group stats
# It is expected the rx frame rate to be 0 at this point, but yet added the check.
ixRequestStats pfcPauseFrameList
while {[statList getRate $chassId $cardId $pfcPauseFramePort] != 1 && [statList cget -framesReceived] != 0} {
	ixPuts "$chassId $cardId $pfcPauseFramePort framesReceived rate: [statList cget -framesReceived]"
	ixRequestStats pfcPauseFrameList
}

set pauseFrameRxTimestamp [mpexpr $pauseFrameTimestamp + 5.12 ]
ixPuts "IXIA - PFC Frame Timestamp $pauseFrameTimestamp + 5.12 (ns) time fully recieved by the DUT: $pauseFrameRxTimestamp\n"


if {[capture get $chassId $cardId $pfcPauseFramePort ]} {
	ixPuts "IXIA - ERROR getting capture $chassId $cardId $pfcPauseFramePort"
	set retCode $::TCL_ERROR
}

set numCapFrames [capture cget -nPackets]

#if {[captureBuffer get $chassId $cardId $pfcPauseFramePort 1 $numCapFrames ]} {
#	ixPuts "IXIA - ERROR getting captureBuffer $chassId $cardId $pfcPauseFramePort"
#	set retCode $::TCL_ERROR
#}

catch {unset capFramTimstampArray}
catch {unset capFrameArray}
set timeStamp "N/A"

# Iterate through the captured packets on PortA in reverse order (last to first), and extract the Tx timestamp embedded in each packet.
ixPuts "IXIA - Captured $numCapFrames stream traffic packets on port $chassId $cardId $pfcPauseFramePort"
set capFrame $numCapFrames
ixPuts "IXIA - Analyzing captured data on port $chassId $cardId $pfcPauseFramePort.....This will take a while."

while { ![captureBuffer get $chassId $cardId $pfcPauseFramePort $capFrame $capFrame ] && ![captureBuffer getframe 1] } {
	#set frame [captureBuffer cget -frame]
	#timestamp- this is what you need
	set timeStamp [captureBuffer cget -timestamp]
	#set capFramTimstampArray($capFrame) $timeStamp
	#set capFrameArray($capFrame) $frame
	#g.	Identify the packet whose Tx timestamp is just under the timestamp of the pause packet.
	if {$timeStamp < $pauseFrameRxTimestamp} {
		ixPuts "IXIA - Found first packet just under the timestamp of the pause packet number $capFrame in the buffer - TimeStamp:$timeStamp"
		ixPuts "IXIA - $pauseFrameRxTimestamp - $timeStamp = [expr $pauseFrameRxTimestamp - $timeStamp]"
		break
	}
	incr capFrame -1
}

if {$timeStamp != "N/A"} {
	ixPuts "IXIA - PFC Frame Timestamp with arrival time and Tx timestamp ($pauseFrameRxTimestamp) just under the timestamp of the pause packet ($timeStamp)"

	#	Subtract this packet number from the total packets received.  This yields the number of packets received after the pause packet was sent.
	set numPacketsReceived [expr $numCapFrames - $capFrame]
	ixPuts "IXIA - Estimated number of packets received after the pause packet was sent: $numPacketsReceived"
} else {
	ixPuts "IXIA - ERROR Unable to calculate the number of packets received after the pause packet was sent ($numCapFrames - $capFrame)"
	set retCode $::TCL_ERROR
}


##########################

# Cleanup the ports after test end
ixStopTransmit portList
ixStopPacketGroups pfcPauseFrameList
ixStopCapture portList
ixClearOwnership $portList


return $retCode