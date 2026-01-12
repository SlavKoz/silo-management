# Debugging Placements Module - Troubleshooting Log

## Problem Statement
**Test works, App doesn't**: When running `run_siloplacements_test.R`, all dropdowns populate correctly. When running through the main app (`app.R`), all dropdowns remain empty.

**Key Symptom**:
- Test: Cursor starts as cross, then changes to hand - everything populates
- App: Cursor stays as cross - nothing populates

**JavaScript Error (App only)**:
```
Uncaught TypeError: Shiny.setInputValue is not a function
    at HTMLDocument.<anonymous> ((index):331:27)
```

---

## What We've Tried (Chronologically)

### 1. ✓ Fixed `isTRUE()` for NA handling
**Lines**: 1662-1664, 1676-1678 in `f_browser_siloplacements.R`
**Issue**: `if` statements with NA values causing "missing value where TRUE/FALSE needed"
**Fix**: Wrapped logical expressions in `isTRUE()` to convert NA to FALSE
**Result**: Fixed the original error, but dropdowns still empty in app

### 2. ✓ Added refresh reactive variables
**Lines**: 442-444 in `f_browser_siloplacements.R`
**Added**: `sites_refresh`, `areas_refresh`, `shape_templates_refresh` reactiveVals
**Result**: Infrastructure added but dropdowns still empty

### 3. ✓ Updated reactive data sources to use refresh triggers
**Lines**: 943, 954, 960 in `f_browser_siloplacements.R`
**Modified**: `shape_templates_data()`, `sites_data()`, `areas_data()` to depend on refresh triggers
**Result**: Data sources can now be refreshed, but still not populating

### 4. ✗ FAILED: Tried `suspendWhenHidden = FALSE` (INVALID SYNTAX)
**Attempted**: `observe(suspendWhenHidden = FALSE, {...})`
**Error**: "`...` must be empty. Problematic argument: suspendWhenHidden = FALSE"
**Result**: **`suspendWhenHidden` is NOT a valid parameter for `observe()`** - only for `outputOptions()` and `bindEvent()`

### 5. ✓ Removed all `suspendWhenHidden` parameters
**Lines**: Multiple observers throughout file
**Fix**: Removed the invalid parameter
**Result**: Syntax errors fixed but dropdowns still empty

### 6. ✓ Wrapped `onFlushed` in `isolate()`
**Lines**: 972-981 in `f_browser_siloplacements.R`
**Issue**: "Operation not allowed without an active reactive context"
**Fix**: Wrapped refresh trigger increments in `isolate()`
**Result**: Error fixed but dropdowns still empty

### 7. ✓ Added route-based refresh detection
**Lines**: 982-1005 in `f_browser_siloplacements.R`
**Logic**: Detect when user navigates to placements route using `route()` reactiveVal
**Console Output**: Shows route change detected and refresh triggered
**Result**: Observers fire correctly, find data, but dropdowns still empty

### 8. ✗ FAILED: Tried fixing UI reactive calls in conditional rendering
**Lines**: 1566, 1580 in `f_browser_siloplacements.R`
**Issue**: Called `edit_mode_state()` during UI rendering (invalid in non-reactive context)
**Fix**: Changed to static CSS with server-side toggling
**Result**: Not the issue - checkboxes are on hidden pane anyway

### 9. ✓ FIXED: JavaScript Error - `Shiny.setInputValue is not a function`
**Location**: `f_app_ui.R` line 237 - `Shiny.addCustomMessageHandler` called before Shiny loaded
**Root Cause**: Script in app UI called `Shiny.addCustomMessageHandler` in `$(document).ready`, which executes before Shiny initializes
**Fix Applied**:
- Wrapped in `$(document).on('shiny:connected', ...)` to wait for Shiny
- Protected ALL `Shiny.setInputValue` calls in `www/js/f_siloplacements_canvas.js` with `if (window.Shiny && Shiny.setInputValue)`
**Files Modified**:
- `R/f_app_ui.R` line 237
- `www/js/f_siloplacements_canvas.js` lines 23, 225-231, 243-251, 355-360, 374-380

---

## Key Observations

### Console Output Comparison

**Test (WORKING)**:
```
[ test ] MODULE INITIALIZATION STARTED
[ test ] Populating layout dropdown observer fired
[ test ] Found 5 layouts
[ test ] onFlushed callback triggered
[ test ] Populating layout dropdown observer fired (again)
```

**App (NOT WORKING)**:
```
[ placements ] MODULE INITIALIZATION STARTED
[ placements ] Populating layout dropdown observer fired
[ placements ] Found 5 layouts
[ placements ] Route changed to: home
[ placements ] Route changed to: placements
[ placements ] First navigation to placements, triggering refresh
[ placements ] Populating layout dropdown observer fired
[ placements ] Found 4 canvases
[ placements ] Canvas dropdown updated with 5 choices
```

**Key Difference**:
- Observers ARE firing
- Data IS being found
- `updateSelectInput()` is being called
- **BUT dropdowns remain empty in the UI**

### Root Cause Analysis

**The Problem**:
1. App loads all module servers at startup (`f_app_server.R` lines 413-418)
2. UI only renders when user navigates to route
3. Observers fire and try to update inputs BEFORE the DOM elements exist
4. JavaScript error breaks Shiny's reactive system
5. Even after navigation, system is in broken state

**Why Test Works**:
- Test creates UI immediately with module server
- DOM exists when observers fire
- No JavaScript timing issues

---

## Current Focus: JavaScript Timing Issue

### Inline Scripts That Need Protection

All `Shiny.setInputValue` calls in inline `tags$script()` HTML must be wrapped:

```javascript
// WRONG (breaks if Shiny not loaded)
Shiny.setInputValue('input-id', value);

// CORRECT
if (Shiny && Shiny.setInputValue) {
  Shiny.setInputValue('input-id', value);
}
```

### Files to Check:
1. `f_browser_siloplacements.R` - inline scripts (lines ~110, ~217, ~339, ~2112)
2. `www/js/f_siloplacements_canvas.js` - external script (all `Shiny.setInputValue` calls)

---

## Next Steps

1. ✓ Document everything we've tried (this file)
2. 🔄 Fix ALL JavaScript `Shiny.setInputValue` calls in both R and JS files
3. Test with hard browser refresh (Ctrl+Shift+R)
4. If still failing: investigate why `updateSelectInput()` isn't working despite being called

---

## Files Modified

- `R/browsers/f_browser_siloplacements.R`
- `R/f_app_server.R` (added error visibility)
- `www/js/f_siloplacements_canvas.js` (needs re-fixing after restore)

---

## Browser Console Errors (App Only)

```
Uncaught TypeError: Shiny.setInputValue is not a function
    at HTMLDocument.<anonymous> ((index):331:27)
Failed to load resource: the server responded with a status of 404 (Not Found) - favicon.ico
[icon-picker] Found 0 icon pickers
```

The first error is the critical one - it breaks Shiny's reactive system.
