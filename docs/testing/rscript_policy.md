# Rscript Execution Policy

This document explains **why and when Rscript or Bash execution is restricted**
when working on this project.

This is a **reference document**.
The actual rule enforcement lives in `.claude/instructions.md`.

---

## Default Rule (MANDATORY)

**Do NOT run `Rscript`, `R CMD`, or Bash commands by default.**

Assume the user will:
- run the app locally
- test UI behavior directly
- report results back

Running commands consumes tokens and provides limited insight for UI-heavy Shiny applications.

---

## Why Running Rscript Is Usually Wrong

Running Rscript via a tool:

- Shows only R console output
- Does NOT show browser DevTools (F12)
- Does NOT show UI rendering issues
- Does NOT show layout, flicker, or modal behavior
- Can mislead debugging by hiding client-side problems

For Shiny apps, **most bugs are visible only in the browser**, not the R console.

---

## Acceptable Exceptions (RARE)

Running Rscript or Bash commands is acceptable **only** when:

1. Debugging server-side errors the user cannot reproduce
2. Investigating database connection failures
3. Verifying pure server-side logic with console output only
4. Inspecting package versions or session info when explicitly requested

If none of the above apply, do NOT run commands.

---

## Required Workflow

Unless explicitly instructed otherwise:

1. Modify code
2. Explain what changed and why
3. Ask the user to test locally
4. Iterate based on feedback

This workflow is faster and more reliable for UI-driven systems.

---

## Violation Handling

If you accidentally run Rscript or Bash:

1. Stop immediately
2. State what command was run
3. Explain why it was unnecessary
4. Ask how to proceed

Do not repeat the mistake.

---

## Summary

- Rscript execution is the **exception**, not the rule
- UI behavior cannot be validated from console output
- Manual testing by the user is preferred
- When in doubt: **do not run commands**
