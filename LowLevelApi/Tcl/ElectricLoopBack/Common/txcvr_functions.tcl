#------------------------------------------------------------------------------
# Name              :   txcvr_functions.tcl
# Author            :   Julio Marcos
# Purpose           :   Functions for transceiver access and CMIS handling
# Copyright         :   (c) 2022 Keysight Technologies - All Rights Reserved
#-------------------------------------------------------------------------------


#---------------------- Global Lookups ----------------------#


#---------------------- Transceiver Functions ----------------------#

#
# Returned signed value when represented
# as 2's complement (variable number of bits)
#
proc twosComplement {value {bits 8}} {
    set max_value [expr {2**$bits}]
    set halfway [expr {$max_value/2}]
    return [expr {$value < $halfway ? $value : -($max_value-$value)}]
}

#
# Returned a signed temperature with 1/256 fractional 
# value coming from 16 bits, in 2's complement.
#
proc convertTemperature16bits {value} {
    set signed_value [twosComplement $value 16]
    set final_value [expr {$signed_value/256.0}]
    return [format "%.1f" $final_value]
}

#
# Returned an F16 formatted value from a 16-bit readout
# -Definition in CMIS 5.0 MSA
# -Min in 1.0e-24, max is 2.047e+10
#
proc convertToF16 {value} {
    set exponent [expr {($value & 0xF800) >> 11}]
    set exponent [expr {$exponent - 24}]
    set exponent 1e$exponent
    set mantissa [expr {$value & 0x07FF}]
    set final_value [expr {$mantissa*$exponent}]
    return [format "%.3e" $final_value]
}


#
# Get the transceiver info (vendor, model, serial) for each port
# Returns: 0 if no errors found, 1 if otherwise
#
proc getTransceiverInfo {portList portInfoVar} {
    upvar 1 $portInfoVar portInfo

    foreach port $portList {
        set port [convertFQPN $port]
        scan $port {%d %d %d} chasId cardId portId
        if {[transceiver get $chasId $cardId $portId] != $::TCL_OK} {
            puts "Warning - Could not issue 'transceiver get' command on port {$port}!"
        }
        set properties [transceiver getReadAvailableProps $chasId $cardId $portId]

        set portInfo(TRANSCEIVER_VENDOR,$chasId,$cardId,$portId) [string trim [transceiver cget -manufacturer]]
        set portInfo(TRANSCEIVER_MODEL,$chasId,$cardId,$portId)  [string trim [transceiver cget -model]]
        set portInfo(TRANSCEIVER_SERIAL,$chasId,$cardId,$portId) [string trim [transceiver cget -serialNumber]]
        set portInfo(TRANSCEIVER_TYPE,$chasId,$cardId,$portId) [transceiver getValue transceiverTypeProperty]

        # Figure-out MSA to apply
        set msaRev 0.0
        set msaType "Unknown"
        set revCompliance [transceiver getValue revComplianceProperty]
        if {[llength [split $revCompliance " "]] > 1} {
            set revComplianceList [split [lindex $revCompliance 0] " "]
            set msaType [lindex $revComplianceList 0]
            set msaRev  [lindex $revComplianceList 1]
        }
        # Decide which pages to read per MSA (assume CMIS)
        # -IxOS treats CMIS 4.1 as 5.0
        switch $msaType {
            SFF-8472 {
                set msaName "SFF-8472"
            }
            SFF-8636 {
                set msaName "SFF-8636"
            }
            CMIS {
                switch $msaRev {
                    4.1 - 5.0 {
                        set msaName "CMIS5"
                    }
                    4.0 {
                        set msaName "CMIS4"
                    }
                    default {
                        set msaName "CMIS3"
                    }
                }
            }
            default {
                set msaName "CMIS3"
            }
        }
        set portInfo(TRANSCEIVER_COMPLIANCE,$chasId,$cardId,$portId) $revCompliance
        set portInfo(TRANSCEIVER_MSA,$chasId,$cardId,$portId) $msaName
    }

    return $::TCL_OK
}

