"""
Non-interactive command-line interface for DataGovExplorer

Provides CLI commands for batch operations and scripting.
"""

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
- `results`: Results to display (DataFrame)
- `output_format::OutputFormat`: How to format the output
- `no_color::Bool`: Disable color output
"""
function display_cli_results(results, output_format::OutputFormat, no_color::Bool=false)
    if output_format == JSON
        # Convert DataFrame to JSON
        json_str = JSON3.write(results)
        println(json_str)
    elseif output_format == CSV
        # Write to stdout as CSV
        CSV.write(stdout, results)
    elseif output_format == PLAIN
        # Simple plain text output
        for row in DataFrames.eachrow(results)
            title = haskey(row, :title) ? row.title : row.name
            println(title)
        end
    else  # TABLE
        # Use PrettyTables for formatted output
        DataGovExplorer.display_table(results, max_rows=1000, show_summary=true)
    end
end

"""
Parse command-line arguments into a dictionary
"""
function parse_args(args::Vector{String})
    parsed = Dict{String, Any}()
    i = 1

    while i <= length(args)
        arg = args[i]

        if startswith(arg, "--")
            # Flag argument
            flag = arg[3:end]

            if flag == "no-color"
                parsed["no-color"] = true
                i += 1
            elseif i < length(args) && !startswith(args[i + 1], "--")
                # Flag with value
                parsed[flag] = args[i + 1]
                i += 2
            else
                # Boolean flag
                parsed[flag] = true
                i += 1
            end
        else
            # Positional argument
            if !haskey(parsed, "_positional")
                parsed["_positional"] = String[]
            end
            push!(parsed["_positional"], arg)
            i += 1
        end
    end

    return parsed
end

"""
Get positional argument at index (1-based)
"""
function get_positional(parsed::Dict, index::Int, default::String="")
    if haskey(parsed, "_positional") && length(parsed["_positional"]) >= index
        return parsed["_positional"][index]
    end
    return default
end

"""
Get flag value with default
"""
function get_flag(parsed::Dict, flag::String, default::Any)
    return get(parsed, flag, default)
end

"""
Search for datasets by keyword
"""
function cmd_search(args::Dict)
    query = get_positional(args, 2, "")

    if isempty(query)
        println("Error: Search query required")
        println("Usage: julia run_explorer.jl search <query> [--limit N] [--export file] [--output format] [--no-color]")
        return
    end

    limit = parse(Int, get_flag(args, "limit", "50"))
    export_path = get_flag(args, "export", "")
    output_format_str = get_flag(args, "output", "table")
    no_color = get_flag(args, "no-color", false)

    client = DataGovExplorer.CKANClient()

    if !no_color
        DataGovExplorer.print_loading("Searching for \"$query\"")
    end

    results = DataGovExplorer.search_packages(client, query=query, rows=limit)

    if !no_color
        DataGovExplorer.print_loaded("Found $(DataFrames.nrow(results)) datasets")
    end

    if DataFrames.nrow(results) == 0
        if !no_color
            DataGovExplorer.print_warning("No datasets found matching \"$query\"")
        else
            println("No results found")
        end
        return
    end

    # Handle export if requested
    if !isempty(export_path)
        DataGovExplorer.export_data(results, export_path)
        if !no_color
            DataGovExplorer.print_success("Exported $(DataFrames.nrow(results)) results to $export_path")
        else
            println("Exported to $export_path")
        end
    else
        # Display results
        output_format = parse_output_format(output_format_str)
        display_cli_results(results, output_format, no_color)
    end
end

"""
Browse datasets by organization
"""
function cmd_org(args::Dict)
    organization = get_positional(args, 2, "")

    if isempty(organization)
        println("Error: Organization name required")
        println("Usage: julia run_explorer.jl org <organization> [--limit N] [--export file] [--output format] [--no-color]")
        return
    end

    limit = parse(Int, get_flag(args, "limit", "50"))
    export_path = get_flag(args, "export", "")
    output_format_str = get_flag(args, "output", "table")
    no_color = get_flag(args, "no-color", false)

    client = DataGovExplorer.CKANClient()

    if !no_color
        DataGovExplorer.print_loading("Fetching datasets for organization \"$organization\"")
    end

    # Search for datasets by organization
    results = DataGovExplorer.search_packages(client, fq="organization:\"$organization\"", rows=limit)

    if !no_color
        DataGovExplorer.print_loaded("Found $(DataFrames.nrow(results)) datasets")
    end

    if DataFrames.nrow(results) == 0
        if !no_color
            DataGovExplorer.print_warning("No datasets found for organization \"$organization\"")
        else
            println("No results found")
        end
        return
    end

    # Handle export if requested
    if !isempty(export_path)
        DataGovExplorer.export_data(results, export_path)
        if !no_color
            DataGovExplorer.print_success("Exported $(DataFrames.nrow(results)) results to $export_path")
        else
            println("Exported to $export_path")
        end
    else
        # Display results
        output_format = parse_output_format(output_format_str)
        display_cli_results(results, output_format, no_color)
    end
end

"""
Browse datasets by tag
"""
function cmd_tag(args::Dict)
    tag_name = get_positional(args, 2, "")

    if isempty(tag_name)
        println("Error: Tag name required")
        println("Usage: julia run_explorer.jl tag <tag_name> [--limit N] [--export file] [--output format] [--no-color]")
        return
    end

    limit = parse(Int, get_flag(args, "limit", "50"))
    export_path = get_flag(args, "export", "")
    output_format_str = get_flag(args, "output", "table")
    no_color = get_flag(args, "no-color", false)

    client = DataGovExplorer.CKANClient()

    if !no_color
        DataGovExplorer.print_loading("Fetching datasets with tag \"$tag_name\"")
    end

    # Search for datasets by tag
    results = DataGovExplorer.search_packages(client, fq="tags:\"$tag_name\"", rows=limit)

    if !no_color
        DataGovExplorer.print_loaded("Found $(DataFrames.nrow(results)) datasets")
    end

    if DataFrames.nrow(results) == 0
        if !no_color
            DataGovExplorer.print_warning("No datasets found with tag \"$tag_name\"")
        else
            println("No results found")
        end
        return
    end

    # Handle export if requested
    if !isempty(export_path)
        DataGovExplorer.export_data(results, export_path)
        if !no_color
            DataGovExplorer.print_success("Exported $(DataFrames.nrow(results)) results to $export_path")
        else
            println("Exported to $export_path")
        end
    else
        # Display results
        output_format = parse_output_format(output_format_str)
        display_cli_results(results, output_format, no_color)
    end
end

"""
List recent datasets
"""
function cmd_recent(args::Dict)
    limit = parse(Int, get_flag(args, "limit", "20"))
    export_path = get_flag(args, "export", "")
    output_format_str = get_flag(args, "output", "table")
    no_color = get_flag(args, "no-color", false)

    client = DataGovExplorer.CKANClient()

    if !no_color
        DataGovExplorer.print_loading("Fetching recent datasets")
    end

    results = DataGovExplorer.search_packages(client, rows=limit)

    if !no_color
        DataGovExplorer.print_loaded("Fetched $(DataFrames.nrow(results)) datasets")
    end

    if DataFrames.nrow(results) == 0
        if !no_color
            DataGovExplorer.print_warning("No recent datasets found")
        else
            println("No results found")
        end
        return
    end

    # Handle export if requested
    if !isempty(export_path)
        DataGovExplorer.export_data(results, export_path)
        if !no_color
            DataGovExplorer.print_success("Exported $(DataFrames.nrow(results)) results to $export_path")
        else
            println("Exported to $export_path")
        end
    else
        # Display results
        output_format = parse_output_format(output_format_str)
        display_cli_results(results, output_format, no_color)
    end
end

"""
List all organizations
"""
function cmd_orgs(args::Dict)
    export_path = get_flag(args, "export", "")
    output_format_str = get_flag(args, "output", "table")
    no_color = get_flag(args, "no-color", false)

    client = DataGovExplorer.CKANClient()

    if !no_color
        DataGovExplorer.print_loading("Fetching organizations")
    end

    results = DataGovExplorer.get_organizations(client)

    if !no_color
        DataGovExplorer.print_loaded("Fetched $(DataFrames.nrow(results)) organizations")
    end

    if DataFrames.nrow(results) == 0
        if !no_color
            DataGovExplorer.print_warning("No organizations found")
        else
            println("No results found")
        end
        return
    end

    # Handle export if requested
    if !isempty(export_path)
        DataGovExplorer.export_data(results, export_path)
        if !no_color
            DataGovExplorer.print_success("Exported $(DataFrames.nrow(results)) results to $export_path")
        else
            println("Exported to $export_path")
        end
    else
        # Display results
        output_format = parse_output_format(output_format_str)
        display_cli_results(results, output_format, no_color)
    end
end

"""
Launch interactive explorer mode
"""
function cmd_interactive(args::Dict)
    DataGovExplorer.interactive_explorer()
end

"""
Display help message
"""
function show_help()
    println("""
