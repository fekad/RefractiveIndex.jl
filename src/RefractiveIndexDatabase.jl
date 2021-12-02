module RefractiveIndexDatabase

using Pkg.Artifacts

using YAML
using HTTP: request
using DelimitedFiles: readdlm

using Memoize
using Unitful: @u_str, uparse, uconvert, ustrip, AbstractQuantity
import Base: show

using Dierckx: Spline1D

abstract type RefractiveIndexDefinitons end
abstract type Formula <: RefractiveIndexDefinitons end
abstract type Tabulated <: RefractiveIndexDefinitons end

abstract type RefractiveIndexInfo end

export get_material, load_file, load_url, search, info
include("database.jl")

include("formulas.jl")

struct Metadata
    reference::String
    comment::String
    specs::Dict{Any,Any}
end

function Base.show(io::IO, ::MIME"text/plain", g::Metadata)
    println(io, typeof(g))
    println(io, "  reference: ", g.reference)
    println(io, "  comment: ", g.comment)
    print(io, "  specs: ", g.specs)
end


struct FormulaN{T<:Formula} <: RefractiveIndexInfo
    metadata::Metadata
    n::T
end

(m::FormulaN)(λ::Float64) = m.n(λ)

function Base.show(io::IO, ::MIME"text/plain", g::FormulaN)
    println(io, typeof(g))
    println(io, "  n: $(typeof(g.n)), $(g.n.λrange)")
    print(io, "  metadata: ", g.metadata)
end


struct FormulaNK{T<:Formula} <: RefractiveIndexInfo
    metadata::Metadata
    n::T
    k::TabulatedK
end

(m::FormulaNK)(λ::Float64) = m.n(λ) + m.k(λ) * im

function Base.show(io::IO, ::MIME"text/plain", g::FormulaNK)
    println(io, typeof(g))
    println(io, "  n: $(typeof(g.n)), $(g.n.λrange)")
    println(io, "  k: $(typeof(g.k)), ($(first(g.k.λ)), $(last(g.k.λ)))")
    print(io, "  metadata: ", g.metadata)
end


struct TabulatedN <: RefractiveIndexInfo
    metadata::Metadata
    λ::Vector{Float64}
    n::Vector{Float64}
    _n_itp::Spline1D

    function TabulatedN(metadata, λ, n)
        @assert length(λ) == length(n)
        _n_itp = Spline1D(λ, n, bc = "error") # error on extrapolation
        return new(metadata, λ, n, _n_itp)
    end
end

(m::TabulatedN)(λ::Float64) = m._n_itp(λ)

function Base.show(io::IO, ::MIME"text/plain", g::TabulatedN)
    println(io, typeof(g))
    println(io, "  λ: ", g.λ)
    println(io, "  n: ", g.n)
    print(io, "  metadata: ", g.metadata)
end


struct TabulatedNK <: RefractiveIndexInfo
    metadata::Metadata
    λ::Vector{Float64}
    n::Vector{Float64}
    k::Vector{Float64}
    _n_itp::Spline1D
    _k_itp::Spline1D

    function TabulatedNK(metadata, λ, n, k)
        @assert length(λ) == length(n) == length(k)
        _n_itp = Spline1D(λ, n, bc = "error") # error on extrapolation
        _k_itp = Spline1D(λ, k, bc = "error") # error on extrapolation
        return new(metadata, λ, n, k, _n_itp, _k_itp)
    end
end

(m::TabulatedNK)(λ::Float64) = m._n_itp(λ) + m._k_itp(λ) * im

function Base.show(io::IO, ::MIME"text/plain", g::TabulatedNK)
    println(io, typeof(g))
    println(io, "  λ: ", g.λ)
    println(io, "  n: ", g.n)
    println(io, "  k: ", g.k)
    print(io, "  metadata: ", g.metadata)
end


@memoize _dim_to_micron(dim) = ustrip(uconvert(u"μm", 1.0uparse(dim)))
(m::RefractiveIndexInfo)(λ, dim::String) = m(λ * _dim_to_micron(dim))
(m::RefractiveIndexInfo)(λ::AbstractQuantity) = m(Float64(ustrip(uconvert(u"μm", λ))))

end # module