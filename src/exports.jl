"""
Export utilities for multiple formats with minimal overhead
"""

"""
Export DataFrame to CSV format
"""
function export_to_csv(df::DataFrame, filepath::String)
    @info "Exporting to CSV..." filepath

    CSV.write(filepath, df)

    filesize_mb = stat(filepath).size / (1024 * 1024)
    @info "Exported $(nrow(df)) rows to CSV ($(round(filesize_mb, digits=2)) MB)" filepath

    return filepath
end

"""
Export DataFrame to JSON format
"""
function export_to_json(df::DataFrame, filepath::String; pretty::Bool=false)
    @info "Exporting to JSON..." filepath

    open(filepath, "w") do io
        JSONTables.arraytable(io, df)
    end

    filesize_mb = stat(filepath).size / (1024 * 1024)
    @info "Exported $(nrow(df)) rows to JSON ($(round(filesize_mb, digits=2)) MB)" filepath

    return filepath
end

"""
Export DataFrame to Apache Arrow format (efficient binary format)
"""
function export_to_arrow(df::DataFrame, filepath::String)
    @info "Exporting to Arrow..." filepath

    Arrow.write(filepath, df)

    filesize_mb = stat(filepath).size / (1024 * 1024)
    @info "Exported $(nrow(df)) rows to Arrow ($(round(filesize_mb, digits=2)) MB)" filepath

    return filepath
end

"""
Export DataFrame to Excel format
"""
function export_to_xlsx(df::DataFrame, filepath::String; sheet_name::String="Data")
    @info "Exporting to Excel..." filepath

    XLSX.writetable(filepath, sheet_name => df)

    filesize_mb = stat(filepath).size / (1024 * 1024)
    @info "Exported $(nrow(df)) rows to Excel ($(round(filesize_mb, digits=2)) MB)" filepath

    return filepath
end

"""
Smart export based on file extension
"""
function export_data(df::DataFrame, filepath::String; kwargs...)
    extension = lowercase(splitext(filepath)[2])

    if extension == ".csv"
        return export_to_csv(df, filepath)
    elseif extension == ".json"
        return export_to_json(df, filepath; kwargs...)
    elseif extension == ".arrow"
        return export_to_arrow(df, filepath)
    elseif extension in [".xlsx", ".xls"]
        return export_to_xlsx(df, filepath; kwargs...)
    else
        @error "Unsupported file format" extension
        error("Unsupported file format: $extension. Use .csv, .json, .arrow, or .xlsx")
    end
end

"""
Quick export with auto-generated filename based on query parameters
"""
function auto_export(
    df::DataFrame,
    base_name::String;
    format::Symbol=:csv,
    output_dir::String="./output"
)
    # Create output directory if it doesn't exist
    if !isdir(output_dir)
        mkpath(output_dir)
    end

    # Generate filename with timestamp
    timestamp = Dates.format(now(), "yyyymmdd_HHMMSS")
    extension = string(format)
    filename = "$(base_name)_$(timestamp).$(extension)"
    filepath = joinpath(output_dir, filename)

    return export_data(df, filepath)
end

"""
Export multiple DataFrames to a single Excel file with multiple sheets
"""
function export_multi_sheet_xlsx(
    data_dict::Dict{String, DataFrame},
    filepath::String
)
    @info "Exporting multi-sheet Excel file..." filepath

    XLSX.writetable(
        filepath,
        [sheet_name => df for (sheet_name, df) in data_dict]...
    )

    filesize_mb = stat(filepath).size / (1024 * 1024)
    @info "Exported $(length(data_dict)) sheets to Excel ($(round(filesize_mb, digits=2)) MB)" filepath

    return filepath
end
