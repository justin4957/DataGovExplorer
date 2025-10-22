# DataGovExplorer Quick Start Guide

## Installation

1. Navigate to the project directory:
```bash
cd /Users/coolbeans/Development/dev/DataGovExplorer
```

2. Start Julia and activate the project:
```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

This will install all required dependencies.

## Running the Interactive Explorer

### Option 1: Using the launcher script

```bash
julia run_explorer.jl
```

### Option 2: From Julia REPL

```julia
include("src/DataGovExplorer.jl")
using .DataGovExplorer
interactive_explorer()
```

## First Steps

Once the interactive explorer starts, you'll see the main menu:

```
DATA.GOV CATALOG EXPLORER
======================================================================

MAIN MENU
----------------------------------------------------------------------
  [o] - Browse Organizations
  [s] - Search Datasets
  [t] - Browse by Tags
  [r] - Recent Datasets
  [q] - Quit

Choice:
```

### Try These First Tasks

#### 1. View Recent Datasets
- Press `r` and Enter
- Browse the most recently updated datasets
- Type a dataset name to view details
- Type `export` to save the list

#### 2. Search for Datasets
- Press `s` and Enter
- Enter a keyword like "climate" or "health"
- View the search results
- Select a dataset to view details

#### 3. Browse by Organization
- Press `o` and Enter
- Browse organizations like NOAA, NASA, EPA
- Select an organization to see their datasets
- Export lists for later analysis

#### 4. Browse by Tags
- Press `t` and Enter
- View popular tags
- Select a tag to see related datasets
- Discover datasets by topic

## Programmatic Usage Example

Create a file `my_search.jl`:

```julia
using Pkg
Pkg.activate(".")

include("src/DataGovExplorer.jl")
using .DataGovExplorer

# Create client
client = CKANClient()

# Search for climate datasets
println("Searching for climate datasets...")
results = search_packages(client, query="climate", rows=20)
println("Found $(nrow(results)) datasets")

# Export to CSV
export_to_csv(results, "climate_data.csv")
println("Exported to climate_data.csv")

# Get details about first dataset
if nrow(results) > 0
    first_dataset = results[1, :name]
    println("\nGetting details for: $first_dataset")
    details = get_package_metadata(client, first_dataset)
    println(details)
end
```

Run it:
```bash
julia my_search.jl
```

## Features at a Glance

### Smart Search
- Fuzzy matching for dataset names
- Auto-correction for typos
- Suggestions when exact matches aren't found

### Export Options
- **CSV**: Universal compatibility
- **JSON**: Web-friendly format
- **Excel**: Spreadsheet analysis
- **Arrow**: Fast binary format

### Built-in Caching
- Metadata is cached to reduce API calls
- Faster subsequent queries
- Force refresh with `force_refresh=true`

### Rate Limiting
- Automatic rate limiting to respect API constraints
- Exponential backoff on failures
- Configurable retry logic

## Common Workflows

### Workflow 1: Find Datasets by Topic

1. Launch interactive explorer
2. Choose `[s] - Search Datasets`
3. Enter topic (e.g., "education")
4. Browse results
5. Export to CSV for analysis

### Workflow 2: Explore Organization Data

1. Launch interactive explorer
2. Choose `[o] - Browse Organizations`
3. Select an organization (e.g., "noaa-gov")
4. View their datasets
5. Get details on specific datasets

### Workflow 3: Programmatic Batch Search

```julia
using DataGovExplorer

client = CKANClient()

# Search multiple topics
topics = ["climate", "health", "education", "transportation"]

for topic in topics
    println("Searching for $topic...")
    results = search_packages(client, query=topic, rows=50)
    export_to_csv(results, "$(topic)_datasets.csv")
    println("Exported $(nrow(results)) datasets for $topic")
end
```

## Tips and Tricks

1. **Start Small**: Use `rows=10` when testing queries
2. **Use Filters**: Combine `query`, `organization`, and `tags` for precise results
3. **Check Cache**: Cached queries are instant - no API call needed
4. **Export Often**: Save interesting datasets for offline analysis
5. **Read API Docs**: Learn more at https://docs.ckan.org/en/2.11/api/

## Troubleshooting

### "Connection refused" or timeout errors
- Check internet connection
- Verify data.gov is accessible
- Try increasing timeout in config

### "No results found"
- Try broader search terms
- Check spelling
- Some datasets may have been removed

### Slow performance
- Reduce `rows` parameter
- Use more specific queries
- Clear cache if needed: `client.cache = Dict()`

## Next Steps

- Explore the `examples/` directory for more usage patterns
- Read the full README.md for detailed API documentation
- Check out the CKAN API docs for advanced queries
- Customize the configuration for your needs

## Getting Help

- Check README.md for full documentation
- Review example files in `examples/`
- Consult CKAN API documentation
- Open an issue for bugs or feature requests

Happy exploring!
