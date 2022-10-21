# AutoExperimentsProjectTemplate

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://BadiaLab.github.io/AutoExperimentsProjectTemplate.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://BadiaLab.github.io/AutoExperimentsProjectTemplate.jl/dev/)
[![Build Status](https://github.com/BadiaLab/AutoExperimentsProjectTemplate.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/BadiaLab/AutoExperimentsProjectTemplate.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/BadiaLab/AutoExperimentsProjectTemplate.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/BadiaLab/AutoExperimentsProjectTemplate.jl)


## Project source org 

The `experiments` folder holds the julia scripts required to run the 
experiments. We can have as many subfolders within `experiments` as different
experiments we may want to perform in our project. For example, `experiments/ex1` holds
the scripts corresponding to a mini-example that we can take as an initial template
for more complex endeavours. The `notebooks` folder holds the 
[Pluto.jl](https://github.com/fonsp/Pluto.jl) notebooks. In principle, we will have as
many notebooks as subfolders we have in `experiments`.  For example, see the `notebooks/ex1.jl` 
Pluto notebook.

## Workflow steps 

1. Run the experiments. This is an stage that is designed to be 
   run outside Pluto notebook (although it might be also run within 
   the notebook if desired). Thus, it might be run in the computational
   node of an HPC cluster. Once completed, we have a set of data files 
   that hold the results of the experiments. 
   If we rerun the script, the experiments for which the results 
   data files already exist are not generated again. 
2. Import & visualize interactively/reactively the results of 
   the experiments by means of a reactive/interactive Pluto notebook.

Step 1. leverages `DrWatson.jl` tools and rationale. See [here](https://juliadynamics.github.io/DrWatson.jl/dev/workflow/) for more details, while step 2. leverages the `Pluto.jl` and `PlutoUI.jl`  projects. See [here](https://github.com/fonsp/Pluto.jl/wiki) for more details. 
Some familiarity with the documentation in these two links is highly recommended, specially 
when developing the scripts for a new experiment.

## How to run experiments 

### Option 1 (best suited if you want to run the experiments from the terminal)

**IMPORTANT NOTE**: *This option requires `DrWatson.jl` to be installed in the main julia 
environment, e.g., `v1.7` if you have Julia 1.7. Please install it in the 
main julia environment before following the instructions in the sequel. See [here](https://juliadynamics.github.io/DrWatson.jl/dev/project/#Activating-a-Project-1), option 4 (`@quickactivate` macro), for more details.*


Go to the folder in which the scripts of the experiment at hand are located, e.g., 
`cd experiments/ex1` and run the `julia` script `run_experiment.jl` as 

```bash 
julia run_experiment.jl 
```

Note that the `--project=XXX` is not required in the call to the `julia` command. 
The script is smart enough  in order to locate the `Project.toml` of the project in an ancestor directory. Upon completion, the results are generated in the `data` directory 
of the project, in particular in a subfolder with the same name of the experiments, e.g.,
`data/ex1`.

### Option 2 (best suited if you want to run the experiments interactively)

Go to the root folder of the repo and run from the terminal: 

```bash 
julia --project=. 
```

Then, in the Julia REPL, run: 

```julia
include("experiments/ex1/run_experiments.jl")
```

## How to run pluto notebook 

Go to the root folder of the project and run the following command:

```
julia --project=.
``` 

Then, in the Julia REPL, run (e.g., for `ex1`)

```julia
import Pluto 
Pluto.run(notebook="notebooks/ex1.jl") 
```

this will trigger a web browser navigator with the contents of the notebook.

## Warnings, lessons learned 

When dealing with `DrWatson.jl`, it is a must (at least in the current version at the moment of writing, i.e., `v2.11.1`) that 
the `Dict`s that are written to data files are such that the `typeof` the key is not abstract, e.g., `Any`. In other words, the key has to be of a concrete type, e.g., `Symbol`. Otherwise, when importing the dictionary from data files (typically in a Pluto notebooks) a cryptic/confusing error message is generated on screen.

## TODOs

* In the `DrWatson.jl` scripts, I am using the `@gitsave` macro in order to 
record inside the data file the git commit ID of the project at which the results 
were generated. However, the data file name does not include the commit ID.
As a result, we cannot re-run the experiments for a different commit without removing
the files of the previous commit. We can easily get around this be either tagging 
the filename with the commit ID, or outputting the files in a separate subfolder 
`data/ex1/commit_ID`. In either case, the Pluto notebook needs to be modified such that 
we provide aslo the `commit_ID` for which we want to visualize the results. 

* (Optionally) Split evenly the experiments triggered in `experiments/ex1` into job scripts so that 
  we can exploit HPC node parallelism.  