#
# Show the basic transceiver information in column format
#
proc showTransceiverInfo {portList portInfoVar {entryWidth 28} {resultWidth 28} {leftJustified 1}} {
    upvar 1 $portInfoVar portInfo

    set str1 [format {%-*s  } $entryWidth "Transceiver vendor"]
    set str2 [format {%-*s  } $entryWidth "Transceiver model"]
    set str3 [format {%-*s  } $entryWidth "Transceiver serial"]
    set str4 [format {%-*s  } $entryWidth "Transceiver revCompliance"]
    set str5 [format {%-*s  } $entryWidth "Transceiver type"]
    foreach port $portList {
        set port [convertFQPN $port]
        scan $port {%d %d %d} chasId cardId portId

        # Take care of very long transceiver type
        set transType $portInfo(TRANSCEIVER_TYPE,$chasId,$cardId,$portId)
        if {[string length $transType] > $resultWidth} {
            # Extract the first word
            set transType [regexp -inline {[0-9A-Za-z\-]+} $transType]
        }
        if {$leftJustified} {
            append str1 [format {%-*s    } $resultWidth $portInfo(TRANSCEIVER_VENDOR,$chasId,$cardId,$portId)]
            append str2 [format {%-*s    } $resultWidth $portInfo(TRANSCEIVER_MODEL,$chasId,$cardId,$portId)]
            append str3 [format {%-*s    } $resultWidth $portInfo(TRANSCEIVER_SERIAL,$chasId,$cardId,$portId)]
            append str4 [format {%-*s    } $resultWidth $portInfo(TRANSCEIVER_COMPLIANCE,$chasId,$cardId,$portId)]
            append str5 [format {%-*s    } $resultWidth $transType]
        } else {
            append str1 [format {%*s    } $resultWidth $portInfo(TRANSCEIVER_VENDOR,$chasId,$cardId,$portId)]
            append str2 [format {%*s    } $resultWidth $portInfo(TRANSCEIVER_MODEL,$chasId,$cardId,$portId)]
            append str3 [format {%*s    } $resultWidth $portInfo(TRANSCEIVER_SERIAL,$chasId,$cardId,$portId)]
            append str4 [format {%*s    } $resultWidth $portInfo(TRANSCEIVER_COMPLIANCE,$chasId,$cardId,$portId)]
            append str5 [format {%*s    } $resultWidth $transType]
        }
    }
    puts [format {%-*s  } $entryWidth "Transceiver Info:"]
    puts $str1
    puts $str2
    puts $str3
    puts $str4
    puts $str5
    flush stdout
}

#
# Show the basic transceiver information in column format
#
proc showTransceiverShortInfo {portList portInfoVar {entryWidth 28} {resultWidth 28} {leftJustified 1}} {
    upvar 1 $portInfoVar portInfo

    set str1 [format {%-*s  } $entryWidth "Transceiver vendor"]
    set str2 [format {%-*s  } $entryWidth "Transceiver model"]
    set str3 [format {%-*s  } $entryWidth "Transceiver serial"]
    foreach port $portList {
        set port [convertFQPN $port]
        scan $port {%d %d %d} chasId cardId portId

        # Take care of very long transceiver type
        set transType $portInfo(TRANSCEIVER_TYPE,$chasId,$cardId,$portId)
        if {[string length $transType] > $resultWidth} {
            # Extract the first word
            set transType [regexp -inline {[0-9A-Za-z\-]+} $transType]
        }
        if {$leftJustified} {
            append str1 [format {%-*s    } $resultWidth $portInfo(TRANSCEIVER_VENDOR,$chasId,$cardId,$portId)]
            append str2 [format {%-*s    } $resultWidth $portInfo(TRANSCEIVER_MODEL,$chasId,$cardId,$portId)]
            append str3 [format {%-*s    } $resultWidth $portInfo(TRANSCEIVER_SERIAL,$chasId,$cardId,$portId)]
        } else {
            append str1 [format {%*s    } $resultWidth $portInfo(TRANSCEIVER_VENDOR,$chasId,$cardId,$portId)]
            append str2 [format {%*s    } $resultWidth $portInfo(TRANSCEIVER_MODEL,$chasId,$cardId,$portId)]
            append str3 [format {%*s    } $resultWidth $portInfo(TRANSCEIVER_SERIAL,$chasId,$cardId,$portId)]
        }
    }
    puts $str1
    puts $str2
    puts $str3
    flush stdout
}

#
# Display Transceiver Info
#
proc readTxcvrInfo {port portInfoVar}\
{
    upvar 1 $portInfoVar portInfo

    set port [convertFQPN $port]
    scan $port {%d %d %d} chasId cardId portId

    # Transceiver Info
    puts [format "Port           : {%s}" $port]
    puts [format "Vendor Name    : %s" $portInfo(TRANSCEIVER_VENDOR,$chasId,$cardId,$portId)]
    puts [format "Part Number    : %s" $portInfo(TRANSCEIVER_MODEL,$chasId,$cardId,$portId)]
    puts [format "Serial Number  : %s" $portInfo(TRANSCEIVER_SERIAL,$chasId,$cardId,$portId)]
    puts [format "MSA Compliance : %s" $portInfo(TRANSCEIVER_COMPLIANCE,$chasId,$cardId,$portId)]
    puts [format "MSA Used       : %s" $portInfo(TRANSCEIVER_MSA,$chasId,$cardId,$portId)]
}


#---------------------- Transceiver Management Access ----------------------#

