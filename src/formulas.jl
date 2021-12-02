@doc raw"""
Sellmeier formula:
```math
n^2 - 1 = c_1 + \sum \limits_{i=1}^{N} \frac{c_{2i} \lambda^2}{\lambda^2 - c_{2i+1}^2}
```
"""
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

@doc raw"""
Sellmeier-2 formula:
```math
n^2 - 1 = c_1 + \sum \limits_{i=1}^{N} \frac{c_{2i} \lambda^2}{\lambda^2 - c_{2i+1}}
```
"""
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

@doc raw"""
Polynomial formula:
```math
n^2 = c_1 + \sum \limits_{i=1}^{N}  c_{2i} \lambda^{c_{2i+1}}
```
"""
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

@doc raw"""
RefractiveIndex.INFO formula:
```math
n^2 = c_1
    + \frac{c_{2} \lambda^{c_{3}}}{\lambda^2 - c_{4}^{c_{5}}}
    + \frac{c_{6} \lambda^{c_{7}}}{\lambda^2 - c_{8}^{c_{9}}}
    + \sum \limits_{i=5}^{N} c_{2i} \lambda^{c_{2i+1}}
```
"""
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

@doc raw"""
Cauchy formula:
```math
n = c_1 + \sum \limits_{i=5}^{N} c_{2i} \lambda^{c_{2i+1}}
```
"""
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

@doc raw"""
Gases formula:
```math
n - 1 = c_1
    + \sum \limits_{i=1}^{N} \frac{c_{2i}}{c_{2i+1} - \lambda^{-2} }
```
"""
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

@doc raw"""
Herzberger formula:
```math
n = c_1
    + \frac{c_{2}}{\lambda^2 - 0.028}
    + c_{3} \left( \frac{1}{\lambda^2 - 0.028} \right)^2
    + \sum \limits_{i=1}^{N} c_{i+3} \lambda^{2i}
```
"""
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

@doc raw"""
Retro formula:
```math
\frac{n^2 - 1}{n^2 +2} = c_1
    + \frac{c_{2} \lambda^2}{\lambda^2 - c_{3}}
    +  c_{4} \lambda^2
```
"""
struct Retro <: Formula
    λrange::NTuple{2,Float64}
    coeffs::NTuple{4,Float64}
end

function (f::Retro)(λ)
    c = f.coeffs
    rhs = c[1] + c[2] * λ^2 / (λ^2 - c[3]) + c[4] * λ^2
    return sqrt((-2rhs - 1) / (rhs - 1))
end

@doc raw"""
Exotic formula:
```math
n^2 = c_1
    + \frac{c_{2}}{\lambda^2 - c_{3}}
    + \frac{c_{4}(\lambda - c_{5})}{(\lambda - c_{5})^2 + c_{6}}
```
"""
struct Exotic <: Formula
    λrange::NTuple{2,Float64}
    coeffs::NTuple{6,Float64}
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

