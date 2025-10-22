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
                display_table(recent, max_rows=20, show_summary=true)

                println("\n📌 OPTIONS:")
                println("  • Enter a dataset name to view details")
                println("  • Type 'export' or 'e' to save dataset list")
                println("  • Press Enter to return to main menu")

                print("\nYour choice: ")
                dataset_choice = strip(readline())

                if dataset_choice in ["export", "e"]
                    export_data(recent, "recent_datasets.csv")
                    print_success("Exported to recent_datasets.csv")
                    println("\nPress Enter to continue...")
                    readline()
                elseif !isempty(dataset_choice)
                    # Validate dataset name
                    if haskey(recent, :name)
                        dataset_names = recent.name
                        dataset_titles = haskey(recent, :title) ? recent.title : recent.name

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
