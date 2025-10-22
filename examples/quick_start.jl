"""
Quick start example for DataGovExplorer
Test basic connectivity and explore the catalog
"""

using DataGovExplorer

# Create a client instance
client = CKANClient()

# Test connectivity by fetching a small sample of packages
println("Testing connection to data.gov catalog...")
packages = get_packages(client, limit=5)
println("Successfully connected! Found $(nrow(packages)) packages (showing first 5)")
println(packages)

# Get some organizations
println("\nFetching organizations...")
orgs = get_organizations(client)
println("Found $(nrow(orgs)) organizations")

# Get some tags
println("\nFetching tags...")
tags = get_tags(client)
println("Found $(nrow(tags)) tags")

println("\n✓ Quick start test completed successfully!")
println("Run interactive_explorer() to start the interactive CLI")
