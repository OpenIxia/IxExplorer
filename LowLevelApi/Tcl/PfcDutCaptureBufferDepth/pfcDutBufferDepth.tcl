

# This script demonstrates how to measure the DUT’s buffer depth with PFC HW/SW/API abiity. This is done for Novus 100G.
# 06/22/2018
# Written by Hasmik Shakaryan and pseudo code by CHRISTOPHER KOWALSKI and Dwayne Hunnicutt 
# Solution: Tested on IxOS 8.40 EA



# Pseudo-code: 
#Use two DUT ports (let’s call them A and B) and two Ixia ports (let’s call them 1 and 2).  Port A is connected to 1 and port B is connected to 2.

# 1. Configure the DUT to switch all ingress packets on port A to egress on port B.
# 2. From port 2 send pause frames with max quanta at line rate.  This will prevent any packets from being sent out of port B.
# 3. Do the following:
#	 A.	Send 10000 packets from port 1
#	 B.	Stop the pause traffic being sent by port 2
#	 C.	See how many packets are received on port 2.  The number received is the buffer size.  If all packets are received repeat the steps again but send more packets in step A.
# 4. If the DUT has a drop count you can use that also to calculate the buffer size:
#	 A.	Packets sent – drop count = buffer size
#    B. After following the steps below, multiply the number of received packets by 64B.  The result is the buffer depth.

# NOTE:
# NovusStreamTraffic corresponds to “Ixia port 1.”  NovusPauseFrames.prt corresponds to “Ixia port 2.”    
# NovusPauseFrames.prt has streams to pause specific PFC queues, but they are currently disabled.  The enabled stream will pause all PFC queues.
# 
# We do not recommend calculating all priorities at the same time.  

#Steps to run the script: pfcDutBufferSize.tcl

#1.	Modify script to point to your chassis, hostname
#2.	Modify the script to point to the location of the port files in the attached zip file. Note that this are Novus ports. If you choose to run on a different port, you need to create new port files with the same configuration
#   You can use usePortFile flag to either load the .prt file or configure the ports using the script.
#3.	Source pfcDutBufferSize.tcl from the IxOS wish console.

package req IxTclHal
set hostName 10.36.88.91
set retCode $::TCL_OK

ixLogin hasmik

ixConnectToChassis $hostName
set chassId [chassis cget -id]

set cardId 8
set pfcStreamTrafficPort 	1
set pfcPauseFramePort		2
set numFramesSent			10000

set portList [list [list $chassId $cardId $pfcPauseFramePort ] [list $chassId $cardId $pfcStreamTrafficPort]]
set pfcPauseFrameList [list [list $chassId $cardId $pfcPauseFramePort ] ]
set pfcStreamTrafficPortList [list [list $chassId $cardId $pfcStreamTrafficPort]]

ixLogin hasmik
ixTakeOwnership $portList

# Unexposed feature enum
set portFeatureResourceGroupEx 479
	
set usePortFile 0
	
if {$usePortFile } {
	set prtFilePath "C:/Program Files (x86)/Ixia/IxOS/8.40-EA/TclScripts/bin/MySamples"
	set pfcPauseFramePortFile $prtFilePath/100GNovus_PFC_PauseFrames.prt
	set pfcStreamTrafficPortFile $prtFilePath/100GNovus_PFC_trafficStream.prt
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
	ixPuts "IXIA - ERROR Will not be able to calculate the DUT Buffer depth. Exiting."
	return $retCode
}

