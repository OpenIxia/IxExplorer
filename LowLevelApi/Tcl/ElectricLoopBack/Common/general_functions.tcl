#------------------------------------------------------------------------------
# Name              :   general_functions.tcl
# Author            :   Julio Marcos
# Purpose           :   Functions for port config and stats display
# Copyright         :   (c) 2022 Keysight Technologies - All Rights Reserved
#-------------------------------------------------------------------------------


#---------------------- Global Lookups ----------------------#

array set internalSpeed {
    800000    800000
    400000    400000
    200000    200000
    100000    100000
    50000     50000
    40000     40000
    25000     25000
    10000     10000
    1000      1000
    BERT      400000
    800G-R8   800000
    400G-R4   400000
    200G-R2   200000
    100G-R    100000
    400G-R8   400000
    200G-R4   200000
    100G-R2   100000
    50G-R     50000
    50G-R-HD  50000
    50G-HD    50000
    100G-R4   100000
    50G-R2    50000
    25G-R     25000
    40G-R4    40000
    10G-R     10000
    BERT-800G 800000
    BERT-PAM4 400000
    BERT-NRZ  200000
    100G-R*   100000
}

array set lineSpeed {
    800000    800GE
    400000    400GE
    200000    200GE
    100000    100GE
    50000     50GE
    40000     40GE
    25000     25GE
    10000     10GE
    1000      1GE
    BERT      BERT
    800G-R8   800GE
    400G-R4   400GE
    200G-R2   200GE
    100G-R    100GE
    400G-R8   400GE
    200G-R4   200GE
    100G-R2   100GE
    50G-R     50GE
    50G-R-HD  50GE
    50G-HD    50GE
    100G-R4   100GE
    50G-R2    50GE
    25G-R     25GE
    40G-R4    40GE
    10G-R     10GE
    BERT-800G BERT
    BERT-PAM4 BERT
    BERT-NRZ  BERT
    100G-R*   100GE
}

array set encodedSpeed {
    800000    {800G-R8 PAM4}
    400000    {400G-R8 PAM4}
    200000    {200G-R4 PAM4}
    100000    {100G-R2 PAM4}
    50000     {50G-R PAM4}
    40000     {40G-R4 NRZ}
    25000     {25G-R NRZ}
    10000     {10G-R NRZ}
    1000      {1G-R NRZ}
    BERT      {BERT}
    800G-R8   {800G-R8 PAM4}
    400G-R4   {400G-R4 PAM4}
    200G-R2   {200G-R2 PAM4}
    100G-R    {100G-R PAM4}
    400G-R8   {400G-R8 PAM4}
    200G-R4   {200G-R4 PAM4}
    100G-R2   {100G-R2 PAM4}
    50G-R     {50G-R PAM4}
    50G-R-HD  {50G-R PAM4}
    50G-HD    {50G-R PAM4}
    100G-R4   {100G-R4 NRZ}
    50G-R2    {50G-R2 NRZ}
    25G-R     {25G-R NRZ}
    40G-R4    {40G-R4 NRZ}
    10G-R     {10G-R NRZ}
    BERT-800G {BERT 800G}
    BERT-PAM4 {BERT PAM4}
    BERT-NRZ  {BERT NRZ}
    100G-R*   {100G-R*}
}


# Max PAM4 electrical lane index per port speed
# -Index starts at 1
array set maxLaneNumber {
    800000      8
    400000      8
    200000      4
    100000      2
    50000       1
    BERT        8
    800G-R8     8
    400G-R4     4
    200G-R2     2
    100G-R      1
    400G-R8     8
    200G-R4     4
    100G-R2     2
    50G-R       1
    50G-R-HD    1
    50G-HD      1
    100G-R*     2
}

# Link states
array set linkStates {
     0 linkDown
     1 linkUp
     2 linkLoopback
     3 miiWrite
     4 restartAuto
     5 autoNegotiating
     6 miiFail
     7 noTransceiver
     8 invalidAddress
     9 readLinkPartner 
    10 noLinkPartner
    11 restartAutoEnd
    12 fpgaDownloadFail
    13 noGbicModule
    14 fifoReset
    15 fifoResetComplete
    16 pppOff
    17 pppUp
    18 pppDow
    19 pppInit
    20 pppWaitForOpen
    21 pppAutoNegotiate
    22 pppClose
    23 pppConnect
    24 n/a
    25 lossOfSignal
    26 lossOfFramePpp
    27 stateMachineFailure
    28 pppRestartNegotiation
    29 pppRestartInit
    30 Open
    31 Close
    32 pppRestartFinish
    33 localProcessorDown
    34 ignoreLink
    41 sublayerUnlock
    42 demoMode
    43 waitingForFpgaDownload
    44 lossOfCell
    45 noXFPModule
    46 moduleNotReady
    47 hardwareFault
    48 noX2Module
    49 lossOfPointer
    50 lossOfAligment
    51 lossOfMultiframe
    52 gfpOutOfSync
    53 lcasSequenceMismatch
    54 ethernetOamLoopback
}

