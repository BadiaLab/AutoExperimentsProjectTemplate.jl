
using DrWatson
using AutoExperimentationTools

# Define parameter-value combinations for the experiment.
# Parameter-value combinations s.t. corresponding results
# are already available in the data folder are not re-run.
# You have to eliminate them from the data folder if you wish
# them to be re-rerun
function generate_param_dicts()
   params = []
   push!(params,Dict(
     :m      => collect(0:0.1:1),  #
     :a      => collect(0:0.1:1),  #
     :b      => collect(0:0.1:1),  #
     :p      => [false,true],      #
   ))
   vcat(map(dict_list,params)...)
end

# Defines the Driver module with the driver(...) function inside
# The computational heavy stuff and the actual code of the experiment
# at hand is here.
include("driver.jl")

function run_experiment(params)
  outfile = datadir(experiment_filename("step1",params,"bson"))
  if isfile(outfile)
    println("$outfile (done already)")
    return nothing
  end
  print("$outfile (running)")
  m   = params[:m]
  a   = params[:a]
  b   = params[:b]
  p   = params[:p]
  dict = Driver.driver(m,a,b,p)
  merge!(dict,params)
  save(outfile,dict)
  println(" (done)")
end

# Run all parameter value combinations
dicts=generate_param_dicts()
for params in dicts
  GC.gc()
  run_experiment(params)
end
