using Documenter
using Decisions
using Random

DocMeta.setdocmeta!(Decisions, :DocTestSetup, :(using Decisions); recursive=true)

makedocs(
    modules = [Decisions],
    format = Documenter.HTML(
        prettyurls = false                                  # For Local Doc Development
        #prettyurls = get(ENV, "CI", nothing) == "true"     # For GitHub Deployment
    ),
    sitename = "Decisions.jl",
    # NOTE: Match with `docs/src/index.md`.
    pages = [
        "index.md",
        "DecisionNetworks.jl" => [
            "networks/dns.md",
            "networks/conditional_dists.md",
            "networks/spaces.md",
            "networks/traits.md",
            "networks/transformations.md",
        ],
    ],
    warnonly = [:missing_docs, :cross_references]
)

#deploydocs(
#    repo = "github.com/[...].git",
#    push_preview=true,
#)