# Possible port link fault states
array set linkFaultStates {
    0   NoFault
    1   LocalFault
    2   RemoteFault
    n/a n/a
}

# line-side link encoding
array set linkEncoding {
    0   PAM4
    1   NRZ
    n/a n/a
}


# Port Stats with Traffic 
# -Note: some stats such as TrafficFLR are not native stats
set portStatsList {
    {lineSpeed                              {Line Speed}}
    {link                                   {Link State}}
    {linkFaultState                         {Link Fault State}}
    {localFaults                            {Local Faults}}
    {remoteFaults                           {Remote Faults}}
    {framesSent                             {Frames Sent}}
    {framesReceived                         {Valid Frames Received}}
    {oversize                               {Oversize and good CRCs}}
    {fragments                              {Fragments}}
    {undersize                              {Undersize}}
    {fcsErrors                              {CRC Errors}}
    {oversizeAndCrcErrors                   {Oversize and CRC Errors}}
    {pcsLocalFaultsReceived                 {PCS Local Faults}}
    {pcsRemoteFaultsReceived                {PCS Remote Faults}}
    {pcsSyncErrorsReceived                  {PCS Sync Errors}}
    {pcsIllegalCodesReceived                {PCS Illegal Codes}}
    {pcsIllegalOrderedSetReceived           {PCS Illegal Ordered Set}}
    {pcsIllegalIdleReceived                 {PCS Illegal Idle}}
    {pcsIllegalSofReceived                  {PCS Illegal SOF}}
    {fecTotalBitErrors                      {FEC Total Bit Errors}}
    {fecMaxSymbolErrors                     {FEC Max Symbol Errors}}
    {fecCorrectedCodewords                  {FEC Corrected Codewords}}
    {fecTotalCodewords                      {FEC Total Codewords}}
    {fecFrameLossRatio                      {FEC Frame Loss Ratio}}
    {trafficFrameLossRatio                  {Traffic Frame Loss Ratio}}
    {preFecBer                              {Pre-FEC Bit Error Rate}}
    {fecMaxSymbolErrorsBin0                 {FEC Codeword with 0 errors}}
    {fecMaxSymbolErrorsBin1                 {FEC Codeword with 1 errors}}
    {fecMaxSymbolErrorsBin2                 {FEC Codeword with 2 errors}}
    {fecMaxSymbolErrorsBin3                 {FEC Codeword with 3 errors}}
    {fecMaxSymbolErrorsBin4                 {FEC Codeword with 4 errors}}
    {fecMaxSymbolErrorsBin5                 {FEC Codeword with 5 errors}}
    {fecMaxSymbolErrorsBin6                 {FEC Codeword with 6 errors}}
    {fecMaxSymbolErrorsBin7                 {FEC Codeword with 7 errors}}
    {fecMaxSymbolErrorsBin8                 {FEC Codeword with 8 errors}}
    {fecMaxSymbolErrorsBin9                 {FEC Codeword with 9 errors}}
    {fecMaxSymbolErrorsBin10                {FEC Codeword with 10 errors}}
    {fecMaxSymbolErrorsBin11                {FEC Codeword with 11 errors}}
    {fecMaxSymbolErrorsBin12                {FEC Codeword with 12 errors}}
    {fecMaxSymbolErrorsBin13                {FEC Codeword with 13 errors}}
    {fecMaxSymbolErrorsBin14                {FEC Codeword with 14 errors}}
    {fecMaxSymbolErrorsBin15                {FEC Codeword with 15 errors}}
    {fecUncorrectableCodewords              {FEC Uncorrectable Codewords}}
    {fecTranscodingUncorrectableErrors      {FEC Uncorrectable Events}}
}


#---------------------- Misc Functions ----------------------#

# Enhanced 'after' function so we can refresh the display
proc sleep {timeInMilliseconds}\
{
    update idletasks
    after $timeInMilliseconds
}

# Enhanced 'after' function (in seconds) 
proc sleepSeconds {time}\
{
    update idletasks
    after [expr {int($time * 1000)}]
}

# Add commas to a number every 3 digits
proc commify number {regsub -all {\d(?=(\d{3})+($|\.))} $number {\0,}}

# Remove commas from a number
proc decommify number {regsub -all {,} $number ""}


#---------------------- Chassis/Card/Port Functions ----------------------#

