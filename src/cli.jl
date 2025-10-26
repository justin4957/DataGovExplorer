"""
Non-interactive command-line interface for DataGovExplorer

Provides CLI commands for batch operations and scripting.
"""

using Comonicon

"""
Output format options for CLI commands
"""
@enum OutputFormat begin
    TABLE
    JSON
    CSV
    PLAIN
end

"""
Parse output format string to OutputFormat enum
"""
function parse_output_format(format_str::String)::OutputFormat
    format_lower = lowercase(format_str)
    if format_lower == "json"
        return JSON
    elseif format_lower == "csv"
        return CSV
    elseif format_lower == "plain"
        return PLAIN
    else
        return TABLE
    end
end

"""
Display results based on output format

# Arguments
- `results::DataFrame`: Results to display
- `output_format::OutputFormat`: How to format the output
- `no_color::Bool`: Disable color output
"""
function display_cli_results(results::DataFrame, output_format::OutputFormat, no_color::Bool=false)
    if output_format == JSON
        # Convert DataFrame to JSON
        json_str = JSON3.write(results)
        println(json_str)
    elseif output_format == CSV
        # Write to stdout as CSV
        CSV.write(stdout, results)
    elseif output_format == PLAIN
        # Simple plain text output
        for row in eachrow(results)
            title = haskey(row, :title) ? row.title : row.name
            println(title)
        end
    else  # TABLE
        # Use PrettyTables for formatted output
        if no_color
            display_table(results, max_rows=1000, show_summary=true)
        else
            display_table(results, max_rows=1000, show_summary=true)
        end
    end
end

"""
Search for datasets by keyword

# Arguments
- `query::String`: Search query string
- `limit::Int`: Maximum number of results (default: 50)
- `export_path::String`: Optional export file path
- `output_format::String`: Output format (table, json, csv, plain)
- `no_color::Bool`: Disable color output

# Example
```bash
julia run_explorer.jl search "climate data" --limit 20 --output json
```
"""
@main function search(
    query::String;
    limit::Int = 50,
    export::String = "",
    output::String = "table",
    no_color::Bool = false
)
    client = CKANClient()

    if !no_color
        print_loading("Searching for \"$query\"")
    end

    results = search_packages(client, q=query, rows=limit)

    if !no_color
        print_loaded("Found $(nrow(results)) datasets")
    end

    if nrow(results) == 0
        if !no_color
            print_warning("No datasets found matching \"$query\"")
        else
            println("No results found")
        end
        return
    end

    # Handle export if requested
    if !isempty(export)
        export_data(results, export)
        if !no_color
            print_success("Exported $(nrow(results)) results to $export")
        else
            println("Exported to $export")
        end
    else
        # Display results
        output_format = parse_output_format(output)
        display_cli_results(results, output_format, no_color)
    end
end

"""
Browse datasets by organization

# Arguments
- `organization::String`: Organization name or ID
- `limit::Int`: Maximum number of results (default: 50)
- `export_path::String`: Optional export file path
- `output_format::String`: Output format (table, json, csv, plain)
- `no_color::Bool`: Disable color output

# Example
```bash
julia run_explorer.jl org "Department of Commerce" --limit 20
```
"""
@cast function org(
    organization::String;
    limit::Int = 50,
    export::String = "",
    output::String = "table",
    no_color::Bool = false
)
    client = CKANClient()

    if !no_color
        print_loading("Fetching datasets for organization \"$organization\"")
    end

    # Search for datasets by organization
    results = search_packages(client, fq="organization:\"$organization\"", rows=limit)

    if !no_color
        print_loaded("Found $(nrow(results)) datasets")
    end

    if nrow(results) == 0
        if !no_color
            print_warning("No datasets found for organization \"$organization\"")
        else
            println("No results found")
        end
        return
    end

    # Handle export if requested
    if !isempty(export)
        export_data(results, export)
        if !no_color
            print_success("Exported $(nrow(results)) results to $export")
        else
            println("Exported to $export")
        end
    else
        # Display results
        output_format = parse_output_format(output)
        display_cli_results(results, output_format, no_color)
    end
end

"""
Browse datasets by tag

# Arguments
- `tag::String`: Tag name
- `limit::Int`: Maximum number of results (default: 50)
- `export_path::String`: Optional export file path
- `output_format::String`: Output format (table, json, csv, plain)
- `no_color::Bool`: Disable color output

# Example
```bash
julia run_explorer.jl tag "environment" --limit 30
```
"""
@cast function tag(
    tag_name::String;
    limit::Int = 50,
    export::String = "",
    output::String = "table",
    no_color::Bool = false
)
    client = CKANClient()

    if !no_color
        print_loading("Fetching datasets with tag \"$tag_name\"")
    end

    # Search for datasets by tag
    results = search_packages(client, fq="tags:\"$tag_name\"", rows=limit)

    if !no_color
        print_loaded("Found $(nrow(results)) datasets")
    end

    if nrow(results) == 0
        if !no_color
            print_warning("No datasets found with tag \"$tag_name\"")
        else
            println("No results found")
        end
        return
    end

    # Handle export if requested
    if !isempty(export)
        export_data(results, export)
        if !no_color
            print_success("Exported $(nrow(results)) results to $export")
        else
            println("Exported to $export")
        end
    else
        # Display results
        output_format = parse_output_format(output)
        display_cli_results(results, output_format, no_color)
    end
end

"""
List recent datasets

# Arguments
- `limit::Int`: Maximum number of results (default: 20)
- `export_path::String`: Optional export file path
- `output_format::String`: Output format (table, json, csv, plain)
- `no_color::Bool`: Disable color output

# Example
```bash
julia run_explorer.jl recent --limit 10 --output json
```
"""
@cast function recent(;
    limit::Int = 20,
    export::String = "",
    output::String = "table",
    no_color::Bool = false
)
    client = CKANClient()

    if !no_color
        print_loading("Fetching recent datasets")
    end

    results = search_packages(client, rows=limit)

    if !no_color
        print_loaded("Fetched $(nrow(results)) datasets")
    end

    if nrow(results) == 0
        if !no_color
            print_warning("No recent datasets found")
        else
            println("No results found")
        end
        return
    end

    # Handle export if requested
    if !isempty(export)
        export_data(results, export)
        if !no_color
            print_success("Exported $(nrow(results)) results to $export")
        else
            println("Exported to $export")
        end
    else
        # Display results
        output_format = parse_output_format(output)
        display_cli_results(results, output_format, no_color)
    end
end

"""
List all organizations

# Arguments
- `export_path::String`: Optional export file path
- `output_format::String`: Output format (table, json, csv, plain)
- `no_color::Bool`: Disable color output

# Example
```bash
julia run_explorer.jl orgs --export organizations.csv
```
"""
@cast function orgs(;
    export::String = "",
    output::String = "table",
    no_color::Bool = false
)
    client = CKANClient()

    if !no_color
        print_loading("Fetching organizations")
    end

    results = get_organizations(client)

    if !no_color
        print_loaded("Fetched $(nrow(results)) organizations")
    end

    if nrow(results) == 0
        if !no_color
            print_warning("No organizations found")
        else
            println("No results found")
        end
        return
    end

    # Handle export if requested
    if !isempty(export)
        export_data(results, export)
        if !no_color
            print_success("Exported $(nrow(results)) results to $export")
        else
            println("Exported to $export")
        end
    else
        # Display results
        output_format = parse_output_format(output)
        display_cli_results(results, output_format, no_color)
    end
end

"""
Launch interactive explorer mode

# Example
```bash
julia run_explorer.jl interactive
```
"""
@cast function interactive()
    interactive_explorer()
end
