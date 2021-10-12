module RefractiveIndex

using Pkg.Artifacts
using YAML
using Interpolations
using HTTP.URIs: unescapeuri
using Unitful: @u_str, uparse, uconvert, ustrip, AbstractQuantity
using Memoize
using DelimitedFiles: readdlm

import Base: getindex, show

export RefractiveMaterial
export load_file

const RI_INFO_ROOT = Ref{String}()
const RI_LIB = Dict{Tuple{String, String, String}, NamedTuple{(:name, :path), Tuple{String, String}}}()


# struct Entry
#     name::String
#     path::String
# end

function __init__()
    RI_INFO_ROOT[] = joinpath(artifact"refractiveindex.info", "refractiveindex.info-database-2020-01-19", "database")

    lib = YAML.load_file(joinpath(RI_INFO_ROOT[], "library.yml"), dicttype=Dict{String, Any})
    for shelf in lib
        shelfname = shelf["SHELF"]
        for book in shelf["content"]
            haskey(book, "DIVIDER") && continue
            bookname = book["BOOK"]
            for page in book["content"]
                haskey(page, "DIVIDER") && continue
                pagename = string(page["PAGE"])
                RI_LIB[(shelfname, bookname, pagename)] =(name = page["name"], path=page["data"])
            end
        end
    end

end

# const database = Dict{Tuple{String, String, String}, Entry}()
# RI_INFO_ROOT[] = joinpath(artifact"database","refractiveindex.info-database-2020-01-19", "database")
#
# lib = YAML.load_file(joinpath(RI_INFO_ROOT[], "library.yml"), dicttype=Dict{String, Any})
# for shelf in lib
#     shelfname = shelf["SHELF"]
#     for book in shelf["content"]
#         haskey(book, "DIVIDER") && continue
#         bookname = book["BOOK"]
#         for page in book["content"]
#             haskey(page, "DIVIDER") && continue
#             pagename = string(page["PAGE"])
#             database[(shelfname, bookname, pagename)] = Entry(page["name"],  joinpath(RI_INFO_ROOT[], "data", page["data"]))
#         end
#     end
# end


include("dispersions.jl")

struct RefractiveMaterial{DF<:Dispersion}
    name::String
    reference::String
    comment::String
    dispersion::DF
    λrange::Tuple{Float64, Float64}
    specs::Dict{Symbol, Any}
end

const DISPERSIONFORMULAE = Dict(
    "formula 1" => Sellmeier,
    "formula 2" => Sellmeier2,
    "formula 3" => Polynomial,
    "formula 4" => RIInfo,
    "formula 5" => Cauchy,
    "formula 6" => Gases,
    "formula 7" => Herzberger,
    "formula 8" => Retro,
    "formula 9" => Exotic,
    "tabulated nk" => TabulatedNK,
    "tabulated n" => TabulatedN,
    "tabulated k" => TabulatedK,
)

function str2tuple(str)
    arr = parse.(Float64, split(str))
    ntuple(i -> arr[i], length(arr))
end

function get_dispersion(data)
    DF = DISPERSIONFORMULAE[data[:type]]

    if haskey(data, :coefficients)
        λrange = str2tuple(data[:wavelength_range])
        return DF(str2tuple(data[:coefficients])), λrange
    else
        raw = readdlm(IOBuffer(data[:data]), ' ', Float64)
        λrange = extrema(@view raw[:, 1])
        return DF(raw), λrange
    end
end
#
# function get_data_Sellmeier(data)
# end
#
# function get_data_Sellmeier2(data)
# end
#
# function get_data_Polynomial(data)
# end
#
# function get_data_RIInfo(data)
# end
#
# function get_data_Cauchy(data)
# end
#
# function get_data_Gases(data)
# end
#
# function get_data_Herzberger(data)
# end
#
# function get_data_Retro(data)
# end
#
# function get_data_Exotic(data)
# end
#
# function get_data_TabulatedNK(data)
# end
#
# function get_data_TabulatedN(data)
# end
#
# function get_data_TabulatedK(data)
# end
#
#


