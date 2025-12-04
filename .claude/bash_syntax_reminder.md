# CRITICAL: Bash Syntax Reminders

## Windows vs Bash stderr redirection

**NEVER USE:** `2>nul` (creates literal file named "nul")
**CORRECT:**   `2>/dev/null` (redirects to null device)

## Examples

❌ WRONG (creates nul file):
```bash
command 2>nul
```

✅ CORRECT:
```bash
command 2>/dev/null
```

## If you need Windows CMD syntax
Use proper escaping or avoid bash tool entirely.
