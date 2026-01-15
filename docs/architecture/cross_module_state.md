# Cross-Module State Management

This document describes the **approved pattern** for sharing and
invalidating state across Shiny modules in this project.

This is a **reference document**.
Only the condensed rule belongs in `.claude/conventions.md`.

---

## The Problem

Shiny modules are isolated by design.
Changes in one module often need to refresh or invalidate data in others.

Naive approaches lead to:
- stale UI
- hidden dependencies
- unpredictable refresh behavior

---

## Approved Pattern: Versioned Shared State

Use `session$userData` with a version counter.

---

## Example Pattern

### Initialize shared version

```r
session$userData$icons_version <- 0
```

---

### Depend on the version

```r
icons <- reactive({
  session$userData$icons_version
  fetch_icons_from_db()
})
```

The reactive will re-run whenever the version changes.

---

### Invalidate after change

```r
session$userData$icons_version <- session$userData$icons_version + 1
```

This forces all dependent reactives to refresh.

---

## Why This Works

- Explicit dependency
- No hidden observers
- Predictable invalidation
- Scales to many modules

---

## Anti-Patterns (DO NOT USE)

- Global variables
- `reactiveValues()` shared across modules implicitly
- Triggering fake input changes
- Using time-based refreshes

---

## When to Use This Pattern

- Icon updates
- Lookup tables
- Shared reference data
- Any cross-module dependency

---

## Summary

- Use explicit version counters
- Store them in `session$userData`
- Depend on them in reactives
- Increment after mutation
