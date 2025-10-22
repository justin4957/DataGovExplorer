"""
Display utilities for the interactive explorer
Handles table formatting and presentation
"""

# Color definitions for consistent styling
const COLOR_SUCCESS = Crayon(foreground = :green, bold = true)
const COLOR_ERROR = Crayon(foreground = :red, bold = true)
const COLOR_WARNING = Crayon(foreground = :yellow, bold = true)
const COLOR_INFO = Crayon(foreground = :blue)
const COLOR_HEADER = Crayon(foreground = :cyan, bold = true)
const COLOR_HIGHLIGHT = Crayon(foreground = :magenta)
const COLOR_RESET = Crayon(reset = true)

"""
Print colored success message
"""
function print_success(msg::String)
    println(COLOR_SUCCESS, "✓ ", msg, COLOR_RESET)
end

"""
Print colored error message
"""
function print_error(msg::String)
    println(COLOR_ERROR, "✗ ", msg, COLOR_RESET)
end

"""
Print colored warning message
"""
function print_warning(msg::String)
    println(COLOR_WARNING, "⚠  ", msg, COLOR_RESET)
end

"""
Print colored info message
"""
function print_info(msg::String)
    println(COLOR_INFO, "ℹ  ", msg, COLOR_RESET)
end

"""
Print colored header
"""
function print_header(text::String)
    println(COLOR_HEADER, text, COLOR_RESET)
end

"""
Print colored highlight text
"""
function print_highlight(text::String)
    println(COLOR_HIGHLIGHT, text, COLOR_RESET)
end

"""
Print loading message for long-running operation
"""
function print_loading(msg::String)
    print(COLOR_INFO, "⏳ ", msg, "...", COLOR_RESET)
    flush(stdout)
end

"""
Clear loading message and print completion
"""
function print_loaded(msg::String="Done")
    print("\r\033[K")  # Clear line
    print_success(msg)
end

"""
Execute a function with loading indicator
"""
function with_loading(f::Function, loading_msg::String, success_msg::String="Done")
    print_loading(loading_msg)
    result = f()
    print_loaded(success_msg)
    return result
end

"""
Show summary statistics for DataFrame
"""
function show_data_summary(df::DataFrame)
    println("\n" * "="^70)
    print_header("📊 DATA SUMMARY")
    println("="^70)
    println("  Total rows: $(nrow(df))")
    println("  Total columns: $(ncol(df))")

    if ncol(df) > 0
        println("  Columns: $(join(names(df), ", "))")
    end

    # Show unique values for key columns
    for col in [:name, :title, :organization, :id, :display_name]
        if col in propertynames(df)
            unique_vals = unique(skipmissing(df[!, col]))
            unique_count = length(unique_vals)
            if unique_count <= 5
                println("  Unique $col: $(join(unique_vals, ", "))")
            else
                println("  Unique $col: $unique_count")
            end
        end
    end
    println("="^70)
end

"""
Display DataFrame with smart formatting and summary
"""
function display_table(df::DataFrame; max_rows::Int=20, show_summary::Bool=true)
    # Show summary first
    if show_summary && nrow(df) > 0
        show_data_summary(df)
    end

    if nrow(df) == 0
        print_warning("No data to display")
        return
    end

    # Reorder columns to show most important first
    df_display = reorder_columns(df)

    # Display table
    if nrow(df_display) > max_rows
        println("\nShowing first $max_rows of $(nrow(df_display)) rows:")
        pretty_table(first(df_display, max_rows),
            maximum_number_of_columns=10,
            maximum_number_of_rows=max_rows,
            crop=:horizontal)
        println("\n... $(nrow(df_display) - max_rows) more rows (use export to save all)")
    else
        println()
        pretty_table(df_display,
            maximum_number_of_columns=10,
            crop=:horizontal)
    end
end

"""
Reorder DataFrame columns to show most important first
"""
function reorder_columns(df::DataFrame)
    cols = names(df)

    # Priority order for columns
    priority_cols = [:name, :title, :package_count, :description, :num_resources,
                     :num_tags, :organization, :author, :maintainer, :license_title,
                     :metadata_created, :metadata_modified, :state, :type, :id]

    # Build ordered column list
    ordered_cols = Symbol[]

    # Add priority columns that exist
    for col in priority_cols
        if col in Symbol.(cols)
            push!(ordered_cols, col)
        end
    end

    # Add remaining columns
    for col in Symbol.(cols)
        if !(col in ordered_cols)
            push!(ordered_cols, col)
        end
    end

    # Return reordered DataFrame
    return df[:, ordered_cols]
end

"""
Display a numbered list of items (organizations, datasets, etc.)
"""
function display_numbered_list(df::DataFrame; title_col::Symbol=:title, name_col::Symbol=:name, max_items::Int=50)
    println()
    for (i, row) in enumerate(eachrow(df))
        if i > max_items
            println("  ... and $(nrow(df) - max_items) more (type 'export' to save full list)")
            break
        end

        # Get display text - prefer title, fallback to name
        display_text = ""
        if title_col in propertynames(row) && !ismissing(row[title_col]) && !isempty(string(row[title_col]))
            display_text = string(row[title_col])
        elseif name_col in propertynames(row) && !ismissing(row[name_col]) && !isempty(string(row[name_col]))
            display_text = string(row[name_col])
        else
            display_text = "Item $i"
        end

        # Show package count if available
        count_info = ""
        if :package_count in propertynames(row) && !ismissing(row[:package_count])
            count_info = " ($(row[:package_count]) datasets)"
        elseif :num_resources in propertynames(row) && !ismissing(row[:num_resources])
            count_info = " ($(row[:num_resources]) resources)"
        end

        # Truncate long names
        max_length = 70
        if length(display_text) > max_length
            display_text = display_text[1:max_length-3] * "..."
        end

        println("  [$i] $(display_text)$(count_info)")
    end
    println()
end

"""
Clear screen for better navigation
"""
function clear_screen()
    print("\033[2J\033[H")
end

"""
Show a separator line
"""
function show_separator(char::String="─", width::Int=70)
    println(char^width)
end

"""
Show a prominent header
"""
function show_header(text::String)
    println("\n" * "="^70)
    print_header(text)
    println("="^70)
end
