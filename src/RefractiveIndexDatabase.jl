module RefractiveIndexDatabase

using Pkg.Artifacts

using YAML
using HTTP: request
using DelimitedFiles: readdlm

using Memoize
using Unitful: @u_str, uparse, uconvert, ustrip, AbstractQuantity

using Dierckx: Spline1D

abstract type Formula end
abstract type RefractiveIndex end

include("formulas.jl")

export get_material, load_file, load_url, search, info
include("database.jl")

export interpolate


# Data strucutres for materials stored in the database

struct Metadata
    reference::String
    comment::String
    specs::Dict{Any,Any}
end


struct FormulaN{T<:Formula} <: RefractiveIndex
    metadata::Metadata
    n::T
end

struct FormulaNK{T<:Formula}
    metadata::Metadata
    n::T
    λ::Vector{Float64}
    k::Vector{Float64}
end

struct TabulatedN
    metadata::Metadata
    λ::Vector{Float64}
    n::Vector{Float64}
end

struct TabulatedNK
    metadata::Metadata
    λ::Vector{Float64}
    n::Vector{Float64}
    k::Vector{Float64}
end

# Interpolation of tabulated data

struct InterpolatedF{T<:Formula} <: RefractiveIndex
    n::T
    k::Spline1D

    function InterpolatedF(n::T, λ, k) where {T<:Formula}
        k_itp = Spline1D(λ, k, bc = "error") # error on extrapolation
        return new{T}(n, k_itp)
    end
end

struct InterpolatedN <: RefractiveIndex
    n::Spline1D

    function InterpolatedN(λ, n)
        n_itp = Spline1D(λ, n, bc = "error") # error on extrapolation
        return new(n_itp)
    end
end

struct InterpolatedNK <: RefractiveIndex
    n::Spline1D
    k::Spline1D

    function InterpolatedNK(λ, n, k)
        @assert length(λ) == length(n) == length(k)
        n_itp = Spline1D(λ, n, bc = "error") # error on extrapolation
        k_itp = Spline1D(λ, k, bc = "error") # error on extrapolation
        return new(n_itp, k_itp)
    end
end

interpolate(m::FormulaNK) = InterpolatedF(m.n, m.λ, m.k)
interpolate(m::TabulatedN) = InterpolatedN(m.λ, m.n)
interpolate(m::TabulatedNK) = InterpolatedNK(m.λ, m.n, m.k)

# Calulate the refractive index of a material at a given wavelength

(m::FormulaN)(λ) = m.n(λ)
(m::InterpolatedF)(λ) = m.n(λ) + m.k(λ) * im
(m::InterpolatedN)(λ) = m.n(λ)
(m::InterpolatedNK)(λ) = m.n(λ) + m.k(λ) * im


@memoize _dim_to_micron(dim) = ustrip(uconvert(u"μm", 1.0uparse(dim)))
(m::RefractiveIndex)(λ, dim::String) = m(λ * _dim_to_micron(dim))
(m::RefractiveIndex)(λ::AbstractQuantity) = m(Float64(ustrip(uconvert(u"μm", λ))))



function Base.show(io::IO, ::MIME"text/plain", g::Metadata)
    println(io, typeof(g))
    println(io, "  reference: ", g.reference)
    println(io, "  comment: ", g.comment)
    print(io, "  specs: ", g.specs)
end

function Base.show(io::IO, ::MIME"text/plain", g::FormulaN)
    println(io, typeof(g))
    println(io, "  n: ", g.n)
    print(io, "  metadata: ", g.metadata)
end

function Base.show(io::IO, ::MIME"text/plain", g::FormulaNK)
    println(io, typeof(g))
    println(io, "  n: ", g.n)
    println(io, "  λ: ", g.λ)
    println(io, "  k: ", g.k)
    print(io, "  metadata: ", g.metadata)
end

function Base.show(io::IO, ::MIME"text/plain", g::TabulatedN)
    println(io, typeof(g))
    println(io, "  λ: ", g.λ)
    println(io, "  n: ", g.n)
    print(io, "  metadata: ", g.metadata)
end

function Base.show(io::IO, ::MIME"text/plain", g::TabulatedNK)
    println(io, typeof(g))
    println(io, "  λ: ", g.λ)
    println(io, "  n: ", g.n)
    println(io, "  k: ", g.k)
    print(io, "  metadata: ", g.metadata)
end

end # module