#
# Converts the port from FQPN (Fully Qualified Port Numbering)
# to classic chassidID, CardID, portID
#
proc convertFQPN {port} {
    if {[string match */* $port]} {
        # FQPN to triple
        set port [ixUtils convertPortPathToIdTriple $port]
    }
    return $port
}


# Return card family based on full card name
proc getCardName {port} {
    set port [convertFQPN $port]
    scan $port "%d %d %d" chasId cardId portId

    if {[card get $chasId $cardId] != $::TCL_OK} {
        errorMsg "ERROR - Could not issue 'card get' command on card $chasId,$cardId!"
        return $::TCL_ERROR
    }
    # Use card name without fanout speed qualifiers
    set cardName [lindex [split [card cget -typeName] '+'] 0]
    
    if {[string first "800GE"   $cardName] > -1} {return "Raven"}
    if {[string first "S400"    $cardName] > -1} {return "Star"}
    if {[string first "T400GP"  $cardName] > -1} {return "Life"}
    if {[string first "T400"    $cardName] > -1} {return "Titan"}
    if {[string first "QSFP-DD" $cardName] > -1} {return "K400"}
    if {[string first "NOVUS"   $cardName] > -1} {return "Novus"}

    # Default
    puts "No match for card name: $cardName"
    return "Unknown"
}


# Calculate Front Panel Port based on Star/Titan/port number
proc getFrontPanelPort {port {returnRG 0}} {
    set port [convertFQPN $port]
    scan $port "%d %d %d" chasId cardId portId

    set cardName [getCardName $port]
    switch $cardName {
        Raven {
            if {$portId >= 57} {
                # 100G PAM4 ports are in the range 57..121
                set fpp [expr {int(ceil(($portId - 56)/8.0))}]
            } elseif {$portId >= 25} {
                # 200G PAM4 ports are in the range 25..56
                set fpp [expr {int(ceil(($portId - 24)/4.0))}]
            } elseif {$portId >= 9} {
                # 400G PAM4 ports are in the range 9..24
                set fpp [expr {int(ceil(($portId - 8)/2.0))}]
            } else {
                # 800G PAM4 ports map 1:1 to RG's
                set fpp $portId
            }
            # 800G front panel ports map 1:1 to RG's
            set rg $fpp
        }
        Star {
            if {$portId >= 497} {
                # 10G NRZ ports are in the range 497..624
                set fpp [expr {int(ceil(($portId - 496)/8.0))}]
            } elseif {$portId >= 465} {
                # 40G NRZ ports are in the range 465..496
                set fpp [expr {int(ceil(($portId - 464)/2.0))}]
            } elseif {$portId >= 337} {
                # 25G NRZ ports are in the range 337..464
                set fpp [expr {int(ceil(($portId - 336)/8.0))}]
            } elseif {$portId >= 273} {
                # 50G NRZ ports are in the range 273..336
                set fpp [expr {int(ceil(($portId - 272)/4.0))}]
            } elseif {$portId >= 241} {
                # 100G NRZ ports are in the range 241..272
                set fpp [expr {int(ceil(($portId - 240)/2.0))}]
            } elseif {$portId >= 113} {
                # 50G PAM4 ports are in the range 113..240
                set fpp [expr {int(ceil(($portId - 112)/8.0))}]
            } elseif {$portId >= 49} {
                # 100G PAM4 ports are in the range 49..112
                set fpp [expr {int(ceil(($portId - 48)/4.0))}]
            } elseif {$portId >= 17} {
                # 200G PAM4 ports are in the range 17..48
                set fpp [expr {int(ceil(($portId - 16)/2.0))}]
            } else {
                # 400G PAM4 ports map 2:1 to RG's
                set fpp $portId
            }
            # Star has 2 x QDD ports per RG
            set rg [expr {int(ceil($fpp/2.0))}]
        }
        Titan {
            if {$portId >= 57} {
                # 50G ports are in the range 57..120
                set fpp [expr {int(ceil(($portId - 56)/8.0))}]
            } elseif {$portId >= 25} {
                # 100G ports are in the range 25..56
                set fpp [expr {int(ceil(($portId - 24)/4.0))}]
            } elseif {$portId >= 9} {
                # 200G ports are in the range 9..24
                set fpp [expr {int(ceil(($portId - 8)/2.0))}]
            } else {
                set fpp $portId
            }
            # 400G front panel ports map 1:1 to RG's
            set rg $fpp
        }
        default {
            # Not supported
            #set fpp -1
            #set rg  -1
			set fpp $portId
			set rg $portId
        }
    }

    if {$returnRG} {
        return $rg
    } else {
        return $fpp
    }
}

# Calculate Resource Group (RG) based on  Star/Titan/Life/K400/Novus port number
proc getRGfromPort {port} {
    set returnRG 1
    return [getFrontPanelPort $port $returnRG]
}


#
# Description: Speed mode change on a card
# Arguments  : portList
#              -speed <400G-R8|200G-R4|100G-R2|100G-R4|50G-R|...|BERT|BERT-PAM4|BERT-NRZ>
# Returns    : 0 if no errors found, 1 if otherwise
#
proc modeSwitch {portList {speed 400G-R8} {soakTime 0}}\
{
    global internalSpeed
    global encodedSpeed

    set portIndex 0 
    set switchesDone 0
    # foreach port $frontPanelPortList 
    foreach port $portList {
        set cardName [getCardName $port]
        set port [convertFQPN $port]
        scan $port "%d %d %d" chasId cardId portId
        set rgPort [getRGfromPort $port]
        incr portIndex

        # First check whether we are in the desired mode already
        card get $chasId $cardId
        resourceGroupEx get $chasId $cardId $portId
        set currentMode [resourceGroupEx cget -mode]
        set currentAttr [resourceGroupEx cget -attributes]
        if {[catch {
            set currentModeName [resourceGroupEx cget -modeName]
        }]} {
            set currentModeName ""
        }
        set inBERTmode [expr {$currentMode == 400000 && ($currentAttr == {{bert}}) || \
                                $currentMode == 800000 && ($currentAttr == {{bert serdesModePam4}})}]
        set finalSpeed $speed

        if {$cardName == "Star"} {
            # Star with all its PAM4/NRZ modes
            # -will have to use 400G-R8 / 200G-R4 / 100G-R2 / 100G-R4 etc rather than just speed such as 400000
            # -For BERT, we'll use either BERT-PAM4 or BERT-NRZ
            if {$internalSpeed($speed) == $currentMode && $finalSpeed == $currentModeName} {
                puts "Front panel port for {$port} --> RG $rgPort already in $encodedSpeed($finalSpeed) mode ($currentModeName)"
                continue
            } else {
                puts "Front panel port for {$port} --> RG $rgPort in $currentMode ($currentModeName), mode switching to $encodedSpeed($finalSpeed)..."
                incr switchesDone
            }
        } else {
            # All other cards (Titan/K400/Novus/Raven)
            #
            if {$speed == "BERT" || $speed == "BERT-800G"} {
                if {$inBERTmode} {
                    puts "Front panel port for {$port} --> RG $rgPort already in BERT mode."
                    continue
                } else {
                    puts "Front panel port for {$port} --> RG $rgPort in $currentMode ($currentModeName), mode switching to BERT..."
                    incr switchesDone
                }
            } elseif {$internalSpeed($finalSpeed) == $currentMode && !$inBERTmode} {
                puts "Front panel port for {$port} --> RG $rgPort already in $encodedSpeed($finalSpeed) mode ($currentModeName)"
                continue
            } else {
                set currentMode [expr {$inBERTmode ? "BERT" : $currentMode}]
                puts "Front panel port for {$port} --> RG $rgPort in $currentMode ($currentModeName), mode switching to $encodedSpeed($finalSpeed)..."
                incr switchesDone
            }
        }
        sleep 1

        # Configure resource group to new mode
        resourceGroupEx setDefault
        resourceGroupEx config -mode $internalSpeed($speed)
        if {$cardName == "Star"} {
            # For Star we need to specify the modeName (100G-R2, 1000G-R4) as well
            resourceGroupEx config -modeName $finalSpeed
        }
        # -Configure non-LAN modes
        switch $speed {
            BERT {
                # This is for non-STAR BERT modes
                resourceGroupEx config -mode $internalSpeed($speed)
                resourceGroupEx config -attributes {bert}
            }
            BERT-800G {
                # Raven 800G BERT
                resourceGroupEx config -modeName BERT-PAM4
            }
        }

        # Set new mode and write to hardware
        if {[resourceGroupEx set $chasId $cardId $portId]} {
            errorMsg "ERROR - Could not issue resourceGroupEx set command on {$port}!"
            return $::TCL_ERROR
        }
        if {[resourceGroupEx write $chasId $cardId $portId]} {
            errorMsg "ERROR - Could not issue resourceGroupEx write command on {$port}!"
            return $::TCL_ERROR
        }
        if {$cardName == "Novus"} {
            sleepSeconds 4
        }
        puts "Port {$port} switched to ${finalSpeed}."
    }
    # Optional soak time after having at least one port mode switch
    if {$switchesDone && $soakTime > 0} {
        puts "Waiting $soakTime seconds after mode switch..."
        sleepSeconds $soakTime
    }

    return $::TCL_OK
}


#---------------------- Chassis/Port Info Functions ----------------------#

# Pretty format a port with chassis Id (or IP), card Id, port Id
proc portDisplay {port {withIP 0}}\
{
    # Allow FQPN (fully qualified port numbering)
    if {[string match */* $port]} {
        return $port
    }

    # Legacy port numbering
    scan $port "%s %s %s" chassis cardId portId
    if {$withIP} {
        chassis get $chassis
        if {[chassis get $chassis] == $::TCL_OK} {
            set chasIP [chassis cget -hostName]
        } else {
            set chasIP $chassis
        }
        return [format "%s;%s;%s" $chasIP $cardId $portId]
    } else {
        return [format "{%s}" $port]
    }
}

