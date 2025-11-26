proc get_json {filename} {
    set fp [open $filename r]
    set file_data [read $fp]
    close $fp
    return [json::json2dict $file_data]
}

# Runs simulation for library files

# [test_dict] - dictionnary containing test entries with "name", "source_names" and "testbench_names" keys. 
# source_names vhd files are searched in the libraries folder
# testbench_names vhd files are searched in the testbenches folder
# Top modules should have the same name as the files and be placed last in the list. Import order matters for dependencies.
proc run_simulation_library { } {
    set_msg_config -id {[Common 17-259]} -limit 0

    set script_dict [file dirname [info script]]

    set test_dict [get_json "$script_dict/../../scripts/parameters/test_para.json"]

    foreach test $test_dict {
        set test_name [dict get $test name]
        if {[string first $test_name "PASS"] != -1} {
            puts "Skipping test with name that contains PASS : $test_name"
            continue
        }
        set source_names [dict get $test source_names]
        set testbench_names [dict get $test testbench_names]

        # Compile sources and testbench (VHDL-2008)
        puts "INFO : Testing $test_name with sources $source_names and testbenches $testbench_names"

        foreach source_name $source_names {
            exec xvhdl -nolog "$script_dict/../../libraries/$source_name.vhd"
        }

        foreach tb $testbench_names {
            exec xvhdl -nolog "$script_dict/../../test_libraries/$tb.vhd"
        }

        # Elaborate and run simulation
        puts "INFO : Starting simulation for test $test_name"
        *
        set last_tb [lindex $testbench_names end]
        exec xelab -nolog -relax -debug typical $last_tb -s top_sim
        xsim top_sim -nolog
        run -all
    }
}

# Runs simulation for top project file

# [test_dict] - dictionnary containing test entries with "name", "source_names" and "testbench_names" keys. 
# source_names vhd files are searched in the pre-project folder (the one in firmware/Projects/project_name)
# testbench_names vhd files are searched in the pre-project/testbenches folder
# Top modules should have the same name as the files and be placed last in the list. Import order matters for dependencies.
proc run_simulation_project {test_dict} {
    set_msg_config -id {[Common 17-259]} -limit 0

    set script_dict [file dirname [info script]]

    foreach test $test_dict {
        set test_name [dict get $test name]
        if {[string first $test_name "PASS"] != -1} {
            puts "Skipping test with name that contains PASS : $test_name"
            continue
        }
        set source_names [dict get $test source_names]
        set testbench_names [dict get $test testbench_names]

        # Compile sources and testbench (VHDL-2008)
        puts "INFO : Testing $test_name with sources $source_names and testbenches $testbench_names"

        foreach source_name $source_names {
            exec xvhdl -nolog "$script_dict/$source_name.vhd"
        }

        foreach tb $testbench_names {
            exec xvhdl -nolog "$script_dict/testbench/$tb.vhd"
        }

        # Elaborate and run simulation
        puts "INFO : Starting simulation for test $test_name"
        *
        set last_tb [lindex $testbench_names end]
        exec xelab -nolog -relax -debug typical $last_tb -s top_sim
        xsim top_sim -nolog
        run -all
    }
}

proc print_help {} {
  variable script_file
  puts "\nDescription:"
  puts "Runs behavioral simulations for a given set of modules and testbenches."
  puts "The procedures rely on a a dictionnary that defines the tests to run. \n"
  puts "run_simulation_library looks at sources in /libraries and testbenches"
  puts "in /testbenches folders. \n"
  puts "run_simulation_project looks at sources in the current project folder and"
  puts "testbenches in the /testbenches subfolder in the project folder. \n"
  puts "Syntax for test dictionnary: \n"
  puts {[{"name" : "<test_name>", "source_names" : ["<source1.vhd>", "<source2.vhd>", "..."], "testbench_names" : ["<tb1.vhd>", "<tb2.vhd>", "..."]}, {...}]}
  puts "Important note : source and testbench names should be in order of dependencies,"
  puts "with the top module being the last in the list.\n"
  puts "If faced with import errors, please check the order of sources and testbenches"
  puts "in the lists.\n"
  puts "Example :\n"
  puts {[{"name" : "TestConverter", "source_names" : ["converter.vhd"], "testbench_names" : ["tb_converter_dependency.vhd","tb_converter.vhd"]}]}
  puts "\n"
  puts "The command expects each testbench to finish with a stop command and to put"
  puts "meaningful messages in the simulation log to indicate success or failure.\n"
  exit 0
}
