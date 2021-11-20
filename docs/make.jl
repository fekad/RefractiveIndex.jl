using Documenter
using RefractiveIndexDatabase

makedocs(
    sitename = "RefractiveIndexDatabase",
    format = Documenter.HTML(),
    modules = [RefractiveIndexDatabase]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
