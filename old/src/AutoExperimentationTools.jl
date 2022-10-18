module AutoExperimentationTools
  using DrWatson

  experiment_filename(args...) = replace(savename(args...),"="=>"")

  function collect_from_dicts(experiment,dicts)
    results = []
    for params in dicts
      outfile = datadir(experiment_filename(experiment,params,"bson"))
      if isfile(outfile)
        out = load(outfile)
        push!(results,out)
      end
    end
    results
  end

  function replace_strings_by_symbols(r)
    d = Dict{Symbol,Any}()
    for (k,v) in r
      d[Symbol(k)] = v
    end
    d
  end

  function restrict_to_keys(i,ks)
    o = typeof(i)()
    for k in ks
      o[k] = i[k]
    end
    o
  end

  export experiment_filename, collect_from_dicts, replace_strings_by_symbols, restrict_to_keys

end # module
