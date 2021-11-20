
struct Sellmeier{N} <: Formula
    λrange::NTuple{2,Float64}
    coeffs::NTuple{N,Float64}
end

function (f::Sellmeier{N})(λ) where {N}
    c = f.coeffs
    rhs = c[1]
    for i = 2:2:N
        rhs += c[i] * λ^2 / (λ^2 - c[i + 1]^2)
    end
    return sqrt(rhs + 1)
end

struct Sellmeier2{N} <: Formula
    λrange::NTuple{2,Float64}
    coeffs::NTuple{N,Float64}
end

function (f::Sellmeier2{N})(λ) where {N}
    c = f.coeffs
    rhs = c[1]
    for i = 2:2:N
        rhs += c[i] * λ^2 / (λ^2 - c[i + 1])
    end
    return sqrt(rhs + 1)
end

struct Polynomial{N} <: Formula
    λrange::NTuple{2,Float64}
    coeffs::NTuple{N,Float64}
end

function (f::Polynomial{N})(λ) where {N}
    c = f.coeffs
    rhs = c[1]
    for i = 2:2:N
        rhs += c[i] * λ^c[i + 1]
    end
    return sqrt(rhs)
end

struct RIInfo{N} <: Formula
    λrange::NTuple{2,Float64}
    coeffs::NTuple{N,Float64}
end

function (f::RIInfo{N})(λ) where {N}
    c = f.coeffs
    rhs = c[1]
    for i = 2:4:min(N, 9)
        rhs += (c[i] * λ^c[i + 1]) / (λ^2 - c[i + 2]^c[i + 3])
    end
    for i = 10:2:N
        rhs += c[i] * λ^c[i + 1]
    end
    return sqrt(rhs)
end

struct Cauchy{N} <: Formula
    λrange::NTuple{2,Float64}
    coeffs::NTuple{N,Float64}
end

function (f::Cauchy{N})(λ) where {N}
    c = f.coeffs
    rhs = c[1]
    for i = 2:2:N
        rhs += c[i] * λ^c[i + 1]
    end
    return rhs
end

struct Gases{N} <: Formula
    λrange::NTuple{2,Float64}
    coeffs::NTuple{N,Float64}
end

function (f::Gases{N})(λ) where {N}
    c = f.coeffs
    rhs = c[1]
    for i = 2:2:N
        rhs += c[i] / (c[i + 1] - 1 / λ^2)
    end
    return rhs + 1
end

struct Herzberger{N} <: Formula
    λrange::NTuple{2,Float64}
    coeffs::NTuple{N,Float64}
end

function (f::Herzberger{N})(λ) where {N}
    c = f.coeffs
    rhs = c[1]
    rhs += c[2] / (λ^2 - 0.028)
    rhs += c[3] * (1 / (λ^2 - 0.028))^2
    for i = 4:N
        pow = 2 * (i - 3)
        rhs += c[i] * λ^pow
    end
    return rhs
end

struct Retro{N} <: Formula
    λrange::NTuple{2,Float64}
    coeffs::NTuple{N,Float64}
end

function (f::Retro{N})(λ) where {N}
    c = f.coeffs
    rhs = c[1] + c[2] * λ^2 / (λ^2 - c[3]) + c[4] * λ^2
    return sqrt((-2rhs - 1) / (rhs - 1))
end

struct Exotic{N} <: Formula
    λrange::NTuple{2,Float64}
    coeffs::NTuple{N,Float64}
end

function (f::Exotic{N})(λ) where {N}
    c = f.coeffs
    rhs = c[1] + c[2] / (λ^2 - c[3]) + c[4] * (λ - c[5]) / ((λ - c[5])^2 + c[6])
    return sqrt(rhs)
end


struct Tabulated{N} <: Formula
    data::Vector{Float64}
    λ::Vector{Float64}
    _itp::Spline1D

    function Tabulated(data, λ)
        n = length(data)
        itp = Spline1D(data, λ, bc="error") # error on ectrapolation
        return new{n}(data, λ, itp)
    end
end

function (f::Tabulated)(λ) where {N}
    return f._itp(λ)
end
