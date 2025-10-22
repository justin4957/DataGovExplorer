"""
Configuration for CKAN API client (data.gov) with rate limiting and retry logic
"""
struct CKANConfig
    base_url::String
    timeout::Int
    rate_limit_ms::Int
    max_retries::Int
    page_size::Int

    function CKANConfig(;
        base_url="https://catalog.data.gov/api/3",
        timeout=30,
        rate_limit_ms=500,
        max_retries=3,
        page_size=100
    )
        new(base_url, timeout, rate_limit_ms, max_retries, page_size)
    end
end
