# KTH-CERN Vivado project suite

A blank project for any Vivado project (hopefully) with :

- A clean file structure
- A slew of modular scripts to limit the need for TCL coding knowledge.
- Useful ignores for clean git usage

## File structure

```
└── Project/
    ├── scripts/
    │   ├── xilinx.tcl
    │   ├── run_impl.tcl
    │   ├── run_synth.tcl
    |   ├── run_sim.tcl
    |   ├── change_board.tcl
    │   └── parameters/
    ├── libraries/
    │   ├── one_IP.xci
    │   └── one_library.vhd
    ├── test_libraries/
    │   └── tb_one_libary.vhd
    ├── constraints/
    │   └── constraint_1.xdc
    ├── projects/
    │    └── your_project/
    │        ├── your_project.vhd
    │        ├── other_project_modules.vhd
    │        ├── generate.tcl
    │        ├── Makefile
    │        ├── your_project/ // Generated
    │        │   ├── project.xpr
    │        │   ├── output/ // Where bitfiles go
    |        │   └── ...
    │        ├── parameters/
    │        │   ├── project_var.json
    |        │   └── run_para.json
    |        └── testbenches/
    │            └── tb_project_module.vhd
    └── Makefile
```

## How to run TCL scripts with Vivado

Using `vivado -mode tcl -source script.tcl` lets one start Vivado's TCL console and import the procedures included in the `script.tcl` file. The procedures can then be called using `proc_name param_1 param_2 ...`

Parameters can be calculated on the fly using `[]` blocks like `my_procedure [param_1_calculator param_2] param_3` for example to use the calculated parameter and `param_3` for `my_procedure`, and values can be set by using variables as well with `set param_1 value` (value can be numbers, strings...).

This will be useful here mainly for the get_json procedure to get procedure parameters below.

## The project Makefile

In your project directory (Project/projects/your_project/) lies a Makefile giving aliases through which everything below can be called easily, automatically using the parameter files and directories indicated. The associated command will be indicated with each section with its alias

## Initiating the project

> make project 

or
>vivado -notrace -nolog -nojournal -mode batch -source ./generate.tcl -tclargs make_project

The project gets initiated with all the files in your project and libraries directory and their associated test directories.

The libraries file (.vhd modules or .xci IPs) are considered as common for all the projects you might want to add to the projects subdirectory.  Unused files will not interact with the synthesis and implementation (normally).

Almost all files are used as-is without copy, except for constraints (Project/constraints/*.xcd) and IPs that are copied into the project. This is to be able to manipulate the IPs (upgrading for example) and implement them down the line.

All files are set into another your_project subfolder.

The command need the project_var.json file to be correctly implemented with the following structure. It is imported into the TCL code as project_dict.

```json
Structure for project_dict :
{
    "project_name" : "your_project", // To find the directory and such
    "device": "xc7s15cpga196-2" // The device to implement to
}
```

> This is where you define the `*.xpr` Vivado project which you will run the implementation on.

## Running tests

> make test

or

> vivado -notrace -nolog -nojournal -mode batch -source ./generate.tcl -tclargs make_simulations

### Implementations

Test runs procedures are defined in the `scripts/run_sim.tcl` script. They are used for running behavioral simulation on the different modules used in the project. **All test procedures expect the modules doing the testing and to be tested having the same name as their file.**

There are two procedures there :

```TCL
proc run_simulation_library {} {...}

proc run_simulation_project {test_dict} {...}
```

Each procedure looks into specific directories for the modules that will be tested. More info on how to declare tests below.

- `run_simulation_library` is meant for the testing of libraries and expects modules and test benches to be found in the `libraries` and `test_libraries` directories respectively

- `run_simulation_project` is meant for the testing of your specific project modules. It looks into the directory you execute the function from and into the `your_project/tesbenches` directory respectively.

You can comment their call in `your_project/generate.tcl` to skip the tests

### How to declare tests

Like the other modular scripts, the simulation procedures use TCL dictionaries.

For the simulation script, the following data structure is expected :

```json
Structure of test_dict :
[
  {
    "name": "TestConverter",
    "source_names": ["converter.vhd"],
    "testbench_names": ["tb_converter_dependency.vhd", "tb_converter.vhd"]
  },
  {...}
]
```

If multiple files are declared in `source_names` or `testbench_names` they are expected to be in order of dependency, with the last name being the top module.

`run_simulation_library` opens the `scripts/parameters/test_para.json` file by itself to find which modules to test and how.

`run_simulation_project` needs an exterior TCL dictionary to function. These dictionaries can be imported manually using json files with the get_json procedure. It is imported automatically by generate.tcl through `your_project/parameters/project_tests.json`.

> If a test contains "PASS" in its name, it is skipped

Individual testbenches should put their results in the console (`report "..." severity X`) and call the end of simulation (`std.env.stop`) once they are done.


## Running implementation

> make impl

or

> vivado -notrace -nolog -nojournal -mode batch -source ./generate.tcl -tclargs make_implementation

The implementation procedure is defined in `scripts/run_impl.tcl`:

```TCL
proc run_implementation {project_dict entries_dict} {}
```

The script is meant to generate simulation, implementation and output a bitstream for each set of parameters given to it for a given project.

These variables are defined using two dictionaries, with the same import options as the ones for testing.

project_dict, as seen above and entries_dict

```json
Structure for entries_dict :
[
  {
    "name": "<run_name>",
    "parameters": "<implementation_parameters>",
    "vector_parameters": {
      "<param_name>": { "size": <size>, "value": "<value>" },
      "<param_name_2>" : {...}
      }
    }
  },
  {...}
]
```

Example for entries_dict :

```json
[
  {
    "name": "Run320mbBigEndian",
    "parameters": "datarate=320",
    "vector_parameters": { "ENDIAN_CHANGER": { "size": 2, "value": "11" } }
  }
]
```

> This example will do a single run-through. It will create an output bitfile with the name "Run320mbBigEndian". It sets the generic _integer_ parameter _datarate_ to 320 and the _ENDIAN_CHANGER_ 2 bit _std_vector_ generic parameter to 0b11.

The result files are put into the `Projects/your_project/your_project/output` directory.

> If a run contains "PASS" in its name, it is skipped

## TL;DR for where to set parameters

To use the project Makefile / generate.tcl script, you'll need to fill out the following files 

`Projects/your_project/parameters/project_var.json` to create the project for the right device

`Projects/your_project/parameters/project_tests.json` for the project test benches

`Projects/scripts/parameters/test_para.json` for the libraries test benhces

`Projects/your_project/parameters/run_para.json` for implementation parameters
