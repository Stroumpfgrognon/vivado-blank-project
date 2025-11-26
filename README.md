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
    │   └── your_library.vhd
    ├── test_libraries/
    │   └── tb_your_libary.vhd
    ├── testbenches
    │   └── tb_your_top-module.vhd
    ├── constraints/
    │   └── top.xdc
    ├── Projects/
    │    └── your_project/
    │        ├── top-module.vhd
    │        ├── other_project_modules.vhd
    │        ├── create_project.tcl
    │        └── generated_project_folder/
    │            ├── project.xpr
    |            └── ...
    │        └── parameters/
    └── Makefile
```

## How to run TCL scripts with Vivado

Using `vivado -mode tcl -source script.tcl` lets one start Vivado's TCL console and import the procedures included in the `script.tcl` file. The procedures can then be called using `proc_name param_1 param_2 ...`

Parameters can be calculated on the fly using `[]` blocks like `my_procedure [param_1_calculator param_2] param_3` for example to use the calculated parameter and `param_3` for `my_procedure`, and values can be set by using variables as well with `set param_1 value` (value can be numbers, strings...).

This will be useful here mainly for the get_json procedure to get procedure parameters below.

## Initiating the project

**TODO**

## Running tests

### The two procedures

Test runs procedures are defined in the `scripts/run_sim.tcl` script. They are used for running behavioral simulation on the different modules used in the project. **All test procedures expect the modules doing the testing and to be tested having the same name as their file.**

There are two procedures there :

```TCL
proc run_simulation_library {} {...}

proc run_simulation_project {test_dict} {...}
```

Each procedure looks into specific folders for the modules that will be tested. More info on how to declare tests below.

- `run_simulation_library` is meant for the testing of libraries and expects modules and test benches to be found in the `libraries` and `test_libraries` folders respectively

- `run_simulation_project` is meant for the testing of your specific project modules. It looks into the folder you execute the function from and into the `tesbenches` folder respectively.

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

`run_simulation_project` needs an exterior TCL dictionary to function. These dictionaries can be imported manually using json files with the get_json procedure.

## Running implementation

The implementation procedure is defined in `scripts/run_impl.tcl`:

```TCL
proc run_implementation {project_dict entries_dict} {}
```

The script is meant to generate simulation, implementation and output a bitstream for each set of parameters given to it for a given project.

These variables are defined using two dictionaries, with the same import options as the ones for testing.

```json
Structure for project_dict :
{
    "project_name" : "your_project",
    "device": "xc7s15cpga196-2",
    "project_root_directory": "../projects/your_project_folder_with_parameters_folder_and_such/"
}
```

> This is where you define the `*.xpr` Vivado project which you will run the implementation on.

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

The result files are put into the `Projects/your_project/generated_project_folder/output` folder.

# The easy way to run scripts

In your new project folder should be a Makefile that can be used to call the different scripts.

It will use parameter files it finds by itself in the following folders :

`Projects/your_project/parameters/test.json` for the Simulation->test_dict parameter

`Projects/your_project/parameters/project_var.json` for the Implementation->project_dict variable

`Projects/your_project/parameters/run_para.json` for the Implementation->entries_dict variable
