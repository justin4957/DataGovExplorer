module DataGovExplorer

using HTTP
using JSON3
using DataFrames
using Dates
using CSV
using PrettyTables
using ProgressMeter
using Arrow
using XLSX
using JSONTables
using StringDistances
using Crayons

export CKANClient, CKANConfig
export get_packages, get_package_details, get_organizations, get_groups, get_tags
export search_packages, get_package_metadata
export export_to_csv, export_to_json, export_to_arrow, export_to_xlsx
export export_data, auto_export, export_multi_sheet_xlsx
export interactive_explorer

# Include core modules
include("config.jl")
include("client.jl")
include("metadata.jl")
include("exports.jl")
include("explorer.jl")

end
