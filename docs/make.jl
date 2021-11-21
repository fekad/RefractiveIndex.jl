using Documenter
using RefractiveIndexDatabase

makedocs(
    sitename = "RefractiveIndexDatabase.jl",
    authors="Adam Fekete <adam.fekete@unamur.be> and contributors",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical="https://fekad.github.io/RefractiveIndexDatabase.jl"
    ),
    modules = [RefractiveIndexDatabase],
    pages=[
        "Home" => "index.md",
        "Usage" => "usage.md",
        "Formualas" => "formulas.md",
    ]
)


deploydocs(
    repo = "github.com/fekad/RefractiveIndexDatabase.jl",
    devbranch = "main"
)