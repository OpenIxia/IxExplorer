#------------------------------------------------------------------------------
# Name              :   BERT_functions.tcl
# Author            :   Julio Marcos
# Purpose           :   Functions for BERT
# Copyright         :   (c) 2022 Keysight Technologies - All Rights Reserved
#-------------------------------------------------------------------------------


#---------------------- Global Lookups ----------------------#

# Max BERT Lane count
set maxLanex8      7
set maxLanex16     15

#
# The patterns with ~ are a shorthand for inverted
# -Also we will designate the 'Q' patterns with an index of +100
#  (even though internally we figure-out with a different property)
array set prbsPatternName {
    0       Unknown
    24      PRBS-7
    25      PRBS-9
    12      PRBS-11
    30      PRBS-13
    13      PRBS-15
    14      PRBS-20
    15      PRBS-23
    11      PRBS-31
    16      ~PRBS-7
    17      ~PRBS-9
    4       ~PRBS-11
    5       ~PRBS-15 
    22      ~PRBS-13
    6       ~PRBS-20
    7       ~PRBS-23 
    3       ~PRBS-31
    32      Auto
    23      23
    100     Unknown
    124     PRBS-7Q
    125     PRBS-9Q
    112     PRBS-11Q
    130     PRBS-13Q
    113     PRBS-15Q
    114     PRBS-20Q
    115     PRBS-23Q
    111     PRBS-31Q
    116     ~PRBS-7Q
    117     ~PRBS-9Q
    104     ~PRBS-11Q
    105     ~PRBS-15Q
    122     ~PRBS-13Q
    106     ~PRBS-20Q
    107     ~PRBS-23Q
    103     ~PRBS-31Q
}

 array set txPrbsPattern {
    PRBS-7       24
    PRBS-9       25
    PRBS-11      12    
    PRBS-15      13
    PRBS-13      30
    PRBS-20      14
    PRBS-23      15
    PRBS-31      11
    PRBS-7INV    16
    PRBS-9INV    17
    PRBS-11INV   4    
    PRBS-15INV   5
    PRBS-13INV   22
    PRBS-20INV   6
    PRBS-23INV   7
    PRBS-31INV   3
}

 array set rxPrbsPattern {
    PRBS-7       24
    PRBS-9       25
    PRBS-11      12    
    PRBS-15      13
    PRBS-13      30
    PRBS-20      14
    PRBS-23      15
    PRBS-31      11
    PRBS-7INV    16
    PRBS-9INV    17
    PRBS-11INV   4    
    PRBS-15INV   5
    PRBS-13INV   22
    PRBS-20INV   6
    PRBS-23INV   7
    PRBS-31INV   3
    Auto        32
}

array set lockLostIcon {
    0 Yes
    2 No
    3 Pre
}




#---------------------- BERT Functions ----------------------#