#
# Show the the port list headers, with IP instead of chassis ID
#
proc showPortHeadersWithIP {portList {entryWidth 28} {resultWidth 28} {leftJustified 1}} {
    set title [format {%-*s  } $entryWidth "Port "]
    set titleSep [format {%-*s  } $entryWidth [string repeat "-" $entryWidth]]
    set showIP 1
    foreach port $portList {
        if {$leftJustified} {
            append title  [format {%-*s    } $resultWidth [portDisplay $port $showIP]]
        } else {
            append title [format {%*s    } $resultWidth [portDisplay $port $showIP]]
        }
        append titleSep [format {%*s    } $resultWidth [string repeat "-" $resultWidth]]
    }
    puts $titleSep
    puts $title
    puts $titleSep

    flush stdout
}

#
# Show the the port list headers, with a description of the port intent
# -For example, one port could be transmitting, other receiving; or just standing-by
#
proc showPortHeadersWithIntent {portList portInfoVar {entryWidth 28} {resultWidth 28} {leftJustified 1}} {
    upvar 1 $portInfoVar portInfo

    set title [format {%-*s  } $entryWidth "Port "]
    set intent [format {%-*s  } $entryWidth "Description "]
    set titleSep [format {%-*s  } $entryWidth [string repeat "-" $entryWidth]]
    foreach port $portList {
        set port [convertFQPN $port]
        scan $port {%d %d %d} chasId cardId portId
         if {![info exists portInfo(INTENT,$chasId,$cardId,$portId)]} {
             set portIntent "Test Port"
         } else {
             set portIntent $portInfo(INTENT,$chasId,$cardId,$portId)
         }

        if {$leftJustified} {
            append title  [format {%-*s    } $resultWidth [portDisplay $port]]
            append intent [format {%-*s    } $resultWidth $portIntent]
        } else {
            append title [format {%*s    } $resultWidth [portDisplay $port]]
            append intent [format {%*s    } $resultWidth $portIntent]
        }
        append titleSep [format {%*s    } $resultWidth [string repeat "-" $resultWidth]]
    }
    puts $title
    puts $intent
    puts $titleSep

    flush stdout
}