"""
    RefractiveMaterial(shelf, book, page)

Load the refractive index data for the material corresponding to the specified
shelf, book, and page within the [refractiveindex.info](https://refractiveindex.info/) database. The data
can be queried by calling the returned `RefractiveMaterial` object at a given wavelength.

# Examples
```julia-repl
julia> MgLiTaO3 = RefractiveMaterial("other", "Mg-LiTaO3", "Moutzouris-o")
"Mg-LiTaO3 (Moutzouris et al. 2011: n(o) 0.450-1.551 µm; 8 mol.% Mg)"

julia> MgLiTaO3(0.45) # default unit is microns
2.2373000025056826

julia> using Unitful

julia> MgLiTaO3(450u"nm") # auto-conversion from generic Unitful.jl length units
2.2373000025056826

julia> MgLiTaO3(450e-9, "m") # strings can be used to specify units (parsing is cached)
2.2373000025056826
```
"""
function RefractiveMaterial(shelf, book, page)

    metadata = RI_LIB[(shelf, book, page)]

    path = joinpath(RI_INFO_ROOT[], "data", metadata.path)
    isfile(path) || @error "Specified material does not exist"

    yaml = YAML.load_file(path; dicttype=Dict{Symbol, Any})

    reference = get(yaml, :REFERENCES, "")
    comment = get(yaml, :COMMENTS, "")
    specs = get(yaml, :SPECS, Dict{Symbol, Any}())

    data = only(get(yaml, :DATA, Dict{Symbol, String}[]))
    DF, λrange = get_dispersion(data)

    RefractiveMaterial(
        string(book, " ($(metadata.name))"),
        reference,
        comment,
        DF,
        λrange,
        specs
    )
end

const DispersionType = Dict(
    "formula 1" => Sellmeier,
    "formula 2" => Sellmeier2,
    "formula 3" => Polynomial,
    "formula 4" => RIInfo,
    "formula 5" => Cauchy,
    "formula 6" => Gases,
    "formula 7" => Herzberger,
    "formula 8" => Retro,
    "formula 9" => Exotic,
    "tabulated nk" => TabulatedNK,
    "tabulated n" => TabulatedN,
    "tabulated k" => TabulatedK,
)


struct MaterialMetadata
    name::String
    reference::String
    comment::String
    specs::Dict{Symbol, Any}
end

struct Material{DF<:Dispersion}
    dispersion::DF
    λrange::Tuple{Float64, Float64}
end

function load_file(path)

    yaml = YAML.load_file(path; dicttype=Dict{Symbol, Any})

    reference = get(yaml, :REFERENCES, "")
    comment = get(yaml, :COMMENTS, "")
    specs = get(yaml, :SPECS, Dict{Symbol, Any}())

    data = yaml[:DATA]

    dispersion_type = data[:type]

    if starts_with(dispersion_type, "formula")
        λrange = str2tuple(data[:wavelength_range])
        return DF(str2tuple(data[:coefficients])), λrange
    elseif starts_with(dispersion_type, "tabulated")

    end

    if haskey(data, :coefficients)
    else
        raw = readdlm(IOBuffer(data[:data]), ' ', Float64)
        λrange = extrema(@view raw[:, 1])
        return DF(raw), λrange
    end

    DF, λrange = get_dispersion(data)

    RefractiveMaterial(
        entry.name,
        reference,
        comment,
        DF,
        λrange,
        specs
    )
end


# function RefractiveMaterial(entry::Entry)
#
#     isfile(entry.path) || @error "Specified material does not exist"
#
#     yaml = YAML.load_file(path; dicttype=Dict{Symbol, Any})
#
#     reference = get(yaml, :REFERENCES, "")
#     comment = get(yaml, :COMMENTS, "")
#     specs = get(yaml, :SPECS, Dict{Symbol, Any}())
#
#     data = only(get(yaml, :DATA, Dict{Symbol, String}[]))
#     DF, λrange = get_dispersion(data)
#
#     RefractiveMaterial(
#         entry.name,
#         reference,
#         comment,
#         DF,
#         λrange,
#         specs
#     )
# end



# show(io::IO, ::MIME"text/plain", m::RefractiveMaterial{DF}) where {DF} = show(io, m.name)

(m::RefractiveMaterial)(λ::Float64) = m.dispersion(λ)
(m::RefractiveMaterial)(λ::AbstractQuantity) = m(Float64(ustrip(uconvert(u"μm", λ))))

@memoize _dim_to_micron(dim) = ustrip(uconvert(u"μm", 1.0uparse(dim)))
(m::RefractiveMaterial)(λ, dim::String) = m(λ*_dim_to_micron(dim))

(m::RefractiveMaterial{T})(λ::Float64) where {T <: Tabulated}= m.dispersion.n(λ)
end # module