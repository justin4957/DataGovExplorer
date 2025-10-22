# DataGovExplorer Terminal UI Roadmap

## Current Status ✅

### Implemented Features
- ✅ Numbered list navigation
- ✅ Pagination (25 items per page)
- ✅ Search/filter functionality
- ✅ Smart column reordering
- ✅ Color-coded messages (success/error/warning/info)
- ✅ Fuzzy matching for dataset names
- ✅ Browse loops (stay in context after viewing details)
- ✅ Multiple view modes (list/table)

## Future Enhancements 🚀

### Phase 1: Enhanced Interactivity (Near-term)

#### 1. Arrow Key Navigation
**Goal**: Navigate lists using ↑/↓ arrow keys instead of typing numbers

**Implementation**:
- Use `REPL.TerminalMenus` module (built into Julia)
- Replace numbered lists with interactive menus
- Highlight current selection
- Press Enter to select

**Benefits**:
- More intuitive navigation
- Faster browsing
- Modern terminal UX

**Example**:
```julia
using REPL.TerminalMenus

menu = RadioMenu(org_titles, pagesize=10)
choice = request("Select organization:", menu)
```

#### 2. Live Search / Type-to-Filter
**Goal**: Filter results as you type (like fzf)

**Implementation**:
- Capture keystrokes in real-time
- Update displayed list on each keystroke
- Show match count dynamically
- ESC to cancel, Enter to select

**Libraries to Consider**:
- Custom REPL mode
- Raw terminal mode with `REPL.Terminals`

**Benefits**:
- Lightning-fast filtering
- No need to type "search" command
- More responsive feel

#### 3. Progress Indicators & Spinners
**Goal**: Better visual feedback during API calls

**Current**: "⏳ Fetching..." text message
**Upgrade**: Animated spinner with status updates

**Implementation**:
```julia
using ProgressMeter

@showprogress "Fetching datasets..." for batch in batches
    # fetch data
end
```

**Enhancements**:
- Spinner animations: ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏
- Download progress: [████████░░] 80% (450/632 datasets)
- ETA calculations for large operations
- Cancellable operations (Ctrl+C handling)

### Phase 2: Rich Formatting (Mid-term)

#### 4. Syntax Highlighting & Markdown Rendering
**Goal**: Render dataset descriptions as formatted markdown

**Use Cases**:
- Dataset descriptions with **bold**, *italic*, links
- README files from datasets
- License texts with proper formatting

**Libraries**:
- `Markdown.jl` (stdlib) for parsing
- Custom terminal renderer
- ANSI color codes for styling

#### 5. Data Previews
**Goal**: Show sample data from datasets directly in terminal

**Features**:
- Preview first 10 rows of CSV/JSON resources
- Display data types and statistics
- Column-wise summaries
- Handle large files gracefully

**Implementation**:
- Fetch resource URLs from CKAN
- Download first N bytes only
- Parse and display in formatted table
- Option to export full dataset

#### 6. Visual Charts & Graphs
**Goal**: ASCII/Unicode charts for dataset statistics

**Use Cases**:
- Timeline of dataset updates: `█▇▆▅▄▃▂▁`
- Organization dataset counts: bar charts
- Tag popularity visualization
- Trend indicators: ↗ → ↘

**Libraries**:
- `UnicodePlots.jl` for terminal plots
- Histograms, bar charts, scatter plots
- Sparklines for inline trends

**Example**:
```
Datasets by Organization:
NASA          ████████████████████ 1,234
NOAA          ███████████████ 987
EPA           ██████████ 654
City of SF    ████ 234
```

### Phase 3: Advanced Features (Long-term)

#### 7. Multi-pane Layout (TUI Framework)
**Goal**: Split-screen interface like `htop` or `lazygit`

**Layout**:
```
┌─────────────────┬──────────────────────────────┐
│ Organizations   │ Datasets for Selected Org    │
│ [1] NASA        │ • Climate Data 2024          │
│ [2] NOAA       │ • Ocean Temperature Readings  │
│ [3] EPA        │ • Air Quality Measurements    │
│                 │                              │
│                 │ [Details Panel Below]        │
├─────────────────┴──────────────────────────────┤
│ Dataset Details:                               │
│ Title: Climate Data 2024                       │
│ Author: NASA Climate Team                      │
│ License: CC0-1.0                               │
│ Resources: 15 files (CSV, JSON)                │
└───────────────────────────────────────────────┘
```

**Libraries**:
- `TerminalUserInterfaces.jl` (experimental)
- Custom terminal UI with ANSI positioning
- Event-driven architecture

**Features**:
- Keyboard shortcuts (j/k for navigation, / for search)
- Mouse support (click to select)
- Resizable panes
- Status bar at bottom
- Help menu (? key)

#### 8. Cached Dataset Browser
**Goal**: Browse downloaded dataset metadata offline

**Features**:
- Cache all metadata locally (SQLite)
- Instant search across all datasets
- Background sync for updates
- Diff view for changed datasets
- Bookmark favorite datasets

#### 9. Collaboration Features
**Goal**: Share discoveries and create collections

