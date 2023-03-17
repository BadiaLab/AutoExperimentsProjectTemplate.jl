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
using DrWatson, DataFrames, BSON, PlutoUI, StatsPlots, Unicode, LaTeXStrings

# ╔═╡ b881120b-853d-4c0f-bcb8-b3b18e2dd9ae
@quickactivate "AutoExperimentsProjectTemplate"

# ╔═╡ 106ded38-479d-4961-a127-24c2b416aa9d
md"""
### Forward 2D Advection-Diffusion Equation Methods Comparison
"""

# ╔═╡ 50fb806d-1431-44dd-93c9-a721ed048374
import Measures: mm

# ╔═╡ 098b6802-971d-4651-9ca5-14d2683e4a4c
experiment_data_dir = "Fwd_2DAdvection_Diffusion_Comparison";

# ╔═╡ 9fa8e973-2d6e-471e-a717-4a7416a8b0c1
demo_data_dir = projectdir("demos/data", experiment_data_dir);

# ╔═╡ 12aa958b-c45f-4b02-a3e0-fbbe68ff2618
commit_dirs = readdir(demo_data_dir);

# ╔═╡ 24121476-672c-48f0-9b77-3b05478c887d
md"""
Select commit ID data directory: $(@bind commitID Select(commit_dirs))
"""

# ╔═╡ feff8f1d-1957-4285-b62a-cc5e145835f3
df = collect_results(projectdir(demo_data_dir, commitID));

# ╔═╡ 1014e48b-5ef5-47b8-ad11-9a1c5baf430e
transform!(df, :, [:ncells] => ByRow(inv) => :mesh_size);

# ╔═╡ 53a71eb1-9d6f-4bda-9a38-7a8be0bff337
absdiff(a, b) = abs.(a - b)

# ╔═╡ 7606d45a-0059-4e9a-a606-f646f5145f50
df[!, :l2es] = absdiff.(df[:, "ûs"], df[:, "us"]);

# ╔═╡ e3b5ac9f-235e-432f-91b8-3b52decb5877
cols_to_filter = [
	"û", "activation", "order", "precondition", "ncells", "neuron", "layer",
	"seed", "mesh_size", "linearized", "distant", "offset", "optimizer", "xs", "ys", "us", "ûs", "l2es", "des", "fem_l2_err", "fem_h1_err", "last_l2_err", "last_h1_err", "l2_errs", "actual_losses"];

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

distant function: $(@bind distantval Select(params_possible_values["distant"]))
offset function: $(@bind offsetval Select(params_possible_values["offset"]))

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
	  scatter!(f, xi[idx], yi[idx], xaxis=xaxis, yaxis=yaxis, label=li, markershape=markershapes[imarker], markerstrokewidth=0.0, markerstrokealpha=0.6, markersize=8)
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
filter_all_constraints = ["û", "order", "ncells", "neuron", "layer",  "activation", "seed", "linearized", "distant", "offset", "optimizer", "precondition"] => (û, order, ncells, neuron, layer, activation, seed, linearized, distant, offset, optimizer, precondition) -> (û == ûval && order == orderval && ncells == ncellsval && neuron == neuronval && layer == layerval && activation == actval && seed == seedval && linearized == linearizedval && distant == distantval && offset == offsetval && optimizer == optimizerval && precondition == preconditionval);

# ╔═╡ 424f8318-948c-4881-9758-59fbc45f1084
df_filtered_all_constraints = filter(filter_all_constraints, df);

# ╔═╡ d9b6d530-6290-4a41-9aca-7a45c02900a2
function draw_contour_plots(df, zcols, titles; color=:jet, size=(800, 320), nlevel=15, xlabel="element=$ncellsval, order=$orderval, linearized=$linearizedval, distant=$distantval, precond=$preconditionval, optimizer=$optimizerval, neuron=$neuronval, layer=$layerval")
	x, y = df[:, "xs"][1], df[:, "ys"][1]
	plts = []
	for (i, zcol) in enumerate(zcols)
		z = df[:, zcol][1]
		plt = contourf(x, y, z, levels=nlevel, color=color, title=titles[i], titlefontsize=9)	
		push!(plts, plt)
	end
	plot(plts..., layout=(1, length(plts)), size=size, plot_title=xlabel, plot_titlefontsize=10, margin=1mm)
end

# ╔═╡ 4cdf75b5-e90d-4633-9ebb-5b8579545012
draw_contour_plots(df_filtered_all_constraints, ["ûs", "us"], ["Exact Solution", "Identified Solution"])

# ╔═╡ 86970d97-db54-40e7-ab98-9bd9d4165a1f
draw_contour_plots(df_filtered_all_constraints, ["l2es", "des"], ["Error", "Magniture of Gradient Error"]; nlevel=10)

