# Does an implementation run based on the provided project and entries dictionaries

# [project_dict] - dictionary containing a "project_file" path to the project xpr file. The path can be relative to where the script is executed. The value is ignored if a project is already open (like if executed through the Vivado GUI).
# [entries_dict] - dictionary containing multiple entries with "name" and "parameters" keys for each implementation run


proc run_implementation {project_dict entries_dict} {
    if {[catch {current_project} result ]} {
        puts "INFO: Project is not open, opening it with project_name and project_directory project_dict variables"
        # #so try and open it
        set project_directory [dict get $global_array ""project_root_directory""]
        set project_name [dict get $global_array "project_name"]
        set project_path "$project_directory/$project_name/$project_name.xpr"
        open_project $project_path
        puts "INFO: Project $project_path opened"
    }
    set project_dir [get_property directory [current_project]]
    set bitfile_name [get_property TOP [get_filesets sources_1]]
    set run_counter 0


    file mkdir $project_dir/output
    foreach entry $entries_dict {
        set name "run_$run_counter"
        incr run_counter

        set runs_project_raw [get_property DIRECTORY [current_run]]
        set runs_project_split [split $runs_project_raw "/"]
        set runs_project_0 [lindex $runs_project_split end-1]
        set runs_project_1 [lindex $runs_project_split end]
        set runs_project "$runs_project_0/$runs_project_1"


        if {[dict exists $entry name] && ![string equal [dict get $entry name] ""]} {
            if {[string first [dict get $entry name] "PASS"] != -1} {
                puts "Skipping run with name that contains PASS : [dict get $entry name]"
                continue
            }
            set name [dict get $entry name]
        } else {
            puts "WARNING : No name specified for this run, using default name $name."
        }
        set parameters ""
        if {[dict exists $entry parameters]} {
            set parameters [dict get $entry parameters]
        } else {
            puts "WARNING : No parameters specified for run $name, using empty parameters"
        }

        puts "Running implementation $name with parameters $parameters for bitfile_$name"

        reset_runs [get_runs]
        set_property generic $parameters [current_fileset]

        if {[dict exists $entry vector_parameters]} {
            set vector_params_dict [dict get $entry vector_parameters]
            foreach {param_name param_info} $vector_params_dict {
                if {[dict exists $param_info size] && [dict exists $param_info value]} {
                    set size [dict get $param_info size]
                    set value [dict get $param_info value]
                    set_property generic $param_name=$size'b$value [current_fileset]
                } else {
                    puts "[ERROR] Vector parameter $param_name must have both 'size' and 'value' fields. Skipping."
                }
            }
        }

        launch_runs $runs_project_1 -to_step write_bitstream -jobs 8
        wait_on_runs [get_runs $runs_project_1]
        file copy -force $project_dir/$runs_project/$bitfile_name.bit $project_dir/output/$name.bit
        file copy -force $project_dir/$runs_project/$bitfile_name.ltx $project_dir/output/$name.ltx
        write_cfgmem  -format mcs -size 1 -interface SPIx4 -loadbit "up 0x00000000 $project_dir/output/$name.bit" -force -file "$project_dir/output/$name.mcs"
    }
}


proc print_help {} {
    variable script_file
    puts "\nDescription:"
    puts "Runs a batch of implementations for a given project. "
    puts "run_implementation relies on a set of two dictionnaries that define which project"
    puts "to open if none are currently opened, and the parameters and name for each"
    puts "implementation run.\n"
    puts "Syntax for project dictionnary: \n"
    puts "{ \"project_file\" : \"<path_to_project.xpr>\" }\n"
    puts "Syntax for entries dictionnary: \n"
    puts {[{"name" : "<run_name>", "parameters" : "<implementation_parameters>", "vector_parameters" : { "<param_name>" : { "size" : <size>, "value" : "<value>" }}}, ...]}
    puts "vector_parameters target std_vector generics that require explicit size declaration\n"
    puts "Examples :\n"
    puts {{"project_file" : "Projects/my_project/my_project.xpr" }}
    puts {{"name" : "Run320mbBigEndian", "parameters" : "datarate=320", "vector_parameters" : { "ENDIAN_CHANGER" : { "size" : 2, "value" : "11" }}}}
    puts "\n"
    exit 0
}
