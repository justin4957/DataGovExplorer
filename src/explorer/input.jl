"""
Input handling utilities for the interactive explorer
Handles user input parsing and validation
"""

"""
Parse comma-separated input into vector of strings
"""
function parse_list_input(input::String)::Vector{String}
    if isempty(strip(input))
        return String[]
    end
    return [strip(item) for item in split(input, ",")]
end

"""
Find fuzzy matches using Jaro-Winkler distance
Returns vector of tuples: (name, description, similarity_score)
"""
function find_fuzzy_matches(
    input::String,
    valid_names::Vector{String},
    descriptions::Vector{String};
    threshold::Float64=0.6,
    max_results::Int=5
)::Vector{Tuple{String, String, Float64}}
    matches = Tuple{String, String, Float64}[]
    input_lower = lowercase(input)

    for (name, desc) in zip(valid_names, descriptions)
        # Check name similarity
        name_score = compare(input_lower, lowercase(name), JaroWinkler())

        # Check description similarity (weighted lower to prioritize exact name matches)
        desc_score = compare(input_lower, lowercase(desc), JaroWinkler()) * 0.85

        # Use the better score
        max_score = max(name_score, desc_score)

        if max_score >= threshold
            push!(matches, (name, desc, max_score))
        end
    end

    # Sort by score (descending) and take top N
    sort!(matches, by=x->x[3], rev=true)
    return matches[1:min(max_results, end)]
end

"""
Get validated name with fuzzy matching suggestions
Returns: (validated_name, was_corrected)
"""
function get_validated_name(
    prompt::String,
    valid_names::Vector{String},
    descriptions::Vector{String};
    allow_empty::Bool=false,
    fuzzy_threshold::Float64=0.6
)::Union{Tuple{String, Bool}, Tuple{Nothing, Bool}}

    while true
        print(prompt)
        input = String(strip(readline()))

        # Handle empty input
        if isempty(input)
            if allow_empty
                return (nothing, false)
            else
                print_warning("Input cannot be empty. Please try again.")
                continue
            end
        end

        # Check for exact match (case-insensitive)
        exact_match_idx = findfirst(x -> lowercase(x) == lowercase(input), valid_names)
        if !isnothing(exact_match_idx)
            name = valid_names[exact_match_idx]
            print_success("Selected: $(descriptions[exact_match_idx])")
            return (name, false)
        end

        # Try fuzzy matching
        suggestions = find_fuzzy_matches(input, valid_names, descriptions, threshold=fuzzy_threshold)

        if !isempty(suggestions)
            println("\n💡 Did you mean:")
            for (i, (name, desc, score)) in enumerate(suggestions)
                score_pct = round(Int, score * 100)
                # Truncate description if too long
                short_desc = length(desc) > 60 ? desc[1:57] * "..." : desc
                println("  [$i] $name - $short_desc ($(score_pct)% match)")
            end
            println("  [r] Re-enter")
            println("  [l] List all available options")

            print("\nYour choice: ")
            choice = String(strip(readline()))

            if choice == "r" || choice == ""
                continue
            elseif choice == "l"
                println("\n📋 Available options:")
                for (i, (name, desc)) in enumerate(zip(valid_names, descriptions))
                    if i <= 20
                        short_desc = length(desc) > 60 ? desc[1:57] * "..." : desc
                        println("  $name - $short_desc")
                    end
                end
                if length(valid_names) > 20
                    println("  ... and $(length(valid_names) - 20) more")
                end
                println()
                continue
            else
                # Try to parse as number
                idx = tryparse(Int, choice)
                if !isnothing(idx) && 1 <= idx <= length(suggestions)
                    selected_name = suggestions[idx][1]
                    selected_desc = suggestions[idx][2]
                    print_success("Selected: $selected_desc")
                    return (selected_name, true)
                else
                    print_warning("Invalid choice. Please try again.")
                    continue
                end
            end
        else
            println("\n⚠️  No matches found for '$input'")
            println("\n💡 Tips:")
            println("  • Check spelling")
            println("  • Try a shorter search term")
            println("  • Type 'list' to see available options")

            print("\nTry again? (y/n): ")
            retry = lowercase(strip(readline()))
            if retry != "y"
                return (nothing, false)
            end
        end
    end
end

"""
Validate multiple names from already-entered input
Returns vector of validated names without re-prompting
"""
function validate_multi_names(
    input::String,
    valid_names::Vector{String},
    descriptions::Vector{String};
    fuzzy_threshold::Float64=0.7
)::Vector{String}

    if isempty(strip(input))
        return String[]
    end

    selected = String[]
    parts = parse_list_input(input)

    for part in parts
        # Check for exact match
        exact_idx = findfirst(x -> lowercase(x) == lowercase(part), valid_names)

        if !isnothing(exact_idx)
            name = valid_names[exact_idx]
            push!(selected, name)
            print_success("Added: $name")
        else
            # Try fuzzy match for auto-correction
            suggestions = find_fuzzy_matches(part, valid_names, descriptions, threshold=fuzzy_threshold, max_results=1)

            if !isempty(suggestions)
                # Auto-correct if found above threshold
                name = suggestions[1][1]
                desc = suggestions[1][2]
                score_pct = round(Int, suggestions[1][3] * 100)
                push!(selected, name)
                print_info("Auto-corrected '$part' → '$desc' ($(score_pct)% match)")
            else
                print_warning("Skipping invalid name: '$part'")
            end
        end
    end

    return selected
end

"""
Get multiple validated names with fuzzy matching
Returns vector of validated names
"""
function get_multi_validated_names(
    prompt::String,
    valid_names::Vector{String},
    descriptions::Vector{String};
    fuzzy_threshold::Float64=0.7
)::Vector{String}

    println(prompt)
    println("(Enter comma-separated values)")
    input = String(strip(readline()))

    return validate_multi_names(input, valid_names, descriptions, fuzzy_threshold=fuzzy_threshold)
end
