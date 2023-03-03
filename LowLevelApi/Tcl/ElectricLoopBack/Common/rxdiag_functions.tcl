#------------------------------------------------------------------------------
# Name              :   rxdiag_functions.tcl
# Author            :   Julio Marcos
# Purpose           :   Functions for Rx Diagnostics (Eye Histograms)
# Copyright         :   (c) 2022 Keysight Technologies - All Rights Reserved
#-------------------------------------------------------------------------------


#---------------------- Global Lookups ----------------------#

# All lane mask per port speed
array set allLanes {
    400000      0xFF
    200000      0x0F
    100000      0x03
    50000       0x01
    BERT        0xFF
    400G-R8     0xFF
    200G-R4     0x0F
    100G-R2     0x03
    50G-R       0x01
}


#---------------------- PAM4 Rx Eye Histogram Functions ----------------------#

#
# Pretty print PMD stats
#
proc formatPmdStats {statsStr} {
    if {$statsStr eq ""} {
        return ""
    }
    return [format "Status=%-6s  VGA=%-2d  CTLE=%-2d  SNR=%-4.1f db  FFO=%4.1f ppm" \
		[lindex $statsStr 2] \
		[expr {[lindex $statsStr 3]}] \
		[expr {[lindex $statsStr 4]}] \
		[expr {[lindex $statsStr 5]}] \
		[expr {[lindex $statsStr 6]}]]
}

