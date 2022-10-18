using DrWatson

# The following macro call let us execute the script with
# the project's environment even if we ran the julia REPL
# without the --project=... flag
@quickactivate "AutoExperimentsProjectTemplate"

using DataFrames
df = collect_results(datadir("ex1"))
println(df)
