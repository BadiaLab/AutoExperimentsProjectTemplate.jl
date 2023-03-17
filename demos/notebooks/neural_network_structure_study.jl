### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 38e1939a-3c91-4b7b-88fd-ae7e01eda602
# Run notebook in Pluto.jl "backward compatibility mode"
# using the so-called "global environment" pattern
# see https://github.com/fonsp/Pluto.jl/wiki/%F0%9F%8E%81-Package-management
# for more details
begin
  import Pkg
  # activate the shared project environment
  Pkg.activate(Base.current_project())
  # instantiate, i.e. make sure that all packages are downloaded
  Pkg.instantiate()
end

# ╔═╡ 299c6e30-9107-4039-a11c-32ed6d9b1460
using DrWatson, DataFrames, BSON, PlutoUI, StatsPlots, Unicode

# ╔═╡ b881120b-853d-4c0f-bcb8-b3b18e2dd9ae
@quickactivate "AutoExperimentsProjectTemplate"

# ╔═╡ 106ded38-479d-4961-a127-24c2b416aa9d
md"""
### Forward 1D Poisson - Neural Network Structure Experiments
"""

# ╔═╡ 50fb806d-1431-44dd-93c9-a721ed048374
import Measures: mm

# ╔═╡ 098b6802-971d-4651-9ca5-14d2683e4a4c
experiment_data_dir = "demos/data/Fwd_1DPoisson_Neural_Network_Structure";

# ╔═╡ 12aa958b-c45f-4b02-a3e0-fbbe68ff2618
commit_dirs = readdir(projectdir(experiment_data_dir));

# ╔═╡ 24121476-672c-48f0-9b77-3b05478c887d
md"""
Select commit ID data directory: $(@bind commitID Select(commit_dirs))
"""

# ╔═╡ feff8f1d-1957-4285-b62a-cc5e145835f3
df = collect_results(projectdir(experiment_data_dir, commitID));

# ╔═╡ c72b112d-dbe3-49ec-bdf7-54c7a3d6b9dc
transform!(df, :, [:l2_errs] => ByRow(last) => :last_l2_err);

# ╔═╡ fa7f1cb3-b28d-4f53-bab8-f0fc74b37979
transform!(df, :, [:h1_errs] => ByRow(last) => :last_h1_err);

# ╔═╡ 1014e48b-5ef5-47b8-ad11-9a1c5baf430e
transform!(df, :, [:ncells] => ByRow(inv) => :mesh_size);

# ╔═╡ 53a71eb1-9d6f-4bda-9a38-7a8be0bff337
absdiff(a, b) = abs.(a - b)

# ╔═╡ 8850e38e-3ab5-4b14-b3ec-1de4d0c2c502
vecabs(a) = abs.(a)

# ╔═╡ 7606d45a-0059-4e9a-a606-f646f5145f50
df[!, :l2es] = absdiff.(df[:, "ûs"], df[:, "us"]);

# ╔═╡ e1963679-33c1-41c4-9432-5b8c066693fe
df[!, :des] = vecabs.(df[:, :des]);

# ╔═╡ e3b5ac9f-235e-432f-91b8-3b52decb5877
cols_to_filter = [
	"û", "activation", "order", "precondition", "ncells", "neuron", "layer", 
	"seed", "mesh_size", "linearized", "optimizer", "xs", "us", "ûs", "l2es", 
	"des", "es_nn", "des_nn", "fem_l2_err", "fem_h1_err", "nn_l2_err", "nn_h1_err", "last_l2_err", "last_h1_err", "l2_errs", "h1_errs", "target_losses", "actual_losses"];

# ╔═╡ 4bde79bd-b9c2-4a35-8e83-b5ef31bb071c
df_filtered = df[:, cols_to_filter];

# ╔═╡ 267d2c56-eab9-4cc9-9e1b-5f92db29f919
df_filtered_cols = Dict(string(k) => v for (k, v) in pairs(eachcol(df_filtered)));

