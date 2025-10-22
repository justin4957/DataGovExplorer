"""
Basic usage examples for DataGovExplorer
Demonstrates simple queries and exports
"""

using DataGovExplorer

# Create a client
client = CKANClient()

# Example 1: Search for datasets about climate
println("Example 1: Searching for climate-related datasets")
climate_data = search_packages(client, query="climate", rows=10)
println("Found $(nrow(climate_data)) climate datasets")
export_to_csv(climate_data, "climate_datasets.csv")
println("Exported to climate_datasets.csv")

# Example 2: Browse datasets by organization
println("\nExample 2: Getting datasets from NOAA")
noaa_datasets = search_packages(client, organization="noaa-gov", rows=20)
println("Found $(nrow(noaa_datasets)) NOAA datasets")
export_to_json(noaa_datasets, "noaa_datasets.json")
println("Exported to noaa_datasets.json")

# Example 3: Browse by tag
println("\nExample 3: Getting datasets tagged with 'health'")
health_datasets = search_packages(client, tags=["health"], rows=15)
println("Found $(nrow(health_datasets)) health datasets")
export_to_xlsx(health_datasets, "health_datasets.xlsx")
println("Exported to health_datasets.xlsx")

# Example 4: Get details about a specific dataset
println("\nExample 4: Getting metadata for a specific dataset")
# Note: Replace with an actual dataset name from your search results
if nrow(climate_data) > 0
    first_dataset = climate_data[1, :name]
    metadata = get_package_metadata(client, first_dataset)
    println("Metadata for $(first_dataset):")
    println(metadata)
    export_to_csv(metadata, "dataset_metadata.csv")
    println("Exported to dataset_metadata.csv")
end

println("\n✓ All examples completed successfully!")