if {$usePortFile } {
	# 1)Load pfc_pause_frames.prt on Port 1
	if {[port import $pfcPauseFramePortFile $chassId $cardId $pfcPauseFramePort]} {
		ixPuts "IXIA - Error import $pfcPauseFramePortFile $chassId $cardId $pfcPauseFramePort"
		set retCode $::TCL_ERROR
	}

	# 2)	Load pfc_stream_traffic.prt on Port 2
	if {[port import $pfcStreamTrafficPortFile $chassId $cardId $pfcStreamTrafficPort]} {
		ixPuts "IXIA - Error import $pfcStreamTrafficPortFile $chassId $cardId $pfcStreamTrafficPort"
		set retCode $::TCL_ERROR
	}
} else {

	foreach port $pfcPauseFrameList {
		scan $port "%d %d %d" chassId cardId portId
		
		ixPuts "IXIA - Pause Frame Port and Pause streams on $chassId $cardId $portId"
		
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

		filter config -userDefinedStat2Enable             true
		if {[filter set $chassId $cardId $portId]} {
			ixPuts "IXIA - Error calling filter set $chassId $cardId $portId"
			set retCode $::TCL_ERROR
		}
		filterPallette config -pattern1                           "DE ED EF FE"
		filterPallette config -patternMask1                       "00 00 00 00"
		filterPallette config -matchType1                         matchUser
		filterPallette config -matchType2                         matchUser
		filterPallette config -patternOffsetType1                 filterPalletteOffsetStartOfFrame

		if {[filterPallette set $chassId $cardId $portId]} {
			ixPuts "IXIA - Error calling filterPallette set $chassId $cardId $portId"
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
		
		# Build the Pause (Q0) stream now.
		#  Stream 1
		set streamId 1
		stream setDefault 
		stream config -name                               "PFC Pause All Queues"
		stream config -enable                             true
		stream config -numFrames                          100
		stream config -percentPacketRate                  100.0
		stream config -rateMode                           streamRateModePercentRate
		stream config -sa                                 "00 00 00 00 05 00"
		stream config -da                                 "01 80 C2 00 00 01"
		stream config -framesize                          64
		stream config -frameSizeType                      sizeFixed
		stream config -dma                                stopStream
		stream config -loopCount                          1
		stream config -returnToId                         1
		stream config -priorityGroup                      priorityGroup0

		protocol setDefault 
		protocol config -name                               pauseControl
		protocol config -appName                            noType
		protocol config -ethernetType                       ethernetII
				
		pauseControl setDefault 
		pauseControl config -da                                 "01 80 C2 00 00 01"
		pauseControl config -pauseTime                          255
		pauseControl config -pauseControlType                   ieee8021Qbb
		pauseControl config -priorityEnableVector               0xff
		pauseControl config -usePfcEnableValueList              0
		pauseControl config -pauseFrame                         "FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF"
		pauseControl config -pfcEnableValueList                 "{1 65535} {1 65535} {1 65535} {1 65535} {1 65535} {1 65535} {1 65535} {1 65535}"
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
		port config -receiveMode                        [expr $::portCapture|$::portRxModeWidePacketGroup]
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
		
		set streamId 1
		#  Stream 1
		stream setDefault 
		stream config -name                               "PFC Traffic Queue 0"
		stream config -enable                             true
		stream config -numFrames                          $numFramesSent  ;# increase this number if needed
		stream config -loopCount                          1
		stream config -percentPacketRate                  100.0
		stream config -rateMode                           streamRateModePercentRate
		stream config -sa                                 "00 00 00 00 04 00"
		stream config -saStep                             1
		stream config -da                                 "00 00 00 00 05 00"
		stream config -daStep                             1
		stream config -framesize                          64
		stream config -frameSizeType                      sizeFixed
		stream config -frameSizeStep                      1
		stream config -fcs                                good
		stream config -patternType                        incrByte
		stream config -dataPattern                        x00010203
		stream config -pattern                            "00 01 02 03"
		stream config -frameType                          "08 00"
		stream config -dma                                stopStream
		stream config -enableStatistic                    true
		stream config -priorityGroup                      priorityGroup0

		protocol setDefault 
		protocol config -name                               mac
		protocol config -appName                            noType
		protocol config -ethernetType                       ethernetII

		
		
		udf setDefault 
		udf config -enable                             true
		udf config -continuousCount                    false
		udf config -offset                             12
		udf config -counterMode                        udfCounterMode
		udf config -udfSize                            32
		udf config -initval                            {DE ED EF FE}
		if {[udf set 1]} {
			ixPuts "IXIA - Error calling audf set 1 $chassId $cardId $portId"
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

	
	}
	
}


ixWritePortsToHardware portList
after 2000
if {[ixCheckLinkState portList]} {
	ixPuts "IXIA - Error ixCheckLinkState"
	return $::TCL_ERROR
}
set done 	1
set maxLoop 5
set loop 	1

ixClearStats portList


while { $done && ($loop <= $maxLoop)} { 
	# 2. From port 2 send pause frames with max quanta at line rate.  This will prevent any packets from being sent out of port B.
	ixStartTransmit pfcPauseFrameList

	# 3. Do the following:
	#	 A.	Send 10000 packets from port 1
	ixStartTransmit pfcStreamTrafficPortList
	after 2000
	ixCheckTransmitDone pfcStreamTrafficPortList
	
	#	 B.	Stop the pause traffic being sent by port 2 - this one only transmits 100 packets, so it will stop by itself
	# ixStopTransmit pfcPauseFrameList

	#	 C.	See how many packets are received on port 2.  The number received is the buffer size.  If all packets are received repeat the steps again but send more packets in step A.
	ixPuts "IXIA Retrieving the number of received packets on $chassId $cardId $pfcPauseFramePort...."
	ixPuts "$loop ================================================\n"

	
	ixRequestStats pfcPauseFrameList
	while {[statList getRate $chassId $cardId $pfcPauseFramePort] != 1 && [statList cget -userDefinedStat2] != 0} {
		#ixPuts "$chassId $cardId $pfcPauseFramePort framesReceived rate: [statList cget -userDefinedStat2]"
		ixRequestStats pfcPauseFrameList
	}
	statList get $chassId $cardId $pfcPauseFramePort
	if {[statList cget -userDefinedStat2] == $numFramesSent } {
		ixPuts " [statList cget -userDefinedStat2] == $numFramesSent"
	    incr loop
		ixClearStats portList
		continue
	} else {
		set done 0
	}
}
	

# 4. If the DUT has a drop count you can use that also to calculate the buffer size:
#	 A.	Packets sent – drop count = buffer size
#    B. After following the steps below, multiply the number of received packets by 64B.  The result is the buffer depth.
ixPuts "Frames Sent 	= $numFramesSent"
ixPuts "Frames Received	= [statList cget -userDefinedStat2]"
set bufferDepth	[expr ($numFramesSent - [statList cget -userDefinedStat2]) * 64 ]
ixPuts "DUT buffer depth= $bufferDepth"


ixClearOwnership $portList
return $retCode