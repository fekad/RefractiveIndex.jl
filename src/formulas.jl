struct Sellmeier <: Formula
    λrange::Vector{Float64}
    coeffs::Vector{Float64}
end

function (f::Sellmeier)(λ)
    c, N = f.coeffs, length(f.coeffs)
    rhs = c[1]
    for i = 2:2:N
        rhs += c[i] * λ^2 / (λ^2 - c[i + 1]^2)
    end
    return sqrt(rhs + 1)
end

struct Sellmeier2 <: Formula
    λrange::Vector{Float64}
    coeffs::Vector{Float64}
end

function (f::Sellmeier2)(λ)
    c, N = f.coeffs, length(f.coeffs)
    rhs = c[1]
    for i = 2:2:N
        rhs += c[i] * λ^2 / (λ^2 - c[i + 1])
    end
    return sqrt(rhs + 1)
end

struct Polynomial <: Formula
    λrange::Vector{Float64}
    coeffs::Vector{Float64}
end

function (f::Polynomial)(λ)
    c, N = f.coeffs, length(f.coeffs)
    rhs = c[1]
    for i = 2:2:N
        rhs += c[i] * λ^c[i + 1]
    end
    return sqrt(rhs)
end

struct RIInfo <: Formula
    λrange::Vector{Float64}
    coeffs::Vector{Float64}
end

function (f::RIInfo)(λ)
    c, N = f.coeffs, length(f.coeffs)
    rhs = c[1]
    for i = 2:4:min(N, 9)
        rhs += (c[i] * λ^c[i + 1]) / (λ^2 - c[i + 2]^c[i + 3])
    end
    for i = 10:2:N
        rhs += c[i] * λ^c[i + 1]
    end
    return sqrt(rhs)
end

struct Cauchy <: Formula
    λrange::Vector{Float64}
    coeffs::Vector{Float64}
end

function (f::Cauchy)(λ)
    c, N = f.coeffs, length(f.coeffs)
    rhs = c[1]
    for i = 2:2:N
        rhs += c[i] * λ^c[i + 1]
    end
    return rhs
end

struct Gases <: Formula
    λrange::Vector{Float64}
    coeffs::Vector{Float64}
end

function (f::Gases)(λ)
    c, N = f.coeffs, length(f.coeffs)
    rhs = c[1]
    for i = 2:2:N
        rhs += c[i] / (c[i + 1] - 1 / λ^2)
    end
    return rhs + 1
end

struct Herzberger <: Formula
    λrange::Vector{Float64}
    coeffs::Vector{Float64}
end

function (f::Herzberger)(λ)
    c, N = f.coeffs, length(f.coeffs)
    rhs = c[1]
    rhs += c[2] / (λ^2 - 0.028)
    rhs += c[3] * (1 / (λ^2 - 0.028))^2
    for i = 4:N
        pow = 2 * (i - 3)
        rhs += c[i] * λ^pow
    end
    return rhs
end

struct Retro <: Formula
    λrange::Vector{Float64}
    coeffs::Vector{Float64}
end

function (f::Retro)(λ)
    c = f.coeffs
    rhs = c[1] + c[2] * λ^2 / (λ^2 - c[3]) + c[4] * λ^2
    return sqrt((-2rhs - 1) / (rhs - 1))
end

struct Exotic <: Formula
    λrange::Vector{Float64}
    coeffs::Vector{Float64}
end

function (f::Exotic)(λ)
    c = f.coeffs
    rhs = c[1] + c[2] / (λ^2 - c[3]) + c[4] * (λ - c[5]) / ((λ - c[5])^2 + c[6])
    return sqrt(rhs)
end


struct TabulatedK <: Tabulated
    λ::Vector{Float64}
    k::Vector{Float64}
    _itp::Spline1D

    function TabulatedK(λ, k)
        itp = Spline1D(λ, k, bc="error") # error on extrapolation
        return new(λ, k, itp)
    end
end

function (f::TabulatedK)(λ)
    return f._itp(λ)
end

