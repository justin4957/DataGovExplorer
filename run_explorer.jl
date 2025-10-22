#!/usr/bin/env julia

"""
Launcher script for DataGovExplorer interactive CLI
Run with: julia run_explorer.jl
"""

# Add current directory to load path
push!(LOAD_PATH, @__DIR__)

# Load the package
using Pkg
Pkg.activate(@__DIR__)

# Load DataGovExplorer module
include("src/DataGovExplorer.jl")
using .DataGovExplorer

# Launch the interactive explorer
println("Starting Data.gov Catalog Explorer...")
println("Loading dependencies...")

interactive_explorer()
