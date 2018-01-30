#!/usr/bin/tclsh 

# This script will retrieve all the stream configuration from IxExplorer
# and transfer the configs to IxNetwork QuickFlow.
#
# To modify existing stream configs, must login first (ixLogin <username>)
# stream config -framesisze 128
# stream set 1 1 1 1
# stream write 1 1 1 1
# ixWriteConfigToHardware port (will work too)

package req Ixia
#package req IxTclHal
#package req IxTclNetwork

set ixChassisIp 10.205.4.35
set ixNetworkTclServer 10.205.1.42
set ixNetworkVersion 7.0
set userName hgee
set portList {1/1/1 1/1/2}


if {[ixConnectToTclServer $ixChassisIp]} {
    puts "Failed to connect to tcl server $ixChassisIp"
    exit
}

if {[ixConnectToChassis $ixChassisIp]} {
    puts "Failed to connect to ixia chassis $ixChassisIp"
    exit
}

# The ::halCommands is a global variable consists of every IxTclHal commands
# Uncomment this line to view all of them
# puts $::halCommands

set halList {port stream interfaceIpv4 interfaceIpv6 protocol ip udp tcp icmp arp dhcp igmp pauseControl stat udf vlan ipV6}

foreach property $halList {
    puts "\n---- Property: $property ----\n"
    $property get 1 1 1 1
    puts [showCmd $property]
}

exit

#card get 1 2
#puts "Card type: [card cget -typeName]"
#puts "Card serial number: [card cget -serialNumber]"



set cardList {}
set portList {1/2/1 1/2/2 1/2/3 1/2/4}

# To get all the statistic commands
#   1> stat get statAllStats 1 1 1
#   2> showCmd stat



stream get 1 1 1 1

puts "Stream cget da: [stream cget -da] ---"
puts "Stream cget sa: [stream cget -sa] ---"
puts "Stream cget name: [stream cget -name] ---"
puts "Protocol cget -type [protocol cget -ethernetType]"

version get
puts "Install version: [version cget -installVersion]"
puts "ixTclHalVersion: [version cget -ixTclHALVersion]"
puts "ixTclProtocolVersion: [version cget -ixTclProtocolVersion]"
puts "Product version: [version cget -productVersion]"


puts "InterfaceIpv4 cget -ipAddress: [interfaceIpV4 cget -ipAddress]"
#puts "InterfaceIpv4 cget -maskWidth: [interfaceIpV4 cget -maskWidth]"
#puts "InterfaceIpv4 cget -gatewayIpAddress: [interfaceIpV4 cget -gatewayIpAddress]"
#puts "InterfaceIpv4 cget -macAddress: [interfaceIpV4 cget -macAddress]"
#puts "DiscoveredAddress cget -ipAddress: [discoveredAddress cget -ipAddress]"

# discoveredNeighbor cget: ipRouter, getFirstAddress, getNextAddress, macAddress
#vlan get 1 1 1




if 0 {
showCmd stream
stream cget -asyncIntEnable: 0
stream cget -bpsRate: 76190476.0
stream cget -da: 00 00 00 00 00 00
stream cget -daMaskSelect: 00 00 00 00 00 00
stream cget -daMaskValue: 00 00 00 00 00 00
stream cget -daRepeatCounter: 4
stream cget -daStep: 1
stream cget -dataPattern: 12
stream cget -dma: 0
stream cget -enable: 1
stream cget -enableDaContinueFromLastValue: 0
stream cget -enableDisparityError: 0
stream cget -enableIbg: 0
stream cget -enableIncrFrameBurstOverride: 0
stream cget -enableIsg: 0
stream cget -enableSaContinueFromLastValue: 0
stream cget -enableSourceInterface: 0
stream cget -enableStatistic: 1
stream cget -enableSuspend: 0
stream cget -enableTimestamp: 0
stream cget -endOfProtocolPad: 0
stream cget -enforceMinGap: 12
stream cget -fcs: 0
stream cget -fir: -1
stream cget -floatRate: 0.0
stream cget -fpsRate: 148810.0
stream cget -frameSizeMAX: 64
stream cget -frameSizeMIN: 64
stream cget -frameSizeStep: 1
stream cget -frameSizeType: 0
stream cget -frameType: 
stream cget -framerate: 0
stream cget -framesize: 64
stream cget -gapUnit: 0
stream cget -ibg: 960.0
stream cget -ifg: 960.0
stream cget -ifgMAX: 960.0
stream cget -ifgMIN: 960.0
stream cget -ifgType: 0
stream cget -isg: 960.0
stream cget -loopCount: 1
stream cget -name: 
stream cget -numBursts: 1
stream cget -numDA: 1
stream cget -numFrames: 100
stream cget -numSA: 1
stream cget -packetView: 
stream cget -pattern: 00 01 02 03
stream cget -patternType: 0
stream cget -percentPacketRate: 100.0
stream cget -preambleData: 55 55 55 55 55 55
stream cget -preambleSize: 8
stream cget -priorityGroup: 0
stream cget -rateMode: 1
stream cget -region: 0
stream cget -returnToId: 1
stream cget -rxTriggerEnable: 0
stream cget -sa: 00 00 00 00 00 00
stream cget -saMaskSelect: 00 00 00 00 00 00
stream cget -saMaskValue: 00 00 00 00 00 00
stream cget -saRepeatCounter: 4
stream cget -saStep: 1
stream cget -sourceInterfaceDescription: 
stream cget -startOfDataPattern: 0
stream cget -startOfProtocolPad: 0
stream cget -startTxDelay: 0.0
stream cget -startTxDelayUnit: 4
stream cget -suspendState: 0
stream cget -warnings: 
}