#
# Get the card name, IxOS, and other environment info for each port
# Returns: 0 if no errors found, 1 if otherwise
#
proc getEnvironmentInfo {portList portInfoVar} {
    upvar 1 $portInfoVar portInfo

    foreach port $portList {
        set port [convertFQPN $port]
        scan $port {%d %d %d} chasId cardId portId
        if {[chassis get $chasId] != $::TCL_OK} {
            errorMsg "ERROR - Could not issue 'chassis get' command on chassis $chasId!"
            return $::TCL_ERROR
        }
        if {[card get $chasId $cardId] != $::TCL_OK} {
            errorMsg "ERROR - Could not issue 'card get' command on card $chasId,$cardId!"
            return $::TCL_ERROR
        }
        if {[port get $chasId $cardId $portId] != $::TCL_OK} {
            errorMsg "ERROR - Could not issue 'port get' command on port $chasId,$cardId,$portId!"
            return $::TCL_ERROR
        }
        set portInfo(CHASSIS_NAME,$chasId,$cardId,$portId) [chassis cget -serialNumber]
        set portInfo(IXOS_VERSION,$chasId,$cardId,$portId) [chassis cget -ixServerVersion]
        set portInfo(CARD_TYPE,$chasId,$cardId,$portId)    [card cget -typeName]
        set portInfo(CARD_INFO,$chasId,$cardId,$portId)    [string range [card cget -serialNumber] 1 end]
        set portInfo(PORT_SPEED,$chasId,$cardId,$portId)   [format %d    [port cget -speed]]

        # Use card name without fanout speed qualifiers
        set cardName [lindex [split [card cget -typeName] '+'] 0]
        set portInfo(CARD_NAME,$chasId,$cardId,$portId) $cardName
    }

    return $::TCL_OK
}

