"""
Configuration for CKAN API client (data.gov) with rate limiting and retry logic
"""
struct CKANConfig
    # API settings
    base_url::String
    timeout::Int
    rate_limit_ms::Int
    max_retries::Int
    page_size::Int

    # Default export settings
    default_export_format::String

    # UI settings
    colors_enabled::Bool

    function CKANConfig(;
        base_url="https://catalog.data.gov/api/3",
        timeout=30,
        rate_limit_ms=500,
        max_retries=3,
        page_size=100,
        default_export_format="csv",
        colors_enabled=true
    )
        new(base_url, timeout, rate_limit_ms, max_retries, page_size,
            default_export_format, colors_enabled)
    end
end

"""
Find configuration file in order of precedence:
1. Project-level: ./.datagov.toml or ./datagov.yml
2. Home directory: ~/.datagov.toml or ~/.datagov.yml
Returns the path to the first found config file, or nothing if none found
"""
function find_config_file()
    # Check project-level configs first
    project_toml = joinpath(pwd(), ".datagov.toml")
    project_yml = joinpath(pwd(), "datagov.yml")

    if isfile(project_toml)
        return project_toml
    elseif isfile(project_yml)
        return project_yml
    end

    # Check home directory configs
    home_dir = homedir()
    home_toml = joinpath(home_dir, ".datagov.toml")
    home_yml = joinpath(home_dir, ".datagov.yml")

    if isfile(home_toml)
        return home_toml
    elseif isfile(home_yml)
        return home_yml
    end

    return nothing
end

"""
Load configuration from TOML file
"""
function load_toml_config(filepath::String)
    return TOML.parsefile(filepath)
end

"""
Load configuration from YAML file
"""
function load_yaml_config(filepath::String)
    return YAML.load_file(filepath)
end

"""
Load configuration from file (auto-detects format)
"""
function load_config_file(filepath::String)
    if endswith(filepath, ".toml")
        return load_toml_config(filepath)
    elseif endswith(filepath, ".yml") || endswith(filepath, ".yaml")
        return load_yaml_config(filepath)
    else
        error("Unsupported config file format: $filepath. Use .toml or .yml")
    end
end

"""
Extract value from nested dict with fallback
"""
function get_nested(dict::Dict, keys::Vector, default)
    current = dict
    for key in keys
        key_str = string(key)
        if haskey(current, key_str)
            current = current[key_str]
        else
            return default
        end
    end
    return current
end

"""
Create CKANConfig from file-based configuration
Loads config file if available, otherwise uses defaults
"""
function load_config()
    config_path = find_config_file()

    if isnothing(config_path)
        @debug "No config file found, using defaults"
        return CKANConfig()
    end

    @info "Loading configuration from: $config_path"

    try
        config_dict = load_config_file(config_path)

        # Extract API settings
        base_url = get_nested(config_dict, ["api", "base_url"], "https://catalog.data.gov/api/3")
        timeout = get_nested(config_dict, ["api", "timeout"], 30)
        max_retries = get_nested(config_dict, ["api", "max_retries"], 3)
        rate_limit_ms = get_nested(config_dict, ["api", "rate_limit_ms"], 500)

        # Extract defaults
        page_size = get_nested(config_dict, ["defaults", "page_size"], 100)
        export_format = get_nested(config_dict, ["defaults", "export_format"], "csv")

        # Extract UI settings
        colors_enabled = get_nested(config_dict, ["ui", "colors_enabled"], true)

        return CKANConfig(
            base_url=base_url,
            timeout=Int(timeout),
            rate_limit_ms=Int(rate_limit_ms),
            max_retries=Int(max_retries),
            page_size=Int(page_size),
            default_export_format=String(export_format),
            colors_enabled=Bool(colors_enabled)
        )
    catch e
        @warn "Failed to load config file, using defaults" exception=e
        return CKANConfig()
    end
end
