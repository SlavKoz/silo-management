# PROJECT CONVENTIONS

This file defines **stable patterns and shared understanding** for the project.
These are mandatory unless explicitly overridden by the user.

---

## Core Coding Rules

- ALWAYS use `f_or(value, default)` for null-coalescing
- NEVER define or use `%||%`
- Prefer helpers and modules over inline logic
- Keep functions small and single-purpose

---

## R / Shiny Architecture

- Use DBI + odbc with parameterized queries only
- Never build SQL with string concatenation
- Keep reactives minimal and well-scoped
- Avoid blocking operations in reactive contexts
- Use progress indicators for long-running tasks

---

## DOM Debugging Rule (MANDATORY)

When JavaScript cannot find elements:
- Inspect the actual DOM first
- Verify real IDs, namespaces, and rendering state
- Check `suspendWhenHidden`

Never start with timing hacks or delays.

(Details live in `docs/debugging/dom_inspection.md`)

---

## UI Component Terminology

- **React Table** = HTML Form Module  
  - `R/react_table/mod_html_form.R`
  - `R/react_table/html_form_renderer.R`

- **React List** = Compact List Module  
  - `R/utils/f_mod_compact_list.R`

Use these terms consistently.

---

## Formatting Change Protocol (MANDATORY)

Before any formatting change, ALWAYS ask:
> “Should this change be applied globally or locally?”

- **Global**
  - React Table → `mod_html_form.R` CSS
  - React List → `f_mod_compact_list.R` CSS
- **Local**
  - Add scoped CSS in the calling module only

Never assume.

---

## Selectize / Fomantic Rule (MANDATORY)

- Never manipulate Selectize inputs with jQuery alone
- Use the Selectize API and notify Shiny explicitly
- Never use timing hacks to force observers

(Details live in `docs/ui/fomantic_dropdown_rules.md`)

---

## Cross-Module State Rule

- Use versioned shared state in `session$userData`
- Depend on the version in reactives
- Increment the version after mutation
- Never use globals or timing-based refresh

(Details live in `docs/architecture/cross_module_state.md`)
