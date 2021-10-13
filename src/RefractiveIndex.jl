module RefractiveIndexDatabase

# using Pkg.Artifacts
using YAML
using Interpolations
# using HTTP.URIs: unescapeuri
# using Unitful: @u_str, uparse, uconvert, ustrip, AbstractQuantity
# using Memoize
using DelimitedFiles: readdlm

import Base: getindex, show

export RefractiveMaterial
export load_file

abstract type Dispersion end
abstract type Formula <: Dispersion end
abstract type Tabulated <: Dispersion end

struct MaterialEntry{DF<:Dispersion}
    shelf::String
    book::String
    page::String
end

struct MaterialMetadata
    name::String
    reference::String
    comment::String
    specs::Dict{Symbol, Any}
end

# https://en.m.wikipedia.org/wiki/Refractive_index
struct RefractiveIndex{DF<:Dispersion}
    n::DF
    k::DF
    λrange::Tuple{Float64, Float64}
end

struct RefractiveIndex2{DF<:Dispersion}
    n::ComplexF64
    λrange::Tuple{Float64, Float64}
end

struct Permitivity{}
    eps::Complex
    λrange::Tuple{Float64, Float64}
end

include("parse.jl")
include("dispersions.jl")



# """
#     RefractiveMaterial(shelf, book, page)
#
# Load the refractive index data for the material corresponding to the specified
# shelf, book, and page within the [refractiveindex.info](https://refractiveindex.info/) database. The data
# can be queried by calling the returned `RefractiveMaterial` object at a given wavelength.
#
# # Examples
# ```julia-repl
# julia> MgLiTaO3 = RefractiveMaterial("other", "Mg-LiTaO3", "Moutzouris-o")
# "Mg-LiTaO3 (Moutzouris et al. 2011: n(o) 0.450-1.551 µm; 8 mol.% Mg)"
#
# julia> MgLiTaO3(0.45) # default unit is microns
# 2.2373000025056826
#
# julia> using Unitful
#
# julia> MgLiTaO3(450u"nm") # auto-conversion from generic Unitful.jl length units
# 2.2373000025056826
#
# julia> MgLiTaO3(450e-9, "m") # strings can be used to specify units (parsing is cached)
# 2.2373000025056826
# ```
# """


# show(io::IO, ::MIME"text/plain", m::RefractiveMaterial{DF}) where {DF} = show(io, m.name)

# (m::RefractiveMaterial)(λ::Float64) = m.dispersion(λ)
# (m::RefractiveMaterial)(λ::AbstractQuantity) = m(Float64(ustrip(uconvert(u"μm", λ))))
#
# @memoize _dim_to_micron(dim) = ustrip(uconvert(u"μm", 1.0uparse(dim)))
# (m::RefractiveMaterial)(λ, dim::String) = m(λ*_dim_to_micron(dim))
#
# (m::RefractiveMaterial{T})(λ::Float64) where {T <: Tabulated}= m.dispersion.n(λ)
end # module