# These are the features that the customer wants to convert
# from IxExplorer to IxNetwork QuickFlow.
#
# These variable name values must be exactly the same as how 
# IxTclHal uses them in get and cget.
set streamConfigs {sa da framesize numFrames percentPacketRate name}
set ipv4Configs {sourceIpAddr destIpAddr}
set ipv6Configs {sourceAddr destAddr}
set vlanConfigs {vlanID}

# Loop each port/stream for all it's properties and values
foreach port $portList {
    scan $port "%d/%d/%d" chassis card portNumber
    
    for {set streamId 1} {$streamId <= 4000} {incr streamId} {
	if {[stream get $chassis $card $portNumber $streamId] == 1} {
	    break
	}

	foreach streamAttribute $streamConfigs {
	    catch {set value [stream cget -$streamAttribute]} errMsg
	    if {[regexp "Invalid" $errMsg]} {
		puts "No such stream attribute: $streamAttribute"
		exit
	    } else {
		set portConfigs($port,$streamId,$streamAttribute) $value
	    }
	}

	if {[info exists ipv4Configs]} {
	    foreach streamAttribute $ipv4Configs {
		# sourceClass 0=Class_A  1=Class_B   2=Class_C
		# AddrMode 1=incrementHost 2=decrementHost  3=continuousIncrementHost 
		#          4=continuousDecrementHost   5=incrementNetwork  6=decrementNetwork
		#          7=continuousIncrementNetwork 8=continuousDecrementNetwork
		if {[ip get $chassis $card $portNumber] != 1} {
		    set ipv4 [ip cget -$streamAttribute $chassis $card $portNumber $streamId]

		    # 4 = ipv4  ; 31 = ipv6
		    if {[protocol cget -name] == "4"} {
			if {$streamAttribute == "sourceIpAddr"} {
			    set sourceIpAddrRepeatCount [ip cget -sourceIpAddrRepeatCount $chassis $card $portNumber $streamId]
			    set sourceIpAddrMode [ip cget -sourceIpAddrMode $chassis $card $portNumber $streamId]
			    set sourceClass [ip cget -sourceClass $chassis $card $portNumber $streamId]
			    set portConfigs($port,$streamId,$streamAttribute) "sourceIpAddr $ipv4 sourceIpAddrRepeatCount $sourceIpAddrRepeatCount sourceIpAddrMode $sourceIpAddrMode sourceClass $sourceClass"
			}
			
			if {$streamAttribute == "destIpAddr"} {
			    set destIpAddrRepeatCount [ip cget -destIpAddrRepeatCount $chassis $card $portNumber $streamId]
			    set destIpAddrMode [ip cget -destIpAddrMode $chassis $card $portNumber $streamId]
			    set destClass [ip cget -destClass $chassis $card $portNumber $streamId]
			    set portConfigs($port,$streamId,$streamAttribute) "destIpAddr $ipv4 destIpAddrRepeatCount $destIpAddrRepeatCount destIpAddrMode $destIpAddrMode destClass $destClass"
			}
		    }
		}
	    }
	}

	if {[info exists ipv6Configs]} {
	    foreach streamAttribute $ipv6Configs {
		# SourceAddrMode  0=fixed 5=incrementInterfaceId  6=decrementInterfaceId
		if {[ipV6 get $chassis $card $portNumber] != 1} {
		    
		    # 4 = ipv4  ; 31 = ipv6
		    if {[protocol cget -name] == "31"} {
			set ipv6 [ipV6 cget -$streamAttribute]

			if {$streamAttribute == "sourceAddr"} {
			    set sourceAddrRepeatCount [ipV6 cget -sourceAddrRepeatCount $chassis $card $portNumber $streamId]
			    set sourceAddrMode [ipV6 cget -sourceAddrMode $chassis $card $portNumber $streamId]
			    set sourceStepSize [ipV6 cget -sourceStepSize $chassis $card $portNumber $streamId]
			    set trafficClass [ipV6 cget -trafficClass $chassis $card $portNumber $streamId]

			    set portConfigs($port,$streamId,$streamAttribute) "sourceAddr $ipv6 sourceAddrRepeatCount $sourceAddrRepeatCount sourceAddrMode $sourceAddrMode sourceStepSize $sourceStepSize trafficClass $trafficClass"
			}

			if {$streamAttribute == "destAddr"} {
			    set destAddrRepeatCount [ipV6 cget -destAddrRepeatCount $chassis $card $portNumber $streamId]
			    set destAddrMode [ipV6 cget -destAddrMode $chassis $card $portNumber $streamId]
			    set destStepSize [ipV6 cget -destStepSize $chassis $card $portNumber $streamId]
			    set trafficClass [ipV6 cget -trafficClass $chassis $card $portNumber $streamId]

			    set portConfigs($port,$streamId,$streamAttribute) "destAddr $ipv6 destAddrRepeatCount $destAddrRepeatCount destAddrMode $destAddrMode destStepSize $destStepSize trafficClass $trafficClass"
			}
		    }
		}
	    }
	}

	if {[info exists vlanConfigs]} {
	    foreach streamAttribute $vlanConfigs {
		if {[vlan get $chassis $card $portNumber] != 1} {
		    if {[protocol cget -enable802dot1qTag] == 1} {
			set vlanId [vlan cget -$streamAttribute $chassis $card $portNumber $streamId]
			set vlanPriority [vlan cget -userPriority $chassis $card $portNumber $streamId]
			set vlanRepeat [vlan cget -repeat $chassis $card $portNumber $streamId]
			# vlanCountMode: 0=fixed 1=increment 2=decrement 3=continuousIncr
			#                4=continuousDecr 5=random
			set vlanCountMode [vlan cget -mode $chassis $card $portNumber $streamId]
			set vlanCountStep [vlan cget -step $chassis $card $portNumber $streamId]
			append portConfigs($port,$streamId,vlanID) ""
			append portConfigs($port,$streamId,vlanID) " vlanId $vlanId"
			append portConfigs($port,$streamId,vlanID) " vlanPriority $vlanPriority"
		        append portConfigs($port,$streamId,vlanID) " vlanCount $vlanRepeat"
			append portConfigs($port,$streamId,vlanID) " vlanCountMode $vlanCountMode"
			append portConfigs($port,$streamId,vlanID) " vlanCountStep $vlanCountStep"
		    }
		}
	    }
	}
    }
}

