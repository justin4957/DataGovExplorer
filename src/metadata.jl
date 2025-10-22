"""
Metadata retrieval functions for CKAN API (data.gov catalog)
"""

"""
Get list of all packages (datasets) with pagination support
"""
function get_packages(
    client::CKANClient;
    limit::Union{Int, Nothing}=nothing,
    force_refresh::Bool=false
)
    cache_key = "packages_$(limit)"

    if !force_refresh && haskey(client.cache, cache_key)
        @info "Using cached package list"
        return client.cache[cache_key]
    end

    @info "Fetching package list from API..."

    params = Dict{String, String}()

    if !isnothing(limit)
        # For limited queries, use package_list
        response = safe_get(client, "action/package_list", params)

        if get(response, :success, false)
            packages = get(response, :result, [])
            if limit < length(packages)
                packages = packages[1:limit]
            end

            df = DataFrame(name=packages)
        else
            @warn "Failed to fetch package list"
            df = DataFrame()
        end
    else
        # For full queries, use package_search with pagination
        packages = fetch_all_pages(client, "action/package_search", params)

        # Convert to DataFrame
        if !isempty(packages)
            df = DataFrame(packages)
        else
            df = DataFrame()
        end
    end

    client.cache[cache_key] = df
    @info "Retrieved $(nrow(df)) packages"

    return df
end

"""
Get detailed information about a specific package
"""
function get_package_details(client::CKANClient, package_id::String)
    @info "Fetching package details..." package_id

    params = Dict("id" => package_id)
    response = safe_get(client, "action/package_show", params)

    if !get(response, :success, false)
        @error "Failed to fetch package details" package_id
        return nothing
    end

    return get(response, :result, nothing)
end

"""
Search for packages matching query criteria
"""
function search_packages(
    client::CKANClient;
    query::Union{String, Nothing}=nothing,
    filter_query::Union{String, Nothing}=nothing,
    organization::Union{String, Nothing}=nothing,
    tags::Union{Vector{String}, Nothing}=nothing,
    rows::Int=100
)
    @info "Searching packages..." query filter_query organization

    params = Dict{String, String}("rows" => string(rows))

    if !isnothing(query)
        params["q"] = query
    end

    if !isnothing(filter_query)
        params["fq"] = filter_query
    end

    # Build filter query for organization and tags
    filters = String[]
    if !isnothing(organization)
        push!(filters, "organization:$organization")
    end
    if !isnothing(tags) && !isempty(tags)
        tag_filter = join(["tags:$tag" for tag in tags], " AND ")
        push!(filters, tag_filter)
    end

    if !isempty(filters)
        existing_fq = get(params, "fq", "")
        if !isempty(existing_fq)
            params["fq"] = "$existing_fq AND " * join(filters, " AND ")
        else
            params["fq"] = join(filters, " AND ")
        end
    end

    packages = fetch_all_pages(client, "action/package_search", params)

    if !isempty(packages)
        return DataFrame(packages)
    else
        return DataFrame()
    end
end

"""
Get list of all organizations
"""
function get_organizations(
    client::CKANClient;
    force_refresh::Bool=false
)
    cache_key = "organizations"

    if !force_refresh && haskey(client.cache, cache_key)
        @info "Using cached organization list"
        return client.cache[cache_key]
    end

    @info "Fetching organization list from API..."

    params = Dict("all_fields" => "true")
    response = safe_get(client, "action/organization_list", params)

    if !get(response, :success, false)
        @warn "Failed to fetch organization list"
        return DataFrame()
    end

    organizations = get(response, :result, [])

    if !isempty(organizations)
        df = DataFrame(organizations)
    else
        df = DataFrame()
    end

    client.cache[cache_key] = df
    @info "Retrieved $(nrow(df)) organizations"

    return df
end

"""
Get list of all groups
"""
function get_groups(
    client::CKANClient;
    force_refresh::Bool=false
)
    cache_key = "groups"

    if !force_refresh && haskey(client.cache, cache_key)
        @info "Using cached group list"
        return client.cache[cache_key]
    end

    @info "Fetching group list from API..."

    params = Dict("all_fields" => "true")
    response = safe_get(client, "action/group_list", params)

    if !get(response, :success, false)
        @warn "Failed to fetch group list"
        return DataFrame()
    end

    groups = get(response, :result, [])

    if !isempty(groups)
        df = DataFrame(groups)
    else
        df = DataFrame()
    end

    client.cache[cache_key] = df
    @info "Retrieved $(nrow(df)) groups"

    return df
end

"""
Get list of all tags used in the catalog
"""
function get_tags(
    client::CKANClient;
    force_refresh::Bool=false
)
    cache_key = "tags"

    if !force_refresh && haskey(client.cache, cache_key)
        @info "Using cached tag list"
        return client.cache[cache_key]
    end

    @info "Fetching tag list from API..."

    params = Dict("all_fields" => "true")
    response = safe_get(client, "action/tag_list", params)

    if !get(response, :success, false)
        @warn "Failed to fetch tag list"
        return DataFrame()
    end

    tags = get(response, :result, [])

    if !isempty(tags)
        # Tags might be simple strings or objects
        if !isempty(tags) && isa(tags[1], String)
            df = DataFrame(name=tags)
        else
            df = DataFrame(tags)
        end
    else
        df = DataFrame()
    end

    client.cache[cache_key] = df
    @info "Retrieved $(nrow(df)) tags"

    return df
end

"""
Get metadata about a specific package (dataset) and return as DataFrame
"""
function get_package_metadata(client::CKANClient, package_id::String)
    details = get_package_details(client, package_id)

    if isnothing(details)
        return DataFrame()
    end

    # Extract key metadata fields
    metadata = Dict(
        "id" => get(details, :id, ""),
        "name" => get(details, :name, ""),
        "title" => get(details, :title, ""),
        "author" => get(details, :author, ""),
        "maintainer" => get(details, :maintainer, ""),
        "license_title" => get(details, :license_title, ""),
        "notes" => get(details, :notes, ""),
        "metadata_created" => get(details, :metadata_created, ""),
        "metadata_modified" => get(details, :metadata_modified, ""),
        "organization" => get(get(details, :organization, Dict()), :title, ""),
        "num_resources" => length(get(details, :resources, [])),
        "num_tags" => length(get(details, :tags, []))
    )

    return DataFrame([metadata])
end