proc checkPMDLanes {portList speed pmdInfoVar passInfoVar testInfoVar {minSNR 20} {maxVGA 20} {entryWidth 28} {resultWidth 28}}\
{
    global pcsLaneList
    global maxLaneNumber
    global allLanes
    upvar 1 $pmdInfoVar pmdInfo
    upvar 1 $passInfoVar passInfo
    upvar 1 $testInfoVar testInfo

    set report stdout

    # Min/Max lanes available at current port speed
    set minLane 1
    set maxLane $maxLaneNumber($speed)
    set allLaneMask $allLanes($speed)

    # Gather PMD lane stats across all ports
    puts "PMD Lane Statistics:"
    foreach port $portList {
        scan $port "%d %d %d" chasId cardId portId
        if {[rxLaneDiag getPmdStats $chasId $cardId $portId]} {
            errorMsg "ERROR - Could not issue getPmdStats command on port {$port}"
            puts ""
            return $::TCL_ERROR
        }
        # Get lane stats
        for {set lane $minLane} {$lane <= $maxLane} {incr lane} { 
            set pmdStats [rxLaneDiag returnPmdStat $lane]
            if {$pmdStats eq ""} {
                set lock "N"
                set vga  99
                set ctle 0
                set snr  0.0
                set ffo  0.0
            } else {
                set lock [lindex $pmdStats 2]
                set vga  [lindex $pmdStats 3]
                set ctle [lindex $pmdStats 4]
                set snr  [format "%4.1f" [lindex $pmdStats 5]]
                set ffo  [format "%.1f" [lindex $pmdStats 6]]
                if {$ffo >= 100 || $ffo <= -10} {
                    # Want 4 digits max including -ve sign when less than 10
                    set ffo  [format "%.0f" $ffo]
                }
            }
            set pmdInfo(lock{$lane},$chasId,$cardId,$portId)  [expr {$lock == "Lock" ? "Y" : "N"}]
            set pmdInfo(vga{$lane},$chasId,$cardId,$portId)   $vga
            set pmdInfo(ctle{$lane},$chasId,$cardId,$portId)  $ctle
            set pmdInfo(snr{$lane},$chasId,$cardId,$portId)   $snr
            set pmdInfo(ffo{$lane},$chasId,$cardId,$portId)   $ffo
        }
    }

    # Error checks
    foreach port $portList {
        set noLockFlag 0
        set vgaFlag  0
        set snrFlag  0
        scan $port "%d %d %d" chasId cardId portId
        for {set lane $minLane} {$lane <= $maxLane} {incr lane} { 
            set lock $pmdInfo(lock{$lane},$chasId,$cardId,$portId)
            set vga  $pmdInfo(vga{$lane},$chasId,$cardId,$portId)
            set snr  $pmdInfo(snr{$lane},$chasId,$cardId,$portId)

            # Prepare Pass/Fail info
            set passInfo(lock{$lane},$chasId,$cardId,$portId) " "
            set passInfo(vga{$lane},$chasId,$cardId,$portId) " "
            set passInfo(snr{$lane},$chasId,$cardId,$portId) " "

            # First check for lane lock
            if {$lock == "N"} {
                set noLockFlag 1
                set passInfo(lock{$lane},$chasId,$cardId,$portId) "F"
            } else {
                # Check VGA gain to see if RxOut EQ setting from the module is too low
                if {$vga > $maxVGA} {
                    set vgaFlag 1
                    set passInfo(vga{$lane},$chasId,$cardId,$portId) "F"
                }
                # Check SNR threshold
                if {$snr < $minSNR} {
                    set snrFlag 1
                    set passInfo(snr{$lane},$chasId,$cardId,$portId) "F"     
                }
            }
        }
        if {$noLockFlag} {
            set testInfo(PORT_FAIL,$chasId,$cardId,$portId) 1
            lappend testInfo(PORT_INFO_STR,$chasId,$cardId,$portId) \
                "Fail: port {$port} has lost lock on some PMD lanes; module might be suspect."
        }
        if {$vgaFlag} {
            set testInfo(PORT_FAIL,$chasId,$cardId,$portId) 1
            lappend testInfo(PORT_INFO_STR,$chasId,$cardId,$portId) \
                "Fail: port {$port} has lane(s) with VGA > $maxVGA; might indicate not enough signal from trasnceiver."
        }
        if {$snrFlag} {
            set testInfo(PORT_FAIL,$chasId,$cardId,$portId) 1
            lappend testInfo(PORT_INFO_STR,$chasId,$cardId,$portId) \
                "Fail: port {$port} has lane(S) with SNR < $minSNR; module might be suspect."
        }
    }

    # Format output for side-by-side display
    set fmt "%-*s    "
    set str1 "PMD FFO             SNR"
    set str2 "Lck ppm  CTLE VGA   (dB)  "
    set str3 "--- ---- ---- ----  ------"
    foreach port $portList {
        append outStr1 [format $fmt $resultWidth $str1]
        append outStr2 [format $fmt $resultWidth $str2]
        append outStr3 [format $fmt $resultWidth $str3]
    }
    puts $report [format {%-*s  %s} $entryWidth "" $outStr1]
    puts $report [format {%-*s  %s} $entryWidth "" $outStr2]
    puts $report [format {%-*s  %s} $entryWidth "" $outStr3]

    set strFmt " %1s  %4s %3s  %2s %1s  %4s %1s      "
    foreach port $portList {
        scan $port "%d %d %d" chasId cardId portId
        for {set lane $minLane} {$lane <= $maxLane} {incr lane} { 
            append pmdStr($lane) [format $strFmt \
                $pmdInfo(lock{$lane},$chasId,$cardId,$portId) \
                $pmdInfo(ffo{$lane},$chasId,$cardId,$portId)  \
                $pmdInfo(ctle{$lane},$chasId,$cardId,$portId) \
                $pmdInfo(vga{$lane},$chasId,$cardId,$portId)  $passInfo(vga{$lane},$chasId,$cardId,$portId) \
                $pmdInfo(snr{$lane},$chasId,$cardId,$portId)  $passInfo(snr{$lane},$chasId,$cardId,$portId)]
        }
    }
    for {set lane $minLane} {$lane <= $maxLane} {incr lane} { 
        puts $report [format {%-*s  %s} $entryWidth "PMD Statistics Lane $lane" $pmdStr($lane)]
    }
    puts ""
}



