#
# Tcl tee
#
# From: https://wiki.tcl-lang.org/page/Tee
#

namespace eval tee {
    variable methods {initialize finalize write}
    namespace ensemble create -subcommands {replace append channel} \
      -unknown [namespace current]::default
    namespace ensemble create -command transchan -parameters fd \
      -subcommands $methods
}

proc tee::default {command subcommand args} {
    return [list $command replace $subcommand]
}

proc tee::channel {chan fd} {
    chan push $chan [list [namespace which transchan] $fd]
    return $fd
}

proc tee::replace {chan file} {
    return [channel $chan [open $file w]]
}

proc tee::append {chan file} {
    return [channel $chan [open $file a]]
}

proc tee::initialize {fd handle mode} {
    variable methods
    return $methods
}

proc tee::finalize {fd handle} {
    close $fd
}

proc tee::write {fd handle buffer} {
    puts -nonewline $fd $buffer
    return $buffer
}