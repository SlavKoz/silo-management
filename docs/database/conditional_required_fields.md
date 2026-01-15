# Conditional Required Fields (R Script Logic)

This document describes the **R-side mechanism** used to enforce
*conditional required fields* based on related input state.

This is **not a database rule**.
It is implemented in R / Shiny logic.

---

## What This Is

Conditional required fields mean:
- a field is required **only when certain conditions are met**
- requirements change dynamically based on user input or data context

Examples:
- A field required only for specific categories
- A value required when a checkbox is enabled
- Additional fields required when editing (but not creating)

---

## Where This Logic Lives

- R server logic (validation)
- Shiny observers or reactive checks
- Form save handlers

**Not** in database constraints.

---

## Core Pattern

1. Determine current context
2. Determine which fields are required in that context
3. Validate before save
4. Provide clear feedback to the user

---

## Example Pattern (Conceptual)

```r
required_fields <- character(0)

if (data$type == "SPECIAL") {
  required_fields <- c(required_fields, "ExtraField")
}

missing <- required_fields[is.na(data[required_fields])]

if (length(missing) > 0) {
  stop("Missing required fields: ", paste(missing, collapse = ", "))
}
```

This logic belongs in the save/validation layer.

---

## UI Feedback Rules

- Highlight missing fields
- Provide specific messages
- Do not rely on generic errors

Avoid:
- silent failures
- database errors for validation
- post-save discovery of missing data

---

## Why This Is an R Concern

- Requirements are dynamic
- Context may not map cleanly to schema
- UI state matters
- Database constraints cannot express conditional logic well

---

## Summary

- Conditional required fields are enforced in R logic
- They depend on context, not schema
- Validation happens before save
- Errors must be explicit and user-friendly
