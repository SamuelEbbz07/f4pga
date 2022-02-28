# Usage

## Getting started

To use `f4pga` you need a working Python 3 installation which should be included as a part of the conda virtual
environment set up during F4PGA installation.
`f4pga` is installed together with F4PGA, regardless of the version of the toolchain.
However, only _XC7_ architectures are supported currently and _Quicklogic_ support is a work in progress.

To get started with a project that already uses `f4pga`, go to the project's directory and run the following line to
generate a bitstream:

```bash
$ f4pga flow.json -p platform_name -t bitstream
```

Substitute `platform_name` by the name of the target platform (eg. `x7a50t`).
`flow.json` should be a *project flow configuration* file included with the project.
If you are unsure if you got the right file, you can check an example of the contents of such file shown in the
*Build a target* section below.

The location of the bitstream will be indicated by `f4pga` after the flow completes.
Look for a line like this one on stdout:

```bash
Target `bitstream` -> build/arty_35/top.bit
```

## Fundamental concepts

If you want to create a new project, it's highly recommended that you read this section first.

### f4pga

`f4pga` is a modular build system designed to handle various _Verilog-to-bitsream_ flows for FPGAs.
It works by wrapping the necessary tools in Python, which are called *f4pga modules*.
Modules are then referenced in *platform flow definition* files, together with configuration specific for a given
platform.
Flow definition files for the following platforms are included as a part of `f4pga`:

* x7a50t
* x7a100t
* x7a200t (_soon_)

You can also write your own *platform flow definition* file if you want to bring support for a different device.

Each project that uses `f4pga` to perform any flow should include a _.json_ file describing the project.
The purpose of that file is to configure inputs for the flow and override configuration values if necessary.

### Modules

A *module* (also referred to as *f4pga module* in situations where there might be confusion between arbitrary Python
_modules_ and f4pga _modules_) is a Python script that wraps a tool used within the F4PGA ecosystem.
The main purpose of the wrappers is to provide a unified interface for `f4pga` to use and to configure the tool,
as well as provide information about files required and produced by the tool.

### Dependecies

A *dependency* is any file, directory or a list of such that a *module* takes as its input or produces on its output.

Modules specify their dependencies by using symbolic names instead of file paths.
The files they produce are also given symbolic names and paths which are either set through *project flow configuration*
file or derived from the paths of the dependencies taken by the module.

### Target

*Target* is a dependency that the user has asked F4PGA to produce.

### Flow

A *flow* is set of *modules* executed in a right order to produce a *target*.

### .symbicache

All *dependencies* are tracked by a modification tracking system which stores hashes of the files
(directories get always `'0'` hash) in `.symbicache` file in the root of the project.
When F4PGA constructs a *flow*, it will try to omit execution of modules which would receive the same data on their
input.
There is a strong _assumption_ there that a *module*'s output remains unchanged if the input configuration isn't
change, ie. *modules* are deterministic.

### Resolution

A *dependency* is said to be *resolved* if it meets one of the following critereia:

* it exists on persistent storage and its hash matches the one stored in .symbicache
* there exists such *flow* that all of the dependieces of its modules are *resolved* and it produces the *dependency* in
  question.

### Platform's flow definition

*Platform flow definition* is a piece of data describing a space of flows for a given platform, serialized into a _JSON_.
It's stored in a file that's named after the device's name under `f4pga/platforms`.

*Platform flow definition* contains a list of modules available for constructing flows and defines a set of values which
the modules can reference.
In case of some modules it may also define a set of parameters used during their construction.
`mkdirs` module uses that to allow production of of multiple directories as separate dependencies.
This however is an experimental feature which possibly will be removed in favor of having multiple instances of the same
module with renameable ouputs.

Not all *dependencies** have to be *resolved* at this stage, a *platform's flow definition* for example won't be able to
provide a list of source files needed in a *flow*.

### Projects's flow configuration

Similarly to *platform flow definition*, *Projects flow configuration* is a _JSON_ that is used to configure *modules*. There are however a couple differences here and there.

