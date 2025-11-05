"""
Interactive CLI explorer for browsing data.gov catalog
"""

using REPL

# Include explorer modules
include("explorer/display.jl")
include("explorer/input.jl")
include("explorer/menu.jl")

"""
Main interactive explorer entry point
"""
function interactive_explorer()
    println("\n" * "="^70)
    println("DATA.GOV CATALOG EXPLORER")
    println("="^70)
    println("\nInitializing client...")

    client = CKANClient()

    # Set colors based on config
    set_colors_enabled(client.config.colors_enabled)

    while true
        println("\n" * "-"^70)
        println("MAIN MENU")
        println("-"^70)
        println("  [o] - Browse Organizations")
        println("  [s] - Search Datasets")
        println("  [t] - Browse by Tags")
        println("  [r] - Recent Datasets")
        println("  [q] - Quit")
        print("\nChoice: ")

        choice = lowercase(strip(readline()))

        if choice == "o"
            explore_organizations(client)
        elseif choice == "s"
            search_datasets_menu(client)
        elseif choice == "t"
            browse_by_tags(client)
        elseif choice == "r"
            show_header("RECENT DATASETS")

            print_loading("Fetching recent datasets")
            recent = search_packages(client, rows=50)
            print_loaded("Fetched $(nrow(recent)) datasets")

            if nrow(recent) > 0
                # Loop to allow browsing multiple datasets
                while true
                    display_table(recent, max_rows=20, show_summary=true)

                    println("\n📌 OPTIONS:")
                    println("  • Type a number (1-$(nrow(recent))) to view dataset details")
                    println("  • Enter a dataset name to view details")
                    println("  • Type 'list' or 'l' to see numbered list")
                    println("  • Type 'export' or 'e' to save dataset list")
                    println("  • Press Enter to return to main menu")

                    print("\nYour choice: ")
                    dataset_choice = String(strip(readline()))

                    if dataset_choice == ""
                        break
                    elseif dataset_choice in ["export", "e"]
                        export_data(recent, "recent_datasets.csv")
                        print_success("Exported to recent_datasets.csv")
                        println("\nPress Enter to continue...")
                        readline()
                    elseif dataset_choice in ["list", "l"]
                        # Show numbered list of datasets
                        println("\n📋 RECENT DATASETS:")
                        for (i, row) in enumerate(eachrow(recent))
                            title = haskey(row, :title) ? row.title : row.name
                            println("  [$i] $(title)")
                        end
                        println()
                    else
                        # Check if it's a number
                        idx = tryparse(Int, dataset_choice)
                        if !isnothing(idx) && 1 <= idx <= nrow(recent)
                            # Direct index selection
                            dataset_name = recent[idx, :name]
                            view_dataset_details(client, dataset_name)
                        elseif !isempty(dataset_choice)
                            # Validate dataset name
                            if :name in propertynames(recent)
                                dataset_names = recent.name
                                dataset_titles = :title in propertynames(recent) ? recent.title : recent.name

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
            else
                print_warning("No recent datasets found")
                println("\nPress Enter to continue...")
                readline()
            end
        elseif choice == "q"
            print_info("Goodbye!")
            break
        else
            print_error("Invalid choice. Please try again.")
        end
    end
end
