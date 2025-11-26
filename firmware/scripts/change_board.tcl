# tcl script to create the board connections for the Vivado project
# created by Prerna Baranwal, code modified for usage from the open source libraries available at: https://github.com/analogdevicesinc/hdl/

#package require match

# adds an instance of thoe board 

proc setDevice {{name ""} {dev ""} {boa ""}} {

    puts "in setDevice $name $dev $boa"
    if {$name eq ""} {
        puts "No project name is given. ERROR"
        set name "xczu3eg-sbva484-1-e"
        exit 1
    } elseif {$dev eq ""} {
        puts "No part is  given used default part is xczu3eg-sbva484-1-e"
    } 


    changeDevice $name $dev
    if { $boa ne ""} {
        changeBoard $name $boa
    }

}

proc changeDevice {name dev} {

    set project_name ${name}.xpr
    set proj_path [file join [file dirname [file normalize [info script]]] ../../Projects/$name]
    set proj_path_normalized [file normalize $proj_path]
    set device_name $dev

    set possible_parts [get_parts]

    if {[lsearch -exact $possible_parts $device_name] == -1} {
        puts "the given part: '$device_name' is not a valid chip"
        exit 1
    }

    if {[get_projects *] eq ""} {
        puts "opening  project $proj_path_normalized/$project_name with part $device_name"

        open_project $proj_path_normalized/$project_name 
        set_property part $device_name [current_project]
        close_project 
        puts "succefully changed project device"

    } else {
        puts "existing project gets changed"
        set_property part $device_name [current_project]
    }

}


proc changeBoard {name boa} {

    set project_name ${name}.xpr
    set proj_path [file join [file dirname [file normalize [info script]]] ../../Projects/$name]
    set proj_path_normalized [file normalize $proj_path]
    set board_name $boa

    set possible_boards [get_boards]

    if {[lsearch -exact $possible_boards $board_name] == -1} {
        puts "the given part: '$board_name' is not a valid board"
        exit 1
    }
        
        
    if {[get_projects *] eq ""} {
        puts "opening  project $proj_path_normalized/$project_name "

        open_project $proj_path_normalized/$project_name 
        set_property board $board_name [current_project]
        close_project 
        puts "succefully changed and saved new project parts"

    } else {
        puts "existing project gets changed"
        set_property board $board_name [current_project]
    }

}
