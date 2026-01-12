# SiloPlacements Integration - ROOT CAUSE & SOLUTION

## Root Cause: CONFIRMED ✅

**shiny.semantic** (loaded in `global.R` line 9) includes **Fomantic UI**, which automatically hijacks ALL `<select>` elements on the page and converts them to Fomantic dropdowns. This prevents Shiny's selectize from working.

### Scientific Proof:
1. ✅ Standalone WITHOUT shiny.semantic: Works perfectly
2. ❌ Standalone WITH shiny.semantic: Fails (grey buttons, empty dropdowns)
3. ❌ Main app WITH shiny.semantic: Fails

## Solutions Attempted ❌

### 1. Convert to shiny.semantic::dropdown_input
- **Status:** FAILED
- **Issue:** Fomantic dropdowns render as plain text, no interactivity
- **Why:** shiny.semantic's components don't work properly with the module's dynamic renderUI

### 2. Block Fomantic from hijacking selects
- **Status:** FAILED
- **Issue:** Fomantic hijacks selects BEFORE our blocking code runs
- **Why:** Timing issue - can't intercept early enough

## Working Solution: Don't Load shiny.semantic in Placements Context

### Option A: Conditional Loading (RECOMMENDED)
Only load shiny.semantic for modules that need it, not globally.

**Change global.R:**
```r
# Don't load globally - breaks selectize in some modules
# library(shiny.semantic)
```

**Load per-module as needed:**
```r
# In modules that need Fomantic UI:
if (!requireNamespace("shiny.semantic", quietly = TRUE)) {
  library(shiny.semantic)
}
```

### Option B: Load Placements in iframe
Isolate placements module in an iframe so it has its own JavaScript context without Fomantic.

## Current State

**Standalone test works** (with shiny.semantic commented out in `run_siloplacements_test.R`)
**Main app fails** (shiny.semantic loaded globally in `global.R`)

## Next Steps

1. Audit which modules actually USE shiny.semantic components
2. Remove from global.R if only few modules need it
3. Load conditionally per-module
4. Test placements in main app

## Files Modified (Need Cleanup)

- `R/browsers/f_browser_siloplacements.R` - Has test blocking code (lines 22-49) to remove
- `run_siloplacements_test.R` - Has shiny.semantic commented out
- `.claude/bash_syntax_reminder.md` - Created for debugging