# ╔═╡ 902c0a48-f30a-4abe-be67-1531f9c03b2b
params_possible_values = Dict([k => unique(df_filtered_cols[k])
                               for k in keys(df_filtered_cols)]);

# ╔═╡ d97732c5-f321-44a1-b285-d2b73608371b
markershapes = [:star7, :rect, :hexagon, :star5, :diamond, :heptagon, :ltriangle, :star4, :dtriangle, :circle, :star8, :xcross, :rtriangle, :pentagon, :octagon, :cross, :x, :+, :star6, :utriangle];

# ╔═╡ 48116d1d-0d47-4281-8e02-5f26c3cfce54
function get_x_y_vectors(yparam, ffilter, df; xparam=nothing)
  df_filtered = filter(ffilter, df)
  df_filtered_cols = Dict(pairs(eachcol(df_filtered)))

  @assert (xparam === nothing) || (xparam in keys(df_filtered_cols))
  @assert yparam in keys(df_filtered_cols)

  params_possible_values =
    Dict([k => unique(df_filtered_cols[k])
          for k in keys(df_filtered_cols) if k != xparam && k != yparam])

  dl = dict_list(params_possible_values)

  # The following code is general enough so that for
  # fixed (xparam, yparam) there might be several
  # possible combinations for the rest of parameters
  # after applying ffilter. In such a case we generate
  # as many curves as combinations of the rest of
  # parameter values.
  xall = []
  yall = []
  for d in dl
    function f(a...)
      all(a .== values(d))
    end
    ffilter_current_d = collect(keys(d)) => f
    df_tmp = filter(ffilter_current_d, df_filtered)
    if xparam != nothing
      x = df_tmp[!, xparam]
      y = df_tmp[!, yparam]
      push!(xall, x[1])
      push!(yall, y[1])
    else
      y = df_tmp[!, yparam]
      push!(xall, collect(1:length(y[1])))
      push!(yall, y[1])
    end
  end
  (xall, yall, params_possible_values)
end

# ╔═╡ beae208c-a82a-4fc3-bc0b-67d8153b2a22
function generate_labels(params_possible_values; only_legends_for_vars=true)
  dl = dict_list(params_possible_values)
  labels = Vector{String}(undef, length(dl))
  for (i, d) in enumerate(dl)
    label = ""
    for (key, val) in d
      if (!only_legends_for_vars || length(params_possible_values[key]) > 1)
        label *= label == "" ? "$(key)=$(val)" : ", $(key)=$(val)"
      end
    end
    labels[i] = label
  end
  labels
end

# ╔═╡ e0ba07a2-7541-4377-9235-d0ecea7d0223
md"""
#### Parameter Selection

û: $(@bind ûval Select(params_possible_values["û"]))
order:  $(@bind orderval Select(params_possible_values["order"]))
element: $(@bind ncellsval Select(params_possible_values["ncells"]))

neuron: $(@bind neuronval Select(params_possible_values["neuron"]))
layer: $(@bind layerval Select(params_possible_values["layer"]))
activation: $(@bind actval Select(params_possible_values["activation"]))
initialization seed: $(@bind seedval Select(params_possible_values["seed"]))

optimizer: $(@bind optimizerval Select(params_possible_values["optimizer"]))

precondition mode: $(@bind preconditionval Select(params_possible_values["precondition"]))

linearized test space: $(@bind linearizedval Select(params_possible_values["linearized"]))

#### Customize Visualization

legend position: $(@bind lposition Select([:right, :left, :top, :bottom, :inside, :best, :legend, :topright, :topleft, :bottomleft, :bottomright]))

markers: $(@bind addmarkers CheckBox(;default=false))

autoxlims: $(@bind autoxlims CheckBox(;default=true))
xlimleft: $(@bind xliml TextField((3,1);default="0.0"))
xlimright: $(@bind xlimr TextField((3,1);default="1.0"))

autoylims: $(@bind autoylims CheckBox(;default=true))
ylimbottom: $(@bind ylimb TextField((3,1);default="0.0"))
ylimtop: $(@bind ylimt TextField((3,1);default="1.0"))

logx: $(@bind logxval CheckBox())
logy: $(@bind logyval CheckBox())
"""