if {[info exists portConfigs]} {
    parray portConfigs
} else {
    puts "\nLooks like your IxExplorer ports $portList don't have any configurations. Please verify.\n"
    exit
}



if 0 {
stream get 1 1 2 1
vlan get 1 1 2
catch {vlan cget} vlanMsg
puts "\nvlan cget: $vlanMsg\n"

catch {stream cget -da} streamMsg
puts "\nstream cget: $streamMsg\n"

catch {port cget} portMsg
puts "\nport cget: $portMsg\n"

stream get 1 1 1 1
catch {protocol cget} protocolMsg
showCmd protocol
puts "\nprotocol 1/1/1 cget: $protocolMsg\n"

stream get 1 1 2 2
catch {protocol cget} protocolMsg
showCmd protocol
puts "\nprotocol 1/1/2 cget: $protocolMsg\n"

#exit

catch {interfaceIpV4 cget} interfaceIpv4
puts "\ninterfaceIpV4 cget: $interfaceIpv4\n"
}

stream get 1 1 1 1
catch {ip get 1 1 1} ipMsg
puts "\nip cget 1/1/1 1: $ipMsg\n"
puts "\nsrcIpAddress: [ip cget -sourceIpAddr 1 1 1 1]\n"
puts "dstIpAddress: [ip cget -destIpAddr 1 1 1 1]\n"
puts "srcIpMask: [ip cget -sourceIpMask 1 1 1 1]"
puts "srcIpRepeatCount: [ip cget -sourceIpAddrRepeatCount 1 1 1 1]"
# AddrMode 1=incrementHost 2=decrementHost  3=continuousIncrementHost 
#          4=continuousDecrementHost   5=incrementNetwork  6=decrementNetwork
#          7=continuousIncrementNetwork 8=continuousDecrementNetwork
puts "srcIpAddrMode: [ip cget -sourceIpAddrMode 1 1 1 1]"
# sourceClass 0=Class_A  1=Class_B   2=Class_C
puts "srcIpClass: [ip cget -sourceClass 1 1 1 1]"
puts "dstIpMask: [ip cget -destIpMask 1 1 1 1]"
puts "dstIpRepeatCount: [ip cget -destIpAddrRepeatCount 1 1 1 1]"
puts "dstIpAddrMode: [ip cget -destIpAddrMode 1 1 1 1]"
puts "dstIpClass: [ip cget -destClass 1 1 1 1]"
#puts "ipProtocol 1/1/1 1: [ip cget -ipProtocol 1 1 1 1]"


stream get 1 1 2 1
catch {ipV6 get 1 1 2} ipMsg
puts "\nipV6 cget 1/1/2 1: $ipMsg\n"
puts "ipv6 srcIpAddress: [ipV6 cget -sourceAddr 1 1 2 1]"
puts "ipv6 dstIpAddress: [ipV6 cget -destAddr 1 1 2 1]"
puts "ipv6 srcIpRepeatCount: [ipV6 cget -sourceAddrRepeatCount 1 1 2 1]"
# AddrMode  0=fixed 5=incrementInterfaceId  6=decrementInterfaceId
puts "ipv6 srcIpAddrMode: [ipV6 cget -sourceAddrMode 1 1 2 1]"
puts "ipv6 srcIpClass: [ipV6 cget -trafficClass 1 1 2 1]"

showCmd ipV6


catch {tcp cget} tcpMsg
puts "\ntcp cget: $tcpMsg\n"

catch {udp cget} udpMsg
puts "\nudp cget: $udpMsg\n"

catch {icmp cget} icmpMsg
puts "\nicmp cget: $icmpMsg\n"

catch {dhcp cget} dhcpMsg
puts "\ndhcp cget: $dhcpMsg\n"

catch {showCmd stream} showMsg
puts "\nshowCmd stream: $showMsg\n"

catch {showCmd ip} showIpMsg
puts "\nshowCmd ip: $showIpMsg\n"

catch {showCmd interfaceIpV4} showInterfaceIpV4Msg
puts "\nshowCmd interfaceIpV4: $showInterfaceIpV4Msg\n"

catch {showCmd port} showPortMsg
puts "\nshowCmd port: $showPortMsg\n"

catch {showCmd config} showConfigMsg
puts "\nshowCmd config: $showConfigMsg\n"


#exit


proc MapPortToVport { vPort port } {
    puts "\nMapping $port --> $vPort ..."
    ixNet setAttribute $vPort \
	-connectedTo $port
    ixNet commit
}

proc ConfigVportRootLevel { vPort name } {
    ixNet setMultiAttrs $vPort \
	-connectedTo ::ixnet::OBJ-null \
	-name $name \
	-txMode interleaved \
	-type ethernet
    ixNet commit
}