DataGovExplorer CLI - Explore data.gov catalog from the command line

USAGE:
    julia run_explorer.jl [COMMAND] [OPTIONS]

COMMANDS:
    search <query>        Search for datasets by keyword
    org <organization>    Browse datasets from a specific organization
    tag <tag_name>        Browse datasets by tag
    recent                View recently updated datasets
    orgs                  List all organizations
    interactive           Launch interactive explorer mode
    help                  Show this help message

OPTIONS:
    --limit <N>          Maximum number of results (default varies by command)
    --export <file>      Export results to file (format detected from extension)
    --output <format>    Output format: table, json, csv, plain (default: table)
    --no-color           Disable colored output

EXAMPLES:
    # Search for datasets
    julia run_explorer.jl search "climate data" --limit 20

    # Export results directly
    julia run_explorer.jl search "climate" --export results.csv

    # Browse by organization
    julia run_explorer.jl org "Department of Commerce" --limit 50

    # Browse by tag with JSON output
    julia run_explorer.jl tag "environment" --output json

    # View recent datasets
    julia run_explorer.jl recent --limit 10

    # List all organizations
    julia run_explorer.jl orgs --export organizations.csv

For more information, visit: https://github.com/justin4957/DataGovExplorer
""")
end

"""
Main CLI entry point
"""
function cli_main(args::Vector{String})
    if length(args) == 0
        show_help()
        return
    end

    command = args[1]
    parsed_args = parse_args(args)

    if command == "search"
        cmd_search(parsed_args)
    elseif command == "org"
        cmd_org(parsed_args)
    elseif command == "tag"
        cmd_tag(parsed_args)
    elseif command == "recent"
        cmd_recent(parsed_args)
    elseif command == "orgs"
        cmd_orgs(parsed_args)
    elseif command == "interactive"
        cmd_interactive(parsed_args)
    elseif command == "help" || command == "--help" || command == "-h"
        show_help()
    else
        println("Error: Unknown command '$command'")
        println("Run 'julia run_explorer.jl help' for usage information")
    end
end
