#------------------------------------------------------------------------------
# Name              :   test_ELB.tcl
# Author            :   Julio Marcos
# Purpose           :   Simplistic ApSel switching 
# Copyright         :   (c) 2022 Keysight Technologies - All Rights Reserved
#-------------------------------------------------------------------------------

package require IxTclHal


# Chassis and port parameters
set userName user
set hostName 172.27.45.204
set portList [list  [list 1 1 1] \
                    [list 1 1 4] \
                ]
# set portList [list  [list 1 1 4] \
#                 ]

# Tests to run
set runPmdStats         1
set runSlicerDiags      1
set runBERT             1

#
# Test parameters (Rx Diagnostics - PMD Stats)
#
# -SNR (Signal to Noise Ratio) of around 20 or higher
#  usually indicates good lane performance
set minSNR              20.0
# -Variable Gain Amplifier (VGA) indicates how much the retimer 
#  has to amplify a weak signal. A module that is not providing enough
#  signal will lead to high a VGA (applies to active modules, not passive)
set maxVGA              18

#
# Test parameters (Rx Diagnostics - Slicer Stats)
#
# -Number of ADC/Slicer acquisitions (20 is usually a good number)
set maxAcquisitions     20
# -The projected BER should be low, but remember this is just an estimate
set maxProjBER          1.0e-6
# -Vertical Eye Closure (VEC, in dB): lower the better (more margin)
set maxVEC              15
# -A low eye linearity (Rlm) indicates PAM4 level ratio mismatch
set minRlm              0.940

#
# Test parameters (BERT)
#
# -Max 25G PRBS lane BER 
set maxLaneBER          1e-8
set timeRunBERT         10.0

# Log to a file (tee the stdout)
set logToFile           1
set logFileName         "./elb_log.txt"

#-------------------------  Locked Settings -------------------------#

# Expected Port Speed (BERT/400G-R8)
set portSpeed           BERT

###### Other Parameters for Rx Diagnostics - PMD Stats ######
# Number of PMD stat acquisitions
set pmdAcquisitions     2

# Time per PMD stat acquisition in seconds
set timePerPMDstat      3.0


###### Other Parameters for Rx Diagnostics - Slicer Stats ######
# Time per ADC/Slicer acquisition in seconds
set timePerAcquisition  3.0

# Slicer items to display
set statsLevel          2
set showHistogram       1
set showMeasBathtub     0
set showProjBathtub     0


###### Misc ######
# Formatting widths
set entryWidth          28
set resultWidth         28
set leftJustified       1

# Soak time after mode switch
set waitAfterModeSwitch 10


#------------------------- Global Variables -------------------------#

# Arrays to track:
# a) Port statistics
# b) RxDiag statistics
# c) RxDiag pass/fail info
# d) BERT lane statistics
# e) Overall test pass/fail info
array set portInfo {}
array set diagInfo {}
array set passInfo {}
array set bertInfo {}
array set testInfo {}


#----------------------- Custom Functions -----------------------#

