#!/usr/bin/tclsh

namespace eval ::ixHlt {
    namespace export *

    variable ixNetworkTclServerIp 0
    variable pgidCounter 0
    variable hltParams {}
}

proc EnableHltDebug {} {
    # Creating a HLT debug log file in case debugging is needed
    set ::ixia::logHltapiCommandsFlag 1
    set ::ixia::logHltapiCommandsFileName ixiaHltDebug.txt
}

proc ::ixHlt::ConnectToTrafficGenerator { args } {
    variable portList
    variable ixNetworkTclServerIp
   
    set ::ixHlt::hltParams ""

    set argIndex 0
    while {$argIndex < [llength $args]} {
	set currentArg [lindex $args $argIndex]
	switch -exact -- $currentArg {
	    -ixChassisIp {
		set ixChassisIp [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-device $ixChassisIp"
		incr argIndex 2
	    }
	    -ixosTclServerIp {
		set ixosTclServerIp [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-tcl_server $ixosTclServerIp"
		incr argIndex 2
	    }
	    -ixNetworkTclServerIp {
		set ixNetworkTclServerIp [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-ixnetwork_tcl_server $ixNetworkTclServerIp"
		incr argIndex 2
	    }
	    -reset {
		set reset [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-reset"
		incr argIndex
	    }
	    -config_file {
		set ixncfgFile [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-config_file $ixncfgFile"
		incr argIndex 2
	    }
	    -session_resume_keys {
		# Choices: 0 or 1 for loading ixncfg file only.
		set sessionResumeKeys [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-session_resume_keys $sessionResumeKeys"
		incr argIndex 2
	    }
	    -userName {
		set userName [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-username $userName"
		incr argIndex 2
	    }
	    -portList {
		set portList [lindex $args [expr $argIndex + 1]]
		set allPorts {}
		# port_list format   = 1/1.  Not 1/1/1	
		# port_handle format = 1/1/1.  Not 1/1
		foreach port $portList {
		    lappend allPorts [string range $port 2 end]
		}
		AppendHltParams "-port_list $allPorts"
		incr argIndex 2
	    }
	    -interactive {
		set interactiveMode [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-interactive $interactiveMode"
		incr argIndex 2
	    }
	    default {
		::ixHlt::IxLog -error "No such parameter: $currentArg"
		exit
	    }
	}
    }

    if {[info exists ixosTclServerIp] == 0} {
	set ixosTclServerIp $ixChassisIp
    }

    set allPorts {}
    # port_list format   = 1/1.  Not 1/1/1	
    # port_handle format = 1/1/1.  Not 1/1
    foreach port $portList {
     	lappend allPorts [string range $port 2 end]
    }

    # Verify if user is loading an ixncfg file. If yes, make sure
    # user didn't include the -reset parameter. Remove it for user.
    if {[info exists ixncfgFile] == 1 && [lsearch $::ixHlt::hltParams -reset] != -1} {
	set resetParamIndex [lsearch $::ixHlt::hltParams -reset]
	set ::ixHlt::hltParams [lreplace $::ixHlt::hltParams $resetParamIndex $resetParamIndex]
    }

    if {$ixNetworkTclServerIp == 0} {
	::ixHlt::IxLog -info "Starting IxOS connection ..."
	# Connect to the chassis, reset to factory defaults and take ownership
	set connect_status [eval ::ixia::connect $::ixHlt::hltParams]
    }
    
    if {$ixNetworkTclServerIp != 0} {
	::ixHlt::IxLog -info "Starting IxNetwork Tcl Server connection on $portList ..."
	if {[lsearch $::ixHlt::hltParams -reset] != -1} {
	    ::ixHlt::IxLog -info "Please wait 40 seconds while ports are rebooting ..."
	}
	# Connect to the chassis, reset to factory defaults and take ownership
	set connect_status [eval ::ixia::connect $::ixHlt::hltParams]
    }

    # ::connect_status: connect_status = {port_handle {{10 {{205 {{4 {{35 {{1/1 1/1/1} {1/2 1/1/2}}}}}}}}}}} {vport_list {1/1/1 1/1/2}} {status 1}
    
    if {[keylget connect_status status] != $::SUCCESS} {
        ::ixHlt::IxLog -noTimeStamp [KeylPrint connect_status]
	::ixHlt::IxLog -abort "ConnectToTrafficGeneratorHltIxia: FAILED"
    }

    foreach port $portList {
	scan [split $port /] "%d %d %d" chassis slot portNumber
	port get $chassis $slot $portNumber
	lappend ixiaPortAndSpeedList "$port [port cget -speed]"
	lappend ixiaPortListSpeed "[port cget -speed]"
    }
    
    ::ixHlt::IxLog -info "Port/speed: $ixiaPortAndSpeedList"
    ::ixHlt::IxLog -info "ConnectToTrafficGeneratorHlt: Connected to Ixia chassis $ixChassisIp"
    #    ResetPorts $port_list
    return $connect_status
}

proc ::ixHlt::InterfaceConfig { args } {
    if {[info exists ::ixHlt::userDefinedParams]} {
	unset ::ixHlt::userDefinedParams
    }

    set ::ixHlt::hltParams ""

    set argIndex 0
    while {$argIndex < [llength $args]} {
	set currentArg [lindex $args $argIndex]
	switch -exact -- $currentArg {
	    -mode {
		set mode [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-mode $mode"
	    }
	    -port_handle {
		set portHandle [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-port_handle [list $portHandle]"
	    }
	    -intf_ip_addr {
		set ipAddress [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-intf_ip_addr [list $ipAddress]"
	    }
	    -gateway {
		set gateway [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-gateway [list $gateway]"
	    }
	    -netmask {
		set netmask [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-netmask [list $netmask]"
	    }
	    -src_mac_addr {
		set macAddress [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-src_mac_addr [list $macAddress]"
	    }
	    -connected_count {
		set totalIpAddress [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-intf_ip_addr_step 0.0.0.1 -gateway_step 0.0.0.0 -src_mac_addr_step 0000.0000.0001 -connected_count $totalIpAddress"
	    }
	    -autonegotiation {
		# No value required
		AppendHltParams" -autonegotiation 1"
		incr argIndex
	    }
	    -speed {
		# Choices: ether10 ether100 ether1000 ether40Gig ether100Gig
		#          ether1000lan ether4000lan ether100000lan auto
		set portSpeed [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-speed $portSpeed"
		incr argIndex 2
	    }
	    -duplex {
		set portDuplex [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-duplex $portduplex"
		incr argIndex 2
	    }
	    -port_rx_mode {
		# Options: auto_detect_autoinstrumentation data_integrity sequence_checking
		#          wide_packet_group capture packet_group
		set portRxMode [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-port_rx_mode $portRxMode"
		incr argIndex 2
	    }
	    -pgid_offset {
		set pgidOffset [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-pgid_offset $pgidOffset"
		incr argIndex 2
	    }
	    -signature_offset {
		set signatureOffset [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-signature_offset $signatureOffset"
		incr argIndex 2
	    }
	    -signature {
		set signature [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-signature $signature"
		incr argIndex 2
	    }
	    -phy_mode {
		# Choices: copper or fiber
		set phyMode [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-phy_mode $phyMode"
		incr argIndex 2
	    }
	    -arp_send_req {
		set sendArpReq [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-arp_send_req $sendArpReq"
		incr argIndex 2
	    }
	    -arp_req_retries {
		set arpReqRetries [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-arp_req_retries $arpReqRetries"
		incr argIndex 2
	    }
	    -arp_req_timer {
		set arpReqTimer [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-arp_req_timer $arpReqTimer"
		incr argIndex 2
	    }
	    -no_write {
		# Just a FLAG
		AppendHltParams "-no_write"
		incr argIndex
	    }
	    -sequence_checking {
		set sequenceChecking [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-sequence_checking $sequenceChecking"
		incr argIndex 2
	    }
	    -sequence_num_offset {
		set sequenceNumOffset [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-sequence_num_offset $sequenceNumOffset"
		incr argIndex 2		
	    }
	    -data_integrity {
		set dataIntegrity [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-data_integrity $dataIntegrity"
		incr argIndex 2
	    }
	    -integrity_signature {
		set integritySignature [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-integrity_signature $integritySignature"
		incr argIndex 2
	    }
	    -integrity_signature_offset {
		set integritySignatureOffset [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-integrity_signature_offset $integritySignatureOffset"
		incr argIndex 2
	    }
	    -intf_mode {
		# Choices: ethernet cisco arp ethernet_fcoe fc bert
		set intfMode [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-intf_mode $intfMode"
		incr argIndex 2		
	    }
	    default {
		::ixHlt::IxLog -abort "ConfigL3Int: No such parameter: $currentArg"
	    }
	}
    }

    set interfaceConfigStatus [eval ::ixia::interface_config $::ixHlt::hltParams]

    if {[keylget interfaceConfigStatus status] != $::SUCCESS} {
	::ixHlt::IxLog -error "Failed to configure L3 interface on $portHandle. \
        \n\t[KeylPrint interfaceConfigStatus]"
    } else {
	::ixHlt::IxLog -info "ConfigL3Int: Successfully configured $portHandle"
	::ixHlt::IxLog -noTimeStamp \n[parray ::ixHlt::userDefinedParams]
    }

    # Need to return interfaceConfigStatus for IxNetwork only.
    # Consist of vport/interfaces for configuring endpoints on trafficItems
    if {$::ixHlt::ixNetworkTclServerIp != 0} {
	return [keylget interfaceConfigStatus interface_handle]
    }
}

proc ::ixHlt::TrafficConfig { args } {
    # The variable userDefinedParams is an array that 
    # gets built in Proc AppendHltParams
    if {[info exists ::ixHlt::userDefinedParams]} {
	unset ::ixHlt::userDefinedParams
    }

    set ::ixHlt::hltParams ""
    set argIndex 0

    while {$argIndex < [llength $args]} {
	set currentArg [lindex $args $argIndex]
	switch -exact -- $currentArg {
	    -mode {
		# create | modify
		set mode [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-mode $mode"
	    }
	    -port_handle {
		set portHandle [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-port_handle $portHandle"
	    }
	    -port_handle2 {
		set portHandle2 [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-port_handle2 $portHandle2"
	    }
	    -emulation_src_handle {
		set srcEndpoint [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-emulation_src_handle $srcEndpoint"
	    }
	    -emulation_dst_handle {
		set dstEndpoint [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-emulation_dst_handle $dstEndpoint"
	    }
	    -stream_id {
		set streamId [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-stream_id $streamId"
	    }
	    -pgid_offset {
		set pgidOffset [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-pgid_offset $pgidOffset"
	    }
	    -pgid_value {
		set pgidValue [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-pgid_value $pgidValue"
	    }
	    -signature_offset {
		set signatureOffset [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-signature_offset $signatureOffset"
	    }
	    -signature {
		set signature [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-signature $signature"
	    }
	    -track_by {
		set trackBy [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-track_by $trackBy"
	    }
	    -name {
		set trafficItemName [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-name $trafficItemName"
	    }
	    -src_dest_mesh {
		set srcDestMesh [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-srcDestMesh $srcDestMesh"
	    }
	    -circuit_endpoint_type {
		# Choices: ipv4 ipv6
		set circuitEndpointType [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-circuitEndpointType $circuitEndpointType"
	    }
	    -circuit_type {
		# Choices: raw l2vpn l3vpn mpls 6pe 6vpe vpls stp mac_in_mac
		#          quick_flows none
		set circuitType [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-circuit_type $circuitType"
	    }
	    -bidirectional {
		# Choices: 0 or 1
		set biDirectional [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-bidirectional $biDirectional"
	    }
	    -frame_size {
		set frameSize [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-frame_size $frameSize"
	    }
	    -rate_percent {
		set ratePercent [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
		AppendHltParams "-rate_percent $ratePercent"
	    }
	    -signature_offset {
		set signatureOffset [lindex $args [expr $argIndex + 1]]
		AppendHltParams" -signature_offset $signatureOffset"
		incr argIndex 2
	    }
	    -mac_dst_mode {
		# increment, fixed
		set macDstMode [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-mac_dst_mode $macDstMode"  
		incr argIndex 2
	    }
	    -mac_dst {
		# Value = discovery or mac address
		set destMac [lindex $args [expr $argIndex + 1]]
		if {$destMac == "discovery"} {
		    AppendHltParams "-mac_dst_mode $destMac"
		} else {
		    AppendHltParams "-mac_dst $destMac"
		}
		incr argIndex 2
	    }
	    -mac_dst_count {
		set macDstCount [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-mac_dst_count $macDstCount"
		incr argIndex 2
	    }
	    -mac_dst_step {
		# -mac_dst_step 0000.0000.0001
		set macDstStep [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-mac_dst_step $macDstStep"  
		incr argIndex 2
	    }
	    -mac_src {
		set srcMac [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-mac_src $srcMac"  
		incr argIndex 2
	    }
	    -mac_src_mode {
		# increment, fixed
		set macSrcMode [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-mac_src_mode $macSrcMode"  
		incr argIndex 2
	    }
	    -mac_src_count {
		set srcMacTotal [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-mac_src_count $srcMacTotal"  
		incr argIndex 2
	    }
	    -mac_src_step {
		# -mac_src_step 0000.0000.0001
		set macSrcStep [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-mac_src_step $macSrcStep"  
		incr argIndex 2
	    }
	    -ip_src_addr {
		set srcIp [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-ip_src_addr $srcIp" "-l3_protocol ipv4"
		incr argIndex 2
	    }
	    -ip_src_count {
		set srcIpTotal [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-ip_src_mode increment -ip_src_step 0.0.0.1 \
                       -ip_src_count $srcIpTotal"
		incr argIndex 2
	    }
	    -ip_src_step {
		set ipSrcStep [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-ip_src_step $ipSrcStep"
		incr argIndex 2
	    }
	    -ip_dst_addr {
		set destIp [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-ip_dst_addr $destIp" "-l3_protocol ipv4"
		incr argIndex 2
	    }
	    -ip_dst_count {
		set destIpTotal [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-ip_dst_mode increment -ip_dst_step 0.0.0.1 \
                       -ip_dst_count $destIpTotal"
		incr argIndex 2
	    }
	    -transmit_mode {
		# single_burst, continuous, random_spaced
		# single_pkt, multi_burst, continuous_burst
		set transmitMode [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-transmit_mode $transmitMode"
		incr argIndex 2
	    }
	    -pkts_per_burst {
		set totalPackets [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-pkts_per_burst $totalPackets"
		incr argIndex 2
	    }
	    -enable_auto_detect_instrumentation {
		# Value must be 0 or 1
		set autoInstrumentation [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-enable_auto_detect_instrumentation $autoInstrumentation"
		incr argIndex 2
	    }
	    -sequence_checking {
		# Value must be 0 or 1
		set sequenceChecking [lindex $args [expr $argIndex + 1]]
		incr argIndex 2
	    }
	    -enable_data_integrity {
		set dataIntegrity 1
		AppendHltParams "-enable_data_integrity $dataIntegrity"
		incr argIndex 2
	    }
	    -integrity_signature {
		set integritySignature [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-integrity_signature $integritySignature"
		incr argIndex 2
	    }
	    -integrity_signature_offset {
		set integritySignatureOffset [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-integrity_signature_offset $integritySignatureOffset"
		incr argIndex 2
	    }
	    -frame_sequencing {
		set frameSequencing [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-frame_sequencing $frameSequencing"
		incr argIndex 2
	    }
	    -frame_sequencing_offset {
		set frameSequenceOffset [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-frame_sequencing_offset $frameSequenceOffset"
		incr argIndex 2
	    }
	    -ethernet_value {
		set ethernetValue [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-ethernet_value $ethernetValue"
		incr argIndex 2
	    }
	    -tcp_src_port {
		set tcpSrcPort [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-tcp_src_port $tcpSrcPort"
		incr argIndex 2
	    }
	    -tcp_dst_port {
		set tcpDstPort [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-tcp_dst_port $tcpDstPort"
		incr argIndex 2
	    }
	    -udp_src_port {
		set udpSrcPort [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-udp_src_port $udpSrcPort"
		incr argIndex 2
	    }
	    -udp_dst_port {
		set udpDstPort [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-udp_dst_port $udpDstPort"
		incr argIndex 2
	    }
	    -ip_dscp {
		set dscp [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-ip_dscp $dscp"
		incr argIndex 2		
	    }
	    -ip_precedence {
		# NOTE: -ip_precedence doesn't work if -ip_dscp is included.
		#       It must be either or
		set precedence [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-ip_precedence $precedence"
		incr argIndex 2		
	    }
	    -l3_protocol {
		# Choices: ipv4 ipv6 arp pause_control ipx none
		set l3Protocol [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-l3_protocol $l3Protocol"
		incr argIndex 2
	    }
	    -l4_protocol {
		# Choices: igmp igmp ip tcp gre
		set l4Protocol [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-l4_protocol $l4Protocol"
		incr argIndex 2
	    }
	    -vlan {
		# IxNetwork only. Choice: enable or disable
		set vlanEnable [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-vlan $vlanEnable"
		incr argIndex 2
	    }
	    -vlan_id {
		set vlanId [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-vlan_id $vlanId"
		incr argIndex 2
	    }
	    -vlan_user_priority {
		# 0-7
		set vlanUserPriority [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-vlan_user_priority $vlanUserPriority"
		incr argIndex 2
	    }
	    -vlan_id_tracking {
		# IxNetwork only: Choices: 0 or 1
		set vlanIdTracking [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-vlan_id_tracking $vlanIdTracking"
		incr argIndex 2
	    }
	    -vlan_protocol_tag_id {
		set vlanProtocolTagId [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-vlan_protocol_tag_id $vlanProtocolTagId"
		incr argIndex 2
	    }
	    -vlan_id_mode {
		set vlanIdMode [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-vlan_id_mode $vlanIdMode"
		incr argIndex 2
	    }
	    -vlan_id_step {
		set vlanIdStep [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-vlan_id_step $vlanIdStep"
		incr argIndex 2
	    }
	    -vlan_id_count {
		set vlanIdCount [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-vlan_id_count $vlanIdCount"
		incr argIndex 2
	    }
	    -vlan_cfi {
		set vlanCfi [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-vlan_cfi $vlanCfi"
		incr argIndex 2
	    }
	    -data_pattern_mode {
		set dataPatternMode [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-data_pattern_mode $dataPatternMode"
		incr argIndex 2
	    }
	    -data_pattern {
		set dataPattern [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-data_pattern $dataPattern"
		incr argIndex 2
	    }
	    -ethernet_type {
		set ethernetType [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-ethernet_type $ethernetType"
		incr argIndex 2
	    }
	    -fcs {
		set fcs [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-fcs $fcs"
		incr argIndex 2
	    }
	    -fcs_type {
		set fcsType [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-fcs_type $fcsType"
		incr argIndex 2
	    }
	    -length_mode {
		set lengthMode [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-length_mode $lengthMode"
		incr argIndex 2
	    }
	    -l3_length_min {
		set l3LengthMin [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-l3_length_min $l3LengthMin"
		incr argIndex 2
	    }
	    -l3_length_max {
		set l3LengthMax [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-l3_length_max $l3LengthMax"
		incr argIndex 2
	    }
	    -l3_length_step {
		set l3LengthStep [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-l3_length_step $l3LengthStep"
		incr argIndex 2
	    }
	    -l3_length {
		set l3Length [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-l3_length $l3Length"
		incr argIndex 2
	    }
	    -igmp_type {
		# Choices: membership_query membership_report  leave_group
		set igmpType [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-igmp_type $igmpType"
		incr argIndex 2
	    }
	    -igmp_version {
		# Choices: 1 2 or 3
		set igmpVersion [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-igmp_version $igmpVersion"
		incr argIndex 2
	    }
	    -igmp_group_addr {
		# IP
		set igmpGroupAddr [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-igmp_group_addr $igmpGroupAddr"
		incr argIndex 2
	    }
	    -igmp_record_type {
		# Choices: mode_is_include  mode_is_exclude  change_to_include_mode
		#          change_to_exclude_mode  allow_new_sources  block_old_sources
		set igmpRecordType [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-igmp_record_type $igmpRecordType"
		incr argIndex 2
	    }
	    -igmp_group_count {
		set igmpGroupCount [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-igmp_group_count $igmpGroupCount"
		incr argIndex 2		
	    }
	    -igmp_group_mode {
		# Choices: fixed  increment  decrement
		set igmpGroupMode [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-igmp_group_mode $igmpGroupMode"
		incr argIndex 2
	    }
	    -igmp_max_response_time {
		set igmpMaxResponseTime [lindex $args [expr $argIndex + 1]]
		AppendHltParams "-igmp_max_response_time $igmpMaxResponseTime"
		incr argIndex 2
	    }	    
	    default {
		::ixHlt::IxLog -abort "ConfigStream: No such parameter: $currentArg"
	    }
	}
    }

    ::ixHlt::IxLog -noTimeStamp \n[parray ::ixHlt::userDefinedParams]

    if {$::ixHlt::ixNetworkTclServerIp != 0} {
	set portHandle "$srcEndpoint $dstEndpoint" 
    }

    if {[lsearch $args "-name"] == -1 && $mode != "modify" && $mode != "append_header"} {
	AppendHltParams "-name Stream $streamId"
    }

    set trafficConfigStatus [eval ::ixia::traffic_config $::ixHlt::hltParams]
    
    if {[keylget trafficConfigStatus status] != $::SUCCESS} {
	::ixHlt::IxLog -error "Failed to config traffic on $portHandle \n[KeylPrint trafficConfigStatus]"
    }

    if {$::ixHlt::ixNetworkTclServerIp == 0 && [lsearch -regexp $args -igmp] != -1} {
	# For IxExplorer only.
	# If the stream has igmp, we must disable the timestamp
	# to avoid igmp checksum error.
	# Doing it using IxTclHal.  No hlt command for it.
	::ixHlt::DisableTimestamp $portHandle $streamId
    }

    if {$::ixHlt::ixNetworkTclServerIp == 0 && $mode == "create"} {
	# Note: stream equals pgid number
	set currentPgidNumber [incr ::ixHlt::pgidCounter]
	set ::ixHlt::portWithPgid($currentPgidNumber) $portHandle
	set ::ixHlt::portToStreamId($portHandle,$streamId) $streamId
	set ::ixHlt::portStreamIdToPgid($currentPgidNumber) $streamId

	#puts "\n[parray ::ixHlt::portStreamIdToPgid]\n"
	#puts "\n[parray ::ixHlt::portToStreamId]\n"
	#puts "\n[parray ::ixHlt::portWithPgid]\n"
    }
    
    return $trafficConfigStatus
}

# When calling ::ixia::traffic_config, it will return a keylist of things like
# trafficItem, trafficItem headers, streams, stream headers, etc.
# This proc parses the key list and return what the user wants.
proc GetTrafficConfigElements { trafficConfigKeyList element } {
    # Choices:
    # streamId, trafficItem, trafficItemHeaders, 
    # streamIds, streamIdHeaders, endpoint, encapsulation

    switch -exact -- $element {
	streamId {
	    # stream_id is the name of the trafficItem: TI0-My_TrafficItem_1
	    return [keylget trafficConfigKeyList stream_id]
	}
	trafficItem {
	    # ::ixNet::OBJ-/traffic/trafficItem:1/configElement:1
	    return [keylget trafficConfigKeyList traffic_item]
	}
	trafficItemHeaders {
	    # ::ixNet::OBJ-/traffic/trafficItem:1/configElement:1/stack:"ethernet-1" 
	    # ::ixNet::OBJ-/traffic/trafficItem:1/configElement:1/stack:"ipv4-2" 
	    # ::ixNet::OBJ-/traffic/trafficItem:1/configElement:1/stack:"fcs-3"
	    set trafficItem [keylget trafficConfigKeyList traffic_item]
	    set trafficItemHeaders [keylget trafficConfigKeyList $trafficItem.headers]
	}
	streamIds {
	    # ::ixNet::OBJ-/traffic/trafficItem:1/highLevelStream:1 
	    # ::ixNet::OBJ-/traffic/trafficItem:1/highLevelStream:2
	    set trafficItem [keylget trafficConfigKeyList traffic_item]
	    return [keylget trafficConfigKeyList $trafficItem.stream_ids]
	    
	}
	streamIdHeaders {
	    # ::ixNet::OBJ-/traffic/trafficItem:1/highLevelStream:1/stack:"ethernet-1"
	    # ::ixNet::OBJ-/traffic/trafficItem:1/highLevelStream:1/stack:"ipv4-2"
	    #::ixNet::OBJ-/traffic/trafficItem:1/highLevelStream:1/stack:"fcs-3"
	    set trafficItem [keylget trafficConfigKeyList traffic_item]
	    set streamIds [keylget trafficConfigKeyList $trafficItem.stream_ids]
	    set streamHeaderList {}
	    foreach stream $streamIds {
		lappend streamHeaderList [keylget trafficConfigKeyList $trafficItem.$stream.headers]	
	    }
	    return $streamHeaderList
	}
	endpoint {
	    # Returns the endpoint number
	    set trafficItem [keylget trafficConfigKeyList traffic_item]
	    set endPointSet [keylget trafficConfigKeyList $trafficItem.endpoint_set_id]
	}
	encapsulation {
	    # Ethernet.IPv4
	    set trafficItem [keylget trafficConfigKeyList traffic_item]
	    set encapsulation [keylget trafficConfigKeyList $trafficItem.encapsulation_name]
	}
	default {
	    puts "GetTrafficConfigElements: No such element: $element"
	}
    }
}


proc ::ixHlt::IxLog { type msg } {
    switch -exact -- $type {
	-noTimeStamp {
	    puts $msg
	}
	-info {
	    puts "\nINFO::[GetTime]: $msg"
	}
	-warning {
	    puts "\nWARNING::[GetTime]: $msg\n"
	}
	-error {
	    puts "\nERROR::[GetTime]: $msg\n"
	}
	-abort {
	    puts "\nABORTING::[GetTime]: $msg"
	    exit
	}
    }
}

proc ::ixHlt::GetTime {} {
    return [clock format [clock seconds] -format "%H:%M:%S"]
}

proc ::ixHlt::DisconnectIxia { } {
    ::ixHlt::IxLog -info "DisconnectIxia: Disconnecting from Ixia Chassis"
    ixia::cleanup_session
    #package forget Ixia
}

proc ::ixHlt::GetMacAddrForPort { port } {
    regexp "(\[0-9]+)\/(\[0-9]+)\/(\[0-9]+)" $port - chassisId slot port

    if {[string length $slot] == 1} {
	set slot 0$slot
    }
    if {[string length $port] == 1} {
	set port 0$port
    }

    return 00:0$chassisId:$slot:$port:00:01
}

proc ::ixHlt::ClearPgidStatsHltIxia { port_list } {
    set ixPortList {}
    # The low level API doesn't accept slashes on ports
    foreach p $port_list {
	lappend ixPortList [split $p /]
    }

    if {[ixClearTimeStamp ixPortList]} {
	::ixHlt::IxLog -error "Clearing timestamp on $port_list failed"
    } else {
	::ixHlt::IxLog -info "Cleared timestamp"
    }

    puts "ClearPgidStats: Clear stats before sending traffic"

    # -action clear_stats will start pgid capture also.
    set clear_stats_status [ixia::traffic_control \
				-port_handle $port_list \
				-action clear_stats \
			       ]
    if {[keylget clear_stats_status status] != $::SUCCESS} {
	::ixHlt::IxLog -error "Failed to clear PGID stats on $port_list"
	::ixHlt::IxLog -noTimeStamp $clear_stats_status
    } else {
	::ixHlt::IxLog -info "Cleared PGID stats on $port_list\n[KeylPrint clear_stats_status]"
    }
}

proc ::ixHlt::AppendHltParams { args {add_param ""} } {
    if {$add_param != ""} {
	if {[lsearch $::ixHlt::hltParams [lindex $add_param 0]] == -1} {
	    
	    append ::ixHlt::hltParams " $add_param"

	    foreach {param value} $add_param {
		set ::ixHlt::userDefinedParams($param) $value
	    }
	}
    }
    
    append ::ixHlt::hltParams " $args"
    
    foreach {param value} $args {
	set ::ixHlt::userDefinedParams($param) $value
    }
}

proc ::ixHlt::StartTrafficHlt { args } {
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
		::ixHlt::IxLog -abort "StartTrafficHlt: No such parameter: $currentArg"
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
    if {$::ixHlt::ixNetworkTclServerIp == 0} {
	::ixHlt::IxLog -info "Starting IxExplorer traffic ..."
	set trafficControlStatus [ixia::traffic_control \
				      -port_handle $portHandleList \
				      -action sync_run \
				     ]
    }

    # For IxNetwork
    # Have to use "run" instead of "sync_run".
    if {$::ixHlt::ixNetworkTclServerIp != 0} {
	::ixHlt::IxLog -info "Starting IxNetwork traffic ..."
	set trafficControlStatus [ixia::traffic_control \
				      -port_handle $portHandleList \
				      -action run \
				     ]
    }


    if {[keylget trafficControlStatus status] != $::SUCCESS} {
	::ixHlt::IxLog -error "StartTrafficHlt: Ixia traffic failed to start on port $portHandleList"
	::ixHlt::IxLog -noTimeStamp [KeylPrint trafficControlStatus]
	set startTrafficFlag 1
    } else {
	::ixHlt::IxLog -info "StartTrafficHlt: Traffic started on port $portHandleList"
    }

    if {$startTrafficFlag == 0 } {
	if {$trafficDuration > 0} {
	    ::ixHlt::IxLog -info "Traffic will run in the background for $trafficDuration seconds"

	    sleep $trafficDuration
	    set trafficControlStatus [ixia::traffic_control \
					    -port_handle $portHandleList \
					    -action stop \
					   ]

	    if {[keylget trafficControlStatus status] != $::SUCCESS} {
		::ixHlt::IxLog -error "Failed to stop Ixia traffic on ports $portHandleList"
		::ixHlt::IxLog -noTimeStamp [KeylPrint trafficControlStatus]
	    }
	    if {$checkTransmitDone == 1} {
		CheckPortTransmitDoneIxia $txPorts
		#::ixHlt::IxLog -info "All ports $txPorts all done and stopped transmitting."
		after 2000
	    }
	} else {
	    after 2000
	}
    }
}

proc ::ixHlt::StopTraffic { port_handle_list } {
    set trafficControlStatus [ixia::traffic_control \
				    -port_handle $port_handle_list \
				    -action stop
			       ]
    if {[keylget trafficControlStatus status] != $::SUCCESS} {
	::ixHlt::IxLog -error "Failed to stop Ixia traffic on ports $port_handle_list\n[KeylPrint trafficControlStatus]"
    } else {
	::ixHlt::IxLog -info "StopTraffic: Ixia traffic stopped on ports $port_handle_list"
    }
}

proc ::ixHlt::CheckPortTransmitDoneIxia { port_list } {
    foreach port $port_list {
	lappend portList "[split $port /]"
    }

    ixCheckTransmitDone portList
    ::ixHlt::IxLog -info "$port_list stopped transmitting."
}

proc ::ixHlt::KeylPrint {keylist {space ""}} {
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
proc ::ixHlt::VerifyReceivedPktCount { args } {
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
		::ixHlt::IxLog -abort "VerifyReceivedPktCount: No such parameter: $currentArg"
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

    ::ixHlt::IxLog -noTimeStamp "\nAll Rx ports == $listeningPorts"
    ::ixHlt::IxLog -noTimeStamp "Expected Rx ports == $expectedRxPorts"

    puts "\nPorts      TrasnmittedPkts       ReceivedPkts"
    puts "-----------------------------------------------------"

    set totalReceivedPackets 0
    foreach rxPort $listeningPorts {
	set receivedPackets 0
	set pgidStatistics [ixia::traffic_stats \
				      -port_handle $rxPort \
				      -packet_group_id $::ixHlt::pgidCounter \
				     ]
	
	#xputs "\n[KeylPrint pgidStatistics]\n"

	# Look at all the PGID for each port to see all the true packets received.
	for {set pgidIndex 1} {$pgidIndex <= $::ixHlt::pgidCounter} {incr pgidIndex} {
	    set receivedPackets [mpexpr $receivedPackets + [keylget pgidStatistics $rxPort.pgid.rx.pkt_count.$pgidIndex]]
	    set totalReceivedPackets [mpexpr $totalReceivedPackets + $receivedPackets]
	}

	set transmittedPackets [keylget pgidStatistics $rxPort.aggregate.tx.pkt_count]
	set crcErrorCount [keylget pgidStatistics $rxPort.aggregate.rx.crc_errors_count]
	#set sequenceErrorCount [keylget pgidStatistics $rxPort.aggregate.rx.sequence_errors_count]


	if {$totalTransmittedPackets == 0} {
	    ::ixHlt::IxLog -error "TX port $txPorts failed to transmit packets"
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
	    #::ixHlt::IxLog -info "Port $rxPort rx'd 0 pkt as expected.  Good!"
	}
    }
    
    if {$errorList != ""} {
	foreach errorItem $errorList {
	    ::ixHlt::IxLog -error $errorItem
	}
    }

    if {$totalReceivedPackets < $totalTransmittedPackets} {
	::ixHlt::IxLog -error "Total transmitted pkts: $totalTransmittedPackets; Total received pkts: $totalReceivedPackets"
    }
    
    if {$totalReceivedPackets == $totalTransmittedPackets} {
	::ixHlt::IxLog -noTimeStamp "\nTotal Tx packets: $totalTransmittedPackets"
	::ixHlt::IxLog -noTimeStamp "Total Rx packets: $totalReceivedPackets"
    }
    puts \n
}

proc ::ixHlt::GetStats {} {
    puts "\n[format %6s Port][format %10s Tx][format %12s Rx]"
    puts "-----------------------------------"

    foreach port $::ixHlt::portList {
	set pgidStatistics [ixia::traffic_stats \
				    -port_handle $port \
				    -packet_group_id $::ixHlt::pgidCounter \
				   ]

	set totalTx [keylget pgidStatistics $port.aggregate.tx.pkt_count]
	set totalRx [keylget pgidStatistics $port.aggregate.rx.pkt_count]
	puts "[format %6s $port][format %13s $totalTx][format %12s $totalRx]"
    }
    puts \n
}

proc ::ixHlt::GetRate { port } {
    #set portRate [keylget getTxPortRate $port.aggregate.rx.total_pkt_rate] ;# $port.pgid.rx.frame_rate
    
    # Get total amount of pgid
    set allPgid {}
    foreach {pgid streamId} [array get ::portStreamIdToPgid *] {
	lappend allPgid $pgid
    }

    set getTxPortRate [ixia::traffic_stats -port_handle $port -packet_group_id [llength $allPgid]]

    ::ixHlt::IxLog -noTimeStamp "\n [format %6s RxPort][format %12s RxRate][format %15s FromStreamId]"
    ::ixHlt::IxLog -noTimeStamp "-----------------------------------"

    for {set pgid 1} {$pgid <= [llength $allPgid]} {incr pgid} {
	set portRate [keylget getTxPortRate $port.pgid.rx.frame_rate.$pgid]
	#set minLatency [keylget getTxPortRate $port.pgid.rx.min_latency.$pgid]
	#set avgLatency [keylget getTxPortRate $port.pgid.rx.avg_latency.$pgid]
	#set maxLatency [keylget getTxPortRate $port.pgid.rx.max_latency.$pgid]

	::ixHlt::IxLog -noTimeStamp "[format %6s $port][format %12s $portRate][format %11s $::portStreamIdToPgid($pgid)]"
    }
}

proc ::ixHlt::DisableTimestamp { port_handle stream_id } {
    ::ixHlt::IxLog -info "UnConfiguring time stamp on $port_handle stream $stream_id"
    scan [split $port_handle /] "%d %d %d" chassis slot portNumber
    set portList [list [list $chassis $slot $portNumber]]
    
    stream get $chassis $slot $portNumber $stream_id
    stream config -enableTimestamp false
    stream set $chassis $slot $portNumber $stream_id
    ixWriteConfigToHardware portList -noProtocolServer
}

proc ::ixHlt::CheckTrafficState {} {
    # startedWaitingForStats,startedWaitingForStreams,stopped,stoppedWaitingForStats,txStopWatchExpected,unapplied
    set currentTrafficState [ixNet getAttribute [ixNet getRoot]/traffic -state]
    switch -exact -- $currentTrafficState {
	::ixNet::OK {
	    return notRunning
	}
	stopped {
	    return stopped
	}
	started {
	    return started
	}
	locked {
	    return locked
	}
	unapplied {
	    return unapplied
	}
	startedWaitingForStreams {
	    return startedWaitingForStreams
	}
	startedWaitingForStats {
	    return startedWaitingForStats
	}
	stoppedWaitingForStats {
	    return stoppedWaitingForStats
	}
	default {
	    return $currentTrafficState
	    ::ixHlt::IxLog -abort "CheckTrafficState: Traffic state is currently: $currentTrafficState"
	}
    }
}

proc ::ixHlt::CheckTrafficStopped {} {
    set flag 0
    set state stopped
    set stopTimer 20
    for {set timer 1} {$timer <= $stopTimer} {incr timer} {
	set currentTrafficState [::ixHlt::CheckTrafficState]
	if {$currentTrafficState != $state} {
	    ::ixHlt::IxLog -noTimeStamp "Traffic state is \"$currentTrafficState\". Wait $timer/$stopTimer seconds"
	    after 1000
	}
	if {[CheckTrafficState] == $state} {
	    set flag 1
	    break
	}
    }
    if {$flag == 1} {
	::ixHlt::IxLog -info "Traffic state is $state"
    } else {
	::ixHlt::IxLog -warning "Traffic is not in $state state"
    }
}
