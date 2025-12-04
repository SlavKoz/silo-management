# SiloPlacements Integration - Next Steps

## Problem
SiloPlacements browser works standalone but fails to populate dropdowns when embedded in app router.

## Root Cause Identified
JavaScript file had hardcoded namespace `'test-'` instead of being dynamic. When launched in app as `"placements"` module, message handlers didn't match.

## What We Fixed

### 1. Made JavaScript Namespace-Agnostic
- **File**: `www/js/f_siloplacements_canvas.js`
- Refactored all message handlers to dynamically detect namespace from canvas ID
- Added `nsSelector(ns, id)` helper function
- Moved all 19 message handlers into `registerMessageHandlers()` function
- Now works with ANY namespace: `test`, `placements`, etc.

### 2. Added JavaScript Loading to Module UI
- **File**: `R/browsers/f_browser_siloplacements.R` (line 18)
- Added: `tags$script(src = paste0("js/f_siloplacements_canvas.js?v=", format(Sys.time(), "%Y%m%d%H%M%S")))`
- JavaScript wasn't loading in app context before

### 3. Cleaned Up App Routes
- **File**: `R/f_app_server.R`
- Removed test routes: `minimal`, `minimal2`, `testdropdown`
- Deleted files: `minimal_test.R`, `minimal_test2.R`, `browser_placements_minimal.R`, `f_browser_siloplacements_fixed.R`
- Only `placements` route remains

### 4. UI Improvements Completed
- Narrowed Layout selector from 220px to 132px (40%)
- Narrowed buttons from 40px to 80px then back (settled on 80px)
- Created Edit dropdown menus on background and placement toolbars
- Moved Rotate/BG Size into background Edit dropdown
- Moved Grid Snap/Zoom into placement Edit dropdown
- Dropdowns stay open when clicking inside, close on ESC or clicking Edit again
- Text input for "Add New" layout flexes to fill space with Save button

### 5. Fixed git_runner Issue
- **File**: `git_runner.R`
- Added cleanup to remove `.db_pool_env` at start to avoid conflicts with running app

## Current Status (Last Test)
**Standalone test**: ✅ Works perfectly
- Console shows: `[Canvas] Initializing canvas with namespace: test`
- Dropdowns populate
- Buttons change from dark blue → pale blue (Selectize initialized)

**App integration - Session End Status**: ⚠️ FIXED timing issue, needs testing
- JavaScript file NOW LOADS (200 OK in Network tab)
- BUT: No console messages, buttons grey, dropdowns empty
- **ROOT CAUSE FOUND**: Timing issue
  - JS loads AFTER Shiny already connected
  - `shiny:connected` event listener never fires
  - Canvas never initializes

**FIX APPLIED** (not yet tested):
- Changed JS to check if `Shiny.shinyapp` exists when loading
- If already connected → initialize immediately via `$(function())`
- If not connected yet → wait for `shiny:connected` event
- Lines 202-209 in `f_siloplacements_canvas.js`

## Next Steps (IMMEDIATE - START HERE TOMORROW)

### 1. Test Timing Fix
```r
# Restart R session (IMPORTANT - must reload updated JS)
# Then:
shinyApp(app_ui, app_server)
```
- Navigate to **Placements** in sidebar
- **Open browser DevTools (F12), Console tab**
- Look for initialization messages:
  ```
  [Canvas] Shiny already connected, initializing immediately...
  [Canvas] Starting canvas initialization...
  [Canvas] Initializing canvas with namespace: placements
  [Canvas] Registering message handlers for namespace: placements
  ```

### 2. Expected Results
If working:
- ✅ Console shows namespace: `placements`
- ✅ Dropdowns populate (Layout, Site, Background, Area)
- ✅ Buttons change from grey/dark blue → pale blue
- ✅ Canvas renders with placements

If NOT working:
- Check browser console for JavaScript errors
- Verify JS file loads: DevTools → Sources → `js/f_siloplacements_canvas.js`
- Check if file shows new code (starts with `// Simple canvas renderer for SiloPlacements (namespace-agnostic)`)

### 3. If Still Fails
Possible issues:
- Browser cache (hard reload: Ctrl+Shift+R)
- Module not reloaded (restart R session)
- renderUI timing issue (may need show/hide approach instead)

## Files Modified This Session
1. `www/js/f_siloplacements_canvas.js` - Namespace-agnostic refactor
2. `R/browsers/f_browser_siloplacements.R` - Added JS loading, UI tweaks
3. `www/css/f_siloplacements.css` - Grid column sizing, selectize styling
4. `R/f_app_server.R` - Removed test routes, cleaned up
5. `git_runner.R` - Added db pool cleanup

## Technical Notes

### Why Standalone Works But App Didn't
**Standalone** (`run_siloplacements_test.R`):
- Module ID: `"test"` → namespace: `test-`
- JS loaded in `fluidPage` header
- Message handlers: `test-root:setData` ✅ matches

**App (before fix)**:
- Module ID: `"placements"` → namespace: `placements-`
- JS NOT loaded (missing from module UI)
- Old JS handlers: `test-root:setData` ❌ no match
- Result: JavaScript never initialized, dropdowns never populated

**App (after fix)**:
- JS now loads with module
- Handlers dynamically register as: `placements-root:setData` ✅ should match
- Should work identically to standalone

### The Visual Indicator
Button color changes indicate Selectize.js initialization:
1. Initial: Dark blue (HTML rendered, minimal CSS)
2. After Selectize: Pale blue (DOM transformed, full CSS applied)
3. Grey in app = different state, possibly incomplete initialization

When JavaScript initializes properly:
- Selectize wraps `<select>` elements in custom divs
- This triggers CSS recalculation
- Buttons inherit different color values
- Dropdowns get populated via Shiny messages

## Git Status Before Next Session
Modified files ready to commit:
- M R/browsers/f_browser_siloplacements.R
- M R/f_app_server.R
- M git_runner.R
- M www/css/f_siloplacements.css
- M www/js/f_siloplacements_canvas.js

Deleted files:
- R/browsers/f_browser_siloplacements_fixed.R
- R/browsers/minimal_test.R
- R/browsers/minimal_test2.R
- R/browsers/browser_placements_minimal.R

## Success Criteria
✅ Browser console shows `namespace: placements`
✅ All dropdowns populate with data
✅ Canvas renders placements
✅ Edit dropdowns work (Rotate, BG Size, Grid Snap, Zoom)
✅ Add New layout/background buttons work
✅ Move/Duplicate functionality works

## Troubleshooting (If Still Fails Tomorrow)

### If No Console Messages
1. **Hard reload browser**: Ctrl+Shift+R (clear JS cache)
2. **Check Network tab**: Verify JS file timestamp matches latest edit
3. **Check Sources tab**: Open `f_siloplacements_canvas.js`, verify lines 202-209 show new timing check
4. **Browser console**: Run `typeof Shiny` and `Shiny.shinyapp` to verify Shiny loaded

### If Console Messages But No Dropdowns
- Timing is fixed but server-side data not sending
- Check R console for errors
- Check if `browser_siloplacements_server("placements", pool, route = current)` is being called

### Alternative Approach (If Timing Fix Doesn't Work)
Use show/hide instead of renderUI:
- Render placements UI statically in app shell
- Use `shinyjs::hide()` / `shinyjs::show()` to display when route matches
- This ensures JS loads before Shiny connects
- But requires significant app structure changes

## Key Files Modified Today
1. `www/js/f_siloplacements_canvas.js` - Lines 125-209: Timing fix
2. `R/browsers/f_browser_siloplacements.R` - Line 18-20: Added JS loading
3. All other files from previous session