#
# Display detailed port summary with lane dttransceiver info
#
proc showPortLaneSummary {portList portInfoVar diagInfoVar bertInfoVar passInfoVar testInfoVar {maxLane 8}} {
    upvar 1 $portInfoVar portInfo
    upvar 1 $diagInfoVar diagInfo
    upvar 1 $bertInfoVar bertInfo
    upvar 1 $passInfoVar passInfo
    upvar 1 $testInfoVar testInfo

    puts ""
    puts "Detailed Summary:"
    puts "================="
    puts [format "%-4s  %-12s %-16s %-16s %-4s  %-3s  %-3s  %-4s   %-8s  %-4s  %-5s   %-8s  %-4s   %s" \
            QDD Transceiver Transceiver Transceiver QDD  PMD "" "" Slicer VEC "" BERT Lost " "]
    puts [format "%-4s  %-12s %-16s %-16s %-4s  %-3s  %-3s  %-4s   %-8s  %-4s  %-5s   %-8s  %-4s   %s" \
            Port Vendor Model Serial Lane Lck VGA SNR ProjBER (db) Rlm BER Lock Outcome]
    puts [format "%-4s  %-12s %-16s %-16s %-4s  %-3s  %-3s  %-4s   %-8s  %-4s  %-5s   %-8s  %-4s   %s" \
            ---- ------------ ---------------- ---------------- ---- --- --- ---- -------- ---- ----- -------- ---- -------]
    foreach port $portList {
        incr portIndex
        for {set lane 1} {$lane <= $maxLane} {incr lane} {
            set port [convertFQPN $port]
            scan $port {%d %d %d} chasId cardId portId
            set fpp [getFrontPanelPort $port]
            set txcvrVendor $portInfo(TRANSCEIVER_VENDOR,$chasId,$cardId,$portId)
            set txcvrModel  $portInfo(TRANSCEIVER_MODEL,$chasId,$cardId,$portId)
            set txcvrSerial $portInfo(TRANSCEIVER_SERIAL,$chasId,$cardId,$portId)

            # PMD Stats
            if {[info exists diagInfo(lock{$lane},$chasId,$cardId,$portId)]} {
                set pmdTest 1
                set pmdLck $diagInfo(lock{$lane},$chasId,$cardId,$portId)
                set pmdVga $diagInfo(vga{$lane},$chasId,$cardId,$portId)
                set pmdSnr [format "%4.1f" $diagInfo(snr{$lane},$chasId,$cardId,$portId)]
            } else {
                # PMD test was not run
                set pmdTest 0
                set pmdLck "--"
                set pmdVga "--"
                set pmdSnr "--"
            }

            # Slicer Stats
            if {[info exists diagInfo(proj_ber{$lane},$chasId,$cardId,$portId)]} {
                set slicerTest 1
                if {$passInfo(proj_ber{$lane},$chasId,$cardId,$portId) == "N"} {
                    # Slicer test did not return data for this lane
                    set slicerBer [format "%8s" n/a]
                } else {
                    set slicerBer [format "%8.2e" $diagInfo(proj_ber{$lane},$chasId,$cardId,$portId)]
                }
                if {$passInfo(vec{$lane},$chasId,$cardId,$portId) == "N"} {
                    # Slicer test did not return data for this lane
                    set slicerVec [format "%4s" n/a]
                } else {
                    set slicerVec [format "%4.1f" $diagInfo(vec{$lane},$chasId,$cardId,$portId)]
                }
                if {$passInfo(rlm{$lane},$chasId,$cardId,$portId) == "N"} {
                    # Slicer test did not return data for this lane
                    set slicerRlm [format "%5s" n/a]
                } else {
                    set slicerRlm [format "%5.3f" $diagInfo(rlm{$lane},$chasId,$cardId,$portId)]
                }
            } else {
                # Slicer test was not run
                set slicerTest 0
                set slicerBer "--"
                set slicerVec "--"
                set slicerRlm "--"
            }

            # BERT Stats
            # -Will use the combined PAM4 results
            if {[info exists bertInfo(bertBer{$lane},$chasId,$cardId,$portId)]} {
                set bertTest 1
                set bertBerStr [format "%8.2e" $bertInfo(bertBer{$lane},$chasId,$cardId,$portId)]
                set bertLostLock $bertInfo(bertLostLock{$lane},$chasId,$cardId,$portId)
            } else {
                # BERT was not run
                set bertTest 0
                set bertBerStr "--"
                set bertLostLock "--"
            }

            # Outcome string
            set outcome "OK"
            if {$pmdTest} {
                if {$passInfo(lock{$lane},$chasId,$cardId,$portId) == "F"} {
                    set outcome [expr {$outcome == "OK" ? "No_Lock" : "$outcome;No_Lock"}]
                }
                if {$passInfo(vga{$lane},$chasId,$cardId,$portId) == "F"} {
                    set outcome [expr {$outcome == "OK" ? "Hi_VGA" : "$outcome;Hi_VGA"}]
                }
                if {$passInfo(snr{$lane},$chasId,$cardId,$portId) == "F"} {
                    set outcome [expr {$outcome == "OK" ? "Low_SNR" : "$outcome;Low_SNR"}]
                }
            }
            if {$slicerTest} {
                if {$passInfo(proj_ber{$lane},$chasId,$cardId,$portId) == "F"} {
                    set outcome [expr {$outcome == "OK" ? "Hi_projBER" : "$outcome;Hi_projBER"}]
                }
                if {$passInfo(vec{$lane},$chasId,$cardId,$portId) == "F"} {
                    set outcome [expr {$outcome == "OK" ? "Hi_VEC" : "$outcome;Hi_VEC"}]
                }
                if {$passInfo(rlm{$lane},$chasId,$cardId,$portId) == "F"} {
                    set outcome [expr {$outcome == "OK" ? "Low_RlmR" : "$outcome;Low_Rlm"}]
                }                
                if {$passInfo(proj_ber{$lane},$chasId,$cardId,$portId) == "N" || \
                    $passInfo(vec{$lane},$chasId,$cardId,$portId) == "N" || \
                    $passInfo(rlm{$lane},$chasId,$cardId,$portId) == "N"} {
                    set outcome [expr {$outcome == "OK" ? "No_Slicer_Data" : "$outcome;No_Slicer_Data"}]
                }
            }
            if {$bertTest} {
                # We will use the 25G PRBS lane 0..15 info for the BERT BER pass/fail
                if {$passInfo(ber{[expr {($lane-1)*2}]},$chasId,$cardId,$portId) == "F" || \
                    $passInfo(ber{[expr {($lane-1)*2+1}]},$chasId,$cardId,$portId) == "F"} {
                   set outcome [expr {$outcome == "OK" ? "Hi_BER" : "$outcome;Hi_BER"}]
                }
                if {$bertInfo(bertLostLock{$lane},$chasId,$cardId,$portId) == "Yes"} {
                    set outcome [expr {$outcome == "OK" ? "Lost_Lock" : "$outcome;Lost_Lock"}]
                }
            }

            puts [format "%-4s  %-12s %-16s %-16s %-4s  %-3s  %-3s  %-4s   %-8s  %-4s  %-5s   %-8s  %-4s   %s" \
                $fpp $txcvrVendor $txcvrModel $txcvrSerial \
                $lane $pmdLck $pmdVga $pmdSnr $slicerBer $slicerVec $slicerRlm $bertBerStr $bertLostLock $outcome]
        }
        puts ""
    }
}

