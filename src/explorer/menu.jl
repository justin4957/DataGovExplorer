"""
Menu navigation and interaction logic for the interactive explorer
"""

"""
Interactive menu for exploring organizations
"""
function explore_organizations(client::CKANClient)
    orgs = get_organizations(client)

    if nrow(orgs) == 0
        print_warning("No organizations found")
        println("\nPress Enter to return...")
        readline()
        return
    end

    # Loop to allow browsing multiple organizations
    while true
        show_header("DATA.GOV ORGANIZATIONS ($(nrow(orgs)) total)")

        # Show numbered list instead of table for better readability
        display_numbered_list(orgs, title_col=:title, name_col=:name)

        println("\n📌 NAVIGATION:")
        println("  • Type a number (1-$(nrow(orgs))) to view organization datasets")
        println("  • Enter an organization name to search")
        println("  • Type 'table' or 't' to see detailed table view")
        println("  • Type 'export' or 'e' to save organization list")
        println("  • Type 'back' or 'b' to return to main menu")

        print("\nYour choice: ")
        choice = String(strip(readline()))

        if choice in ["back", "b", ""]
            break
        elseif choice in ["export", "e"]
            export_data(orgs, "datagov_organizations.csv")
            print_success("Exported to datagov_organizations.csv")
            println("\nPress Enter to continue...")
            readline()
        elseif choice in ["table", "t"]
            # Show detailed table view
            display_table(orgs, max_rows=20, show_summary=true)
            println("\nPress Enter to continue...")
            readline()
        else
            # Check if it's a number
            idx = tryparse(Int, choice)
            if !isnothing(idx) && 1 <= idx <= nrow(orgs)
                # Direct index selection
                org_name = orgs[idx, :name]
                explore_organization_datasets(client, org_name)
            else
                # Fuzzy search by name
                org_names = orgs.name
                org_titles = orgs.title

                result = get_validated_name(
                    "Confirm organization name: ",
                    org_names,
                    org_titles,
                    allow_empty=true,
                    fuzzy_threshold=0.5
                )

                if !isnothing(result[1])
                    explore_organization_datasets(client, result[1])
                end
            end
        end
    end
end

"""
Explore datasets for a specific organization
"""
function explore_organization_datasets(client::CKANClient, org_name::String)
    show_header("ORGANIZATION: $org_name - DATASETS")

    print_loading("Fetching datasets for organization")
    datasets = search_packages(client, organization=org_name, rows=100)
    print_loaded("Fetched $(nrow(datasets)) datasets")

    if nrow(datasets) == 0
        print_warning("No datasets found for organization $org_name")
        println("\nPress Enter to return...")
        readline()
        return
    end

    # Loop to allow browsing multiple datasets
    while true
        display_table(datasets, max_rows=20, show_summary=true)

        println("\n📌 NAVIGATION:")
        println("  • Type a number (1-$(nrow(datasets))) to view dataset details")
        println("  • Enter a dataset name to view details")
        println("  • Type 'list' or 'l' to see numbered list")
        println("  • Type 'export' or 'e' to save dataset list")
        println("  • Type 'back' or 'b' to return")

        print("\nYour choice: ")
        choice = String(strip(readline()))

        if choice in ["back", "b", ""]
            break
        elseif choice in ["export", "e"]
            filename = "org_$(org_name)_datasets.csv"
            export_data(datasets, filename)
            print_success("Exported to $filename")
            println("\nPress Enter to continue...")
            readline()
        elseif choice in ["list", "l"]
            # Show numbered list of datasets
            println("\n📋 DATASETS FROM '$org_name':")
            for (i, row) in enumerate(eachrow(datasets))
                if i <= 50
                    title = haskey(row, :title) ? row.title : row.name
                    println("  [$i] $(title)")
                end
            end
            if nrow(datasets) > 50
                println("  ... and $(nrow(datasets) - 50) more")
            end
            println()
        else
            # Check if it's a number
            idx = tryparse(Int, choice)
            if !isnothing(idx) && 1 <= idx <= nrow(datasets)
                # Direct index selection
                dataset_name = datasets[idx, :name]
                view_dataset_details(client, dataset_name)
            else
                # Validate dataset name with fuzzy matching
                if haskey(datasets, :name)
                    dataset_names = datasets.name
                    dataset_titles = haskey(datasets, :title) ? datasets.title : datasets.name

                    result = get_validated_name(
                        "Confirm dataset name: ",
                        dataset_names,
                        dataset_titles,
                        allow_empty=true,
                        fuzzy_threshold=0.6
                    )

                    if !isnothing(result[1])
                        view_dataset_details(client, result[1])
                    end
                end
            end
        end
    end