#
# Show environment info
#
proc showEnvironmentInfo {portList portInfoVar {entryWidth 28} {resultWidth 28} {leftJustified 1}} {
    upvar 1 $portInfoVar portInfo

    set str0 [format {%-*s  } $entryWidth "Chassis name"]
    set str1 [format {%-*s  } $entryWidth "IxOS version"]
    set str2 [format {%-*s  } $entryWidth "Card name"]
    set str3 [format {%-*s  } $entryWidth "Port speed"]
    foreach port $portList {
        set port [convertFQPN $port]
        scan $port {%d %d %d} chasId cardId portId
        if {$leftJustified} {
            append str0 [format {%-*s    } $resultWidth $portInfo(CHASSIS_NAME,$chasId,$cardId,$portId)]
            append str1 [format {%-*s    } $resultWidth $portInfo(IXOS_VERSION,$chasId,$cardId,$portId)]
            append str2 [format {%-*s    } $resultWidth $portInfo(CARD_NAME,$chasId,$cardId,$portId)]
            append str3 [format {%-*s    } $resultWidth $portInfo(PORT_SPEED,$chasId,$cardId,$portId)]
        } else {
            append str0 [format {%*s    } $resultWidth $portInfo(CHASSIS_NAME,$chasId,$cardId,$portId)]
            append str1 [format {%*s    } $resultWidth $portInfo(IXOS_VERSION,$chasId,$cardId,$portId)]
            append str2 [format {%*s    } $resultWidth $portInfo(CARD_NAME,$chasId,$cardId,$portId)]
            append str3 [format {%*s    } $resultWidth $portInfo(PORT_SPEED,$chasId,$cardId,$portId)]
        }
    }
    puts $str0
    puts $str1
    puts $str2
    puts $str3
    flush stdout
}



#
# Get the port Tx taps and Rx equalization setting
# Returns: 0 if no errors found, 1 if otherwise
#
proc getElectricalInterfaceInfo {portList portInfoVar} {
    upvar 1 $portInfoVar portInfo

    foreach port $portList {
        set port [convertFQPN $port]
        scan $port {%d %d %d} chasId cardId portId
        set properties [transceiver getReadAvailableProps $chasId $cardId $portId]

        # For each of the pre/main/post/ctle coefficients, use the one for the first lane
        set portInfo(TX_EQ_PRE,$chasId,$cardId,$portId)   [lindex [split [transceiver getValue txPreTapControlValueProperty] ':'] 1]
        set portInfo(TX_EQ_MAIN,$chasId,$cardId,$portId)  [lindex [split [transceiver getValue txMainTapControlValueProperty] ':'] 1]
        set portInfo(TX_EQ_POST,$chasId,$cardId,$portId)  [lindex [split [transceiver getValue txPostTapControlValueProperty] ':'] 1]

        # Make sure the properties are available before accessing them:
        # -K400 and AresONE have DSP mode and CTLE settings, but not AresONE-S
        if {[lsearch -exact $properties rxCtleControlValueProperty] != -1} {
            set portInfo(RX_EQ_CTLE,$chasId,$cardId,$portId)  [lindex [split [transceiver getValue rxCtleControlValueProperty] ':'] 1]
        } else {
            set portInfo(RX_EQ_CTLE,$chasId,$cardId,$portId) "n/a"
        }
        if {[lsearch -exact $properties rxDspModeControlValueProperty] != -1} {
            set portInfo(RX_DSP,$chasId,$cardId,$portId)  [lindex [split [transceiver getValue rxDspModeControlValueProperty] ':'] 1]
        } else {
            set portInfo(RX_DSP,$chasId,$cardId,$portId) "n/a"
        }
        # -Both AresONE and AresONE-S have pre2 tap
        if {[lsearch -exact $properties txPre2TapControlValueProperty] != -1} {
            set portInfo(TX_EQ_PRE2,$chasId,$cardId,$portId)  [lindex [split [transceiver getValue txPre2TapControlValueProperty] ':'] 1]
        } else {
            set portInfo(TX_EQ_PRE2,$chasId,$cardId,$portId)  "n/a"
        }
        # -AresONE has post2,post3 taps but not AresONE-S
        if {[lsearch -exact $properties txPost2TapControlValueProperty] != -1} {
            set portInfo(TX_EQ_POST2,$chasId,$cardId,$portId) [lindex [split [transceiver getValue txPost2TapControlValueProperty] ':'] 1]
            set portInfo(TX_EQ_POST3,$chasId,$cardId,$portId) [lindex [split [transceiver getValue txPost3TapControlValueProperty] ':'] 1]
        } else {
            set portInfo(TX_EQ_POST2,$chasId,$cardId,$portId) "n/a"
            set portInfo(TX_EQ_POST3,$chasId,$cardId,$portId) "n/a"      
        }

    }

    return $::TCL_OK
}

