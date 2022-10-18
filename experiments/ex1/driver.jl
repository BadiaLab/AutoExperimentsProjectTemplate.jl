module Driver
  # Add here whichever modules/packages your
  # driver function may need

  function f_p_true(m,a,b)
    (a + b)*m
  end

  function f_p_false(m,a,b)
    a + b*m
  end

  function driver(m,a,b,p)
    if (p)
      f=f_p_true(m,a,b)
    else
      f=f_p_false(m,a,b)
    end
    # We may have here one more than one output
    # (as many as we like)
    output=Dict()
    output["f"]=f
    output
  end

end # module
