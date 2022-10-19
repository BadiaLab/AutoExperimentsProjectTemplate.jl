### A Pluto.jl notebook ###
# v0.19.13

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

# ╔═╡ b881120b-853d-4c0f-bcb8-b3b18e2dd9ae
begin
  using DrWatson
  @quickactivate "AutoExperimentsProjectTemplate"
end

# ╔═╡ 52a4a234-a99c-4e0d-b1e7-f54ddc11ff45
using DataFrames

# ╔═╡ 08a6ab1f-ef85-41a3-bb1a-933d578e4f93
using BSON

# ╔═╡ 696ffce0-e025-409c-8628-48b06fc7fd38
using PlutoUI

# ╔═╡ e82ad202-94eb-4f79-8aa3-7dd40375328b
using Plots

# ╔═╡ 106ded38-479d-4961-a127-24c2b416aa9d
md"""# Experiment 1 (mini-example)

This mini-example notebook reactively visualizes the following three single variable functions in a separate plot each. 

$g(a)=f(b=\alpha,m=\beta,p=\gamma;a)$ 
$g(b)=f(a=\alpha,m=\beta,p=\gamma;b)$ 
$g(m)=f(b=\alpha,m=\beta,p=\gamma;m)$
with $\gamma$=[true,false]
"""

# ╔═╡ 57a8e472-d24d-44d0-a8c2-35c056c524ef
df = collect_results(datadir("ex1"));

# ╔═╡ 1e681e9b-165f-4cd1-963c-0847fa55ff1d
println(df)

# ╔═╡ 602c6a8b-5a9d-4aba-9a73-c7af073feed0
cols_to_filter = [:a,:m,:b,:p,:f];

# ╔═╡ 82f442f6-9b3b-46ce-9c91-bb3e54abd526
df_filtered = df[:,cols_to_filter];

# ╔═╡ e4e03f80-42b4-459a-b75a-1e1364b3b659
df_cols_filtered = Dict(pairs(eachcol(df_filtered)));

# ╔═╡ a2dbc933-5f57-40e0-be54-f43e7de71478
params_possible_values=
	    Dict([k=>unique(df_cols_filtered[k]) for k in keys(df_cols_filtered)])

# ╔═╡ 17e099ff-caec-4d52-8de8-c3d9f110cf0c


# ╔═╡ e6574182-c313-4f09-b9a7-ad09751ad5ef
md"""
Select the parameter-value combination that you want to visualize!:

a: $(@bind aval Select(params_possible_values[:a])) 
b: $(@bind bval Select(params_possible_values[:b]))
m: $(@bind mval Select(params_possible_values[:m]))
p: $(@bind pval CheckBox())
"""

# ╔═╡ ee0fe5d7-1b47-46f2-a471-1b9a5b2c709e
(aval,bval,mval,pval)

# ╔═╡ 79071a98-5cbc-4ae1-aab6-807a8b77a969
#case = Dict(:n=>n,:k=>k,:fespace=>fespace,:loads=>loads,:disp=>disp,:epsilon=>epsilon,:delta=>delta,:geom=>geom,:solution=>solution);

# ╔═╡ 709b74db-ff0d-440b-847a-2ed683bf19eb
xaxis=:none

# ╔═╡ f2e0e623-9584-4dd0-9196-be84c07d7886
yaxis=:none

# ╔═╡ 5748a503-4534-462a-b485-386d68fe857d
function generate_labels(params_possible_values)
  dl=dict_list(params_possible_values)
  println(dl)
  labels=Vector{String}(undef,length(dl))
  for (i,d) in enumerate(dl)
	label=""
	for (key,val) in d
	  label=label * " $(key)=$(val)"
	end
	labels[i]=label  
  end
  labels
end 

# ╔═╡ 2c7a1e9b-ebe7-4631-a14d-0c2ea0d7293b
function get_x_y(xparam, yparam, ffilter, df)
  df_filtered = filter(ffilter,df)
  df_filtered_cols = Dict(pairs(eachcol(df_filtered)))
  @assert xparam in keys(df_filtered_cols)
  @assert yparam in keys(df_filtered_cols)
	
  params_possible_values=
	    Dict([k=>unique(df_filtered_cols[k]) 
			    for k in keys(df_filtered_cols) if k != xparam && k != yparam])
	
  # Double check that there is a single combination 
  # of parameter-value for those columns distinct from 
  # xparam and yparam. Note: We may extend this functionality to 
  # support plotting of multiple curves  in the same plot
  for key in keys(params_possible_values)
	if key != xparam && key != yparam
	  @assert length(params_possible_values[key])==1
	end 
  end
  sort!(df_filtered,[xparam,])
  x = df_filtered[!,xparam]
  y = df_filtered[!,yparam]
  (x,y,params_possible_values)
end


# ╔═╡ 9478d88e-bc39-40b2-be09-3789e4fff51e
function plot_xparam_versus_yparam(xparam,yparam,ffilter,df)
  f = plot()
  x,y,params_possible_values = get_x_y(xparam,yparam,ffilter,df)
  labels=generate_labels(params_possible_values)
  @assert length(labels)==1	
  plot!(x,y,xaxis=xaxis,yaxis=yaxis,label=labels[1],markershape=:auto)
  plot!(xlabel="$xparam",ylabel="$yparam")
  f
end

# ╔═╡ 8cdaefc4-2d08-4797-83e2-32790d9989c1
plot_xparam_versus_yparam(:m,:f,
                          [:a,:p,:b]=>(a,b,p)->(a==1.0 && b==0.0 && p==true),
	                      df_filtered)


# ╔═╡ Cell order:
# ╠═106ded38-479d-4961-a127-24c2b416aa9d
# ╠═38e1939a-3c91-4b7b-88fd-ae7e01eda602
# ╠═b881120b-853d-4c0f-bcb8-b3b18e2dd9ae
# ╠═52a4a234-a99c-4e0d-b1e7-f54ddc11ff45
# ╠═08a6ab1f-ef85-41a3-bb1a-933d578e4f93
# ╠═696ffce0-e025-409c-8628-48b06fc7fd38
# ╠═e82ad202-94eb-4f79-8aa3-7dd40375328b
# ╠═57a8e472-d24d-44d0-a8c2-35c056c524ef
# ╟─1e681e9b-165f-4cd1-963c-0847fa55ff1d
# ╠═602c6a8b-5a9d-4aba-9a73-c7af073feed0
# ╠═82f442f6-9b3b-46ce-9c91-bb3e54abd526
# ╠═e4e03f80-42b4-459a-b75a-1e1364b3b659
# ╠═a2dbc933-5f57-40e0-be54-f43e7de71478
# ╟─17e099ff-caec-4d52-8de8-c3d9f110cf0c
# ╠═e6574182-c313-4f09-b9a7-ad09751ad5ef
# ╠═ee0fe5d7-1b47-46f2-a471-1b9a5b2c709e
# ╟─79071a98-5cbc-4ae1-aab6-807a8b77a969
# ╠═709b74db-ff0d-440b-847a-2ed683bf19eb
# ╠═f2e0e623-9584-4dd0-9196-be84c07d7886
# ╠═8cdaefc4-2d08-4797-83e2-32790d9989c1
# ╠═9478d88e-bc39-40b2-be09-3789e4fff51e
# ╠═5748a503-4534-462a-b485-386d68fe857d
# ╠═2c7a1e9b-ebe7-4631-a14d-0c2ea0d7293b
