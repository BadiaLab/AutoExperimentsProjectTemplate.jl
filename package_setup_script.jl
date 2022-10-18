import Pkg
Pkg.add("PkgTemplates")
using PkgTemplates
t = Template(;
            user="BadiaLab",
            authors=["Santiago Badia <santiago.badia@monash.edu>", "Alberto F. Martin <alberto.martin@monash.edu>"],
            dir=pwd(),
            julia=v"1.8",
            plugins=[
                License(; name="MIT", path=nothing, destination="LICENSE.md"),
                CompatHelper(),
                Codecov(),
                GitHubActions(;
                osx=false,
                windows=false,
                ),
                Documenter{GitHubActions}(),
                Git(;
                    ignore=["*.jl.*.cov",
                            "*.jl.cov",
                            "*.jl.mem",
                            "*.code-workspace",
                            ".DS_Store",
                            "docs/build/",
                            "Manifest.toml",
                            "tmp/"],
                    ssh=true
                ),
            ],
        )
t("AutoExperimentsProjectTemplate")
