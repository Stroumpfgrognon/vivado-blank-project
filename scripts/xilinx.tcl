# TCL file for compiling the Xilinx based dependancies. Includes the device configuration. More Xilinx boards can be added here later on.
# created by Prerna Baranwal, code modified for usage from the open source libraries available at: https://github.com/analogdevicesinc/hdl/

# enables the out of context synthesis for the project

if {[info exists ::env(USE_OOC_SYNTHESIS)]} {
  if {[string equal $::env(USE_OOC_SYNTHESIS) n]} {
    set USE_OOC_SYNTHESIS 0
  } else {
    set USE_OOC_SYNTHESIS 1
  }
} elseif {![info exists USE_OOC_SYNTHESIS]} {
  set USE_OOC_SYNTHESIS 1
}

# sets the number of parallel out of context jobs

if {![info exists ::env(MAX_OOC_JOBS)]} {
  set MAX_OOC_JOBS 8
} else {
  set MAX_OOC_JOBS $::env(MAX_OOC_JOBS)
}

# sets the incremental compilation for the project

set USE_INCR_COMP 1

# Enables the power optimisation

set POWER_OPTIMIZATION 0

## Initialize global variables
set p_board "not-applicable"
set p_device "none"
set p_prcfg_init ""
set p_prcfg_list ""
set p_prcfg_status ""




# Cretaes a Vivado Project

# [project_name] - name of the project
# [mode] - value 0 is used for project mode and the value 1 is used for the project mode.
# [parameter_list] - a list of global parameters (parameters of the top level module of the vhdl design)
# [device] - FPGA part number
# [board] - option to include evaluation board if required.
#
proc firmware_create {project_name mode parameter_list device {board "not-applicable"}}  {


  global hdl_dir
  global p_board
  global p_device
  global required_vivado_version
  global IGNORE_VERSION_CHECK
  global USE_OOC_SYNTHESIS
  global USE_INCR_COMP


  if {![info exists ::env(PROJECT_DIR)]} {
    set actual_project_name $project_name
  } else {
    set actual_project_name "$::env(PROJECT_DIR)${project_name}"
  }

  set proc_dir ../$actual_project_name/$actual_project_name

  ## update the value of $p_device only if it was not already updated elsewhere
  if {$p_device eq "none"} {
    set p_device $device
  }
  set p_board $board

  # check if the compatible vivado version is installed
  set VIVADO_VERSION [version -short]


  # creates the vivado projects
  if {$mode == 0} {
    puts "mode 0"
    set project_system_dir "${proc_dir}/${actual_project_name}.srcs/sources_1/bd/${actual_project_name}"
    create_project $proc_dir/${actual_project_name} . -part $p_device -force
  } else {
    puts "mode not 0"
    set project_system_dir "${proc_dir}/${actual_project_name}.srcs/sources_1/bd/${actual_project_name}"
    create_project -in_memory -part $p_device
  }

  puts "Project directory:  ${proc_dir} and system directory for it: $project_system_dir"

  ##default language VHDL

  ## If target language is not VHDL, the line below can be commented out
  set_property target_language VHDL [current_project]

  set obj [current_project]
  set_property -name "default_lib" -value "work" -objects $obj
  set_property -name "enable_vhdl_2008" -value "1" -objects  $obj
  ## end of VHDL-specific properties
  
  set_property -name "ip_cache_permissions" -value "read write" -objects $obj

  if {$mode == 1} {
    puts "mode 1"
    file mkdir ${proc_dir}/${actual_project_name}.data
  }

  if {$p_board ne "not-applicable"} {
    set_property board_part $p_board [current_project]
  }

  #change device /board
  set script_dir [file normalize [file join [file dirname [info script]] ../../scripts/]]
  puts "script directory $script_dir"
  puts "project_name: $actual_project_name $p_device $p_board"
  source ${script_dir}/change_board.tcl
  puts "nach source: $actual_project_name $p_device $p_board"
  setDevice $actual_project_name $p_device $p_board

  #sets the directories of the project libraries.
  file mkdir $project_system_dir/libraries
  set lib_dirs $project_system_dir/libraries
  puts "lib_dirs: $lib_dirs"

  # sets a common IP cache, this prevents the IPs to get locked.
  if {$USE_OOC_SYNTHESIS == 1} {
    if {[file exists $project_system_dir/ipcache] == 0} {
      file mkdir $project_system_dir/ipcache
    }
    config_ip_cache -import_from_project -use_cache_location $project_system_dir/ipcache
  }
  set_property ip_repo_paths $lib_dirs [current_fileset]
  update_ip_catalog

  # can insert customised additional warnings during the addition of the ip here later on
  # changes the number of the messages that are displayed here:
  set_param messaging.defaultLimit 2000

}


# Add source files to an exisitng project once it has been created

# [project_name] - name of the project
# [project_dir] - directory to the project