# ╔═╡ 7769bd08-5a2f-456a-8bbc-e3169b8de35b
function plot_x_versus_y(yparam, xaxis, yaxis, ffilter, df;
  xparam=nothing,
  refparam=nothing,
  title="",
  xlabel="",
  ylabel="",
  size=nothing,
  autoxlims=true,
  autoylims=true,
  xliml=0.0,
  xlimr=1.0,
  ylimb=0.0,
  ylimt=1.0)
  f = plot(margins=4mm, dpi=200)
  x, y, params_possible_values = get_x_y_vectors(yparam, ffilter, df; xparam=xparam)
  labels = generate_labels(params_possible_values)
  @assert length(x) == length(y)
  @assert length(labels) == length(y)
  imarker = 1
  for (xi, yi, li) in zip(x, y, labels)
	if !addmarkers
	  plot!(f, xi, yi, xaxis=xaxis, yaxis=yaxis, label=li)
	else
	  idx = Int64.(floor.(collect(range(1, length(xi), 20))))
	  scatter!(f, xi[idx], yi[idx], xaxis=xaxis, yaxis=yaxis, label=li, markershape=markershapes[imarker], markerstrokewidth=0.0, markerstrokealpha=0.6)
	  plot!(f, xi, yi, xaxis=xaxis, yaxis=yaxis, label="")
	  imarker += 1
	end
  end
  xlabl = (xlabel != "" ? xlabel : "$xparam")
  ylabl = (ylabel != "" ? ylabel : "$yparam")
  plot!(f, xlabel=xlabl, ylabel=ylabl, legend=lposition, title=title)
  if (refparam !== nothing)
    df_filtered_ref = df[1, [String(xparam), String(refparam)]]
    xref = df_filtered_ref[String(xparam)]
    yref = df_filtered_ref[String(refparam)]
    plot!(f,
      xref, yref,
      markershape=:none,
      linestyle=:dashdot,
      linewidth=3,
      linecolor=:red,
      label="reference")
  end
  if (size != nothing)
    plot!(size=size)
  end
  if (!autoxlims)
    xlims!((xliml, xlimr))
  end
  if (!autoylims)
    ylims!((ylimb, ylimt))
  end
  f
end

# ╔═╡ 7e34624a-2ac7-45a1-a2c4-aa0d7e6da52a
filter_precond_free = ["û", "order", "ncells", "neuron", "layer",  "activation", "seed", "linearized", "optimizer", "precondition"] => (û, order, ncells, neuron, layer, activation, seed, linearized, optimizer, precondition) -> (û == ûval && order == orderval && ncells == ncellsval && neuron == neuronval && layer == layerval && activation == actval && seed == seedval && linearized == linearizedval && optimizer == optimizerval && (precondition in (:none, :full)));

# ╔═╡ eaa5f549-21fc-4b1e-9db1-5d8027c14cbd
begin
  cols_to_filter_state = ["û", "order", "ncells", "neuron", "activation", "layer", 
    "seed", "precondition", "linearized", "optimizer", "us", "ûs", "xs"]
  df_filtered_state = df[:, cols_to_filter_state]
  plot_x_versus_y(:us,
    (logxval ? :log10 : :none),
    (logyval ? :log10 : :none),
    filter_precond_free,
    df_filtered_state;
    title="neuron = $neuronval, layer = $layerval, linearized = $linearizedval, optimizer = $optimizerval",
	ylabel="u",
    xparam=:xs,
    refparam="ûs",
    size=(750, 300),
    autoxlims=autoxlims,
    autoylims=autoylims,
    xliml=parse(Float64, xliml), xlimr=parse(Float64, xlimr),
    ylimb=parse(Float64, ylimb), ylimt=parse(Float64, ylimt))
