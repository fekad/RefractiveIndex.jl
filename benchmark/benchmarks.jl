using RefractiveIndexDatabase
using BenchmarkTools


suite = BenchmarkGroup()
suite["formula"] = BenchmarkGroup()
suite["tabulated"] = BenchmarkGroup()

let material, l
    material = get_material("other", "Mg-LiTaO3", "Moutzouris-o")
    l = range(material.n.λrange..., length=1000)
    suite["formula"]["MgLiTaO3"] = @benchmarkable $material.($l)
end


let material, l
    material = get_material("main", "Ag", "Johnson")
    l = range(extrema(material.λ)..., length=1000)
    suite["tabulated"]["Ag"] = @benchmarkable $material.($l)
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

