module AutoExperimentsProjectTemplate
  using DrWatson

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

  export replace_strings_by_symbols
  export restrict_to_keys

end # module
