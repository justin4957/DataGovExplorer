#!/usr/bin/env julia

using Pkg
Pkg.activate(".")

using DataGovExplorer

println("="^70)
println("Testing Configuration File Loading")
println("="^70)

# Test 1: Load default config (no config file)
println("\n[Test 1] Loading default config (no config file)...")
try
    config = load_config()
    println("✓ Default config loaded successfully")
    println("  - Base URL: $(config.base_url)")
    println("  - Timeout: $(config.timeout)")
    println("  - Rate limit: $(config.rate_limit_ms)ms")
    println("  - Max retries: $(config.max_retries)")
    println("  - Page size: $(config.page_size)")
    println("  - Default export format: $(config.default_export_format)")
    println("  - Colors enabled: $(config.colors_enabled)")
catch e
    println("✗ Failed to load default config: $e")
end

# Test 2: Create a test TOML config and load it
println("\n[Test 2] Testing TOML config loading...")
test_toml_path = joinpath(pwd(), ".datagov.toml")
try
    open(test_toml_path, "w") do io
        write(io, """
[api]
base_url = "https://test.example.com/api/3"
timeout = 45
max_retries = 5
rate_limit_ms = 1000

[defaults]
export_format = "json"
page_size = 50

[ui]
colors_enabled = false
""")
    end

    config = load_config()
    println("✓ TOML config loaded successfully")
    println("  - Base URL: $(config.base_url)")
    println("  - Timeout: $(config.timeout)")
    println("  - Rate limit: $(config.rate_limit_ms)ms")
    println("  - Max retries: $(config.max_retries)")
    println("  - Page size: $(config.page_size)")
    println("  - Default export format: $(config.default_export_format)")
    println("  - Colors enabled: $(config.colors_enabled)")

    # Verify values
    @assert config.base_url == "https://test.example.com/api/3" "Base URL mismatch"
    @assert config.timeout == 45 "Timeout mismatch"
    @assert config.max_retries == 5 "Max retries mismatch"
    @assert config.rate_limit_ms == 1000 "Rate limit mismatch"
    @assert config.page_size == 50 "Page size mismatch"
    @assert config.default_export_format == "json" "Export format mismatch"
    @assert config.colors_enabled == false "Colors enabled mismatch"
    println("✓ All values match expected configuration")

    # Clean up
    rm(test_toml_path)
catch e
    println("✗ Failed to test TOML config: $e")
    # Clean up on error
    if isfile(test_toml_path)
        rm(test_toml_path)
    end
end

# Test 3: Test client initialization with config
println("\n[Test 3] Testing client initialization with config...")
try
    client = CKANClient()
    println("✓ Client initialized successfully")
    println("  - Using base URL: $(client.config.base_url)")
    println("  - Default export format: $(client.config.default_export_format)")
catch e
    println("✗ Failed to initialize client: $e")
end

println("\n" * "="^70)
println("Configuration tests completed!")
println("="^70)
