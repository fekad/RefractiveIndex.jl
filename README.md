# RefractiveIndexDatabase

Provides an offline/online interface to [refractiveindex.info](http://refractiveindex.info).

Database:
https://github.com/polyanskiy/refractiveindex.info-database


### Examples
```julia-repl
julia> using RefractiveIndexDatabase

julia> MgLiTaO3 = get_material("other", "Mg-LiTaO3", "Moutzouris-o")
RefractiveIndexDatabase.RealFormula

julia> MgLiTaO3(0.45) # default unit is microns
2.2373000025056826

julia> using Unitful

julia> MgLiTaO3(450u"nm") # auto-conversion from generic Unitful.jl length units
2.2373000025056826

julia> MgLiTaO3(450e-9, "m") # strings can be used to specify units (parsing is cached)
2.2373000025056826

julia> Ar = load_url("https://refractiveindex.info/database/data/main/Ar/Peck-15C.yml")
RefractiveIndexDatabase.RealFormula

julia> Ar(532, "nm")
1.0002679711455778
```