end

"""
View detailed information about a specific dataset
"""
function view_dataset_details(client::CKANClient, dataset_name::String)
    show_header("DATASET: $dataset_name")

    print_loading("Fetching dataset details")
    metadata = get_package_metadata(client, dataset_name)
    print_loaded("Fetched dataset metadata")

    if nrow(metadata) == 0
        print_warning("Failed to fetch dataset details")
        println("\nPress Enter to return...")
        readline()
        return
    end

    display_table(metadata, max_rows=50, show_summary=true)

    println("\n📌 OPTIONS:")
    println("  • Type 'export' or 'e' to save dataset metadata")
    println("  • Press Enter to return")

    print("\nYour choice: ")
    choice = strip(lowercase(readline()))

    if choice in ["export", "e"]
        filename = "dataset_$(dataset_name)_metadata.csv"
        export_data(metadata, filename)
        print_success("Exported to $filename")
        println("\nPress Enter to continue...")
        readline()
    end
end

"""
Search for datasets by keyword
"""
function search_datasets_menu(client::CKANClient)
    show_header("SEARCH DATASETS")

    println("\n🔍 SEARCH OPTIONS:")
    println("  Enter a search query (keywords to search for)")
    println("  Or type 'back' or 'b' to return")
    print("\nSearch query: ")

    query = String(strip(readline()))

    if query in ["back", "b", ""]
        return
    end

    print_loading("Searching for datasets matching '$query'")
    results = search_packages(client, query=query, rows=100)
    print_loaded("Found $(nrow(results)) datasets")

    if nrow(results) == 0
        print_warning("No datasets found matching '$query'")
        println("\n💡 Try:")
        println("  • Different keywords")
        println("  • Broader search terms")
        println("  • Check spelling")
        println("\nPress Enter to return...")
        readline()
        return
    end

    # Loop to allow browsing multiple datasets
    while true
        display_table(results, max_rows=20, show_summary=true)

        println("\n📌 OPTIONS:")
        println("  • Type a number (1-$(nrow(results))) to view dataset details")
        println("  • Enter a dataset name to view details")
        println("  • Type 'list' or 'l' to see numbered list")
        println("  • Type 'export' or 'e' to save search results")
        println("  • Type 'back' or 'b' to return")

        print("\nYour choice: ")
        choice = String(strip(readline()))

        if choice in ["back", "b", ""]
            break
        elseif choice in ["export", "e"]
            safe_query = replace(query, r"[^a-zA-Z0-9]" => "_")
            filename = "search_$(safe_query)_results.csv"
            export_data(results, filename)
            print_success("Exported to $filename")
            println("\nPress Enter to continue...")
            readline()
        elseif choice in ["list", "l"]
            # Show numbered list of datasets
            println("\n📋 SEARCH RESULTS:")
            for (i, row) in enumerate(eachrow(results))
                if i <= 50  # Limit to first 50
                    title = haskey(row, :title) ? row.title : row.name
                    println("  [$i] $(title)")
                end
            end
            if nrow(results) > 50
                println("  ... and $(nrow(results) - 50) more")
            end
            println()
        else
            # Check if it's a number
            idx = tryparse(Int, choice)
            if !isnothing(idx) && 1 <= idx <= nrow(results)
                # Direct index selection
                dataset_name = results[idx, :name]
                view_dataset_details(client, dataset_name)
            else
                # Validate dataset name with fuzzy matching
                if haskey(results, :name)
                    dataset_names = results.name
                    dataset_titles = haskey(results, :title) ? results.title : results.name

                    result = get_validated_name(
                        "Confirm dataset name: ",
                        dataset_names,
                        dataset_titles,
                        allow_empty=true,
                        fuzzy_threshold=0.6
                    )

                    if !isnothing(result[1])
                        view_dataset_details(client, result[1])
                    end
                end
            end
        end
    end
end

"""
Browse datasets by tags
"""
function browse_by_tags(client::CKANClient)
    show_header("BROWSE BY TAGS")

    print_loading("Fetching tags")
    tags = get_tags(client)
    print_loaded("Fetched $(nrow(tags)) tags")

    if nrow(tags) == 0
        print_warning("No tags found")
        println("\nPress Enter to return...")
        readline()
        return
    end

    display_table(tags, max_rows=30, show_summary=true)

    println("\n📌 NAVIGATION:")
    println("  • Enter a tag name to view datasets with that tag")
    println("  • Type 'export' or 'e' to save tag list")
    println("  • Type 'back' or 'b' to return")

    tag_names = tags.name
    tag_descs = tag_names  # Tags usually don't have separate descriptions

    result = get_validated_name(
        "\nYour choice: ",
        vcat(tag_names, ["back", "b", "export", "e"]),
        vcat(tag_descs, ["Return to main menu", "Return to main menu", "Export tag list", "Export tag list"]),
        allow_empty=true,
        fuzzy_threshold=0.5
    )

    if isnothing(result[1]) || result[1] in ["back", "b"]
        return
    elseif result[1] in ["export", "e"]
        export_data(tags, "datagov_tags.csv")
        print_success("Exported to datagov_tags.csv")
        println("\nPress Enter to continue...")
        readline()
    else
        browse_datasets_by_tag(client, result[1])
    end
