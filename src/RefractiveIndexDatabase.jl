module RefractiveIndexDatabase

using Pkg.Artifacts

using YAML
using HTTP: request
using DelimitedFiles: readdlm

using Memoize
using Unitful: @u_str, uparse, uconvert, ustrip, AbstractQuantity

using Dierckx: Spline1D

abstract type Formula end
include("formulas.jl")

export get_material, load_file, load_url, search, info
include("database.jl")

export RefractiveIndex

# Data strucutres for materials stored in the database

struct Metadata
    reference::String
    comment::String
    specs::Dict{Any,Any}
end


struct FormulaN{T<:Formula}
    metadata::Metadata
    n::T
end

struct FormulaNTabulatedK{T<:Formula}
    metadata::Metadata
    n::T
    λ_k::Vector{Float64}
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


struct TabulatedNTabulatedK
    metadata::Metadata
    λ_n::Vector{Float64}
    n::Vector{Float64}
    λ_k::Vector{Float64}
    k::Vector{Float64}
end


# Interpolation of tabulated data

struct RefractiveIndex{Tn<:Union{Formula,Spline1D},Tk<:Union{Spline1D,Nothing}}
    n::Tn
    k::Tk
end

function RefractiveIndex(m::FormulaN)
    return RefractiveIndex(m.n, nothing)
end

function RefractiveIndex(m::FormulaNTabulatedK)
    k_itp = Spline1D(m.λ_k, m.k, bc = "error")
    return RefractiveIndex(m.n, k_itp)
end

function RefractiveIndex(m::TabulatedN)
    n_itp = Spline1D(m.λ, m.n, bc = "error")
    return RefractiveIndex(n_itp, nothing)
end

function RefractiveIndex(m::TabulatedNK)
    n_itp = Spline1D(m.λ, m.n, bc = "error")
    k_itp = Spline1D(m.λ, m.k, bc = "error")
    return RefractiveIndex(n_itp, k_itp)
end

function RefractiveIndex(m::TabulatedNTabulatedK)
    n_itp = Spline1D(m.λ_n, m.n, bc = "error")
    k_itp = Spline1D(m.λ_k, m.k, bc = "error")
    return RefractiveIndex(n_itp, k_itp)
end


(m::RefractiveIndex{<:Formula,Nothing})(λ) = m.n(λ)
(m::RefractiveIndex{<:Spline1D,Nothing})(λ) = m.n(λ)
(m::RefractiveIndex{<:Formula,<:Spline1D})(λ) = m.n(λ) + m.k(λ) * im
(m::RefractiveIndex{<:Spline1D,<:Spline1D})(λ) = m.n(λ) + m.k(λ) * im


# Calulate the refractive index of a material at a given wavelength

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

function Base.show(io::IO, ::MIME"text/plain", g::FormulaNTabulatedK)
    println(io, typeof(g))
    println(io, "  n: ", g.n)
    println(io, "  λ_k: ", g.λ_k)
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

function Base.show(io::IO, ::MIME"text/plain", g::TabulatedNTabulatedK)
    println(io, typeof(g))
    println(io, "  λ_n: ", g.λ_n)
    println(io, "  n: ", g.n)
    println(io, "  λ_k: ", g.λ_k)
    println(io, "  k: ", g.k)
    print(io, "  metadata: ", g.metadata)
end

end # module