# ╔═╡ 4b90c1d9-dc25-4e82-a7ee-930db8bc4a89
filter_precond_free = ["û", "order", "ncells", "neuron", "layer",  "activation", "seed", "linearized", "distant", "optimizer", "precondition"] => (û, order, ncells, neuron, layer, activation, seed, linearized, distant, optimizer, precondition) -> (û == ûval && order == orderval && ncells == ncellsval && neuron == neuronval && layer == layerval && activation == actval && seed == seedval && linearized == linearizedval && distant == distantval && optimizer == optimizerval && (precondition in (:none, :full)));

# ╔═╡ 249a3111-e542-4934-aa96-3aaf94e23ee2
begin
  cols_to_filter_actual_losses = [
	  "û", "order", "ncells", "neuron", "activation", "layer", "seed", 
	  "precondition", "linearized", "distant", "offset", "optimizer", "actual_losses"]
  df_filtered_actual_losses = df[:, cols_to_filter_actual_losses]
  filter_distant_offset_free = ["û", "order", "ncells", "neuron", "layer",  "activation", "seed", "linearized", "distant", "offset", "optimizer", "precondition"] => (û, order, ncells, neuron, layer, activation, seed, linearized, distant, offset, optimizer, precondition) -> (û == ûval && order == orderval && ncells == ncellsval && neuron == neuronval && layer == layerval && activation == actval && seed == seedval && linearized == linearizedval && distant in (true, false) && offset in (:standard, :smooth) && optimizer == optimizerval && precondition == preconditionval)
  plot_x_versus_y(:actual_losses,
    (logxval ? :log10 : :none),
    :log10,
    filter_distant_offset_free,
    df_filtered_actual_losses;
    xlabel="Iteration", ylabel="Actual Loss",
    title="order=$orderval, element=$ncellsval, neuron=$neuronval, layer=$layerval, linearized=$linearizedval",
    size=(1000, 400),
    autoxlims=autoxlims,
    autoylims=autoylims,
    xliml=parse(Float64, xliml), xlimr=parse(Float64, xlimr),
    ylimb=parse(Float64, ylimb), ylimt=parse(Float64, ylimt))
end


# ╔═╡ 8106a0d4-bb59-47f1-b16f-6f3d6ea3b838
begin
  cols_to_filter_l2_errs = [
	  "û", "order", "ncells", "neuron", "activation", "layer", "seed",
	  "precondition", "linearized", "distant", "offset", "optimizer", "l2_errs"]
  df_filtered_target_losses = df[:, cols_to_filter_l2_errs]
  plot_x_versus_y(:l2_errs,
    (logxval ? :log10 : :none),
    :log10,
    filter_distant_offset_free,
    df_filtered_target_losses;
    xlabel="Iteration", ylabel="\"L2 Error\"",
    title="order=$orderval, element=$ncellsval, neuron=$neuronval, layer=$layerval, linearized=$linearizedval",
    size=(1000, 400),
    autoxlims=false,
    autoylims=autoylims,
    xliml=parse(Float64, "0"), xlimr=parse(Float64, "13100"),
    ylimb=parse(Float64, ylimb), ylimt=parse(Float64, ylimt))
end


# ╔═╡ 7f8ecd86-009d-4118-a88f-466c0f04dd3e
function plot_error_bar(;errtype="l2_err", size=(1000, 400))
	hist_filter = ["order", "precondition", "linearized", "distant", "offset", "ncells", "optimizer", "seed"] => (order, precondition, linearized, distant, offset, ncells, optimizer, seed) -> (order == orderval && precondition == preconditionval && linearized == linearizedval && distant == distantval && offset == offsetval && ncells == ncellsval && optimizer == optimizerval && seed == seedval)
	hist_df = filter(hist_filter, df)
	layers, neurons = hist_df[:, :layer], hist_df[:, :neuron]
	errcolname = "last_"*errtype
	errs = hcat([sort(filter(x -> x.layer == layer, hist_df)[:, [errcolname, "neuron"]], order("neuron"))[:, errcolname] for layer in sort(unique(layers))]...)
	layerlabels = repeat(["$layer layers" for layer in sort(unique(layers))], inner=length(unique(neurons)))
	neuronlabels = repeat([neuron for neuron in sort(unique(neurons))], outer=length(unique(layers)))
	bwidth = 8.0
	bplot = groupedbar(neuronlabels, errs, bar_position=:dodge, bar_width=bwidth, yaxis=:log, xlabel="Number of Neurons", ylabel=errtype == "l2_err" ? "L2 Error" : "H1 Error", group=layerlabels, xticks=sort(unique(neurons)), yticks=[10.0^i for i in -3:-1:-10], ylim=(1e-12, 1e-3), title="order=$orderval, precond=$preconditionval, cell=$ncellsval, linearized=$linearizedval, distant=$distantval, optimizer=$optimizerval, seed=$seedval")
	x = range(minimum(neurons)-4.0, maximum(neurons)+4.0, 15)
	plot!(bplot, x, [first(hist_df[:, "fem_"*errtype]) for _ in x], linecolor=:red, linestyle=:dashdot, label="FEM Ref", width=2.0, size=size, margin=3mm)
	bplot