#
# Display port summary
#
proc showOverallSummary {portList portInfoVar testInfoVar} {
    upvar 1 $portInfoVar portInfo
    upvar 1 $testInfoVar testInfo

    set failCount 0

    puts ""
    puts "Overall Summary:"
    puts "================"
    puts [format "%-4s  %-12s %-16s %-16s %s" Port Vendor Model Serial  Outcome]
    puts [format "%-4s  %-12s %-16s %-16s %s" ---- ------------ ---------------- ---------------- -------]
    foreach port $portList {
        incr portIndex
        set port [convertFQPN $port]
        scan $port {%d %d %d} chasId cardId portId
        set fpp [getFrontPanelPort $port]
        set txcvrVendor $portInfo(TRANSCEIVER_VENDOR,$chasId,$cardId,$portId)
        set txcvrModel  $portInfo(TRANSCEIVER_MODEL,$chasId,$cardId,$portId)
        set txcvrSerial $portInfo(TRANSCEIVER_SERIAL,$chasId,$cardId,$portId)

        # Outcome string
        set outcome "Pass"
        if {[info exists testInfo(PORT_FAIL,$chasId,$cardId,$portId)] && \
            $testInfo(PORT_FAIL,$chasId,$cardId,$portId) > 0} {
            set outcome "FAIL"
            incr failCount
        }
        puts [format "%-4s  %-12s %-16s %-16s %s" \
            $fpp $txcvrVendor $txcvrModel $txcvrSerial $outcome]
    }
    puts ""

    return $failCount
}


#
#------------------------------ MAIN FUNCTION ------------------------------#
#

# Source shared functions; but avoid relative path issues
source [file join [file dirname [info script]] "./Common/general_functions.tcl"]
source [file join [file dirname [info script]] "./Common/txcvr_functions.tcl"]
source [file join [file dirname [info script]] "./Common/rxdiag_functions.tcl"]
source [file join [file dirname [info script]] "./Common/bert_functions.tcl"]
source [file join [file dirname [info script]] "./Common/tee.tcl"]

# Optional tee to a file
if {$logToFile} {
    set tee [tee append stdout $logFileName]
}

puts "Test Parameters:"
puts "-run PMD Stats      : $runPmdStats"
puts "-run Slicer Diags   : $runSlicerDiags"
puts "-run BERT           : $runBERT"
puts "-Min SNR            : $minSNR"
puts "-Max VGA            : $maxVGA"
puts "-Slicer Acquisitions: $maxAcquisitions"
puts "-Max Projected BER  : $maxProjBER"
puts "-Max VEC            : $maxVEC"
puts "-Max Rlm            : $minRlm"
puts "-BERT Max Lane BER  : $maxLaneBER"
puts "-BERT test time     : $timeRunBERT"
# puts "-pmdAcquisitions   : $pmdAcquisitions"
# puts "-statsLevel        : $statsLevel"
# puts "-showHistogram     : $showHistogram"
# puts "-showMeasBathtub   : $showMeasBathtub"
# puts "-showProjBathtub   : $showProjBathtub"
# puts "-timePerPMDstat    : $timePerPMDstat s"
# puts "-timePerAcquisition: $timePerAcquisition s"
puts ""