proc ConfigTrafficItem { object name {type oneToOne} } {
    # Type could be fullyMesh also

    puts "\nInitiating $type traffic item: $name ..."

    ixNet setMultAttrs $object \
	-enabled True \
	-name $name \
	-routeMesh oneToOne \
	-srcDestmesh oneToOne \
	-trafficType ipv4 \
	-transmitMode interleaved \
	-trafficItemType quick \
	-trafficType raw
    ixNet commit
}

proc ConfigInterface { object mtu } {
    puts "\nEnabling interface: $object ..."
    ixNet setMultiAttrs $object \
	-enabled True \
	-mtu $mtu

    ixNet commit
}

proc ConfigInterfaceSrcMac { object port } {
    scan $port "%d/%d" card port
    set srcMac [format "00:%02x:%02x:00:00:01" $card $port]

    puts "\nConfiguring srcMac $srcMac on $object ..."
    ixNet setMultiAttrs $object/ethernet \
	-macAddress $srcMac
    
    ixNet commit
}

proc ConfigInterfaceIpv4 { object ip gateway mask } {
    puts "\nIP = $ip ; mask = $mask ; gateway = $gateway"
    ixNet setMultiAttrs $object \
	-gateway $gateway \
	-ip $ip \
	-maskWidth $mask

    ixNet commit
}

proc ConfigFrameSize { object frameSize } {
    puts "\nFrame size = $frameSize on $object ..."
    ixNet setMultiAttrs $object/frameSize \
	-fixedSize $frameSize \
	-type fixed
    ixNet commit 
}

proc ConfigLineRate { object rate } {
    puts "\nFrame rate = $rate on $object ..."
    ixNet setMultiAttrs $object/frameRate \
	-rate $rate \
	-type percentLineRate
    ixNet commit
}

proc ConfigPacketBurst { object frameCount } {
    puts "\nFrame count = $frameCount on $object ..."
    ixNet setMultiAttrs $object/transmissionControl \
	-duration 1 \
	-interationCount 1 \
	-frameCount $frameCount \
	-type fixedFrameCount \
	-repeatBurst 1 \
	-bursePacketCount 1
    ixNet commit
}

proc ConfigEndpoints { object srcEndpoints dstEndpoints } {
    puts "\nSrcEndpoint = $srcEndpoints"
    puts "\nDstEndpoints = $dstEndpoints"

    ixNet setMultiAttrs $object \
	-destinations $dstEndpoints \
	-sources $srcEndpoints
    ixNet commit
}

proc TrackBy { object trackings } {
    puts "\nTracking traffic by: $trackings ..."
    ixNet setAttribute $object/tracking -trackBy $trackings 
    ixNet commit
}

# Flow tracking
proc ConfigFlowTracking { object flowTrackBy } {
    puts "\nFlow Tracking = $flowTrackBy ..."
    ixNet setAttribute $object/transmissionDistribution \
	-distributions $flowTrackBy
    ixNet commit
}

proc ConfigMacAddress { object mac } {
    puts "\nConfigMacAddress: $mac ; $object ..."
    ixNet setMultiAttrs $object \
	-randomMask {00:00:00:00:00:00} \
	-optionalEnabled True \
	-auto False \
	-seed {1} \
	-activeFieldChoice False \
	-countValue 1 \
	-trackingEnabled False \
	-startValue $mac \
	-fieldValue {00:00:00:00:00:00} \
	-fixedBits {00:00:00:00:00:00} \
	-fullMesh False \
	-valueType $mac \
	-singleValue $mac \
	-stepValue 1 \
	-valueList {}
    ixNet commit
}