#
# Create histogram plot from histogram Y values
# (return is equivalent to returnSlicerHistogramString)
#
proc getHistogramResultPlot {histogramResult {plotHeight 20} {lineStart  "    "}} {
    set max [tcl::mathfunc::max {*}$histogramResult]
    if { $max == 0 } { set max [expr 1] }
    list heights []
    foreach value $histogramResult {
        lappend heights [expr {(0.0 + $value) / (0.0 + $max) * (0.0 + $plotHeight)}]
    }
    set result ""
    set first 1
    for {set y 0} {$y < $plotHeight} {incr y} {
	if { $y != 0 } {
	    append result "\n$lineStart"
	}
	foreach height $heights {
	    set gauge [expr {0.0 + $plotHeight - $y - $height}]
	    if { $gauge >= 1.0 } {
		append result " "
	    } elseif { $gauge >= 0.7 } {
		append result "."
	    } elseif { $gauge >= 0.4 } {
		append result "x"
	    } else {
		append result "X"
	    }
	}
    }
    append result [format "\n%s%s" $lineStart [string repeat "-" [llength $histogramResult]]]
    return $result
}


#
# Create log histogram plot from histogram Y values
# (return is equivalent to returnMeasuredBathtubString or returnProjecteddBathtubString)
#
proc getHistogramResultPlotLogY {histogramResult {plotHeight 20} {lineStart  "    "}} {
    if {$histogramResult eq ""} {
        return ""
    }
    set min [tcl::mathfunc::min {*}$histogramResult]
    set max [tcl::mathfunc::max {*}$histogramResult]
    set logMin [expr {log10(0.0 + $min)}]
    set logMax [expr {log10(0.0 + $max)}]
    list logHistogramResult [lrange $histogramResult 0 2]
    foreach value $histogramResult {
	lappend logHistogramResult [expr {(log10(0.0 + $value) - $logMin) / ($logMax - $logMin)}]
    }
    return [getHistogramResultPlot $logHistogramResult $plotHeight $lineStart]
}

proc trimResult {result} {
    return [lrange $result 3 end]
}


