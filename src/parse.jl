const RI_INFO_ROOT = Ref{String}()
const RI_LIB = Dict{Tuple{String, String, String}, NamedTuple{(:name, :path), Tuple{String, String}}}()


# struct Entry
#     name::String
#     path::String
# end

# function __init__()
#     RI_INFO_ROOT[] = joinpath(artifact"refractiveindex.info", "refractiveindex.info-database-2020-01-19", "database")
#
#     lib = YAML.load_file(joinpath(RI_INFO_ROOT[], "library.yml"), dicttype=Dict{String, Any})
#     for shelf in lib
#         shelfname = shelf["SHELF"]
#         for book in shelf["content"]
#             haskey(book, "DIVIDER") && continue
#             bookname = book["BOOK"]
#             for page in book["content"]
#                 haskey(page, "DIVIDER") && continue
#                 pagename = string(page["PAGE"])
#                 RI_LIB[(shelfname, bookname, pagename)] =(name = page["name"], path=page["data"])
#             end
#         end
#     end
#
# end

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