proc ConfigIpAddress { object params } {
    puts "\nConfigIpAddress: $object ; $params ...\n"
    
    # IPv4
    # sourceClass 0=Class_A  1=Class_B   2=Class_C
    #
    # AddrMode 0=fixed 1=incrementHost 2=decrementHost  3=continuousIncrementHost 
    #          4=continuousDecrementHost   5=incrementNetwork  6=decrementNetwork
    #          7=continuousIncrementNetwork 8=continuousDecrementNetwork

    # IPv6
    # SourceAddrMode  0=fixed 5=incrementInterfaceId  6=decrementInterfaceId    

    if {[lsearch $params sourceAddr] == -1 && [lsearch $params destAddr] == -1} {
	set ipProtocol ipv4
    } else {
	set ipProtocol ipv6
    }

    # IPv4
    if {$ipProtocol == "ipv4"} {
	if {[lsearch $params sourceIpAddrMode] != -1} {
	    set index [lsearch $params sourceIpAddrMode]
	    set mode [lindex $params [expr $index + 1]]
	}
	if {[lsearch $params destIpAddrMode] != -1} {
	    set index [lsearch $params destIpAddrMode]
	    set mode [lindex $params [expr $index + 1]]
	}

	if {$mode == 0} {
	    set mode singleValue
	    set ipAddrMode singleValue
	}
	if {$mode == 1} {
	    set mode incrementHost
	    set ipAddrMode increment
	}
	if {$mode == 2} {
	    set mode decrementHost
	    set ipAddrMode decrement
	}
	if {$mode == 3} {
	    set mode incrementHost
	    set ipAddrMode increment
	}
	if {$mode == 4} {
	    set mode decrementHost
	    set ipAddrMode decrement
	}
	if {$mode == 5} {
	    set mode incrementNetwork
	    set ipAddrMode increment
	}
	if {$mode == 6} {
	    set mode decrementNetwork
	    set ipAddrMode decrement
	}
	if {$mode == 7} {
	    set mode incrementNetwork
	    set ipAddrMode increment
	}
	if {$mode == 8} {
	    set mode decrementNetwork
	    set ipAddrMode decrement
	}
    }

    # IPv6
    if {$ipProtocol == "ipv6"} {
	if {[lsearch $params sourceAddrMode] != -1} {
	    set index [lsearch $params sourceAddrMode]
	    set mode [lindex $params [expr $index + 1]]
	}
	if {[lsearch $params destAddrMode] != -1} {
	    set index [lsearch $params destAddrMode]
	    set mode [lindex $params [expr $index + 1]]
	}

	if {$mode == 0} {
	    set mode singleValue
	    set ipAddrMode singleValue
	}
	if {$mode == 5} {
	    set mode increment
	    set ipAddrMode increment
	}
	if {$mode == 6} {
	    set mode decrement
	    set ipAddrMode decrement
	}
	if {$mode == 7} {
	    set mode increment
	    set ipAddrMode increment
	}
	if {$mode == 8} {
	    set mode decrement
	    set ipAddrMode decrement
	}
	if {$mode == 9} {
	    set mode increment
	    set ipAddrMode increment
	}
	if {$mode == 10} {
	    set mode decrement
	    set ipAddrMode decrement
	}
	if {$mode == 11} {
	    set mode increment
	    set ipAddrMode increment
	}
	if {$mode == 12} {
	    set mode decrement
	    set ipAddrMode decrement
	}
	if {$mode == 13} {
	    set mode increment
	    set ipAddrMode increment
	}
	if {$mode == 14} {
	    set mode decrement
	    set ipAddrMode decrement
	}
	
	if {$mode == 15} {
	    set mode increment
	    set ipAddrMode increment
	}
	if {$mode == 16} {
	    set mode decrement
	    set ipAddrMode decrement
	}
    }

    set ipAddrStepSize 1
    set ipAddrRepeatCount 1

    set argIndex 0
    while {$argIndex < [llength $params]} {
	set currentArg [lindex $params $argIndex]
	switch -exact -- $currentArg { 
	    sourceIpAddr {
		set ipAddr [lindex $params [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    sourceIpAddrRepeatCount {
		set ipAddrRepeatCount [lindex $params [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    sourceIpAddrMode {
		incr argIndex 2
	    }
	    sourceClass {
		set class [lindex $params [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    destIpAddr {
		set ipAddr [lindex $params [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    destIpAddrRepeatCount {
		set ipAddrRepeatCount [lindex $params [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    destIpAddressMode {
		set ipAddressMode [lindex $params [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    destIpAddrMode {
		incr argIndex 2
	    }
	    destClass {
		set class [lindex $params [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    sourceAddr {
		# IPv6
		set ipAddr [lindex $params [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    sourceAddrRepeatCount {
		# IPv6
		set ipAddrRepeatCount [lindex $params [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    sourceAddrMode {
		# IPv6
		incr argIndex 2
	    }
	    sourceStepSize {
		# IPv6
	     	set ipAddrStepSize [lindex $params [expr $argIndex + 1]]
	    	incr argIndex 2
	    }
	    trafficClass {
		# IPv6
		set class [lindex $params [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    stepValue {
		# IPv6
		set stepValue [lindex $params [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    destAddr {
		# IPv6
		set ipAddr [lindex $params [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    destAddrRepeatCount {
		# IPv6
		set ipAddrRepeatCount [lindex $params [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    destAddrMode {
		# IPv6
		incr argIndex 2
	    }
	    destStepSize {
		# IPv6
	     	set ipAddrStepSize [lindex $params [expr $argIndex + 1]]
	    	incr argIndex 2
	    }
	    default {
		puts "\nERROR: No such parameter: $currentArg\n"
		exit
	    }
	}
    }

    set startValue $ipAddr

    # Set the defaults first
    if {$ipProtocol == "ipv4"} {
	set stepValue 0.0.0.1
    }

    if {$ipProtocol == "ipv6"} {
	set stepValue 0::1
    }
    
    if {$mode != "singleValue"} {
	if {$ipProtocol == "ipv4"} {
	    if {[lsearch $params sourceIpAddr] != -1} {
		# sourceClass 0=Class_A  1=Class_B   2=Class_C
		if {$class == 0} {
		    set stepValue 0.1.0.0
		}
		if {$class == 1} {
		    set stepValue 0.0.1.0
		}
		if {$class == 2} {
		    set stepValue 0.0.0.1
		}
	    }
	    
	    if {[lsearch $params destIpAddr] != -1} {
		# sourceClass 0=Class_A  1=Class_B   2=Class_C
		if {$class == 0} {
		    set stepValue 0.1.0.0
		}
		if {$class == 1} {
		    set stepValue 0.0.1.0
		}
		if {$class == 2} {
		    set stepValue 0.0.0.1
		}
	    }
	}

	if {$ipProtocol == "ipv6"} {
	    if {[info exists ipAddrStepSize]} {
		set stepValue 0::$ipAddrStepSize
	    }
	}
    }

    # singleValue == 0.0.0.0
    # startValue == 0.0.0.0 ; Specifiy the initial value for increment/decrement
    # stepValue == 0.0.0.0
    # valueType = fixed, increment, decrement, random, valueList
    # countValue = 1
    # 
    puts "\nConfigIpAddress: ipAddrRepeatCount = $ipAddrRepeatCount startValue = $startValue ipAddr = $ipAddr stepValue = $stepValue  valueType = $ipAddrMode \n"

    ixNet setMultiAttrs $object \
	-randomMask {0.0.0.0} \
	-optionalEnabled True \
	-auto False \
	-seed {1} \
	-activeFieldChoice False \
	-countValue $ipAddrRepeatCount \
	-trackingEnabled False \
	-startValue $startValue \
	-fieldValue $ipAddr \
	-fixedBits {00:00:00:00:00:00} \
	-fullMesh False \
	-valueType $ipAddrMode \
	-singleValue $ipAddr \
	-stepValue $stepValue \
	-valueList {}
    ixNet commit
}

proc ConfigIpAddress_backup { object ip } {
    puts "\nConfigIpAddress: $ip ; $object ..."
    ixNet setMultiAttrs $object \
	-randomMask {0.0.0.0} \
	-optionalEnabled True \
	-auto False \
	-seed {1} \
	-activeFieldChoice False \
	-countValue 1 \
	-trackingEnabled False \
	-startValue $ip \
	-fieldValue $ip \
	-fixedBits {00:00:00:00:00:00} \
	-fullMesh False \
	-valueType singleValue \
	-singleValue $ip \
	-stepValue 1 \
	-valueList {}
    ixNet commit
}

proc ConfigVlan { object params } {

    set vlanStepCount 1
    set vlanPriority 0
    set vlanCount 1
    set vlanMode singleValue
    set vlanCountStep 1

    set argIndex 0
    while {$argIndex < [llength $params]} {
	set currentArg [lindex $params $argIndex]
	switch -exact -- $currentArg { 
	    vlanId {
		set vlanId [lindex $params [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    vlanPriority {
		set vlanPriority [lindex $params [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    vlanCount {
		set vlanCount [lindex $params [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    vlanCountMode {
		set vlanMode [lindex $params [expr $argIndex + 1]]
		incr argIndex 2

		# vlanCountMode: 0=fixed 1=increment 2=decrement 3=continuousIncr
		#                4=continuousDecr 5=random
		if {$vlanMode == 0} {
		    set vlanMode singleValue
		}
		if {$vlanMode == 1} {
		    set vlanMode increment
		}
		if {$vlanMode == 2} {
		    set vlanMode decrement
		}
		if {$vlanMode == 3} {
		    # IxExplorer has continuous incremement
		    # but IxNetwork doesn't. Setting it to increment.
		    set vlanMode increment
		}
		if {$vlanMode == 4} {
		    # IxExplorer has continuous decremement
		    # but IxNetwork doesn't. Setting it to decrement.
		    set vlanMode decrement
		}
		if {$vlanMode == 5} {
		    set vlanMode random
		}
	    }
	    vlanCountStep {
		set vlanCountStep [lindex $params [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    default {
		puts "\nConfigVlan: No such parameter: $currentArg\n"
	    }
	}
    }

    puts "\nConfigVlan: $object\nvlanId=$vlanId vlanPriority=$vlanPriority vlanCount=$vlanCount vlanMode=$vlanMode vlanCountStep=$vlanCountStep"
    
    ixNet setMultiAttrs $object \
	-randomMask $vlanId \
	-optionalEnabled True \
	-auto False \
	-seed {1} \
	-activeFieldChoice False \
	-countValue $vlanCount \
	-trackingEnabled False \
	-startValue $vlanId \
	-fieldValue $vlanId \
	-fixedBits $vlanId \
	-fullMesh False \
	-valueType $vlanMode \
	-singleValue $vlanId \
	-stepValue $vlanCountStep \
	-valueList {}
    ixNet commit

    if {$vlanPriority != "0"} {
	set vlanPriorityObject [string map {" " .} [lreplace [split $object .] end end vlanUserPriority-1\"]]

	ixNet setMultiAttr $vlanPriorityObject \
	    -singleValue $vlanPriority \
	    -fieldValue $vlanPriority
	ixNet commit
    }
}

proc ClearPortOwnership { PortList } {
    after 3000
    set flag 0
    foreach Port $PortList {
	set cardNumber [lindex [split $Port /] 0]
	set portNumber [lindex [split $Port /] 1]
	
	catch {ixNet execute clearOwnership $::ixChassis/card:$cardNumber/port:$portNumber} errMsg

	if {$errMsg != "::ixNet::OK"} {
	    set flag 1
	    puts "\nClearPortOwnership: Failed on $Port\n$errMsg\n"
	}
	puts "\nClearPortOwnership: $Port ; $errMsg"
	after 2000
    }
    if {$flag == 1} {
	exit
    }
}

proc ShowCurrentProtocolStack { TrafficItemElement } {
    puts \n
    foreach protocol [ixNet getList $TrafficItemElement stack] {
	puts "Current Stack: $protocol"
    }
    puts \n
}

proc IsThereProtocolStack { TrafficItemElement Protocol } {
    # ::ixNet::OBJ-/traffic/trafficItem:1/highLevelStream:1/stack:"ethernet-1"
    # ::ixNet::OBJ-/traffic/trafficItem:1/highLevelStream:1/stack:"vlan-2"
    # ::ixNet::OBJ-/traffic/trafficItem:1/highLevelStream:1/stack:"fcs-3"
    set flag 0
    foreach protocol [ixNet getList $TrafficItemElement stack] {
	set protocol [lindex [split [lindex [split $protocol \"] 1] -] 0]
	# TODO: Need to do an exact look up especially for ipv6 because
	#       ipv6 has something like ipv6Authentication and such alikes.
	if {$protocol == $Protocol} {
	    set flag 1
	}
    }
    if {$flag == 0} {
	return 0
    } else {
	return 1
    }
}

ixNet connect $ixNetworkTclServer -port 8009 -version $ixNetworkVersion
ixNet execute newConfig
set myRoot [ixNet getRoot]

set ixChassis [ixNet add $myRoot/availableHardware chassis]
ixNet setAttribue $ixChassis -hostname $ixChassisIp
ixNet commit
set ::ixChassis [lindex [ixNet remapIds $ixChassis] 0]

ClearPortOwnership $portList

# Create total number of vports equaling to all the ports in the $portList
for {set vPortNumber 1} {$vPortNumber <= [llength $portList]} {incr vPortNumber} {
    # Example: set vPort1 [ixNet add $myRoot vport]
    set vPort$vPortNumber [ixNet add $myRoot vport]
}
ixNet commit

# Get the the list of all the vports
set vPortList [ixNet getList [ixNet getRoot] vport]

set cardNumberList {}
foreach vPort $vPortList actualPort $portList {
    scan $actualPort "%d/%d/%d" chassis cardNumber portNumber

    # We just want to add the card once.
    if {[lsearch $cardNumberList $cardNumber] == -1} {
	set card [ixNet add $ixChassis card]
	ixNet commit
	lappend cardNumberlist $cardNumber
    }
    
    MapPortToVport $vPort $::ixChassis/card:$cardNumber/port:$portNumber
    ConfigVportRootLevel $vPort $cardNumber/$portNumber

    # For Quick Flow, must create a vport/protocol because
    # vport/interface:1 doesn't work for EndPoint configuration.
    set vPortProtocolMapping($actualPort) [ixNet add $vPort protocols]
}

parray vPortProtocolMapping

ixNet setMultiAttrs $myRoot/globals/interfaces \
    -arpOnLinkup False \
    -sendSingleArpPerGateway False
ixNet commit

set trafficItem [ixNet add $myRoot/traffic trafficItem]
ConfigTrafficItem $trafficItem "TrafficItem stream 1" oneToOne
set trafficItem [lindex [ixNet remapIds $trafficItem] 0]

ConfigFlowTracking $trafficItem srcDestEndpointPair0
TrackBy $trafficItem {{sourceDestEndpointPair0} {trackingenabled0}}

set incrFlow 0
foreach {actualPort virtualPort} [array get vPortProtocolMapping *] { 
    # verify portConfigs on the port for stream existence
    if {[array name portConfigs $actualPort,*] != ""} {
	set streamCounter {}
	foreach {portStreamAttribute value} [array get portConfigs $actualPort,*,*] {
	    set strmId [lindex [split $portStreamAttribute ,] 1]
	    if {[lsearch $streamCounter $strmId] == -1} {
		lappend streamCounter $strmId
	    }
	}	
	
	set totalStreams [llength $streamCounter]

	if {[info exists streamAttributes]} {
	    unset streamAttributes
	}

	# Now get all the stream configurations for each stream
	for {set stream 1} {$stream <= $totalStreams} {incr stream} {
	    foreach {portStreamAttribute value} [array get portConfigs $actualPort,$stream,*] {
		set attribute [lindex [split $portStreamAttribute ,] end]
		lappend streamAttributes($stream) $attribute
	    }
	}

	set protocolTemplate [ixNet getList [ixNet getRoot]/traffic protocolTemplate]

	# Uncomment this foreach loop for viewing all protocol templates only.
	#foreach proto $protocolTemplate {
	#    puts "\t$proto"
	#}

	set ethernetIndex [lsearch -regexp $protocolTemplate ipv4]
	set ethernetProtocolTemplate [lindex $protocolTemplate $ethernetIndex]
	set vlanIndex [lsearch -regexp $protocolTemplate vlan]
	set vlanProtocolTemplate [lindex $protocolTemplate $vlanIndex]
	set ipv4Index [lsearch -regexp $protocolTemplate ipv4]
	set ipv4ProtocolTemplate [lindex $protocolTemplate $ipv4Index]
	set ipv6ProtocolTemplate ::ixNet::OBJ-/traffic/protocolTemplate:"ipv6"

	for {set streamId 1} {$streamId <= $totalStreams} {incr streamId} {
	    # For each stream will require an individual endpoint set
	    # State the source / destination endpoints
	    set endPointObject [ixNet add $trafficItem endpointSet]
	    
	    # ::ixNet::OBJ-/vport:1/protocols
	    # Since this is Quick Flow configuration to mimic IxExplorer,
	    # just create a source endpoint.
	    ixNet setMultiAttrs $endPointObject -sources $vPortProtocolMapping($actualPort)
	    ixNet commit	    
	    
	    # Create same number of trafficItem as to total streams found in IxExplorer
	    
	    set currentFlow [incr incrFlow]
	    set trafficItemElements $trafficItem/highLevelStream:$currentFlow

	    if {[info exists portConfigs($actualPort,$streamId,vlanID)]} {
		if {[IsThereProtocolStack $trafficItemElements vlan] == 0} {
		    catch {ixNet exec append $trafficItemElements/stack:\"ethernet-1\" $vlanProtocolTemplate} errMsg
		    puts "\nAppending vlan protocol stack for $actualPort streamId $streamId: $errMsg"
		}
	    }

	    # sourceIpAddr=ipv4   sourceAddr=ipv6
	    if {[info exists portConfigs($actualPort,$streamId,sourceIpAddr)]} {
		# IPv4
		if {[info exists portConfigs($actualPort,$streamId,vlanID)]} {
		    if {[IsThereProtocolStack $trafficItemElements ipv4] == 0} {
			catch {ixNet exec append $trafficItemElements/stack:\"vlan-2\" $ipv4ProtocolTemplate} errMsg
			puts "\nAppending IPv4 protocol stack on $actualPort stream $streamId: $errMsg"
			set ipv4StackNumber 3
		    }
		} else {
		    # Getting here means no vlan stack
		    if {[IsThereProtocolStack $trafficItemElements ipv4] == 0} {
			# If vlan is not going to be added, then append after ethernet stack
			catch {ixNet exec append $trafficItemElements/stack:\"ethernet-1\" $ipv4ProtocolTemplate} errMsg
			puts "\nAppending ipv4 protocol stack on $actualPort stream $streamId: $errMsg"
			set ipv4StackNumber 2
		    }
		}
	    }

	    if {[info exists portConfigs($actualPort,$streamId,sourceAddr)]} {
		# IPv6
		if {[info exists portConfigs($actualPort,$streamId,vlanID)]} {
		    if {[IsThereProtocolStack $trafficItemElements ipv6] == 0} {
			catch {ixNet exec append $trafficItemElements/stack:\"vlan-2\" $ipv6ProtocolTemplate} errMsg
			puts "\nAppending IPv6 protocol stack on $actualPort stream $streamId: $errMsg"
			set ipv6StackNumber 3
		    }
		} else {
		    # No vlan stack
		    if {[IsThereProtocolStack $trafficItemElements ipv6] == 0} {
			catch {ixNet exec append $trafficItemElements/stack:\"ethernet-1\" $ipv6ProtocolTemplate} errMsg
			puts "\nAppending IPv6 protocol stack on $actualPort stream $streamId: $errMsg"
			set ipv6StackNumber 2
		    }
		}
	    }

	    puts "\n**** port $actualPort stream $streamId: $streamAttributes($streamId) **** \n"

	    # Do a foreach on the stream attribute
	    foreach attributes $streamAttributes($streamId) {
		switch -exact $attributes {
		    sa {
			ConfigMacAddress $trafficItemElements/stack:\"ethernet-1\"/field:\"ethernet.header.sourceAddress-2\" [string map { " " :} $portConfigs($actualPort,$streamId,$attributes)]
		    }
		    da {
			ConfigMacAddress $trafficItemElements\/stack:\"ethernet-1\"/field:\"ethernet.header.destinationAddress-1\" [string map {" " :} $portConfigs($actualPort,$streamId,$attributes)]
		    }
		    vlanID {
			ConfigVlan $trafficItemElements\/stack:\"vlan-2\"/field:\"vlan.header.vlanTag.vlanID-3\" $portConfigs($actualPort,$streamId,$attributes)
		    }
		    sourceIpAddr {
			# For IPv4
			if {[info exists portConfigs($actualPort,$streamId,sourceIpAddr)]} {
			    #ConfigIpAddress $trafficItemElements\/stack:\"ipv4-$ipv4StackNumber\"/field:\"ipv4.header.srcIp-27\" [string map {" " :} $portConfigs($actualPort,$streamId,$attributes)]
			    ConfigIpAddress $trafficItemElements\/stack:\"ipv4-$ipv4StackNumber\"/field:\"ipv4.header.srcIp-27\" $portConfigs($actualPort,$streamId,$attributes)
			}
		    }
		    destIpAddr {
			# For IPv4
			if {[info exists portConfigs($actualPort,$streamId,destIpAddr)]} {
			    #ConfigIpAddress $trafficItemElements\/stack:\"ipv4-$ipv4StackNumber\"/field:\"ipv4.header.dstIp-28\" [string map {" " :} $portConfigs($actualPort,$streamId,$attributes)]
			    ConfigIpAddress $trafficItemElements\/stack:\"ipv4-$ipv4StackNumber\"/field:\"ipv4.header.dstIp-28\" $portConfigs($actualPort,$streamId,$attributes)
			}
		    }
		    sourceAddr {
			# For IPv6
			if {[info exists portConfigs($actualPort,$streamId,sourceAddr)]} {
			    #ConfigIpAddress $trafficItemElements\/stack:\"ipv6-$ipv6StackNumber\"/field:\"ipv6.header.srcIP-7\" [string map {" " :} $portConfigs($actualPort,$streamId,$attributes)]
			    ConfigIpAddress $trafficItemElements\/stack:\"ipv6-$ipv6StackNumber\"/field:\"ipv6.header.srcIP-7\" $portConfigs($actualPort,$streamId,$attributes)
			}
		    }
		    destAddr {
			# For IPv6
			if {[info exists portConfigs($actualPort,$streamId,destAddr)]} {
			    #ConfigIpAddress $trafficItemElements\/stack:\"ipv6-$ipv6StackNumber\"/field:\"ipv6.header.dstIP-8\" [string map {" " :} $portConfigs($actualPort,$streamId,$attributes)]
			    ConfigIpAddress $trafficItemElements\/stack:\"ipv6-$ipv6StackNumber\"/field:\"ipv6.header.dstIP-8\" $portConfigs($actualPort,$streamId,$attributes)
			}
		    }
		    framesize {
			ConfigFrameSize $trafficItemElements $portConfigs($actualPort,$streamId,$attributes)
		    }
		    percentPacketRate {
			ConfigLineRate $trafficItemElements $portConfigs($actualPort,$streamId,$attributes)
		    }
		    numFrames {
			ConfigPacketBurst $trafficItemElements $portConfigs($actualPort,$streamId,$attributes)
		    }
		    name {
			puts "\nConfiguring Flow Group $currentFlow name: $portConfigs($actualPort,$streamId,name)"
			ixNet setAttribute $trafficItemElements -name "$portConfigs($actualPort,$streamId,name)"
			ixNet commit
		    }
		    default {
			puts "ERROR!  No such IxTclHal Stream paramater: $attributes"
			exit
		    }
		}
	    }
	}
    }    
}