proc firmware_files {project_name project_dir device} {

  set script_dir [file normalize [file join [file dirname [info script]] ../../scripts/]]

  foreach file [glob -nocomplain -directory "${script_dir}/../test_libraries/" *.vhd] {
    # file copy $file "${project_dir}sim_1"
    add_files -fileset sim_1 -norecurse -scan_for_includes $file
  }

  foreach file [glob -nocomplain -directory "${script_dir}/../test_libraries/" *.sv] {
    # file copy $file "${project_dir}sim_1"
    add_files -fileset sim_1 -norecurse -scan_for_includes $file
  }

  foreach file [glob -nocomplain -directory "${script_dir}/../libraries/" *.vhd] {
    # file copy $file "${project_dir}sources_1"
    add_files -norecurse -fileset sources_1 $file
  }

  foreach file [glob -nocomplain -directory "${script_dir}/../libraries/" *.sv] {
    # file copy $file "${project_dir}sources_1"
    add_files -norecurse -fileset sources_1 $file
  }

  foreach file [glob -nocomplain -directory "${script_dir}/../libraries/" *.xci] {
    add_files -norecurse -fileset sources_1 $file
    set f [file normalize $file]
    import_ip $file
  }

  foreach file [glob -nocomplain -directory "${project_dir}sim_1"] {
    add_files -norecurse -fileset sim_1 $file
    set f [file normalize $file]
    set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$f"]]
    set_property -name "library" -value "work" -objects $file_obj

  }

  foreach file [glob -nocomplain -directory "${project_dir}constrs_1"] {
    add_files -norecurse -fileset constrs_1 $file
    set f [file normalize $file]
    set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$f"]]
    set_property -name "file_type" -value "XDC" -objects $file_obj
    set_property -name "library" -value "work" -objects $file_obj
  }

  set constr_dir [file normalize "${project_dir}constrs_1"]

  # returns first xdc file
  set xdc_file ""
  foreach f [glob -nocomplain -directory $constr_dir *.xdc] {
    set xdc_file [file normalize $f]
    break   ;# nur die erste Datei nehmen
  }

  puts "\n used xdc file $xdc_file \n"

  # Error if no xdc file is given
  if {$xdc_file eq ""} {
    error "Keine XDC-Datei im Ordner $constr_dir gefunden!"
  }

  # Fileset constrs_1
  set obj [get_filesets constrs_1]

  # setting properties
  set_property -name target_constrs_file -value $xdc_file -objects $obj
  set_property -name target_part -value $device -objects $obj
  set_property -name target_ucf -value $xdc_file -objects $obj


  foreach file [glob -nocomplain -directory "${project_dir}sources_1" *.vhd] {
    add_files -norecurse -fileset sources_1 $file
    set f [file normalize $file]
    set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$f"]]
    set_property -name "file_type" -value "VHDL 2008" -objects $file_obj
    set_property -name "library" -value "work" -objects $file_obj
  }

  foreach file [glob -nocomplain -directory "${project_dir}sources_1" *.sv] {
    add_files -norecurse -fileset sources_1 $file
    set f [file normalize $file]
    set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$f"]]
    set_property -name "library" -value "work" -objects $file_obj
  }

  foreach file [glob -nocomplain -directory ${project_dir}sources_1/ip/ *.xci] {
    set f [file normalize $file]
    set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$f"]]
    set_property -name "generate_files_for_reference" -value "0" -objects $file_obj
    set_property -name "library" -value "work" -objects $file_obj
    set_property -name "registered_with_manager" -value "1" -objects $file_obj
    if { ![get_property "is_locked" $file_obj] } {
      set_property -name "synth_checkpoint_mode" -value "Singular" -objects $file_obj
    }

  }

  update_compile_order -fileset sources_1

  set_property top $project_name [current_fileset]
}

##creating bd design
#[project_name] - name of the project
proc firmware_bd {project_name} {
  # Set parameters of the top level file.
  set proc_dir ../$project_name/$project_name
  set proj_params [get_property generic [current_fileset]]
  foreach {param value} $parameter_list {
    lappend proj_params $param=$value
    set ad_project_params($param) $value
  }

  set_property generic $proj_params [current_fileset]
  create_bd_design -dir $proc_dir "${project_name}_bd"
  save_bd_design
  validate_bd_design

  if {$USE_OOC_SYNTHESIS == 1} {
    set_property synth_checkpoint_mode Hierarchical [get_files  $proc_dir/${project_name}_bd/${project_name}_bd.bd]
  } else {
    set_property synth_checkpoint_mode None [get_files  $proc_dir/${project_name}_bd/${project_name}_bd.bd]
  }
  generate_target {synthesis implementation} [get_files  $proc_dir/${project_name}_bd/${project_name}_bd.bd]
  if {$USE_OOC_SYNTHESIS == 1} {
    export_ip_user_files -of_objects [get_files  $proc_dir/${project_name}_bd/${project_name}_bd.bd] -no_script -sync -force -quiet
    create_ip_run [get_files  $proc_dir/${project_name}_bd/${project_name}_bd.bd]
  }
  make_wrapper -files [get_files $proc_dir/${project_name}_bd/${project_name}_bd.bd] -top
}



proc print_help {} {
  variable script_file
  puts "\nDescription:"
  puts "firmware_create: creates a vivado project with the given arguments.  "
  puts {[{"project_name" : "<name of the project>", "mode" : "<mode in which vivado should run>", "parameter_list" :  "<list of global parameters>" , "device" :  "<device for which the project should be configured>", "board": "<if applicable a project specific board>"}]}
  puts " "
  puts "firmware_files: imports the source files which are needed for the project"
  puts "\t all vhd files from the libraries folderand the testbenches in the test_libraries folder are imported."
  puts "\t the ip blocks vio_fastcmd and clk are imported"
  puts "\t project specific files have to be copied into the respective folder:   "
  puts "\t Example for source file: <project_directory>/<project_name>/<project_name>.src/sources_1"
  puts {[{"project_name" : "<name of the project>", "project_dir" : "<directory of the project>"}]}
  puts " "
  puts "firmware_bd: creates bd design.  "
  puts {[{"project_name" : "<name of the project>"}]}
  puts " "
  puts "\n"
  exit 0
}