end

# ╔═╡ 09e17155-ccfd-491f-b5dd-a94b021f6a69
function plot_err_vs_meshsize(errlabel)
	ffilter_precond_free = ["û", "order", "neuron", "layer", "activation", "seed", "linearized", "distant", "offset", "optimizer", "precondition"] => (û, order, neuron, layer, activation, seed, linearized, distant, offset, optimizer, precond) -> (û == ûval && order == orderval && neuron == neuronval && layer == layerval && linearized == linearizedval && distant == distantval && offset == offsetval && seed == seedval && activation == actval && optimizer == optimizerval && precond == preconditionval)
	cols_to_filter_err = ["û", "order", "neuron", "layer", "activation", "seed", "linearized", "distant", "offset", "optimizer", "precondition", "mesh_size", "last_"*errlabel, "fem_"*errlabel, "nn_"*errlabel]
	df_filtered_err = sort(filter(ffilter_precond_free, df[:, cols_to_filter_err]), order(:mesh_size))
	ylabel = errlabel == "l2_err" ? "L2 Error" : "H1 Error"
	plt = plot(margins=4mm, size=(1000, 400), xlabel="Mesh Size", ylabel=ylabel, xaxis=:log10, yaxis=:log10, xflip=true, legend=lposition, title="order=$(orderval), linearized=$linearizedval, distant=$distantval, offset=$offsetval")
	plot!(plt, df_filtered_err[:, :mesh_size], df_filtered_err[:, "last_"*errlabel], label="interpolated neural network", markershape=markershapes[1])
	plot!(plt, df_filtered_err[:, :mesh_size], df_filtered_err[:, "fem_"*errlabel], label="finite element method", markershape=markershapes[2])
		plot!(plt, df_filtered_err[:, :mesh_size], df_filtered_err[:, "nn_"*errlabel], label="neural network", markershape=markershapes[3])
	plt
end

# ╔═╡ d072001c-a121-4209-875a-88c811fef709
plot_err_vs_meshsize("l2_err")

# ╔═╡ e90f55eb-6fe8-4566-81ff-b78b920a6fb5
plot_err_vs_meshsize("h1_err")

# ╔═╡ Cell order:
# ╟─106ded38-479d-4961-a127-24c2b416aa9d
# ╟─38e1939a-3c91-4b7b-88fd-ae7e01eda602
# ╠═299c6e30-9107-4039-a11c-32ed6d9b1460
# ╠═50fb806d-1431-44dd-93c9-a721ed048374
# ╠═b881120b-853d-4c0f-bcb8-b3b18e2dd9ae
# ╠═098b6802-971d-4651-9ca5-14d2683e4a4c
# ╠═9fa8e973-2d6e-471e-a717-4a7416a8b0c1
# ╠═12aa958b-c45f-4b02-a3e0-fbbe68ff2618
# ╟─24121476-672c-48f0-9b77-3b05478c887d
# ╠═feff8f1d-1957-4285-b62a-cc5e145835f3
# ╠═1014e48b-5ef5-47b8-ad11-9a1c5baf430e
# ╟─53a71eb1-9d6f-4bda-9a38-7a8be0bff337
# ╠═7606d45a-0059-4e9a-a606-f646f5145f50
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
# ╠═424f8318-948c-4881-9758-59fbc45f1084
# ╟─d9b6d530-6290-4a41-9aca-7a45c02900a2
# ╟─4cdf75b5-e90d-4633-9ebb-5b8579545012
# ╠═86970d97-db54-40e7-ab98-9bd9d4165a1f
# ╠═4b90c1d9-dc25-4e82-a7ee-930db8bc4a89
# ╟─249a3111-e542-4934-aa96-3aaf94e23ee2
# ╟─8106a0d4-bb59-47f1-b16f-6f3d6ea3b838
# ╟─7f8ecd86-009d-4118-a88f-466c0f04dd3e
# ╟─09e17155-ccfd-491f-b5dd-a94b021f6a69
# ╟─d072001c-a121-4209-875a-88c811fef709
# ╟─e90f55eb-6fe8-4566-81ff-b78b920a6fb5