* The most obvious one is that this file is unique for a project and is provided by the user of `f4pga`.

* The other difference is that it doesn't list *modules* available for the platform.

* All the values provided in *projects flow configuration* will override those provided in *platform flow definition*.

* It can contain sections with configurations for different platforms.

* Unlike *platform flow definition* it can give explicit paths to dependencies.

* At this stage all mandatory *dependencies* should be resolved.

Typically *projects flow configuration* will be used to resolve dependencies for _HDL source code_ and _device constraints_.

## Build a target

To build a *target* `target_name`, use the following command:

```bash
$ f4pga flow.json -p platform_device_name -t target_name
```
where `flow.json` is a path to *projects flow configuration*.

For example, let's consider the following *projects flow configuration (flow.json)*:

```json
{
    "dependencies": {
        "sources": ["counter.v"],
        "xdc": ["arty.xdc"],
        "synth_log": "synth.log",
        "pack_log": "pack.log",
        "top": "top"
    },
    "xc7a50t": {
        "dependencies": {
            "build_dir": "build/arty_35"
        }
    }
}
```

It specifies list of paths to Verilog source files as `sources` dependency.
Similarily it also provides an `XDC` file with constrains (`xdc` dependency).

It also names a path for synthesis and logs (`synth_log`, `pack_log`).
These two are optional on-demand outputs, meaning they won't be produces unless their paths are explicitely set.

`top` value is set to in order to specify the name of top Verilog module, which is required during synthesis.

`build_dir` is an optional helper dependency.
When available, modules will put their outputs into that directory.
It's also an _on-demand_ output of `mkdirs` module in _xc7a50t_ flow definition, which means that if specified directory
does not exist, `mkdirs` will create it and provide as `build_dir` dependency.

With this flow configuration, you can build a bitstream for arty_35 using the
following command:

```
$ f4pga flow.json -p x7a50t -t bitstream
```

### Pretend mode

You can also add a `--pretend` (`-P`) option if you just want to see the results of dependency resolution for a
specified target without building it.
This is useful when you just want to know what files will be generated and where wilh they be stored.

### Info mode

Modules have the ability to include description to the dependencies they produce.

Running `f4pga` with `--info` (`-i`) flag allows youn to see descriptions of these dependencies.
This option doesn't require a target to be specified, but you still have to provuide a flow configuration and platform
name.

This is still an experimental option, most targets currently lack descriptions and no information whether the output is
_on-demand_ is currently displayed.

Example:

```bash
$ f4pga flow.json -p x7a50t -i
```

```
Platform dependencies/targets:
    build_dir:          <no descritption>
                        module: `mk_build_dir`
    eblif:              Extended BLIF hierarchical sequential designs file
                        generated by YOSYS
                        module: `synth`
    fasm_extra:         <no description>
                        module: `synth`
    json:               JSON file containing a design generated by YOSYS
                        module: `synth`
    synth_json:         <no description>
                        module: `synth`
    sdc:                <no description>
                        module: `synth`
```

:::{important}
This is only a snippet of the entire output.
:::

### Summary of all available options

| long       | short | arguments              | description                                     |
|------------|:-----:|------------------------|-------------------------------------------------|
| --platform | -p    | device name            | Specify target device name (eg. x7a100t)        |
| --target   | -t    | target dependency name | Specify target to produce                       |
| --info     | -i    | -                      | Display information about available targets     |
| --pretend  | -P    | -                      | Resolve dependencies without executing the flow |

### Dependency resolution display

F4PGA displays some information about dependencies when requesting a target.

Here's an example of a possible output when trying to build `bitstream` target:

```
F4PGA Build System
Scanning modules...

Project status:
    [R] bitstream:  bitstream -> build/arty_35/top.bit
    [O] build_dir:  build/arty_35
    [R] eblif:  synth -> build/arty_35/top.eblif
    [R] fasm:  fasm -> build/arty_35/top.fasm
    [R] fasm_extra:  synth -> build/arty_35/top_fasm_extra.fasm
    [R] io_place:  ioplace -> build/arty_35/top.ioplace
    [R] net:  pack -> build/arty_35/top.net
    [X] pcf:  MISSING
    [R] place:  place -> build/arty_35/top.place
    [R] place_constraints:  place_constraints -> build/arty_35/top.preplace
    [R] route:  route -> build/arty_35/top.route
    [R] sdc:  synth -> build/arty_35/top.sdc
    [N] sources:  ['counter.v']
    [O] xdc:  ['arty.xdc']

F4PGA: DONE
```

