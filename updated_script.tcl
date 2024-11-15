
###############################################################################
# ictrace.tcl  ictrace Addon Script                                           #
#                                                                             #
# Description: TCL supporting script for ictrace data dependency tracing      #
###############################################################################

# internal vars, procedures

set ictrace_var_script [info script]
set ictrace_var_target "undefined"

proc write_to_file {message} {
    if {[info exists ::env(ICPRO_DIR)] && [info exists ::env(STEP)]} {
        set output_dir "$::env(ICPRO_DIR)/innovus/result"
        set output_file "$output_dir/$::env(STEP).yaml"

        # Ensure the directory exists
        if {![file isdirectory $output_dir]} {
            file mkdir $output_dir
        }

        # Append the message to the output file
        set file_id [open $output_file "a"]
        puts $file_id $message
        close $file_id
    } else {
        # If the environment variables are not set, print an error to the console
        puts "RI-ERROR: Environment variables ICPRO_DIR or STEP not set"
    }
}

proc ri_ictrace_separateOptionsAndArguments { args } {
    set options {}
    set arguments {}
    foreach arg $args {
        if {[string match -* $arg]} {
            lappend options $arg
        } else {
            lappend arguments $arg
        }
    }
    return [list $options $arguments]
}

if { [info exists ::ri_ictrace_disable] && $::ri_ictrace_disable!="" && $::ri_ictrace_disable!=0 } {
    proc ri_ictrace { args } { }
    proc ri_ictrace_init { target args } { }
    proc ri_ictrace_file { args } {
        set separgs  [ri_ictrace_separateOptionsAndArguments {*}$args]
        set options  [lindex $separgs 0]
        set fileargs [lindex $separgs 1]
        write_to_file "RI-DEBUG: Tracing disabled."
        return {*}$fileargs
    }
} else {
    proc ri_ictrace { args } {
        set argc [llength $args]
        if {$args == "-help"} {
            write_to_file {Usage: ri_ictrace ?options?}
            write_to_file {Description: Tracing of design flow data item dependencies.}
            write_to_file {Options: -context pdk|tool|resource|release|file}
            write_to_file { -target  <Makefile target>}
            write_to_file { -unit    <design unit>}
            write_to_file { -type    opt <item type>}
            write_to_file { -items   <items to register>}
            write_to_file { -init   }
            write_to_file { -force   }
            write_to_file { -prereg   }
            write_to_file { -debug   }
            write_to_file { -sparse   }
            write_to_file { -norev   }
            write_to_file {Example: %ri_ictrace -context pdk -target generic -items cds_genus/21.14.000}
        } elseif {$argc==0} {
            write_to_file {wrong # args: should be "ri_ictrace ?options?"}
        } else {
            if { [info exists ::env(ICPRO_DIR)] } {
                set ict_args   ""
                set ict_debug  0
                set ict_sparse 0
                set ict_norev  0

                for {set i 0} {$i<[llength $args]} {incr i} {
                    switch [lindex $args $i] {
                        "-debug" {
                            set ict_debug 1
                        }
                        "-sparse" {
                            set ict_sparse 1
                            lappend ict_args "-sparse"
                        }
                        "-norev" {
                            set ict_norev 1
                            lappend ict_args "-norev"
                        }
                        "-force" {
                            lappend ict_args "-force"
                        }
                        "-init" {
                            lappend ict_args "-init"
                        }
                        "-prereg" {
                            lappend ict_args "-prereg"
                        }
                        "-context" {
                            set context  [lindex $args [incr i]]
                            lappend ict_args "-context" $context
                        }
                        "-type" {
                            set type     [lindex $args [incr i]]
                            lappend ict_args "-type" $type
                        }
                        "-items" {
                            set items    [lindex $args [incr i]]
                            lappend ict_args "-items" $items
                        }
                        "-unit" {
                            set unit     [lindex $args [incr i]]
                            lappend ict_args "-unit" $unit
                        }
                        "-target" {
                            set target   [lindex $args [incr i]]
                            lappend ict_args "-target" $target
                        }
                        "" {
                        }
                        default {
                            write_to_file "RI-ERROR: Unknown parameter \"[lindex $args $i]\" for ictrace (ICT-01)"
                        }
                    }
                }
                if {$ict_debug} {
                    write_to_file "RI-DEBUG: executing 'ictrace register $ict_args'"
                }
                set ict_result ""
                set status [catch {exec ictrace "register" {*}$ict_args} ict_result]
                if {$status == 0} {
                    write_to_file $ict_result
                } else {
                    if {[string equal $::errorCode NONE]} {
                        write_to_file "RI-WARNING: The command executed but returned stderr: $ict_result"
                    } else {
                        write_to_file "RI-ERROR: Command execution failed with error code '$status' and result '$ict_result'"
                    }
                }
            } else {
            }
        }
    }