**Features**:
- Save dataset collections as shareable files
- Export reading lists in markdown
- Generate comparison reports
- Annotate datasets with notes
- Tag datasets with custom labels

#### 10. Integration with Data Science Tools
**Goal**: Seamless workflow from discovery to analysis

**Features**:
- Export dataset URLs to Jupyter notebook
- Generate Julia/Python code to load data
- Create reproducible data pipelines
- One-command dataset download
- Integration with DataFrames.jl workflow

**Example Workflow**:
```julia
# In DataGovExplorer
> select dataset "climate-data-2024"
> export to julia

# Generates:
using DataFrames, CSV, HTTP
df = CSV.read(HTTP.get("https://...").body, DataFrame)
```

### Phase 4: Polish & Performance (Ongoing)

#### 11. Keyboard Shortcuts Reference
**Goal**: Quick access to all commands

**Implementation**:
- ? or F1 for help overlay
- Categorized shortcuts
- Context-sensitive help
- Printable cheat sheet

**Shortcuts**:
```
Navigation:
  ↑/↓     Navigate list
  Enter   Select item
  /       Search
  ESC     Go back

Pagination:
  n       Next page
  p       Previous page
  g       First page
  G       Last page

Actions:
  e       Export
  t       Toggle view
  r       Refresh
  q       Quit
```

#### 12. Themes & Customization
**Goal**: Personalize terminal appearance

**Features**:
- Color schemes (light/dark/solarized/etc.)
- Custom icon sets (emoji/ascii/unicode)
- Configurable keybindings
- Layout preferences
- Save preferences in ~/.datagov_explorer_rc

#### 13. Performance Optimizations
**Goal**: Handle massive datasets smoothly

**Strategies**:
- Lazy loading (load data on-demand)
- Virtual scrolling (only render visible items)
- Background preloading of next page
- Parallel API requests
- Smart caching with LRU eviction
- Streaming large responses

#### 14. Accessibility
**Goal**: Usable by everyone

**Features**:
- Screen reader support
- High contrast mode
- Keyboard-only navigation (no mouse required)
- Configurable fonts/sizes
- Alternative text for icons
- Verbose mode for detailed descriptions

## Implementation Priority

### High Priority (Next Release)
1. Arrow key navigation (TerminalMenus)
2. Better progress indicators
3. Keyboard shortcuts reference

### Medium Priority (Q2)
4. Live search/filtering
5. Visual charts (UnicodePlots)
6. Data previews

### Low Priority (Future)
7. Multi-pane TUI
8. Offline cached browser
9. Data science integrations

### Nice to Have
10. Themes & customization
11. Collaboration features
12. Advanced visualizations

## Technical Considerations

### Libraries & Dependencies
- **TerminalMenus.jl**: Interactive menus (stdlib)
- **UnicodePlots.jl**: Terminal charts
- **ProgressMeter.jl**: Progress bars (already used)
- **Crayons.jl**: Colors (already used)
- **REPL.Terminals**: Low-level terminal control
- **SQLite.jl**: Local caching
- Consider: **Gtk.jl** or **Makie.jl** for optional GUI mode

### Compatibility
- Cross-platform (macOS, Linux, Windows)
- Terminal emulator support (iTerm2, Terminal.app, Windows Terminal)
- SSH/remote usage
- Tmux/Screen compatibility
- Handle various terminal sizes (80x24 to 200x60+)

### Performance Targets
- < 100ms response time for interactions
- < 2s for initial load
- Smooth 60fps animations where applicable
- < 50MB memory footprint
- Efficient use of API rate limits

## Inspiration & References

### Similar Tools
- **fzf**: Fuzzy finder (search UX)
- **lazygit**: TUI for git (layout inspiration)
- **htop**: System monitor (multi-pane layout)
- **broot**: Tree navigator (keyboard shortcuts)
- **glow**: Markdown renderer (rich formatting)
- **HTTPie**: API client (beautiful output)

### Terminal UI Frameworks
- **Bubble Tea** (Go) - Elm-inspired TUI framework
- **Rich** (Python) - Beautiful terminal output
- **Ink** (JavaScript) - React for CLIs
- **Blessed** (JavaScript) - ncurses-like library

### Design Principles
1. **Progressive Enhancement**: Basic features work everywhere, advanced features where supported
2. **Keyboard First**: Optimize for keyboard power users
3. **Sensible Defaults**: Works great out of the box
4. **Escape Hatches**: Advanced options available but not required
5. **Feedback**: Always show what's happening
6. **Forgiving**: Hard to make mistakes, easy to undo

## Contributing

Want to help build these features? See individual issues tagged with:
- `enhancement:ui` - User interface improvements
- `enhancement:ux` - User experience enhancements
- `good-first-issue` - Great for newcomers
- `help-wanted` - Community contributions welcome

## Questions & Feedback

Have ideas for improving the terminal UI? Open an issue with:
- Tag: `enhancement:ui` or `enhancement:ux`
- Description of the feature
- Use case / problem it solves
- (Optional) Implementation ideas

---

Last Updated: 2025-01-22
Status: Living document - updated as features are implemented
