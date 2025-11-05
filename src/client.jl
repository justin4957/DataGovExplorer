"""
Main client for interacting with CKAN API (data.gov) with caching and rate limiting
"""
mutable struct CKANClient
    config::CKANConfig
    last_request_time::Float64
    cache::Dict{String, Any}
    headers::Dict{String, String}

    function CKANClient(config::Union{CKANConfig, Nothing}=nothing)
        # Load config from file if not provided
        actual_config = isnothing(config) ? load_config() : config

        headers = Dict(
            "Content-Type" => "application/json",
            "Accept" => "application/json",
            "Accept-Encoding" => "gzip"
        )
        new(actual_config, 0.0, Dict{String, Any}(), headers)
    end
end

"""
Rate-limited HTTP GET request with exponential backoff retry logic
"""
function safe_get(client::CKANClient, endpoint::String, params::Dict=Dict())
    # Implement rate limiting
    elapsed_time = (time() - client.last_request_time) * 1000
    if elapsed_time < client.config.rate_limit_ms
        sleep((client.config.rate_limit_ms - elapsed_time) / 1000)
    end

    url = joinpath(client.config.base_url, endpoint)

    for attempt in 1:client.config.max_retries
        try
            response = HTTP.get(
                url,
                client.headers,
                query=params,
                readtimeout=client.config.timeout,
                retry=false
            )

            client.last_request_time = time()

            if response.status == 200
                return JSON3.read(String(response.body))
            else
                @warn "HTTP $(response.status) on attempt $attempt for $endpoint"
            end
        catch e
            if attempt == client.config.max_retries
                @error "Failed after $(client.config.max_retries) attempts" endpoint exception=e
                rethrow(e)
            end
            @warn "Attempt $attempt failed, retrying..." endpoint exception=e
            sleep(2^attempt)  # Exponential backoff
        end
    end

    error("Failed to complete request after $(client.config.max_retries) attempts")
end

"""
POST request for complex queries
"""
function safe_post(client::CKANClient, endpoint::String, body::Dict)
    elapsed_time = (time() - client.last_request_time) * 1000
    if elapsed_time < client.config.rate_limit_ms
        sleep((client.config.rate_limit_ms - elapsed_time) / 1000)
    end

    url = joinpath(client.config.base_url, endpoint)

    for attempt in 1:client.config.max_retries
        try
            response = HTTP.post(
                url,
                client.headers,
                JSON3.write(body),
                readtimeout=client.config.timeout,
                retry=false
            )

            client.last_request_time = time()

            if response.status == 200
                return JSON3.read(String(response.body))
            else
                @warn "HTTP $(response.status) on attempt $attempt"
            end
        catch e
            if attempt == client.config.max_retries
                @error "Failed after $(client.config.max_retries) attempts" exception=e
                rethrow(e)
            end
            @warn "Attempt $attempt failed, retrying..." exception=e
            sleep(2^attempt)
        end
    end

    error("Failed to complete request after $(client.config.max_retries) attempts")
end

"""
Fetch paginated data with progress bar
CKAN uses 'start' parameter for pagination instead of page numbers
"""
function fetch_all_pages(client::CKANClient, endpoint::String, params::Dict)
    all_data = []
    start_index = 0
    total_records = nothing

    params["rows"] = string(client.config.page_size)

    progress = nothing

    while true
        params["start"] = string(start_index)

        response = safe_get(client, endpoint, params)

        # CKAN response structure: {success: true, result: {count: N, results: [...]}}
        if !get(response, :success, false)
            @warn "API returned success=false"
            break
        end

        result = get(response, :result, nothing)
        if isnothing(result)
            break
        end

        # Handle different result structures
        data = if haskey(result, :results)
            result.results
        elseif isa(result, Vector)
            result
        else
            []
        end

        if isempty(data)
            break
        end

        append!(all_data, data)

        # Initialize progress bar on first page
        if isnothing(total_records) && haskey(result, :count)
            total_records = result.count
            progress = Progress(total_records, desc="Fetching data: ")
        end

        if !isnothing(progress)
            update!(progress, length(all_data))
        end

        # Check if we've retrieved all data
        if haskey(result, :count) && length(all_data) >= result.count
            break
        end

        # If we got fewer records than requested, we're done
        if length(data) < client.config.page_size
            break
        end

        start_index += client.config.page_size
    end

    if !isnothing(progress)
        finish!(progress)
    end

    @info "Fetched $(length(all_data)) total records"

    return all_data
end