#
# Get a management page's deviceNum based on the CMIS version used
#
proc getDeviceNum {page {msa CMIS5} {addr 0x80}}\
{
    # Find deviceNum
    switch $msa {
        SFF-8472 {
            # On AresONE and AresONE-S
            # -SFF-8472 has two devices, 0xA0 (160d) which maps to deviceNum 0, and 0xA2 (162d)
            # -In order to disambiguate for 0xA2, we'll add +20 to the page number parameter
            set deviceNum [expr {$page >= 20 ? 0xA2 : 0x0}]
        }
        SFF-8636 - SFF-8436 {
            # On AresONE-S (not supported on AresONE)
            switch $page {
                0  {set deviceNum [expr {$addr < 0x80 ? 0 : 1}]}
                1  {set deviceNum 2}
                2  {set deviceNum 3}
                3  {set deviceNum 4}
                default {set deviceNum 0}
            }
        }
        CMIS5 {
            # Summary of the CMIS 5 pages
            # Pages 0x00-0x14: Standard CMIS pages
            # Page  0x15     : Timing characteristics
            # Pages 0x20-0x2F: VDM
            # Pages 0x30-0x43: C-CMIS
            # Pages 0x9F-0xAF: CDB (bank 0)
            switch $page {
                0  - 0x00 {set deviceNum [expr {$addr < 0x80 ? 0 : 1}]}
                1  - 0x01 {set deviceNum 2}
                2  - 0x02 {set deviceNum 3}
                4  - 0x04 {set deviceNum 4}
                16 - 0x10 {set deviceNum 5}
                17 - 0x11 {set deviceNum 6}
                18 - 0x12 {set deviceNum 7}
                19 - 0x13 {set deviceNum 8}
                20 - 0x14 {set deviceNum 9}
                21 - 0x15 {set deviceNum 10}
                default {
                    if {$page >= 0x20 && $page <= 0x2F} {
                        # VDM 0x20..0x2F map to 11..26
                        set deviceNum [expr {$page - 21}]
                    } else {
                        set deviceNum 0
                    }
                }
            }
        }
        CMIS4 {
            # Summary of the CMIS 4 pages
            # Pages 0x00-0x14: Standard CMIS pages
            # Pages 0x20-0x2F: VDM
            # Pages 0x30-0x43: C-CMIS
            # Pages 0x9F-0xAF: CDB (bank 0)
            switch [expr {$page}] {
                0  - 0x00 {set deviceNum [expr {$addr < 0x80 ? 0 : 1}]}
                1  - 0x01 {set deviceNum 2}
                2  - 0x02 {set deviceNum 3}
                4  - 0x04 {set deviceNum 4}
                16 - 0x10 {set deviceNum 5}
                17 - 0x11 {set deviceNum 6}
                18 - 0x12 {set deviceNum 7}
                19 - 0x13 {set deviceNum 8}
                20 - 0x14 {set deviceNum 9}
                default {
                    if {$page >= 0x20 && $page <= 0x2F} {
                        # VDM 0x20..0x2F map to 10..25
                        set deviceNum [expr {$page - 22}]
                    } else {
                        set deviceNum 0
                    }
                }
            }
        }
        default {
            # CMIS3
            switch [expr {$page}] {
                0  {set deviceNum [expr {$addr < 0x80 ? 0 : 1}]}
                1  {set deviceNum 2}
                2  {set deviceNum 3}
                16 {set deviceNum 5}
                17 {set deviceNum 6}
                default {set deviceNum 0}   
            }
        }
    }
    return $deviceNum
}

#
# Read one page from transceiver management 
# Returns: 0 (if OK), or -1 if error
#
proc readTxcvrPage {port page {msa CMIS5} {addr 0x80} {mdioIndex 1}}\
{
    set port [convertFQPN $port]
    scan $port {%d %d %d} chasId cardId portId

    # Configure register access preset
    set deviceNum [getDeviceNum $page $msa $addr]
    miiae presetPage $page
    miiae presetDeviceNumber $deviceNum
    miiae presetBaseRegister $addr
    miiae presetNumberOfRegisters 128

    # Perform read
    if {[miiae get $chasId $cardId $portId $mdioIndex]} {
        errorMsg [format "ERROR - Could not read transceiver management on port {$port}"]
        return -1
    }
    miiae getDevice $deviceNum

    return 0
}

#
# Access a register from a page that was alrady read
# Returns: Register value (8 bits)
#
proc accessTxcvrReg {port addr {page 0} {options verbose}}\
{
    set port [convertFQPN $port]
    scan $port {%d %d %d} chasId cardId portId

    # (assumes a call to readTxcvrPage has already been done)
    mmd getRegister $addr
    set regName [mmdRegister cget -name]
    set regVal [mmdRegister cget -registerValue]
    scan $regVal %x decVal
    if {$options == "verbose"} {
        puts [format "Page 0x%02X, reg %3d (0x%02X) - %-60s=> 0x%02X" $page $addr $addr $regName $decVal]
    }

    return $decVal
}