#----------------------- Chassis Connectivity -----------------------#

# Connect to TCL Server if running from Unix
if {[isUNIX] && [ixConnectToTclServer $hostName]} {
    errorMsg "Could not connect to Tcl Server $hostName"
    return $::TCL_ERROR
}

# Now connect to chassis
if {[ixConnectToChassis $hostName]} {
    errorMsg "Could not connect to chassis $hostName"
    return $::TCL_ERROR
}

# Login and take port ownership
ixLogin $userName
if {[ixTakeOwnership $portList]} {
    errorMsg "Could not take ownership of $portList"
    return $::TCL_ERROR
}
puts ""

#----------------------- Port Info -----------------------#
# Show port list header
showPortHeadersWithIP $portList $entryWidth $resultWidth

# Get environment info per port
getEnvironmentInfo $portList portInfo
showEnvironmentInfo $portList portInfo $entryWidth $resultWidth

# Show transceiver info
getTransceiverInfo $portList portInfo
showTransceiverInfo $portList portInfo $entryWidth $resultWidth

# Show port EQ Info
getElectricalInterfaceInfo $portList portInfo
showElectricalInterfaceInfo $portList portInfo $entryWidth $resultWidth

puts ""
puts [format "Time of Test: %s" [clock format [clock seconds] -format "%Y-%b-%d %H:%M:%S"]]
sleep 1

#-------------------------------- TEST START --------------------------------#

# Number of fails recorded
set failCount 0
set warnCount 0

# Min/Max lanes available at current port speed
set minLane 1
set maxLane $maxLaneNumber($portSpeed)
set allLaneMask $allLanes($portSpeed)

# Rx Diag Feature Check
# -This would PMD stats and ADC histograms
foreach port $portList {
    scan $port {%d %d %d} chasId cardId portId
    if {![port isValidFeature $chasId $cardId $portId portFeatureRxLaneDiag]} {
        errorMsg "ERROR - portFeatureRxLaneDiag (basic diagnostics) is NOT a valid feature for port {$port}"
        ixClearOwnership $portList
        return $::TCL_ERROR
    }
}

# Rx Diag Slicer Feature Check
# -This would be for the Slicer histograms with BER projections
foreach port $portList {
    scan $port {%d %d %d} chasId cardId portId
    set fullDiags [port isValidFeature $chasId $cardId $portId portFeatureRxLaneFullDiag]
    if {!$fullDiags} {
        puts "ERROR - portFeatureRxLaneFullDiag (full diagnostics) is NOT a valid feature for port {$port}"
        ixClearOwnership $portList
        return $::TCL_ERROR
    }
}

# BERT feature check
foreach port $portList {
    scan $port {%d %d %d} chasId cardId portId
    if {![port isValidFeature $chasId $cardId $portId $::portFeatureBert]} {
        puts "ERROR - Port {$port} doesn't have BERT capability"
        ixClearOwnership $portList
        return $::TCL_ERROR
    }
}

# Perform speed mode change if there is a mismatch
puts ""
puts "Will now check all ports and mode switch if necessary:"
if {[modeSwitch $portList $portSpeed $waitAfterModeSwitch]} {
    errorMsg "ERROR: could not perform speed mode switch!"
    ixClearOwnership $portList
    return $::TCL_ERROR
}
puts ""

clearAllPortErrors testInfo
clearAllPortErrors diagInfo
clearAllPortErrors bertInfo
clearAllPortErrors passInfo


#----------------------- PMD Stats -----------------------#

if {$runPmdStats} {
    puts "=============== Check Retimer PMD Stats ==============="
    # Reset acquisitions
    puts "Clearing acquisitions..."
    set allLaneMask $allLanes($portSpeed)
    foreach port $portList {
        scan $port {%d %d %d} chasId cardId portId
        if {[rxLaneDiag resetPmdStats $chasId $cardId $portId $allLaneMask]} {
            errorMsg "ERROR - Could not issue resetPmdStats command on port {$port}"
            incr failCount 
        }
    }
    sleep 500

    # Start acquisitions
    foreach port $portList {
        scan $port {%d %d %d} chasId cardId portId
        if {[rxLaneDiag readPmdStats $chasId $cardId $portId $allLaneMask $pmdAcquisitions]} {
            errorMsg "ERROR - Could not issue readPmdStats command on port {$port}"
            incr failCount 
        }
    }
    set waitTime [expr {$pmdAcquisitions * $timePerPMDstat}]
    puts [format "Running %d PMD acquisition%s and waiting for %.1fs..." \
                 $pmdAcquisitions [expr {$pmdAcquisitions ? "s" : ""}] $waitTime]
    sleepSeconds $waitTime

    # Now get the PMD results
    showPortHeadersWithIP $portList $entryWidth $resultWidth
    showTransceiverShortInfo $portList portInfo $entryWidth $resultWidth
    checkPMDLanes $portList $portSpeed diagInfo passInfo testInfo $minSNR $maxVGA 

    #-------- Summary and Pass/Fail Analysis --------#
    set failCount [showAllPortOutcomes $portList testInfo $entryWidth $resultWidth $leftJustified]
    showAllPortErrors $portList testInfo "Port analysis:"
    puts ""
}