end

"""
Browse datasets by a specific tag
"""
function browse_datasets_by_tag(client::CKANClient, tag_name::String)
    show_header("TAG: $tag_name - DATASETS")

    print_loading("Fetching datasets with tag '$tag_name'")
    datasets = search_packages(client, tags=[tag_name], rows=100)
    print_loaded("Fetched $(nrow(datasets)) datasets")

    if nrow(datasets) == 0
        print_warning("No datasets found with tag '$tag_name'")
        println("\nPress Enter to return...")
        readline()
        return
    end

    # Loop to allow browsing multiple datasets
    while true
        display_table(datasets, max_rows=20, show_summary=true)

        println("\n📌 OPTIONS:")
        println("  • Type a number (1-$(nrow(datasets))) to view dataset details")
        println("  • Enter a dataset name to view details")
        println("  • Type 'list' or 'l' to see numbered list")
        println("  • Type 'export' or 'e' to save dataset list")
        println("  • Type 'back' or 'b' to return")

        print("\nYour choice: ")
        choice = String(strip(readline()))

        if choice in ["back", "b", ""]
            break
        elseif choice in ["export", "e"]
            safe_tag = replace(tag_name, r"[^a-zA-Z0-9]" => "_")
            filename = "tag_$(safe_tag)_datasets.csv"
            export_data(datasets, filename)
            print_success("Exported to $filename")
            println("\nPress Enter to continue...")
            readline()
        elseif choice in ["list", "l"]
            # Show numbered list of datasets
            println("\n📋 DATASETS WITH TAG '$tag_name':")
            for (i, row) in enumerate(eachrow(datasets))
                if i <= 50
                    title = haskey(row, :title) ? row.title : row.name
                    println("  [$i] $(title)")
                end
            end
            if nrow(datasets) > 50
                println("  ... and $(nrow(datasets) - 50) more")
            end
            println()
        else
            # Check if it's a number
            idx = tryparse(Int, choice)
            if !isnothing(idx) && 1 <= idx <= nrow(datasets)
                # Direct index selection
                dataset_name = datasets[idx, :name]
                view_dataset_details(client, dataset_name)
            else
                # Validate dataset name with fuzzy matching
                if haskey(datasets, :name)
                    dataset_names = datasets.name
                    dataset_titles = haskey(datasets, :title) ? datasets.title : datasets.name

                    result = get_validated_name(
                        "Confirm dataset name: ",
                        dataset_names,
                        dataset_titles,
                        allow_empty=true,
                        fuzzy_threshold=0.6
                    )

                    if !isnothing(result[1])
                        view_dataset_details(client, result[1])
                    end
                end
            end
        end
    end
end

"""
Prompt user to export data
"""
function export_choice(df::DataFrame, base_name::String)
    println("\n💾 EXPORT OPTIONS:")
    println("  • Type 'csv' or 'c' for CSV format")
    println("  • Type 'json' or 'j' for JSON format")
    println("  • Type 'arrow' or 'a' for Arrow format (efficient binary)")
    println("  • Type 'excel' or 'x' for Excel format")
    println("  • Type 'no' or 'n' to skip export")
    print("\nExport format (or skip): ")

    choice = strip(lowercase(readline()))

    format_map = Dict(
        "csv" => ".csv", "c" => ".csv",
        "json" => ".json", "j" => ".json",
        "arrow" => ".arrow", "a" => ".arrow",
        "excel" => ".xlsx", "x" => ".xlsx"
    )

    if haskey(format_map, choice)
        filename = "$(base_name)_$(Dates.format(now(), "yyyymmdd_HHMMSS"))$(format_map[choice])"
        export_data(df, filename)
        print_success("Exported $(nrow(df)) rows to: $filename")
        println("\nPress Enter to continue...")
        readline()
    elseif choice in ["no", "n", ""]
        # Skip export
    else
        print_warning("Invalid format. Export skipped.")
        println("\nPress Enter to continue...")
        readline()
    end
end
