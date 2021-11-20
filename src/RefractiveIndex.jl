module RefractiveIndex

# using Pkg.Artifacts

using Dierckx:Spline1D

abstract type Formula end
abstract type RefractiveIndexInfo end

include("formulas.jl")

using YAML
using HTTP:request
using DelimitedFiles:readdlm
export load_file, load_url

include("interfaces.jl")


struct Metadata
    reference::String
    comment::String
    specs::Dict{Any,Any}
end

struct RealFormula <: RefractiveIndexInfo
    meta::Metadata
    n::Formula
end


struct ComplexFormula <: RefractiveIndexInfo
    meta::Metadata
    n::Formula
    k::Tabulated
end


struct RealTabulated <: RefractiveIndexInfo
    metadata::Metadata
    λ::Vector{Float64}
    n::Vector{Float64}
    _n_itp::Spline1D

    function RealTabulated(metadata, λ, n)
        @assert length(λ) == length(n)
        _n_itp = Spline1D(λ, n, bc="error") # error on ectrapolation
        return new(metadata, λ, n, _n_itp)
    end
end

struct ComplexTabulated <: RefractiveIndexInfo
    metadata::Metadata
    λ::Vector{Float64}
    n::Vector{Float64}
    k::Vector{Float64}
    _n_itp::Spline1D
    _k_itp::Spline1D

    function ComplexTabulated(metadata, λ, n, k)
        @assert length(λ) == length(n) == length(k)

        _n_itp = Spline1D(λ, n, bc="error") # error on ectrapolation
        _k_itp = Spline1D(λ, n, bc="error") # error on ectrapolation
        return new(metadata, λ, n, k, _n_itp, _k_itp)
    end
end

(f::RealFormula)(λ) = f.n(λ)
(f::ComplexFormula)(λ) = f.n(λ) + f.k(λ)

(f::RealTabulated)(λ) = f._n_itp(λ)
(f::ComplexTabulated)(λ) = f._n_itp(λ) + f._k_itp(λ)





#
# using YAML
# using Interpolations
# # using HTTP.URIs: unescapeuri
# # using Unitful: @u_str, uparse, uconvert, ustrip, AbstractQuantity
# # using Memoize
# using DelimitedFiles: readdlm
#
# import Base: getindex, show
#
# export RefractiveMaterial
# export load_file
#
# abstract type Dispersion end
# abstract type Formula <: Dispersion end
# abstract type Tabulated <: Dispersion end
#
# struct MaterialEntry{DF<:Dispersion}
#     shelf::String
#     book::String
#     page::String
# end
#
# struct MaterialMetadata
#     name::String
#     reference::String
#     comment::String
#     specs::Dict{Symbol, Any}
# end
#
# # https://en.m.wikipedia.org/wiki/Refractive_index
# struct RefractiveIndex{DF<:Dispersion}
#     n::DF
#     k::DF
#     λrange::Tuple{Float64, Float64}
# end
#
# struct RefractiveIndex2{DF<:Dispersion}
#     n::ComplexF64
#     λrange::Tuple{Float64, Float64}
# end
#
# struct Permitivity{}
#     eps::Complex
#     λrange::Tuple{Float64, Float64}
# end
#
# include("parse.jl")
# include("dispersions.jl")
#


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