end

# ╔═╡ fc1af1fb-780b-4d31-b9c1-caba2fde7f6d
begin
  cols_to_filter_error = ["û", "order", "ncells", "neuron", "activation", "layer", 
    "seed", "precondition", "linearized", "optimizer", "l2es", "xs"]
  plot_x_versus_y(:l2es,
    (logxval ? :log10 : :none),
    (logyval ? :log10 : :none),
    filter_precond_free,
    df[:, cols_to_filter_error];
    title="neuron = $neuronval, layer = $layerval, linearized = $linearizedval, optimizer = $optimizerval",
    xparam=:xs,
	xlabel="x",
	ylabel="Error",
    size=(750, 300),
    autoxlims=autoxlims,
    autoylims=autoylims,
    xliml=parse(Float64, xliml), xlimr=parse(Float64, xlimr),
    ylimb=parse(Float64, ylimb), ylimt=parse(Float64, ylimt))
end

# ╔═╡ 5bea3eb3-1da3-4e69-afb2-47a95d8da88b
begin
  cols_to_filter_grad_err = ["û", "order", "ncells", "neuron", "activation", "layer", 
    "seed", "precondition", "linearized", "optimizer", "des", "xs"]
  plot_x_versus_y(:des,
    (logxval ? :log10 : :none),
    (logyval ? :log10 : :none),
    filter_precond_free,
    df[:, cols_to_filter_grad_err];
    title="neuron = $neuronval, layer = $layerval, linearized = $linearizedval, optimizer = $optimizerval",
    xparam=:xs,
	xlabel="x",
	ylabel="Gradient Error",
    size=(750, 300),
    autoxlims=autoxlims,
    autoylims=autoylims,
    xliml=parse(Float64, xliml), xlimr=parse(Float64, xlimr),
    ylimb=parse(Float64, ylimb), ylimt=parse(Float64, ylimt))
end

# ╔═╡ 249a3111-e542-4934-aa96-3aaf94e23ee2
begin
  cols_to_filter_actual_losses = [
	  "û", "order", "ncells", "neuron", "activation", "layer", "seed",
	  "precondition", "linearized", "optimizer", "actual_losses"]
  df_filtered_actual_losses = df[:, cols_to_filter_actual_losses]
  plot_x_versus_y(:actual_losses,
    (logxval ? :log10 : :none),
    :log10,
    filter_precond_free,
    df_filtered_actual_losses;
    xlabel="Iteration", ylabel="Actual Loss", title="neuron = $neuronval, layer = $layerval, linearized = $linearizedval, optimizer = $optimizerval",
    size=(750, 300),
    autoxlims=autoxlims,
    autoylims=autoylims,
    xliml=parse(Float64, xliml), xlimr=parse(Float64, xlimr),
    ylimb=parse(Float64, ylimb), ylimt=parse(Float64, ylimt))
end


# ╔═╡ 8106a0d4-bb59-47f1-b16f-6f3d6ea3b838
begin
  cols_to_filter_target_losses = [
	  "û", "order", "ncells", "neuron", "activation", "layer", "seed",
	  "precondition", "linearized", "optimizer", "target_losses"]
  df_filtered_target_losses = df[:, cols_to_filter_target_losses]
  plot_x_versus_y(:target_losses,
    (logxval ? :log10 : :none),
    :log10,
    filter_precond_free,
    df_filtered_target_losses;
    xlabel="Iteration", ylabel="Target Loss", title="neuron = $neuronval, layer = $layerval, linearized = $linearizedval, optimizer = $optimizerval",
    size=(750, 300),
    autoxlims=autoxlims,
    autoylims=autoylims,
    xliml=parse(Float64, xliml), xlimr=parse(Float64, xlimr),
    ylimb=parse(Float64, ylimb), ylimt=parse(Float64, ylimt))
