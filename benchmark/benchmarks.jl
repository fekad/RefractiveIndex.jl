using RefractiveIndexDatabase
using BenchmarkTools


suite = BenchmarkGroup()
suite["formula"] = BenchmarkGroup()
suite["tabulated"] = BenchmarkGroup()

let material, l, f
    material = get_material("other", "Mg-LiTaO3", "Moutzouris-o")
    l = range(material.n.λrange..., length=10_000)
    f = RefractiveIndex(material)
    suite["formula"]["MgLiTaO3"] = @benchmarkable $f.($l)
end


let material, l, f
    material = get_material("main", "Ag", "Johnson")
    l = range(extrema(material.λ)..., length=10_000)
    f = RefractiveIndex(material)
    suite["tabulated"]["Ag"] = @benchmarkable $f.($l)
end

tune!(suite)
results = run(suite; verbose=true, seconds = 1)

for (suite, group) in results
    @show suite
    for (benchmark, result) in group
        @show benchmark
        display(result)
    end
end

# # If a cache of tuned parameters already exists, use it, otherwise, tune and cache
# # the benchmark parameters. Reusing cached parameters is faster and more reliable
# # than re-tuning `suite` every time the file is included.
# paramspath = joinpath(dirname(@__FILE__), "params.json")
#
# if isfile(paramspath)
#     loadparams!(suite, BenchmarkTools.load(paramspath)[1], :evals)
# else
#     tune!(suite)
#     BenchmarkTools.save(paramspath, params(suite))
# end

