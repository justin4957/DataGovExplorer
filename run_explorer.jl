#!/usr/bin/env julia

"""
Launcher script for DataGovExplorer CLI

Supports both interactive and non-interactive modes:
- Interactive: julia run_explorer.jl (or julia run_explorer.jl interactive)
- Non-interactive: julia run_explorer.jl search "climate" --limit 20
"""

# Add current directory to load path
push!(LOAD_PATH, @__DIR__)

# Load the package
using Pkg
Pkg.activate(@__DIR__)

# Load DataGovExplorer module
include("src/DataGovExplorer.jl")
using .DataGovExplorer

# Check if any arguments were provided
if length(ARGS) == 0
    # No arguments - launch interactive mode
    println("Starting Data.gov Catalog Explorer...")
    println("Loading dependencies...")
    interactive_explorer()
else
    # Arguments provided - use CLI mode
    using Comonicon
    include("src/cli.jl")

    # Let Comonicon handle the command-line arguments
    Comonicon.@main
end