end


# ╔═╡ b614255e-dc59-459e-88ac-9427d87ca71a
begin
  cols_to_filter_l2_errors = [
	  "û", "order", "ncells", "neuron", "activation", "layer", "seed",
	  "precondition", "linearized", "optimizer", "l2_errs", "fem_l2_err"]
  df_filtered_l2_errors = df[:, cols_to_filter_l2_errors]
  plt_l2_err = plot_x_versus_y(:l2_errs,
    (logxval ? :log10 : :none),
    :log10,
    filter_precond_free,
    df_filtered_l2_errors;
    xlabel="Iteration", ylabel="L2 Error", title="neuron = $neuronval, layer = $layerval, linearized = $linearizedval, optimizer = $optimizerval",
    size=(750, 300),
    autoxlims=autoxlims,
    autoylims=autoylims,
    xliml=parse(Float64, xliml), xlimr=parse(Float64, xlimr),
    ylimb=parse(Float64, ylimb), ylimt=parse(Float64, ylimt))
	fem_l2_err = first(filter(row -> row.order == orderval && row.ncells == ncellsval, df_filtered_l2_errors).fem_l2_err)
	x_l2_err = 0:2:maximum(length.(df.l2_errs))
	plot!(plt_l2_err, x_l2_err, fill(fem_l2_err, length(x_l2_err)), label="FEM reference", linestyle=:dashdot, width=2, color=:red)
end

# ╔═╡ 88761bba-468e-4c0b-9958-70a8e8ee0464
begin
  cols_to_filter_h1_errs = [
	  "û", "order", "ncells", "neuron", "activation", "layer", "seed", 
	  "precondition", "linearized", "optimizer", "h1_errs", "fem_h1_err"]
  df_filtered_h1_errs = df[:, cols_to_filter_h1_errs]
  plt_h1_err = plot_x_versus_y(:h1_errs,
    (logxval ? :log10 : :none),
    :log10,
    filter_precond_free,
    df_filtered_h1_errs;
    xlabel="Iteration", ylabel="H1 Error", title="neuron = $neuronval, layer = $layerval, linearized = $linearizedval, optimizer = $optimizerval",
    size=(750, 300),
    autoxlims=autoxlims,
    autoylims=autoylims,
    xliml=parse(Float64, xliml), xlimr=parse(Float64, xlimr),
    ylimb=parse(Float64, ylimb), ylimt=parse(Float64, ylimt))

	fem_h1_err = first(filter(row -> row.order == orderval && row.ncells == ncellsval, df_filtered_h1_errs).fem_h1_err)
	plot!(plt_h1_err, x_l2_err, fill(fem_h1_err, length(x_l2_err)), label="FEM reference", linestyle=:dashdot, width=2, color=:red)
end

# ╔═╡ 7f8ecd86-009d-4118-a88f-466c0f04dd3e
function plot_error_bar(;errtype="l2_err", size=(750, 300))
	hist_filter = ["order", "precondition", "linearized", "ncells", "optimizer"] => (order, precondition, linearized, ncells, optimizer) -> (order == orderval && precondition == preconditionval && linearized == linearizedval && ncells == ncellsval && optimizer == optimizerval)
	hist_df = filter(hist_filter, df)
	layers, neurons = hist_df[:, :layer], hist_df[:, :neuron]
	errcolname = "last_"*errtype
	errs = hcat([sort(filter(x -> x.layer == layer, hist_df)[:, [errcolname, "neuron"]], order("neuron"))[:, errcolname] for layer in sort(unique(layers))]...)
	layerlabels = repeat(["$layer layers" for layer in sort(unique(layers))], inner=length(unique(neurons)))
	neuronlabels = repeat([neuron for neuron in sort(unique(neurons))], outer=length(unique(layers)))
	bwidth = 8.0
	bplot = groupedbar(neuronlabels, errs, bar_position=:dodge, bar_width=bwidth, yaxis=:log, xlabel="Number of Neurons", ylabel=errtype == "l2_err" ? "L2 Error" : "H1 Error", group=layerlabels, xticks=sort(unique(neurons)), yticks=[10.0^i for i in -2:-2:-12], ylim=(1e-12, 1e0), title="order=$orderval, precond=$preconditionval, cell=$ncellsval, linearized=$linearizedval, optimizer=$optimizerval")
	x = range(minimum(neurons)-4.0, maximum(neurons)+4.0, 15)
	plot!(bplot, x, [first(hist_df[:, "fem_"*errtype]) for _ in x], linecolor=:red, linestyle=:dashdot, label="FEM Ref", width=2.0, size=size, margin=3mm)
	bplot
