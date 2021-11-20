using ArtifactUtils, Artifacts

url = "https://github.com/polyanskiy/refractiveindex.info-database/archive/v2021-07-18.tar.gz"

add_artifact!(
    joinpath(@__DIR__, "../Artifacts.toml"),
    "refractiveindex.info",
    url,
    force=true,
    clear=false,
)