#----------------------- Slicer Histograms -----------------------#

if {$runSlicerDiags} {
    puts ""
    puts "=============== Slicer PAM4 Histograms ==============="
    puts "Clearing acquisitions..."
    # Reset acquisitions
    set allLaneMask $allLanes($portSpeed)
    foreach port $portList {
        scan $port {%d %d %d} chasId cardId portId
        if {[rxLaneDiag resetSlicerHistograms $chasId $cardId $portId $allLaneMask]} {
            if {!$fullDiags} {
                # No full diags enabled in chassis, so it's expected to have the error
                puts "Note: no full diags enabled, hence could not issue resetSlicerHistograms command on port {$port}"
            } else {
                # Full diags enabled but still had error with Slicer access
                errorMsg "ERROR - Could not issue resetSlicerHistograms command on port {$port}"
                incr failCount
            }
        }
    }
    sleep 500

    # Start acquisitions
    foreach port $portList {
        scan $port {%d %d %d} chasId cardId portId
        if {[rxLaneDiag acquireSlicerHistograms $chasId $cardId $portId $allLaneMask $maxAcquisitions]} {
            if {!$fullDiags} {
                # No full diags enabled in chassis, so it's expected to have the error
                puts "Note: no full diags enabled, hence could not issue acquireSlicerHistograms command on port {$port}"
            } else {
                # Full diags enabled but still had error with Slicer access
                errorMsg "ERROR - Could not issue acquireSlicerHistograms command on port {$port}"
                incr failCount
            }
        }
    }
    set waitTime [expr {$maxAcquisitions * $timePerAcquisition}]
    puts [format "Running %d Slicer acquisitions and waiting for %.1fs..." $maxAcquisitions $waitTime]
    sleepSeconds $waitTime

    # Now get the Slicer results
    foreach port $portList {
        scan $port {%d %d %d} chasId cardId portId
        if {[rxLaneDiag getHistograms $chasId $cardId $portId]} {
            errorMsg "ERROR - Could not issue getHistograms command on port {$port}"
            incr failCount 
        }
        for {set lane $minLane} {$lane <= $maxLane} {incr lane} { 
            # Prepare Pass/Fail info
        set slicerResultStr [getSlicerResult $port $lane diagInfo passInfo testInfo  $maxProjBER $maxVEC $minRlm\
                            $statsLevel $showHistogram $showMeasBathtub $showProjBathtub]
            if {$slicerResultStr eq ""} {
                puts "Slicer Histogram Port {$port} Lane $lane: no data"
            } else {
                puts "Slicer Histogram Port {$port} Lane $lane:"
                puts $slicerResultStr
            } 
        }
        puts ""
    }
}


#----------------------- Slicer Histograms -----------------------#

if {$runBERT} {
    puts ""
    puts "=============== BERT ==============="
    # Clear Port and lane BERT stats
    puts "Clearing BERT stats..."
    clearAllPortBERT $portList

    # Waiting for specified time period
    puts "Waiting for $timeRunBERT seconds..."
    sleepSeconds $timeRunBERT

    # ---------------- BERT Lane Statistics -------------------
    foreach port $portList {
        checkBERTLaneStats $port bertInfo passInfo testInfo $maxLaneBER
    }
}


#-------- Summary and Pass/Fail Analysis --------#

showPortLaneSummary $portList portInfo diagInfo bertInfo passInfo testInfo
incr failCount [showOverallSummary $portList portInfo testInfo]

if {$failCount} {
    puts "ERROR - Issues found in test!"    
    ixClearOwnership $portList
    chan pop stdout
    return $::TCL_ERROR
} else {
    puts "No issues found."
}

ixClearOwnership $portList
chan pop stdout
return $::TCL_OK

