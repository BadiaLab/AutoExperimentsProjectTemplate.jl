
using DrWatson

# The following macro call let us execute the script with
# the project's environment even if we ran the julia REPL
# without the --project=... flag
@quickactivate "AutoExperimentsProjectTemplate"

using AutoExperimentsProjectTemplate

# Define parameter-value combinations for the experiment.
# Parameter-value combinations s.t. corresponding results
# are already available in the data folder are not re-run.
# You have to eliminate them from the data folder if you wish
# them to be re-run
function generate_param_dicts()
   params = Dict{Symbol,Any}(
     :m      => collect(0:0.2:1),  #
     :a      => collect(0:0.2:1),  #
     :b      => collect(0:0.2:1),  #
     :p      => [false,true],      #
   )
   dict_list(params)
end

# Defines the Driver module with the driver(...) function inside
# The computational heavy stuff and the actual code of the experiment
# at hand is here.
include("driver.jl")

function run_experiment(params)
  outfile = datadir("ex1", savename("ex1",params,"bson"))
  if isfile(outfile)
    println("$outfile (done already)")
    return nothing
  end
  print("$outfile (running)")
  @unpack m, a, b, p = params
  dict = Driver.driver(m,a,b,p)
  merge!(dict,params)
  # @tagsave: add current git commit to dict and then save.
  # "replace_strings_by_symbols" is required to ensure that
  # the dictionary is not of type Dict{Any} but of type
  # Dict{Symbol}
  @tagsave(outfile,replace_strings_by_symbols(dict))
  println(" (done)")
end

# Run all parameter value combinations
dicts=generate_param_dicts()
for params in dicts
  GC.gc()
  run_experiment(params)
end