#
# Show the Tx taps and Rx equalization settings
#
proc showElectricalInterfaceInfo {portList portInfoVar {entryWidth 28} {resultWidth 28} {leftJustified 1}} {
    upvar 1 $portInfoVar portInfo

    puts [format {%-*s  } $entryWidth "Host Electrical Interface:"]
    set str1 [format {%-*s  } $entryWidth "Tx pre2-cursor tap"]
    set str2 [format {%-*s  } $entryWidth "Tx pre-cursor tap"]
    set str3 [format {%-*s  } $entryWidth "Tx main-cursor tap"]
    set str4 [format {%-*s  } $entryWidth "Tx post-cursor tap"]
    set str5 [format {%-*s  } $entryWidth "Tx post2-cursor tap"]
    set str6 [format {%-*s  } $entryWidth "Tx post3-cursor tap"]
    set str7 [format {%-*s  } $entryWidth "Rx CTLE"]
    set str8 [format {%-*s  } $entryWidth "Rx DSP mode"]
    foreach port $portList {
        set port [convertFQPN $port]
        scan $port {%d %d %d} chasId cardId portId
        if {$leftJustified} {
            append str1 [format {%-*s    } $resultWidth $portInfo(TX_EQ_PRE2,$chasId,$cardId,$portId)]
            append str2 [format {%-*s    } $resultWidth $portInfo(TX_EQ_PRE,$chasId,$cardId,$portId)]
            append str3 [format {%-*s    } $resultWidth $portInfo(TX_EQ_MAIN,$chasId,$cardId,$portId)]
            append str4 [format {%-*s    } $resultWidth $portInfo(TX_EQ_POST,$chasId,$cardId,$portId)]
            append str5 [format {%-*s    } $resultWidth $portInfo(TX_EQ_POST2,$chasId,$cardId,$portId)]
            append str6 [format {%-*s    } $resultWidth $portInfo(TX_EQ_POST3,$chasId,$cardId,$portId)]
            append str7 [format {%-*s    } $resultWidth $portInfo(RX_EQ_CTLE,$chasId,$cardId,$portId)]
            append str8 [format {%-*s    } $resultWidth $portInfo(RX_DSP,$chasId,$cardId,$portId)]
        } else {
            append str1 [format {%*s    } $resultWidth $portInfo(TX_EQ_PRE2,$chasId,$cardId,$portId)]
            append str2 [format {%*s    } $resultWidth $portInfo(TX_EQ_PRE,$chasId,$cardId,$portId)]
            append str3 [format {%*s    } $resultWidth $portInfo(TX_EQ_MAIN,$chasId,$cardId,$portId)]
            append str4 [format {%*s    } $resultWidth $portInfo(TX_EQ_POST,$chasId,$cardId,$portId)]
            append str5 [format {%*s    } $resultWidth $portInfo(TX_EQ_POST2,$chasId,$cardId,$portId)]
            append str6 [format {%*s    } $resultWidth $portInfo(TX_EQ_POST3,$chasId,$cardId,$portId)]
            append str7 [format {%*s    } $resultWidth $portInfo(RX_EQ_CTLE,$chasId,$cardId,$portId)]
            append str8 [format {%*s    } $resultWidth $portInfo(RX_DSP,$chasId,$cardId,$portId)]
        }
    }
    puts $str1
    puts $str2
    puts $str3
    puts $str4
    puts $str5
    puts $str6
    puts $str7
    puts $str8
    flush stdout
}


#---------------------- Port Stats Functions ----------------------#

#
# Create a stat group so we can latch the stats for the ports under test
#
proc configStatGroup {portList} {
    statGroup setDefault
    foreach port $portList {
        set port [convertFQPN $port]
        scan $port {%d %d %d} chasId cardId portId
        statGroup add $chasId $cardId $portId
    }
}


#
# Description:  Gather the selected port statistics
#               -Need to call getStatList function beforehand which will 
#                issue the statGroup and statList commands to grab the stats
# Arguments  : port (one port only)
#              port stats list
#              option: "none", "commify", "debug"
# Returns    : 0 if no errors found, 1 if otherwise
#
proc getPortStats {port portStatsList {option "none"}}\
{
    global portStats
    global linkStates
    global lineSpeed
    global linkFaultStates
    global linkEncoding
    global activeFecMode

    set errorFlag 0
    set debugFlag   [expr {$option == "debug" ? 1: 0}]
    set commifyFlag [expr {$option == "commify" ? 1: 0}]
    
    # Display the port stats (and populate in a simple array)
    foreach stat $portStatsList {
        lassign $stat statEntry statName
        if {[catch {
            set value [statList cget -$statEntry]
        }]} {
            set value "n/a"
        }
        switch $statEntry {
            "link" {
                set value $linkStates($value)
            }
            "lineSpeed" {
                set value $lineSpeed($value)
            }
            "linkFaultState" {
                set value $linkFaultStates($value)
            }
            "transmitDuration" - "bertTransmitDuration" {
                set value [format "%.6f" [expr {$value*1.0e-9}]]
            }
            "preFecBer" - "fecFrameLossRatio" - "bertBitErrorRatio" - "bertPam4SymbolsErrorsRatio" {
                set value [format [expr {$value == "n/a" ? "%s" : "%12.2e"}] $value]
            }
            "encoding" {
                set value $linkEncoding($value)
            }
            "fecStatus" {
                set value $activeFecMode($value)
            }
            default {
                set value [expr {$commifyFlag ? [commify $value] : $value}]
            }
        }
        set portStats($statEntry) $value
        
        if {$debugFlag} {
            puts [format "Port %-s - %-28s: %28s" [list $port] $statName $value]
        }
    }
    return $errorFlag
}


