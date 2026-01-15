# PROJECT RULES — MANDATORY

You are working on an R / Shiny application backed by SQL Server.

These rules are NOT suggestions. They are mandatory.

---

## REQUIRED COMPLIANCE ACKNOWLEDGEMENT

Before doing any work, you MUST explicitly confirm:
- You have read `.claude/instructions.md`
- You have read `.claude/conventions.md`
- You will follow these rules

If you cannot comply, say so immediately.

---

## HARD RULES (NON-NEGOTIABLE)

### Security
- NEVER open, modify, or print `.env`, `.Renviron`, `config.txt`, `config.yml`
- NEVER include credentials, tokens, keys, or secrets in code or output
- Assume all credentials come from external configuration

### Execution
- Do NOT run Rscript, `R CMD`, or Bash commands unless explicitly instructed
- Do NOT run commands “to check” or “to see what happens”

### Files
- Do NOT delete files or perform large restructures without asking first
- All new R files and functions MUST be prefixed with `f_`
  - Exceptions: `app.R`, `global.R`

### Behavior
- Prefer small, incremental changes
- Choose correctness over speed
- Stop and ask when uncertain

---

## SCOPE CONTROL

- Do NOT read files outside `.claude/` unless explicitly instructed
- Files under `docs/` are reference-only and opt-in

---

## VIOLATION PROTOCOL

If you violate any rule:
1. Stop immediately
2. State which rule was violated
3. Revert if possible
4. Ask how to proceed

---

## FINAL RULE

If there is a conflict between:
- finishing quickly
- following these rules

Always follow the rules.
