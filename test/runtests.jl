using RefractiveIndexDatabase
using Test


@testset "RefractiveIndexDatabase.jl" begin
    @testset "Dispersion formulas" begin
        # Sellmeier
        @test isapprox(get_material("main", "Ar", "Grace-liquid-90K")(0.3885), 1.22809258, rtol=1e-6)

        # Sellmeier-2
        @test isapprox(get_material("main", "CdTe", "Marple")(1.68), 2.72726378, rtol=1e-6)

        # Polynomial
        @test isapprox(get_material("other", "Mg-LiTaO3", "Moutzouris-o")(1.0), 2.13370331, rtol=1e-6)

        # RefractiveIndex.INFO
        @test isapprox(get_material("main", "ZnTe", "Li")(15.275), 2.66048474, rtol=1e-6)

        # Cauchy
        @test isapprox(get_material("main", "SF6", "Vukovic")(0.95), 1.00072070, rtol=1e-6)

        # Gases
        @test isapprox(get_material("main", "He", "Mansfield")(1.26935), 1.00003472, rtol=1e-6)

        # Herzberger
        @test isapprox(get_material("main", "Si", "Edwards")(13.71865), 3.42084598, rtol=1e-6)

        # Retro
        @test isapprox(get_material("main", "AgBr", "Schröter")(0.5825), 2.26004419, rtol=1e-6)

        # Exotic
        @test isapprox(get_material("organic", "urea", "Rosker-e")(0.68), 1.60004980, rtol=1e-6)
    end

    @testset "Tabular data" begin
        # RefractiveNK
        @test isapprox(get_material("main", "ZnO", "Stelling")(0.866), 1.59478654 + 0.01177447im,  rtol=1e-6)
    end

    @testset "Online data" begin

        path = "https://refractiveindex.info/database/data/main/Ag/Johnson.yml"
        @test isapprox(load_url(path)(0.49), 0.05087409 + 3.04074578im,  rtol=1e-6)

    end

end