#
# Retrieve selected stats in a portlist
# -The stats are defined in portStatsList
# Returns: 0 if no errors found, 1 if otherwise
#
proc getAllPortStats {portList portStatsList portInfoVar {option "none"}} {
    upvar 1 $portInfoVar portInfo
    global portStats

    statGroup get
    statList setDefault
    foreach port $portList {
        set port [convertFQPN $port]
        scan $port "%d %d %d" chasId cardId portId
        if {[statList get $chasId $cardId $portId]} {
                errorMsg "ERROR - Could not get stat list on port {$port}!"
                return $::TCL_ERROR
        }
        getPortStats $port $portStatsList $option
        foreach stat $portStatsList {
            lassign $stat statEntry statName
            set portInfo($statEntry,$chasId,$cardId,$portId) $portStats($statEntry)
        }
    }

    return $::TCL_OK
}


#
# Show port stats side-by-side, including P/F outcome (Pass/Fail) when directed
#
proc showAllPortStats {portList portStatsList portInfoVar testInfoVar {option "verbose"} {entryWidth 28} {resultWidth 28} {leftJustified 0}} {
    upvar 1 $portInfoVar portInfo
    upvar 1 $testInfoVar testInfo

    #puts "Port Statistics:"
    if {$option != "no_headers"} {
        showPortHeadersWithIntent $portList portInfo $entryWidth $resultWidth
    }
    foreach stat $portStatsList {
        lassign $stat statEntry statName
        set str [format {%-*s  } $entryWidth "$statName"]
        foreach port $portList {
            set port [convertFQPN $port]
            scan $port {%d %d %d} chasId cardId portId
            if {$leftJustified} {
                append str [format {%-*s } $resultWidth $portInfo($statEntry,$chasId,$cardId,$portId)]
            } else {
                append str [format {%*s } $resultWidth $portInfo($statEntry,$chasId,$cardId,$portId)]
            }
            set outcome " " 
            if {[info exists testInfo($statEntry,$chasId,$cardId,$portId)]} {
                set outcome $testInfo($statEntry,$chasId,$cardId,$portId)
                if {$option == "quiet" && $outcome != "F"} {
                    # In quiet mode only display the fails
                    set outcome " "
                }
            }
            append str $outcome "  "
        }
        puts $str
        update idletasks
    }
}

#
# Show stored port info and error messages
#
proc showAllPortErrors {portList testInfoVar {header "Port and VDM stats analysis:"}} {
    upvar 1 $testInfoVar testInfo

    puts $header
    set infoCount 0
    foreach port $portList {
        set port [convertFQPN $port]
        scan $port {%d %d %d} chasId cardId portId
        if {[info exists testInfo(PORT_INFO_STR,$chasId,$cardId,$portId)]} {
            foreach infoStr $testInfo(PORT_INFO_STR,$chasId,$cardId,$portId) {
                puts $infoStr
                incr infoCount
            }
        }
    }
    if {!$infoCount} {
        puts "Statistics met the test criteria."
        return $::TCL_OK
    } else {
        return $::TCL_ERROR
    }
}

#
# Show overall outcome summary for each port 
# -Either PASS or FAIL vs. the test criteria
#
proc showAllPortOutcomes {portList testInfoVar {entryWidth 28} {resultWidth 28} {leftJustified 0}}\
{
    upvar 1 $testInfoVar testInfo

    set overallErrorFlag 0
    set str [format {%-*s  } $entryWidth "Overall Outcome:"]
    foreach port $portList {
        set port [convertFQPN $port]
        scan $port {%d %d %d} chasId cardId portId
        set portOutcome "PASS"
        if {[info exists testInfo(PORT_FAIL,$chasId,$cardId,$portId)] &&\
            $testInfo(PORT_FAIL,$chasId,$cardId,$portId) > 0} {
            set portOutcome "FAIL"
            set overallErrorFlag 1
        }
        if {$leftJustified} {
            append str [format {%-*s    } $resultWidth $portOutcome]
        } else {
            append str [format {%*s    } $resultWidth $portOutcome]
        }
    }
    puts $str
    puts ""
    update idletasks
    return $overallErrorFlag
}

#
# Clear port error messages stored in info array
#
proc clearAllPortErrors {testInfoVar} {
    upvar 1 $testInfoVar testInfo

    array unset testInfo
    array set testInfo {}
}