#
# Description: 25G BERT Lane stats check
#              -No need to call getAllPortStats function beforehand 
# Arguments  : port
#              bert info array: will store the lane BERT info for each port
#              maxBER: maximum per lane BER, leave the default to 1.0 for worst case
#              option: "quiet", "x16-full", "x16-compact"
#              option2: "noLatch" to skip stats latching
#              laneVector: TBD
#              laneErrVector: TBD
# Returns    : 0 if no errors found, 1 if otherwise
#
proc checkBERTLaneStats {port bertInfoVar passInfoVar testInfoVar {maxLaneBER 1.0} {option "x16-compact"} {option2 "latch"} \
    {laneVector {0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15}} {laneErrVector {0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0}} }\
{
    global prbsPatternName
    global lockLostIcon
    upvar 1 $bertInfoVar bertInfo
    upvar 1 $passInfoVar passInfo
    upvar 1 $testInfoVar testInfo

    set verbose [expr {$option == "quiet" ? 0 : 1}]

    set port [convertFQPN $port]
    scan $port "%d %d %d" chasId cardId portId

    # Initialize total counts
    set bertInfo(bitsTx{total},$chasId,$cardId,$portId) 0
    set bertInfo(bitsRx{total},$chasId,$cardId,$portId) 0
    set bertInfo(bitErrorsRx{total},$chasId,$cardId,$portId) 0
    set bertInfo(mistmatched1s{total},$chasId,$cardId,$portId) 0
    set bertInfo(mistmatched0s{total},$chasId,$cardId,$portId) 0
    set bertInfo(ber{total},$chasId,$cardId,$portId) 0
    set bertInfo(ser{total},$chasId,$cardId,$portId) 0
    set bertInfo(mistmatched1Ratio{total},$chasId,$cardId,$portId) 0
    set bertInfo(mistmatched0Ratio{total},$chasId,$cardId,$portId) 0
    set bertInfo(lockLostCount{total},$chasId,$cardId,$portId) 0

    # Get the BERT lane stats (16 lanes, even if only want to show 8x50G lanes)
    for {set lane 0} {$lane < 16} {incr lane} {
        if {$option2 == "noLatch"} {
            # Optional skip of BERT lane statistic latching
            continue
        }
        stat getBertLane $chasId $cardId $portId $lane

        # 25G lane stats
        set bertInfo(patternLock{$lane},$chasId,$cardId,$portId)    [expr {[stat cget -bertPatternLock] == 1 ? "Y" : "N"}]
        set bertInfo(patternTx{$lane},$chasId,$cardId,$portId)      $prbsPatternName([stat cget -bertPatternTransmitted])
        set bertInfo(patternRx{$lane},$chasId,$cardId,$portId)      $prbsPatternName([stat cget -bertPatternReceived])
        set bertInfo(bitsTx{$lane},$chasId,$cardId,$portId)         [stat cget -bertBitsSent]
        set bertInfo(bitsRx{$lane},$chasId,$cardId,$portId)         [stat cget -bertBitsReceived]
        set bertInfo(bitErrorsTx{$lane},$chasId,$cardId,$portId)   [stat cget -bertBitErrorsSent]
        set bertInfo(bitErrorsRx{$lane},$chasId,$cardId,$portId)    [stat cget -bertBitErrorsReceived]
        set bertInfo(ber{$lane},$chasId,$cardId,$portId)            [stat cget -bertBitErrorRatio]
        set bertInfo(mistmatched1s{$lane},$chasId,$cardId,$portId)      [stat cget -bertNumberMismatchedOnes]
        set bertInfo(mistmatched0s{$lane},$chasId,$cardId,$portId)      [stat cget -bertNumberMismatchedZeros]
        set bertInfo(mistmatched1Ratio{$lane},$chasId,$cardId,$portId)  [stat cget -bertMismatchedOnesRatio]
        set bertInfo(mistmatched0Ratio{$lane},$chasId,$cardId,$portId)  [stat cget -bertMismatchedZerosRatio]
        set bertInfo(lostLock{$lane},$chasId,$cardId,$portId)           $lockLostIcon([stat cget -bertPatternLockLost])
    }

    # Run totals over all lanes
    for {set lane 0} {$lane < 16} {incr lane} {
        incr bertInfo(bitsTx{total},$chasId,$cardId,$portId)      $bertInfo(bitsTx{$lane},$chasId,$cardId,$portId)
        incr bertInfo(bitsRx{total},$chasId,$cardId,$portId)      $bertInfo(bitsRx{$lane},$chasId,$cardId,$portId)
        incr bertInfo(bitErrorsRx{total},$chasId,$cardId,$portId) $bertInfo(bitErrorsRx{$lane},$chasId,$cardId,$portId)
        incr bertInfo(mistmatched1s{total},$chasId,$cardId,$portId) $bertInfo(mistmatched1s{$lane},$chasId,$cardId,$portId)
        incr bertInfo(mistmatched0s{total},$chasId,$cardId,$portId) $bertInfo(mistmatched0s{$lane},$chasId,$cardId,$portId)
        set bertInfo(ber{total},$chasId,$cardId,$portId) [expr {$bertInfo(ber{total},$chasId,$cardId,$portId) +\
                                                                $bertInfo(ber{$lane},$chasId,$cardId,$portId)}]
        set bertInfo(mistmatched1Ratio{total},$chasId,$cardId,$portId) [expr {$bertInfo(mistmatched1Ratio{total},$chasId,$cardId,$portId) +\
                                                                              $bertInfo(mistmatched1Ratio{$lane},$chasId,$cardId,$portId)}]
        set bertInfo(mistmatched0Ratio{total},$chasId,$cardId,$portId) [expr {$bertInfo(mistmatched0Ratio{total},$chasId,$cardId,$portId) +\
                                                                              $bertInfo(mistmatched0Ratio{$lane},$chasId,$cardId,$portId)}]
        # Divide by the lane count for all the ratios
        if {$lane == 15} {
            set bertInfo(ber{total},$chasId,$cardId,$portId) [expr {$bertInfo(ber{total},$chasId,$cardId,$portId)/16}]
            set bertInfo(mistmatched1Ratio{total},$chasId,$cardId,$portId) [expr {$bertInfo(mistmatched1Ratio{total},$chasId,$cardId,$portId)/16}]
            set bertInfo(mistmatched0Ratio{total},$chasId,$cardId,$portId) [expr {$bertInfo(mistmatched0Ratio{total},$chasId,$cardId,$portId)/16}]
        }
    }

    # -For 25G BERT we need to combine each pairs of lanes to represent a PAM4 lane
    # -Will save info in QDD lane numbering 1..8
    for {set lane 1} {$lane <= 8} {incr lane} {
        set bertLaneA [expr {($lane-1)*2}]
        set bertLaneB [expr {$bertLaneA + 1}]
        set bertBer [expr {($bertInfo(ber{$bertLaneA},$chasId,$cardId,$portId) +\
                            $bertInfo(ber{$bertLaneB},$chasId,$cardId,$portId))/2}]
        set bertInfo(bertBer{$lane},$chasId,$cardId,$portId) $bertBer
        set bertLostLock [expr {$bertInfo(lostLock{$bertLaneA},$chasId,$cardId,$portId) == "Yes" ||
                                $bertInfo(lostLock{$bertLaneB},$chasId,$cardId,$portId) == "Yes" ? "Yes" : "No"}]
        set bertInfo(bertLostLock{$lane},$chasId,$cardId,$portId) $bertLostLock
    }

    # Do some error checking
    set noLockFlag 0
    set berFlag    0
    set lostLockFlag 0
    for {set lane 0} {$lane < 16} {incr lane} {
        # Prepare Pass/Fail info
        set passInfo(lock{$lane},$chasId,$cardId,$portId) " "
        set passInfo(ber{$lane},$chasId,$cardId,$portId)  " "
        set passInfo(txPattern{$lane},$chasId,$cardId,$portId)  " "
        set passInfo(rxPattern{$lane},$chasId,$cardId,$portId) " "
        set passInfo(lostLock{$lane},$chasId,$cardId,$portId)  " "
        # First check for pattern lane lock
        if {$bertInfo(patternLock{$lane},$chasId,$cardId,$portId) == "N"} {
            set noLockFlag 1
            set passInfo(lock{$lane},$chasId,$cardId,$portId) "F"
        } else {
            # Check BER threshold
            if {$bertInfo(ber{$lane},$chasId,$cardId,$portId) > $maxLaneBER} {
                set berFlag 1
                set passInfo(ber{$lane},$chasId,$cardId,$portId) "F"
            }
            # Check for lost lock
            if {$bertInfo(lostLock{$lane},$chasId,$cardId,$portId) != "No"} {
                set lostLockFlag 1
                set passInfo(lostLock{$lane},$chasId,$cardId,$portId) "F"
            }
        }
    }

    array set bertTestInfo {}
    if {$noLockFlag} {
        set testInfo(PORT_FAIL,$chasId,$cardId,$portId) 1
        lappend testInfo(PORT_INFO_STR,$chasId,$cardId,$portId) \
            "Fail: port {$port} has lost pattern lock on some lanes."
        lappend bertTestInfo(PORT_INFO_STR,$chasId,$cardId,$portId) \
            "Fail: port {$port} has lost pattern lock on some lanes."
    }
    if {$berFlag} {
        set testInfo(PORT_FAIL,$chasId,$cardId,$portId) 1
        lappend testInfo(PORT_INFO_STR,$chasId,$cardId,$portId) \
            "Fail: port {$port} has lane(s) with BER > $maxLaneBER"
        lappend bertTestInfo(PORT_INFO_STR,$chasId,$cardId,$portId) \
            "Fail: port {$port} has lane(s) with BER > $maxLaneBER"
    }
    if {$lostLockFlag} {
        set testInfo(PORT_FAIL,$chasId,$cardId,$portId) 1
        lappend testInfo(PORT_INFO_STR,$chasId,$cardId,$portId) \
            "Fail: port {$port} has lost lock on some lanes."
        lappend bertTestInfo(PORT_INFO_STR,$chasId,$cardId,$portId) \
            "Fail: port {$port} has lost lock on some lanes."
    }

    # Display lane stats - 16x25G compact version
    if {$verbose && $option=="x16-compact"} {
        puts "BERT lane stats on port {$port}:"
        puts "PRBS | Patt | Transmit   | Received   | Bits                  | Bits                  | Bit Errors   | Bit Error  | Lost "
        puts "Lane | Lock | Pattern    | Pattern    | Sent                  | Received              | Received     | Ratio      | Lock "
        puts "-----|------|------------|------------|-----------------------|-----------------------|--------------|-------------------"
        set strFmt "%5s|  %1s %1s | %-8s %1s | %-8s %1s | %21s | %21s |%13s | %.2e %1s | %-3s %1s"
        puts [format $strFmt \
                "Total" \
                "" ""\
                "" ""\
                "" ""\
                [commify $bertInfo(bitsTx{total},$chasId,$cardId,$portId)] \
                [commify $bertInfo(bitsRx{total},$chasId,$cardId,$portId)] \
                [commify $bertInfo(bitErrorsRx{total},$chasId,$cardId,$portId)] \
                $bertInfo(ber{total},$chasId,$cardId,$portId)  ""\
                "" ""\
            ]
        puts "-----|------|------------|------------|-----------------------|-----------------------|--------------|-------------------"
        for {set lane 0} {$lane < 16} {incr lane} {
            puts [format $strFmt \
                  [format " %2d " $lane] \
                  $bertInfo(patternLock{$lane},$chasId,$cardId,$portId) $passInfo(lock{$lane},$chasId,$cardId,$portId) \
                  $bertInfo(patternTx{$lane},$chasId,$cardId,$portId) $passInfo(txPattern{$lane},$chasId,$cardId,$portId)\
                  $bertInfo(patternRx{$lane},$chasId,$cardId,$portId) $passInfo(rxPattern{$lane},$chasId,$cardId,$portId)\
                  [commify $bertInfo(bitsTx{$lane},$chasId,$cardId,$portId)] \
                  [commify $bertInfo(bitsRx{$lane},$chasId,$cardId,$portId)] \
                  [commify $bertInfo(bitErrorsRx{$lane},$chasId,$cardId,$portId)] \
                  $bertInfo(ber{$lane},$chasId,$cardId,$portId)  $passInfo(ber{$lane},$chasId,$cardId,$portId)\
                  $bertInfo(lostLock{$lane},$chasId,$cardId,$portId) $passInfo(lostLock{$lane},$chasId,$cardId,$portId)
                ]
        }
    }

    # Display lane stats - 16x25G full version
    if {$verbose && $option=="x16-full"} {
        puts "BERT lane stats on port {$port}:"
        puts "PRBS | Patt | Transmit   | Received   | Bits                  | Bits                  | Bit Errors   | Bit Error  | Mismatched | Mismatched | Mismatch  | Mismatch  | Lost "
        puts "Lane | Lock | Pattern    | Pattern    | Sent                  | Received              | Received     | Ratio (BER)| 1's        | 0's        | 1's Ratio | 0's Ratio | Lock "
        puts "-----|------|------------|------------|-----------------------|-----------------------|--------------|------------|------------|------------|-----------|-----------|------"
        set strFmt "%5s|  %1s %1s | %-8s %1s | %-8s %1s | %21s | %21s |%13s | %.2e %1s |%11s |%11s | %.2e  | %.2e  | %-3s %1s"        
        puts [format $strFmt \
                "Total" \
                "" ""\
                "" ""\
                "" ""\
                [commify $bertInfo(bitsTx{total},$chasId,$cardId,$portId)] \
                [commify $bertInfo(bitsRx{total},$chasId,$cardId,$portId)] \
                [commify $bertInfo(bitErrorsRx{total},$chasId,$cardId,$portId)] \
                $bertInfo(ber{total},$chasId,$cardId,$portId)  ""\
                [commify $bertInfo(mistmatched1s{total},$chasId,$cardId,$portId)] \
                [commify $bertInfo(mistmatched0s{total},$chasId,$cardId,$portId)] \
                $bertInfo(mistmatched1Ratio{total},$chasId,$cardId,$portId) \
                $bertInfo(mistmatched0Ratio{total},$chasId,$cardId,$portId) \
                "" ""\
            ]
        puts "-----|------|------------|------------|-----------------------|-----------------------|--------------|------------|------------|------------|-----------|-----------|------"
        for {set lane 0} {$lane < 16} {incr lane} {
            puts [format $strFmt \
                  [format " %2d " $lane] \
                  $bertInfo(patternLock{$lane},$chasId,$cardId,$portId) $passInfo(lock{$lane},$chasId,$cardId,$portId) \
                  $bertInfo(patternTx{$lane},$chasId,$cardId,$portId) $passInfo(txPattern{$lane},$chasId,$cardId,$portId)\
                  $bertInfo(patternRx{$lane},$chasId,$cardId,$portId) $passInfo(rxPattern{$lane},$chasId,$cardId,$portId)\
                  [commify $bertInfo(bitsTx{$lane},$chasId,$cardId,$portId)] \
                  [commify $bertInfo(bitsRx{$lane},$chasId,$cardId,$portId)] \
                  [commify $bertInfo(bitErrorsRx{$lane},$chasId,$cardId,$portId)] \
                  $bertInfo(ber{$lane},$chasId,$cardId,$portId)  $passInfo(ber{$lane},$chasId,$cardId,$portId)\
                  [commify $bertInfo(mistmatched1s{$lane},$chasId,$cardId,$portId)] \
                  [commify $bertInfo(mistmatched0s{$lane},$chasId,$cardId,$portId)] \
                  $bertInfo(mistmatched1Ratio{$lane},$chasId,$cardId,$portId) \
                  $bertInfo(mistmatched0Ratio{$lane},$chasId,$cardId,$portId) \
                  $bertInfo(lostLock{$lane},$chasId,$cardId,$portId) $passInfo(lostLock{$lane},$chasId,$cardId,$portId)
                ]
        }
    }

    # Pass/Fail summary
    if {$noLockFlag || $berFlag || $lostLockFlag} {
        # Display accumulated errors
        if {[info exists bertTestInfo(PORT_INFO_STR,$chasId,$cardId,$portId)]} {
            foreach infoStr $bertTestInfo(PORT_INFO_STR,$chasId,$cardId,$portId) {
                puts $infoStr
            }
        }
        puts ""
        return $::TCL_ERROR
    } else {
        puts "BERT lanes on port {$port} are as expected."
        puts ""
        return $::TCL_OK
    }
}

#
# Clear BERT Port and lane stats
#
proc clearAllPortBERT {portList}\
{
    foreach port $portList {
        # 'ixClearPortStats' only clears the BERT port stats,
        #  while 'clearBertLane' clears both per-lane and port-level
        if {[string match */* $port]} {
            # FQPN
            stat clearBertLane $port
        } else {
            scan $port {%d %d %d} chasId cardId portId
            stat clearBertLane $chasId $cardId $portId
        }
    }
}

