# DataGovExplorer Architecture

## Overview

DataGovExplorer is built on the proven architecture of UNStatsExplorer, adapted for the data.gov CKAN API. This document explains the architecture and what was adapted from the original project.

## Core Architecture Patterns (Inherited from UNStatsExplorer)

### 1. Configuration Layer
**File**: `src/config.jl`

Defines immutable configuration structs with sensible defaults:
- `CKANConfig` (adapted from `SDGConfig`)
- Base URL, timeout, rate limiting, retry logic
- Enables custom configuration at runtime

### 2. Client Layer
**File**: `src/client.jl`

HTTP client with advanced features:
- `CKANClient` (adapted from `SDGClient`)
- Rate limiting with configurable delays
- Exponential backoff retry logic
- Built-in caching mechanism
- Pagination support

**Key Functions**:
- `safe_get()` - Rate-limited GET with retries
- `safe_post()` - POST with rate limiting
- `fetch_all_pages()` - Automatic pagination handler

**Adaptations for CKAN**:
- Changed pagination from `page` to `start`/`rows` parameters
- Updated response structure handling for CKAN format
- Modified success checking for `success` field in responses

### 3. Metadata Layer
**File**: `src/metadata.jl`

Functions for retrieving catalog information:

**From UNStatsExplorer** → **To DataGovExplorer**:
- `get_goals()` → `get_organizations()`
- `get_indicators()` → `get_packages()`
- `get_series()` → `get_tags()`
- `get_geoareas()` → (removed - not applicable)
- `search_indicators()` → `search_packages()`

**New Functions**:
- `get_package_details()` - Get detailed package information
- `get_package_metadata()` - Format metadata as DataFrame
- `get_groups()` - List dataset groups

### 4. Export Layer
**File**: `src/exports.jl`

Multi-format export utilities (copied directly from UNStatsExplorer):
- CSV export
- JSON export
- Excel export
- Arrow export (binary format)
- Smart dispatcher based on file extension
- Auto-export with timestamps
- Multi-sheet Excel export

**No changes needed** - This layer is completely reusable!

### 5. Explorer Layer
**Files**: `src/explorer.jl`, `src/explorer/*.jl`

Interactive CLI with menu navigation:

#### Display Module (`src/explorer/display.jl`)
**Copied directly** - Color-coded output, loading indicators, table formatting

Features:
- Success/error/warning/info messages
- Loading indicators
- Data summaries
- Smart table display with pagination

#### Input Module (`src/explorer/input.jl`)
**Adapted** from UNStatsExplorer:

**Changes**:
- Removed country code translation (ISO to UN codes)
- Simplified validation to generic name matching
- Kept fuzzy matching with Jaro-Winkler distance
- Kept auto-correction features

**Retained**:
- List parsing
- Fuzzy matching algorithm
- Suggestion system
- Multi-value validation

#### Menu Module (`src/explorer/menu.jl`)
**Significantly adapted** for data.gov structure:

**From UNStatsExplorer** → **To DataGovExplorer**:
- `explore_goals()` → `explore_organizations()`
- `explore_goal_detail()` → `explore_organization_datasets()`
- `explore_indicator_data()` → `view_dataset_details()`
- `filtered_query()` → `search_datasets_menu()`
- (new) `browse_by_tags()`
- (new) `browse_datasets_by_tag()`

**Main Explorer** (`src/explorer.jl`):

Menu options changed from:
- Browse Goals → Browse Organizations
- Search Indicators → Search Datasets
- Query Series → Browse by Tags
- List Areas → Recent Datasets
- Compare Trends → (removed - not applicable)

## API Differences: UN SDG API vs CKAN API

### UN SDG API Structure
```
Goals (1-17)
├── Targets (1.1, 1.2, etc.)
    └── Indicators (1.1.1, 1.1.2, etc.)
        └── Series (specific data series)
            └── Data Points
                ├── Geographic dimensions
                ├── Temporal dimensions
                └── Disaggregation
```

### CKAN API Structure
```
Organizations (government agencies)
├── Packages/Datasets
    ├── Resources (downloadable files)
    ├── Tags (topic keywords)
    └── Groups (categories)
```

## Reusability Analysis

### 100% Reusable (No changes)
- Export layer (`exports.jl`)
- Display utilities (`explorer/display.jl`)
- HTTP client patterns (`safe_get`, `safe_post`)
- Caching mechanism
- Rate limiting logic
- Retry with exponential backoff

### 90% Reusable (Minor adaptations)
- Configuration pattern
- Input validation framework
- Fuzzy matching logic
- Pagination handling
- Error handling

### 50% Reusable (Significant adaptations)
- Metadata functions (different API structure)
- Menu navigation (different hierarchy)
- Search functions (different query parameters)

### Not Reusable (Domain-specific)
- Country code translation (ISO to UN)
- SDG-specific data structures
- Trend comparison (not in CKAN)
- Geographic area filtering (CKAN uses different approach)

## Design Principles Applied

Both projects follow these principles:

1. **Composability**: Small functions combine into larger workflows
2. **Reusability**: Core utilities work independently
3. **Descriptive Naming**: Clear, self-documenting function names
4. **Type Safety**: Robust handling of missing/invalid data
5. **Minimal Overhead**: Efficient caching and resource usage
6. **Progressive Disclosure**: Simple API with advanced options
7. **Fail-Safe**: Graceful error handling

## Performance Characteristics

Similar performance profile to UNStatsExplorer:

- Metadata retrieval: < 2 seconds (cached after first call)
- Package search: 2-5 seconds (depends on query)
- Full organization query: 5-30 seconds (depends on dataset count)
- Export to Arrow: Fastest (binary format)
- Export to CSV: Fast (universal compatibility)
- Export to Excel: Moderate (formatting overhead)

## Key Adaptations Summary

| Component | Change Type | Reason |
|-----------|-------------|---------|
| Config | Minor | Different API URL, adjusted page size |
| Client | Minor | CKAN pagination uses start/rows instead of page numbers |
| Metadata | Major | Different API endpoints and data structure |
| Exports | None | Format-agnostic, fully reusable |
| Display | None | Presentation logic unchanged |
| Input | Moderate | Removed SDG-specific validations |
| Menu | Major | Different navigation hierarchy |
| Explorer | Major | Different menu options and workflows |

## Benefits of Architecture Reuse

1. **Development Speed**: Reused ~70% of codebase
2. **Proven Patterns**: Battle-tested HTTP client, caching, and retry logic
3. **Consistent UX**: Similar user experience across tools
4. **Maintainability**: Familiar structure for developers
5. **Quality**: Inherited robust error handling and performance optimization

## Future Enhancements

Potential additions inspired by UNStatsExplorer:

1. **Data Download**: Add resource download functionality
2. **Advanced Filtering**: Multi-criteria search builder
3. **Comparison Tools**: Compare datasets across organizations
4. **Batch Operations**: Bulk dataset retrieval
5. **Visualization**: Add chart generation for dataset metadata
6. **Export Templates**: Customizable export formats

## Conclusion

The architecture of UNStatsExplorer proved highly adaptable to data.gov's CKAN API. The modular design allowed selective reuse of components while adapting domain-specific logic. This demonstrates the value of:

- Clear separation of concerns
- Generic utility functions
- Composable architecture
- Domain-agnostic patterns

The result is a robust, performant tool built in a fraction of the time it would take to build from scratch.