#
# Return a printable Slicer histogram and statistics per lane
#
# Parameter: lane (1..8)
#            showStatsLevel: 0=no stats; 1=just lane level; 2=all, including PAM4 eyes
# -If no data is available, returns empty string
#
proc getSlicerResult {port lane diagInfoVar passInfoVar testInfoVar {maxProjBER 1e-6} {maxVEC 10} {minRlm 0.950} 
                      {statsLevel 1} {showHistogram 1} {showMeasBathtub 1} {showProjBathtub 1} {plotHeight 20} {lineStart  "    "}} {
    upvar 1 $diagInfoVar diagInfo
    upvar 1 $passInfoVar passInfo
    upvar 1 $testInfoVar testInfo

    scan $port "%d %d %d" chasId cardId portId
    
    set diagInfo(proj_ber{$lane},$chasId,$cardId,$portId) -1
    set diagInfo(vec{$lane},$chasId,$cardId,$portId) -1
    set diagInfo(rlm{$lane},$chasId,$cardId,$portId) -1
    set passInfo(proj_ber{$lane},$chasId,$cardId,$portId) " "
    set passInfo(vec{$lane},$chasId,$cardId,$portId) " "
    set passInfo(rlm{$lane},$chasId,$cardId,$portId) " "

    set histogram_string [rxLaneDiag returnSlicerHistogramString $lane $plotHeight]

    # No histogram data
    if {[llength $histogram_string] == 0} {
        set passInfo(proj_ber{$lane},$chasId,$cardId,$portId) "N"
        set passInfo(vec{$lane},$chasId,$cardId,$portId) "N"
        set passInfo(rlm{$lane},$chasId,$cardId,$portId) "N"
        set testInfo(PORT_FAIL,$chasId,$cardId,$portId) 1
        return ""
    }

    set rx_level_means         [rxLaneDiag returnLevelMeans $lane]
    set rx_level_stddevs       [rxLaneDiag returnLevelStdDevs $lane]
    set rx_eye_height_3stddevs [rxLaneDiag returnEyeHeightsForStdDev $lane 3]
    set rx_eye_height_6stddevs [rxLaneDiag returnEyeHeightsForStdDev $lane 6]
    set rx_eye_height_6        [rxLaneDiag returnEyeHeightsForBER $lane 1.0E-6]
    set rx_eye_height_8        [rxLaneDiag returnEyeHeightsForBER $lane 1.0E-8]
    set rx_eye_height_12       [rxLaneDiag returnEyeHeightsForBER $lane 1.0E-12]
    set sers                   [rxLaneDiag returnProjectedSERs $lane]
    set ber                    [rxLaneDiag returnProjectedBER $lane]
    set vec                    [rxLaneDiag returnVEC $lane]
    set rlm                    [rxLaneDiag returnRlm $lane]

    # When there is too few acquisitions, there won't be statistics yet
    if {$rx_level_means eq ""} {
        set rx_level_means         {0 0 0 0}
        set rx_level_stddevs       {0 0 0 0}
        set rx_eye_height_3stddevs {0 0 0}
        set rx_eye_height_6stddevs {0 0 0}
        set rx_eye_height_6        {0 0 0}
        set rx_eye_height_8        {0 0 0}
        set rx_eye_height_12       {0 0 0}
        set sers                   {0 0 0}
    }

    if {$ber eq NaN} {
        set ber 0
        set berStr "n/a"
        set passInfo(proj_ber{$lane},$chasId,$cardId,$portId) "N"
    } else {
        set berStr [format "%9.2e" $ber]
        set diagInfo(proj_ber{$lane},$chasId,$cardId,$portId) $berStr
    }
    if {$vec eq NaN} {
        set vec 0
        set vecStr "n/a"
        set passInfo(vec{$lane},$chasId,$cardId,$portId) "N"
    } else {
        set vecStr [format "%5.2f dB" $vec]
        set diagInfo(vec{$lane},$chasId,$cardId,$portId) [format "%5.2f" $vec]
    }
    if {$rlm eq NaN} {
        set rlm 0
        set rlmStr "n/a"
        set passInfo(rlm{$lane},$chasId,$cardId,$portId) "N"
    } else {
        set rlmStr [format "%5.3f" $rlm]
        set diagInfo(rlm{$lane},$chasId,$cardId,$portId) $rlmStr
    }

    set histogram_info           [rxLaneDiag returnSlicerHistogramResult $lane]
    set measured_bathtub         [rxLaneDiag returnMeasuredBathtub $lane]
    set measured_bathtub_string  [rxLaneDiag returnMeasuredBathtubString $lane $plotHeight]
    set projected_bathtub        [rxLaneDiag returnProjectedBathtub $lane]
    set projected_bathtub_string [rxLaneDiag returnProjectedBathtubString $lane $plotHeight]

    # Prepare Pass/Fail info
    set berFlag 0
    set vecFlag  0
    set rlmFlag  0

    # Check metrics against thresholds
    if {$ber > $maxProjBER} {
        set berFlag 1
        set passInfo(proj_ber{$lane},$chasId,$cardId,$portId) "F"
    }
    if {$vec > $maxVEC} {
        set vecFlag 1
        set passInfo(vec{$lane},$chasId,$cardId,$portId) "F"     
    }
    if {$rlm < $minRlm && $rlm > 0} {
        set rlmFlag 1
        set passInfo(rlm{$lane},$chasId,$cardId,$portId) "F"     
    }
    if {$berFlag || $vecFlag || $rlmFlag} {
        set testInfo(PORT_FAIL,$chasId,$cardId,$portId) 1
    }

    set result [format "%sAcquisitions: %-3d Remaining: %-3d"\
                        $lineStart [lindex $histogram_info 1] [lindex $histogram_info 2]]
    if {$statsLevel > 0} {
        if {$statsLevel > 1} {
            # PAM4 level
            append result    [format   "\n%s                  Level 0         Level 1         Level 2         Level 3" $lineStart]
            append result [format "\n%s                  --------        --------        --------        --------" $lineStart]
            append result [format "\n%s           Mean   %4.1f %%fs        %4.1f %%fs        %4.1f %%fs        %4.1f %%fs" \
                            $lineStart \
                    [expr {[lindex $rx_level_means 0] * 100}] \
                    [expr {[lindex $rx_level_means 1] * 100}] \
                    [expr {[lindex $rx_level_means 2] * 100}] \
                    [expr {[lindex $rx_level_means 3] * 100}]]
            append result [format "\n%s         StdDev   %4.2f %%fs        %4.2f %%fs        %4.2f %%fs        %4.2f %%fs" \
                    $lineStart \
                    [expr {[lindex $rx_level_stddevs 0] * 100}] \
                    [expr {[lindex $rx_level_stddevs 1] * 100}] \
                    [expr {[lindex $rx_level_stddevs 2] * 100}] \
                    [expr {[lindex $rx_level_stddevs 3] * 100}]]
            append result [format "\n%s Height @6sigma          %5.1f %%fs       %5.1f %%fs       %5.1f %%fs" \
                    $lineStart \
                    [expr {[lindex $rx_eye_height_6stddevs 0] * 100}] \
                    [expr {[lindex $rx_eye_height_6stddevs 1] * 100}] \
                    [expr {[lindex $rx_eye_height_6stddevs 2] * 100}]]
            append result [format "\n%s        @10^-8           %5.1f %%fs       %5.1f %%fs       %5.1f %%fs" \
                    $lineStart \
                    [expr {[lindex $rx_eye_height_8 0] * 100}] \
                    [expr {[lindex $rx_eye_height_8 1] * 100}] \
                    [expr {[lindex $rx_eye_height_8 2] * 100}]]
            append result [format "\n%s            SER          %9.2e       %9.2e       %9.2e" \
                    $lineStart \
                    [expr {[lindex $sers 0]}] \
                    [expr {[lindex $sers 1]}] \
                    [expr {[lindex $sers 2]}]]
            set ser0Str [format "10^%-4.2f" [expr {[lindex $sers 0] == 0 ? 0: log10([lindex $sers 0])}]]
            set ser1Str [format "10^%-4.2f" [expr {[lindex $sers 1] == 0 ? 0: log10([lindex $sers 1])}]]
            set ser2Str [format "10^%-4.2f" [expr {[lindex $sers 2] == 0 ? 0: log10([lindex $sers 2])}]]
        }
        # Lane level
        append result [format "\n%s            BER                          %9s %1s" \
                $lineStart \
                $berStr \
                $passInfo(proj_ber{$lane},$chasId,$cardId,$portId)]
        append result [format "\n%s            VEC                           %8s %1s" \
                $lineStart \
                $vecStr \
                $passInfo(vec{$lane},$chasId,$cardId,$portId)]
        append result [format "\n%s            Rlm                              %5s %1s" \
                $lineStart \
                $rlmStr \
                $passInfo(rlm{$lane},$chasId,$cardId,$portId)]
        append result "\n"
    }
    if {$showHistogram} {
        append result [format "\n%s%s" $lineStart [join $histogram_string [format "\n%s" $lineStart]]]
    }
    if {$showMeasBathtub} {
        append result "\nMeasured Bathtub:\n"
        append result [format "\n%s%s" $lineStart [join $measured_bathtub_string [format "\n%s" $lineStart]]]
    }
    if {$showProjBathtub} {
        append result "\nProjected Bathtub:\n"
        append result [format "\n%s%s" $lineStart [join $projected_bathtub_string [format "\n%s" $lineStart]]]
    }
    if {$showHistogram || $showMeasBathtub || $showProjBathtub} {
        append result "\n"
    }
    return $result
}