The letters in the boxes describe the status of a dependency which's name is next to the box.

 * **X** - dependency unresolved.
   This isn't always a bad sign. Some dependencies are not required to, such as `pcf`.

 * **U** - dependency unreachable.
   The dependency has a module that could produce it, but the module's dependencies are unresolved.
   This doesn't say whether the dependency was necessary or not.

 * **O** - dependency present, unchanged.
   This dependency is already built and is confirmed to stay unchanged during flow execution.

 * **N** - dependency present, new/changed.
   This dependency is already present on the persistent storage, but it was either missing earlier, or its content
   changed from the last time.

   :::{warning}
   It won't continue to be reported as "**N**" after a successful build of any target.
   This may lead to some false "**O**"s in some complex scenarios.
   This should be fixed in the future.
   :::

 * **S** - depenendency not present, resolved.
   This dependency is not currently available on the persistent storage, however it will be produced within flow's
   execution.

 * **R** - depenendency present, resolved, requires rebuild.
  This dependency is currently available on the persistent storage, however it has to be rebuilt due to the changes in
  the project.

Additional info about a dependency will be displayed next to its name after a colon:

* In case of dependencies that are to be built (**S**/**R**), there's a name of a module that will produce this
  dependency, followed by `->` and a path or list of paths to file(s)/directory(ies) that will be produced as this
  dependency.

* In case of dependencies which do not require execution of any modules, only a path or list of paths to
  file(s)/directory(ies) that will be displayed.

* In case of unresolved dependencies (**X**), which are never produced by any module, a text sying "`MISSING`" will be
  displayed.

* In case of unreachable dependencies, a name of such module that could produce them will be displayed followed by
  `-> ???`.

In the example above file `counter.v` has been modified and is now marked as "**N**".
This couses a bunch of other dependencies to be reqbuilt ("**R**").
`build_dir` and `xdc` were already present, so they are marked as "**O**".

## Common targets and values

Targets and values are named with some conventions.
Below are lists of the target and value names along with their meanings.

### Need to be provided by the user

| Target name | list | Description |
|-------------|:----:|-------------|
| `sources` | yes | Verilog sources |
| `sdc` | no | Synopsys Design Constraints |
| `xdc` | yes | Xilinx Design Constraints (available only for Xilinx platforms) |
| `pcf` | no | Physical Constraints File |

### Available in most flows

| Target name | list | Description |
|-------------|:----:|-------------|
| `eblif` | no | Extended blif file |
| `bitstream` | no | Bitstream |
| `net` | no | Netlist |
| `fasm` | no | Final FPGA Assembly |
| `fasm_extra` | no | Additional FPGA assembly that may be generated during synthesis |
| `build_dir` | no | A directory to put the output files in |

### Built-in values

| Value name | type | Description |
|------------|------|-------------|
| `shareDir` | `string` | Path to symbiflow's installation "share" directory |
| `python3` | `string` | Path to Python 3 executable |
| `noisyWarnings` | `string` | Path to noisy warnings log (should be deprecated) |
| `prjxray_db` | `string` | Path to Project X-Ray database |

### Used in flow definitions

| Value name | type | Description |
|------------|------|-------------|
| `top` | `string` | Top module name |
| `build_dir` | `string` | Path to build directory (should be optional) |
| `device` | `string` | Name of the device |
| `vpr_options` | `dict[string -> string \| number]` | Named ptions passed to VPR. No `--` prefix included. |
| `part_name` | `string` | Name of the chip used. The distinction between `device` and `part_name` is ambiguous at the moment and should be addressed in the future. |
| `arch_def` | `string` | Path to an XML file containing architecture definition. |