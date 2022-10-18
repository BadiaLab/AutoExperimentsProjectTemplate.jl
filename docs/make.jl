using AutoExperimentsProjectTemplate
using Documenter

DocMeta.setdocmeta!(AutoExperimentsProjectTemplate, :DocTestSetup, :(using AutoExperimentsProjectTemplate); recursive=true)

makedocs(;
    modules=[AutoExperimentsProjectTemplate],
    authors="Santiago Badia <santiago.badia@monash.edu>, Alberto F. Martin <alberto.martin@monash.edu>",
    repo="https://github.com/BadiaLab/AutoExperimentsProjectTemplate.jl/blob/{commit}{path}#{line}",
    sitename="AutoExperimentsProjectTemplate.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://BadiaLab.github.io/AutoExperimentsProjectTemplate.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/BadiaLab/AutoExperimentsProjectTemplate.jl",
    devbranch="main",
)
