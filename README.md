# RefractiveIndexDatabase

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://fekad.github.io/RefractiveIndexDatabase.jl/)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://fekad.github.io/RefractiveIndexDatabase.jl/dev)
[![Run tests](https://github.com/fekad/RefractiveIndexDatabase.jl/actions/workflows/test.yml/badge.svg)](https://github.com/fekad/RefractiveIndexDatabase.jl/actions/workflows/test.yml)

Provides an offline/online interface to [refractiveindex.info](http://refractiveindex.info).

This package is based on https://github.com/stillyslalom/RefractiveIndex.jl repository.

The source of the database: https://github.com/polyanskiy/refractiveindex.info-database


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

## Contributions

- Adam Fekete (adam.fekete@unamur.be)

This work was carried out at UNamur in Luc Henrard's group. The authors acknowledge financial support from the Communauté Française de Belgique through the Action de Recherche Concertée (ARC - No. 19/24-102)
SURFASCOPE - Surface Enhanced Spectroscopy by Second-Principles Calculations.
