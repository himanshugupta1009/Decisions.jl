using Documenter
using DecisionNetworks
using Random

DocMeta.setdocmeta!(DecisionNetworks, :DocTestSetup, :(using DecisionNetworks); recursive=true)

makedocs(
    modules = [DecisionNetworks],
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
            "networks/decision_graphs.md",
            "networks/conditional_dists.md",
            "networks/spaces.md",
            "networks/traits.md",
            "networks/transformations.md",
        ],
        "DecisionProblems.jl" => [

        ],
        "DecisionSettings.jl" => [

        ]
    ],
    warnonly = [:missing_docs, :cross_references]
)

#deploydocs(
#    repo = "github.com/[...].git",
#    push_preview=true,
#)
