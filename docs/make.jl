using Documenter
using Decisions
using Random

push!(LOAD_PATH,"..")

makedocs(
    modules = [DecisionNetworks, DecisionProblems],
    format = Documenter.HTML(
        assets = ["assets/favicon.ico"],
        collapselevel = 1,
        prettyurls = false       ,                           # For Local Doc Development
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
            "networks/visualization.md",
            "networks/interoperability.md",
            "networks/internals.md",
            "networks/faqs.md",
        ],
        "DecisionProblems.jl" => [
            "problems/metrics.md"
            "problems/algorithms.md"
            "problems/problems.md"
            "problems/faq.md"

        ],
        "DecisionSettings.jl" => [

        ]
    ],
    warnonly = [:missing_docs, :cross_references]
)

deploydocs(
   repo = "github.com/JuliaDecisionMaking/Decisions.jl.git",
   push_preview = true,
   devbranch = "main"
)