end

# ╔═╡ 2763f943-e7d0-463c-be13-52de1995a063
plot_error_bar()

# ╔═╡ feabc799-0a0e-4569-942d-babc8221bc7a
plot_error_bar(errtype="h1_err")

# ╔═╡ Cell order:
# ╟─106ded38-479d-4961-a127-24c2b416aa9d
# ╟─38e1939a-3c91-4b7b-88fd-ae7e01eda602
# ╠═299c6e30-9107-4039-a11c-32ed6d9b1460
# ╠═50fb806d-1431-44dd-93c9-a721ed048374
# ╠═b881120b-853d-4c0f-bcb8-b3b18e2dd9ae
# ╠═098b6802-971d-4651-9ca5-14d2683e4a4c
# ╠═12aa958b-c45f-4b02-a3e0-fbbe68ff2618
# ╟─24121476-672c-48f0-9b77-3b05478c887d
# ╠═feff8f1d-1957-4285-b62a-cc5e145835f3
# ╠═c72b112d-dbe3-49ec-bdf7-54c7a3d6b9dc
# ╠═fa7f1cb3-b28d-4f53-bab8-f0fc74b37979
# ╠═1014e48b-5ef5-47b8-ad11-9a1c5baf430e
# ╟─53a71eb1-9d6f-4bda-9a38-7a8be0bff337
# ╟─8850e38e-3ab5-4b14-b3ec-1de4d0c2c502
# ╠═7606d45a-0059-4e9a-a606-f646f5145f50
# ╠═e1963679-33c1-41c4-9432-5b8c066693fe
# ╠═e3b5ac9f-235e-432f-91b8-3b52decb5877
# ╠═4bde79bd-b9c2-4a35-8e83-b5ef31bb071c
# ╠═267d2c56-eab9-4cc9-9e1b-5f92db29f919
# ╠═902c0a48-f30a-4abe-be67-1531f9c03b2b
# ╠═d97732c5-f321-44a1-b285-d2b73608371b
# ╟─48116d1d-0d47-4281-8e02-5f26c3cfce54
# ╟─7769bd08-5a2f-456a-8bbc-e3169b8de35b
# ╟─beae208c-a82a-4fc3-bc0b-67d8153b2a22
# ╟─e0ba07a2-7541-4377-9235-d0ecea7d0223
# ╠═7e34624a-2ac7-45a1-a2c4-aa0d7e6da52a
# ╟─eaa5f549-21fc-4b1e-9db1-5d8027c14cbd
# ╟─fc1af1fb-780b-4d31-b9c1-caba2fde7f6d
# ╟─5bea3eb3-1da3-4e69-afb2-47a95d8da88b
# ╟─249a3111-e542-4934-aa96-3aaf94e23ee2
# ╟─8106a0d4-bb59-47f1-b16f-6f3d6ea3b838
# ╟─b614255e-dc59-459e-88ac-9427d87ca71a
# ╟─88761bba-468e-4c0b-9958-70a8e8ee0464
# ╟─7f8ecd86-009d-4118-a88f-466c0f04dd3e
# ╟─2763f943-e7d0-463c-be13-52de1995a063
# ╟─feabc799-0a0e-4569-942d-babc8221bc7a
