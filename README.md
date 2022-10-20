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
when developing the scripts and files for a new repository.

## How to run experiments 

Go to the folder in which the scripts of the experiment at hand are located, e.g., 
`cd experiments/ex1` and run the `julia` script `run_experiment.jl` as 

```bash 
julia run_experiment.jl 
```

Note that the `--project=XXX` is not required in the call to the `julia` command. 
The script is smart enough  in order to locate the `Project.toml` of the project in an ancestor directory. Upon completion, the results are generated in the `data` directory 
of the project, in particular in a subfolder with the same name of the experiments, e.g.,
`data/ex1`.

## How to run pluto notebook 

Go to the root folder of the project and run (e.g., for  mini-example `ex1`): 

```
julia --project=.

julia> import Pluto 
julia> Pluto.run(notebook=notebooks/ex1.jl) 
```

this will trigger a web browser navigator with the contents of the notebook.

## Warnings, lessons learned 

When dealing with `DrWatson.jl`, it is a must (at least in the current version at the moment of writing, i.e., `v2.11.1`) that 
the `Dict`s that are written to data files are such that the `typeof` the key is not abstract, e.g., `Any`. In other words, the key has to be of a concrete type, e.g., `Symbol`. Otherwise, when importing the dictionary from data files (typically in a Pluto notebooks) a cryptic/confusing error message is generated on screen. 

