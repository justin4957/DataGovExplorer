# DataGovExplorer

A Julia-based interactive CLI tool for exploring and downloading datasets from the [data.gov catalog](https://catalog.data.gov). Built on the CKAN API, this tool provides an intuitive command-line interface for browsing thousands of government datasets.

<img width="1053" height="640" alt="Screenshot 2025-10-22 at 10 30 39 AM" src="https://github.com/user-attachments/assets/af34b1c9-0376-4413-9913-c6f51fdc7114" />

## Features

- **Interactive CLI Explorer**: Menu-driven interface for browsing datasets
- **Smart Search**: Fuzzy matching and auto-correction for dataset discovery
- **Multiple Browse Modes**:
  - Browse by organization
  - Browse by tags
  - Search by keywords
  - View recent datasets
- **Flexible Export**: Export catalog metadata to CSV, JSON, Excel, or Arrow formats
- **Caching**: Built-in caching to reduce API calls and improve performance
- **Rate Limiting**: Automatic rate limiting and retry logic with exponential backoff
- **Error Handling**: Graceful error handling with helpful suggestions

## Installation

### Prerequisites

- Julia 1.9 or later

### Setup

1. Clone or download this repository:
```bash
cd /Users/coolbeans/Development/dev/DataGovExplorer
```

2. Install dependencies:
```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

## Quick Start

### Interactive Mode

Launch the interactive explorer:
```bash
julia run_explorer.jl
```

Or from Julia REPL:
```julia
using DataGovExplorer
interactive_explorer()
```

### Programmatic Usage

```julia
using DataGovExplorer

# Create a client
client = CKANClient()

# Search for datasets
climate_data = search_packages(client, query="climate", rows=20)

# Export results
export_to_csv(climate_data, "climate_datasets.csv")
```

## Usage Examples

### Example 1: Search for Datasets
<img width="1022" height="762" alt="Screenshot 2025-10-22 at 10 30 30 AM" src="https://github.com/user-attachments/assets/d0ec15cf-3599-4184-b5d4-53a468936de4" />

```julia
using DataGovExplorer

client = CKANClient()

# Search for datasets about climate
results = search_packages(client, query="climate change", rows=50)

# View results
println("Found $(nrow(results)) datasets")
println(results)

# Export to CSV
export_to_csv(results, "climate_datasets.csv")
```

### Example 2: Browse by Organization

```julia
# Get all organizations
orgs = get_organizations(client)

# Get datasets from a specific organization
noaa_data = search_packages(client, organization="noaa-gov", rows=100)

# Export to Excel
export_to_xlsx(noaa_data, "noaa_datasets.xlsx")
```

### Example 3: Browse by Tags

```julia
# Get all available tags
tags = get_tags(client)

# Find datasets with specific tags
health_data = search_packages(client, tags=["health", "covid-19"], rows=50)

# Export to JSON
export_to_json(health_data, "health_datasets.json")
```

### Example 4: Get Dataset Details

```julia
# Get detailed metadata for a specific dataset
dataset_name = "monthly-us-air-quality-1980-2020"
metadata = get_package_metadata(client, dataset_name)

println(metadata)
export_to_csv(metadata, "dataset_details.csv")
```

### Example 5: Multiple Format Export

```julia
# Search for datasets
results = search_packages(client, query="education", rows=100)

# Export to multiple formats
export_to_csv(results, "education.csv")
export_to_json(results, "education.json")
export_to_arrow(results, "education.arrow")  # Efficient binary format
export_to_xlsx(results, "education.xlsx")
```

## API Reference

### Client Configuration

```julia
# Create client with default configuration
client = CKANClient()

# Create client with custom configuration
config = CKANConfig(
    base_url="https://catalog.data.gov/api/3",
    timeout=30,           # Request timeout in seconds
    rate_limit_ms=500,    # Minimum delay between requests
    max_retries=3,        # Maximum retry attempts
    page_size=100         # Results per page
)
client = CKANClient(config)
```

### Metadata Functions

#### `get_packages(client; limit=nothing, force_refresh=false)`
Get list of all packages (datasets).

#### `get_organizations(client; force_refresh=false)`
Get list of all organizations.

#### `get_tags(client; force_refresh=false)`
Get list of all tags.

#### `get_package_details(client, package_id::String)`
Get detailed information about a specific package.

#### `get_package_metadata(client, package_id::String)`
Get formatted metadata for a package as DataFrame.

#### `search_packages(client; query=nothing, organization=nothing, tags=nothing, rows=100)`
Search for packages with various filters.

### Export Functions

#### `export_to_csv(df, filepath)`
Export DataFrame to CSV format.

#### `export_to_json(df, filepath; pretty=false)`
Export DataFrame to JSON format.

#### `export_to_arrow(df, filepath)`
Export DataFrame to Apache Arrow format (efficient binary).

#### `export_to_xlsx(df, filepath; sheet_name="Data")`
Export DataFrame to Excel format.

#### `export_data(df, filepath; kwargs...)`
Smart export based on file extension.

#### `auto_export(df, base_name; format=:csv, output_dir="./output")`
Export with auto-generated filename and timestamp.

#### `export_multi_sheet_xlsx(data_dict, filepath)`
Export multiple DataFrames to Excel with multiple sheets.

## Project Structure

```
DataGovExplorer/
├── src/
│   ├── DataGovExplorer.jl      # Main module
│   ├── config.jl               # Configuration structures
│   ├── client.jl               # HTTP client with rate limiting
│   ├── metadata.jl             # Metadata retrieval functions
│   ├── exports.jl              # Export utilities
│   ├── explorer.jl             # Interactive CLI main loop
│   └── explorer/
│       ├── display.jl          # Table formatting and colors
│       ├── input.jl            # User input validation
│       └── menu.jl             # Menu navigation logic
├── examples/
│   ├── quick_start.jl          # Basic connectivity test
│   └── basic_usage.jl          # Common usage patterns
├── Project.toml                # Package dependencies
├── run_explorer.jl             # Interactive CLI launcher
└── README.md                   # This file
```

## Architecture

The project follows a modular architecture similar to UNStatsExplorer:

- **Configuration Layer**: Centralized configuration for API settings
- **Client Layer**: HTTP client with caching, rate limiting, and retry logic
- **Metadata Layer**: Functions for retrieving catalog information
- **Export Layer**: Multi-format export utilities
- **Explorer Layer**: Interactive CLI with menu navigation

### Key Design Principles

1. **Composability**: Small, focused functions that combine into larger workflows
2. **Reusability**: Core utilities work independently
3. **Descriptive Naming**: Clear, self-documenting function names
4. **Type Safety**: Robust handling of missing/invalid data
5. **Minimal Overhead**: Efficient caching and resource usage
6. **Progressive Disclosure**: Simple API with advanced options

## Dependencies

- **HTTP.jl**: HTTP client for API requests
- **JSON3.jl**: Fast JSON parsing
- **DataFrames.jl**: Tabular data manipulation
- **CSV.jl**: CSV export
- **Arrow.jl**: Apache Arrow format
- **XLSX.jl**: Excel export
- **JSONTables.jl**: JSON export
- **PrettyTables.jl**: Console table formatting
- **ProgressMeter.jl**: Progress bars
- **StringDistances.jl**: Fuzzy matching (Jaro-Winkler)
- **Crayons.jl**: ANSI color output

## CKAN API

This tool uses the CKAN API (version 3) provided by data.gov. CKAN (Comprehensive Knowledge Archive Network) is an open-source data management system used by governments worldwide.

Key API endpoints used:
- `/api/3/action/package_list` - List all packages
- `/api/3/action/package_search` - Search packages
- `/api/3/action/package_show` - Get package details
- `/api/3/action/organization_list` - List organizations
- `/api/3/action/group_list` - List groups
- `/api/3/action/tag_list` - List tags

API Documentation: https://docs.ckan.org/en/2.11/api/index.html

## Performance Tips

1. **Use Caching**: Metadata queries are cached by default
2. **Specify Filters**: Use `organization`, `tags`, and `query` parameters to narrow searches
3. **Arrow Format**: Use Arrow format for large datasets (fastest for re-import)
4. **Pagination**: Results are automatically paginated with progress bars
5. **Rate Limiting**: Built-in rate limiting respects API constraints

## Troubleshooting

### Connection Issues

If you encounter connection issues:
- Check your internet connection
- Verify the data.gov API is accessible
- Try increasing the `timeout` in configuration

### API Errors

If you get API errors:
- Check if the dataset name/ID is correct
- Some datasets may have restricted access
- Try again later if the API is under heavy load

### Performance Issues

If searches are slow:
- Reduce the `rows` parameter
- Use more specific search queries
- Clear the cache: `client.cache = Dict()`

## Contributing

This project was adapted from UNStatsExplorer. Contributions are welcome!

## License

[Specify your license here]

## Acknowledgments

- Based on the architecture of [UNStatsExplorer](../UNStatsExplorer)
- Data provided by [data.gov](https://data.gov)
- CKAN API by [CKAN Association](https://ckan.org)

## Related Projects

- **UNStatsExplorer**: Julia tool for exploring UN SDG data
- **CKAN**: Open-source data management system

## Contact

[Your contact information]
