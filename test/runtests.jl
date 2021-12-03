using RefractiveIndexDatabase
using Test


@testset "RefractiveIndexDatabase.jl" begin
    @testset "Dispersion formulas" begin
        # Sellmeier
        @test isapprox(RefractiveIndex(get_material("main", "Ar", "Grace-liquid-90K"))(0.3885), 1.22809258, rtol=1e-6)

        # Sellmeier-2
        @test isapprox(RefractiveIndex(get_material("main", "CdTe", "Marple"))(1.68), 2.72726378, rtol=1e-6)

        # Polynomial
        @test isapprox(RefractiveIndex(get_material("other", "Mg-LiTaO3", "Moutzouris-o"))(1.0), 2.13370331, rtol=1e-6)

        # RefractiveIndex.INFO
        @test isapprox(RefractiveIndex(get_material("main", "ZnTe", "Li"))(15.275), 2.66048474, rtol=1e-6)

        # Cauchy
        @test isapprox(RefractiveIndex(get_material("main", "SF6", "Vukovic"))(0.95), 1.00072070, rtol=1e-6)

        # Gases
        @test isapprox(RefractiveIndex(get_material("main", "He", "Mansfield"))(1.26935), 1.00003472, rtol=1e-6)

        # Herzberger
        @test isapprox(RefractiveIndex(get_material("main", "Si", "Edwards"))(13.71865), 3.42084598, rtol=1e-6)

        # Retro
        @test isapprox(RefractiveIndex(get_material("main", "AgBr", "Schröter"))(0.5825), 2.26004419, rtol=1e-6)

        # Exotic
        @test isapprox(RefractiveIndex(get_material("organic", "urea", "Rosker-e"))(0.68), 1.60004980, rtol=1e-6)
    end

    @testset "Tabular data" begin
        # FormulaNK
        m = RefractiveIndex(get_material("main","Si","Chandler-Horowitz"))
        @test isapprox(m(10.), 3.41807041 + 7.4e-5im,  rtol=1e-6)


        # TabulatedNK
        m = RefractiveIndex(get_material("main", "ZnO", "Stelling"))
        @test isapprox(m(0.866), 1.59478654 + 0.01177447im,  rtol=1e-6)

    end

    @testset "Load data from url" begin

        url = "https://refractiveindex.info/database/data/main/Ag/Johnson.yml"
        m = RefractiveIndex(load_url(url))
        @test isapprox(m(0.49), 0.05087409 + 3.04074578im,  rtol=1e-6)

    end
    @testset "Load data from file" begin

        path = joinpath(@__DIR__, "data", "BAF2.yml")
        m = RefractiveIndex(load_file(path))
        @test isapprox(m(0.82), 1.56104714 + 1.28383192e-8im,  rtol=1e-6)

    end

end