#
# Access two consecutive registers from a page that was alrady read
# Returns: Register value (16 bits)
#
proc accessTxcvrReg16bits {port addr {page 0} {options verbose}}\
{
    set port [convertFQPN $port]
    scan $port {%d %d %d} chasId cardId portId

    set decVal  [accessTxcvrReg $port $addr $page $options]
    set decVal2 [accessTxcvrReg $port [incr addr] $page $options]
    set val16 [expr {$decVal << 8 | $decVal2}]
    return $val16
}

#
# Access four consecutive registers from a page that was alrady read
# Returns: Register value (32 bits)
#
proc accessTxcvrReg32bits {port addr {page 0} {options verbose}}\
{
    set port [convertFQPN $port]
    scan $port {%d %d %d} chasId cardId portId

    set decVal  [accessTxcvrReg $port $addr $page $options]
    set decVal2 [accessTxcvrReg $port [incr addr] $page $options]
    set decVal3 [accessTxcvrReg $port [incr addr] $page $options]
    set decVal4 [accessTxcvrReg $port [incr addr] $page $options]

    set val32 [expr {$decVal << 24 | $decVal2 << 16 | $decVal3 << 8 | $decVal4}]
    return $val32
}


#
# Read one register from transceiver management using Preset function
#
# Returns: Register value (0..255), or -1 if error
#
proc readTxcvrReg {port addr {page 0} {msa CMIS5} {options verbose} {mdioIndex 1}}\
{
    set port [convertFQPN $port]
    scan $port {%d %d %d} chasId cardId portId

    # Configure register access preset
    set deviceNum [getDeviceNum $page $msa $addr]
    miiae presetPage $page
    miiae presetDeviceNumber $deviceNum
    miiae presetBaseRegister $addr
    miiae presetNumberOfRegisters 1

    # Perform read
    if {[miiae get $chasId $cardId $portId $mdioIndex]} {
        errorMsg [format "ERROR - Could not read management register on port {$port}"]
        return -1
    }
    miiae getDevice $deviceNum
    mmd getRegister $addr
    set regVal [mmdRegister cget -registerValue]
    set regName [mmdRegister cget -name]
    scan $regVal %x decVal

    if {$options == "verbose"} {
        puts [format "Page 0x%02X, reg %3d (0x%02X) - %-60s=> 0x%02X" $page $addr $addr $regName $decVal]
    }
    return $decVal
}


#
# Write a management register
#
proc writeTxcvrReg {port addr writeVal page {msa CMIS5} {options verbose} {mdioIndex 1}}\
{
    set port [convertFQPN $port]
    scan $port {%d %d %d} chasId cardId portId

    # Configure register access preset
    set deviceNum [getDeviceNum $page $msa $addr]
    miiae presetPage $page
    miiae presetDeviceNumber $deviceNum
    miiae presetBaseRegister $addr
    miiae presetNumberOfRegisters 1

    # First read the register
    if {[miiae get $chasId $cardId $portId $mdioIndex]} {
        errorMsg [format "ERROR - Could not read management register on port {$port}"]
        return -1
    }
    miiae getDevice $deviceNum
    mmd getRegister $addr
    set regName [mmdRegister cget -name]

    # Configure new value
    # Note: in the mmdRegister command we should specify hex, not decimal
    set writeValHex [format "0x%02X" $writeVal]
    mmdRegister config -registerValue $writeValHex
    mmd setRegister $addr

    # Finally, after miiae setDevice, we send config down to HW via miiae set 
    miiae setDevice $deviceNum
    if {$options == "verbose"} {
        puts [format "Page 0x%02X, reg %3d (0x%02X) - %-60s<= 0x%02X" $page $addr $addr $regName $writeVal]
    }
    if {[miiae set $chasId $cardId $portId $mdioIndex]} {
        errorMsg [format "ERROR - Could not issue 'miiae set' on port {$port}"]
        return -1
    } else {
        return 0
    }
}

#
# Write two consecutive registers (16 bits)
#
proc writeTxcvrReg16bits {port addr value page {msa CMIS5} {options verbose}}\
{
    set port [convertFQPN $port]
    scan $port {%d %d %d} chasId cardId portId
    set deviceNum [getDeviceNum $page $msa $addr]

    set msb [expr {($value & 0xFF00) >> 8}]
    set lsb [expr {($value & 0x00FF)}]

    set retVal [writeTxcvrReg $port $addr $msb $page $msa $options]
    set retVal [writeTxcvrReg $port [incr addr] $lsb $page $msa $options]

    return $retVal
}

