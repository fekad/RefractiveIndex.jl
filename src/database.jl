const DB_ROOT = joinpath(artifact"refractiveindex.info", "refractiveindex.info-database-2021-07-18", "database")

struct MaterialEntry
    name::String
    path::String
    book_category::String
    page_category::String
end

const DB = Dict{Tuple{String, String, String}, MaterialEntry}()

function __init__()

    lib = YAML.load_file(joinpath(DB_ROOT, "library.yml"), dicttype=Dict{String,Any})

    last_book_divider, last_page_divider = "", ""
    for shelf in lib
        shelfname = shelf["SHELF"]
        for book in shelf["content"]
            if haskey(book, "DIVIDER")
                last_book_divider = book["DIVIDER"]
                continue
            end
            bookname = book["BOOK"]
            for page in book["content"]
                if haskey(page, "DIVIDER")
                    last_page_divider = page["DIVIDER"]
                    continue
                end
                pagename = string(page["PAGE"])
                DB[(shelfname, bookname, pagename)] = MaterialEntry(
                    page["name"],
                    page["data"],
                    last_book_divider,
                    last_page_divider
                )
            end
        end
    end
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

str2vector(str) = Base.parse.(Float64, split(str))

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
            coeffs = str2vector(data[1]["coefficients"])
            λrange = str2vector(data[1]["wavelength_range"])
            n = eval(FORMULAS[data_type])(λrange, coeffs)
            return FormulaN(meta, n)

        elseif data_type == "tabulated n"
            raw = readdlm(IOBuffer(data[1]["data"]), ' ', Float64)
            return TabulatedN(meta, eachcol(raw)...)

        elseif data_type == "tabulated nk"
            raw = readdlm(IOBuffer(data[1]["data"]), ' ', Float64)
            return TabulatedNK(meta, eachcol(raw)...)

        end

    elseif N == 2

        @assert data[1]["type"] in keys(FORMULAS)
        @assert data[2]["type"] == "tabulated k"

        data_type = data[1]["type"]
        coeffs = str2vector(data[1]["coefficients"])
        λrange = str2vector(data[1]["wavelength_range"])

        raw = readdlm(IOBuffer(data[2]["data"]), ' ', Float64)

        n = eval(FORMULAS[data_type])(λrange, coeffs)
        k = TabulatedK(eachcol(raw)...)

        return FormulaNK(meta, n, k)

    end


end


"""
    get_material(shelf, book, page)

Load the refractive index data for the material corresponding to the specified
shelf, book, and page within the [refractiveindex.info](https://refractiveindex.info/) database. The data
can be queried by calling the returned object at a given wavelength.

# Examples
```julia-repl
julia> using RefractiveIndexDatabase

julia> MgLiTaO3 = get_material("other", "Mg-LiTaO3", "Moutzouris-o")
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
function get_material(shelf, book, page)
    item = DB[(shelf, book, page)]
    return load_file(joinpath(DB_ROOT, "data", item.path))
end

"""
    load_file(path)

Load the refractive index data for the material corresponding to a YAML
file within the [refractiveindex.info](https://refractiveindex.info/) database. The data
can be queried by calling the returned object at a given wavelength.

# Examples
```julia-repl
julia> using RefractiveIndexDatabase

julia> path = joinpath(RefractiveIndexDatabase.DB_ROOT, "data", "main", "Ar", "Peck-15C.yml");

julia> Ar = load_file(path)
RefractiveIndexDatabase.FormulaN

julia> Ar(532, "nm")
1.0002679711455778
```
"""
function load_file(path)

    dict = YAML.load_file(path)
    return parse(dict)

end

"""
    load_url(path)

Load the refractive index data for the material corresponding to the specified
url within the [refractiveindex.info](https://refractiveindex.info/) database. The data
can be queried by calling the returned object at a given wavelength.

# Examples
```julia-repl
julia> using RefractiveIndexDatabase

julia> Ar = load_url("https://refractiveindex.info/database/data/main/Ar/Peck-15C.yml")
RefractiveIndexDatabase.FormulaN

julia> Ar(532, "nm")
1.0002679711455778
```
"""
function load_url(path)

    r = request("GET", path)
    dict = YAML.load(String(r.body))
    return parse(dict)

end
