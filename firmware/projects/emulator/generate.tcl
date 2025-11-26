package require json

proc get_json {filename} {
    set fp [open $filename r]
    set file_data [read $fp]
    close $fp
    return [json::json2dict $file_data]
}

set proj_dict [get_json "./parameters/project_var.json"]

set project_name [dict get $proj_dict "project_name"]
set device [dict get $proj_dict "device"]

set project_dir [file dirname [info script]]
set script_dir $project_dir/../../scripts/
set lib_dir $project_dir/../../libraries/
set test_dir $project_dir/../../test_libraires/
set const_dir $project_dir/../../constraints/

set mode 0

source ${script_dir}/xilinx.tcl

puts "The total number of arguments is $argc"
if {$argc > 0} {puts "The arguments in ARGV are: $argv" }

puts [lindex $argv 0]

if {$argc > 0} {
    set proc_mode [lindex $argv 0]
} else {
    set proc_mode 0
}

proc make_project {} {

    global project_name
    global device
    global project_dir
    global script_dir
    global lib_dir
    global test_dir
    global const_dir
    global mode
    global USE_INCR_COMP

    firmware_create emulator $mode {} $device {}

    file mkdir "$project_dir/$project_name/$project_name.srcs/sources_1"
    file mkdir "$project_dir/$project_name/$project_name.srcs/sim_1"
    file mkdir "$project_dir/$project_name/$project_name.srcs/constrs_1"

    if {$mode == 0} {
        file copy "$project_dir/$project_name.vhd" "$project_dir/$project_name/$project_name.srcs/sources_1"
        foreach file [glob -nocomplain -directory "./testbench/" *.vhd] {
            file copy $file "$project_dir/$project_name/$project_name.srcs/sim_1"
        }
        file copy "$const_dir/${project_name}_const.xdc"  "$project_dir/$project_name/$project_name.srcs/constrs_1"
    } else {
        write_hwdef -file "$project_dir/$project_name/$project_name.data/$project_name.hwdef"
    }

    if {$USE_INCR_COMP == 1} {
        if {[file exists ./reference.dcp]} {
            set_property incremental_checkpoint ./reference.dcp [get_runs impl_1]
        }
    }

    firmware_files $project_name "$project_dir/$project_name/$project_name.srcs/"
    puts "included all source files and integrated ip blocks"
}

proc do_simulations {} {
    # running the generall tests for the library files
    global script_dir
    source ${script_dir}/run_sim.tcl
    run_simulation_library

    puts "\n finished simulation\n"

    #simulation for project specific testbenches can be inserted here with
    # run_simulation_project
    #proc get_json {filename} {
    #    set fp [open $filename r]
    #    set file_data [read $fp]
    #    close $fp
    #    return [json::json2dict $file_data]
    #}
    #run_simulation_project [get_json "./parameters/test.json"]
}

proc do_implementation {} {
    # running the implementation
    global script_dir
    source ${script_dir}/run_impl.tcl
    [run_implementation [get_json "./parameters/project_var.json"] [get_json "./parameters/run_para.json"]]
}

proc print_help {} {
    variable script_file
    puts "\nDescription:"
    puts "creates the project emulator. "
    puts "It is implemented for the device xc7s15cpga196-2"
    puts "the project is created, simulated and a bitstream is created."
    puts "for the functionality of the different steps see the different tcl files: "
    puts "xilinx.tcl, change_board.tcl, run_impl.tcl"
    puts "\n"
    exit 0
}

if {$proc_mode == "help"} {
    print_help
} elseif {$proc_mode == "make_project"} {
    make_project
} elseif {$proc_mode == "make_simulations"} {
    do_simulations
} elseif {$proc_mode == "make_implementation"} {
    do_implementation
} elseif {($proc_mode == "all") || ($proc_mode == 0)} {
    make_project
    do_simulations
    do_implementation
} else {
    print_help
    puts "Unknown mode $proc_mode"
}