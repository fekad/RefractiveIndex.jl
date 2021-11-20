# """
#     get_material(shelf, book, page)
#
# Load the refractive index data for the material corresponding to the specified
# shelf, book, and page within the [refractiveindex.info](https://refractiveindex.info/) database. The data
# can be queried by calling the returned object at a given wavelength.
#
# # Examples
# ```julia-repl
# julia> MgLiTaO3 = get_material("other", "Mg-LiTaO3", "Moutzouris-o")
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
function get_material(shelf, book, page)
    k = MaterialCatalog(shelf, book, page)
    return load_file(joinpath(DB_ROOT, "data", DB[k].path))
end


function load_file(path)

    dict = YAML.load_file(path)
    return parse(dict)

end

# """
#     load_url(path)
#
# Load the refractive index data for the material corresponding to the specified
# url within the [refractiveindex.info](https://refractiveindex.info/) database. The data
# can be queried by calling the returned object at a given wavelength.
#
# # Examples
# ```julia-repl
# julia> using RefractiveIndexDatabase
#
# julia> Ar = load_url("https://refractiveindex.info/database/data/main/Ar/Peck-15C.yml")
# RefractiveIndexDatabase.RealFormula
#
# julia> Ar(532, "nm")
# 1.0002679711455778
# ```
# """
function load_url(path)

    r = request("GET", path)
    dict = YAML.load(String(r.body))
    return parse(dict)

end


const FORMULAS = Dict{String,Symbol}(
    "formula 1" => :Sellmeier,
    "formula 2" => :Sellmeier2,
    "formula 3" => :Polynomial,
    "formula 4" => :RIInfo,
    "formula 5" => :Cauchy,
    "formula 6" => :Gases,
    "formula 7" => :Herzberger,
    "formula 8" => :Retro,
    "formula 9" => :Exotic,
)

function str2tuple(str)
    arr = Base.parse.(Float64, split(str))
    ntuple(i -> arr[i], length(arr))
end

function parse(dict)

    reference = get(dict, "REFERENCES", "")
    comment = get(dict, "COMMENTS", "")
    specs = get(dict, "SPECS", Dict{Any,Any}())

    meta = Metadata(reference, comment, specs)

    data = dict["DATA"]
    N = length(data)

    if N == 1

        data_type = data[1]["type"]

        if data_type in keys(FORMULAS)
            coeffs = str2tuple(data[1]["coefficients"])
            λrange = str2tuple(data[1]["wavelength_range"])
            n = eval(FORMULAS[data_type])(λrange, coeffs)
            return RealFormula(meta, n)

        elseif data_type == "tabulated n"
            raw = readdlm(IOBuffer(data[1]["data"]), ' ', Float64)
            return RealTabulated(meta, eachcol(raw)...)

        elseif data_type == "tabulated nk"
            raw = readdlm(IOBuffer(data[1]["data"]), ' ', Float64)
            return ComplexTabulated(meta, eachcol(raw)...)

        end

    elseif N == 2

        @assert data[1]["type"] in keys(FORMULAS)
        @assert data[2]["type"] == "tabulated k"

        data_type = data[1]["type"]
        coeffs = str2tuple(data[1]["coefficients"])
        λrange = str2tuple(data[1]["wavelength_range"])

        raw = readdlm(IOBuffer(data[2]["data"]), ' ', Float64)

        n = eval(FORMULAS[data_type])(λrange, coeffs)
        k = Tabulated(eachcol(raw)...)

        return ComplexFormula(meta, n, k)

    end

    throw("Uknown data structure! Sorry...")

end