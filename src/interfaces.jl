function load_file(path)

    dict = YAML.load_file(path)
    return parse(dict)

end

function load_url(path)

    r = request("GET", path)

    dict = YAML.load(String(r.body))
    return parse(dict)

end


const FORMULAS = Dict{String, Symbol}(
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