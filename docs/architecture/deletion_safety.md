# Deletion Safety & Referential Integrity

This document defines the **mandatory safety pattern** for delete operations
in this project.

This is a **reference document**.
Only the short rule summary belongs in `.claude/conventions.md`.

---

## Core Principle

**Never delete records blindly.**

Every delete operation must:
1. Check for dependent or related data
2. Fail safely with a clear user message
3. Leave the system in a consistent state

---

## Why This Matters

Unsafe deletes cause:
- orphaned records
- broken UI state
- silent data corruption
- difficult-to-debug errors later

Deletion bugs are among the most expensive to fix.

---

## Approved Deletion Pattern

### 1. Pre-check dependencies

Before deleting, explicitly check:
- child records
- foreign key references
- logical dependencies (even if no FK exists)

If dependencies exist → **do not delete**.

---

### 2. Explain why deletion is blocked

Blocked deletes must:
- explain *what* is blocking
- explain *where* it is used
- be actionable for the user

Example:
> “Cannot delete this item because it is used by 3 operations.”

---

### 3. Never cascade silently

- No silent cascading deletes
- No “best guess” cleanup
- No implicit side effects

If cascade behavior is needed, it must be:
- explicit
- visible
- confirmed by the user

---

## UI-Level Safety

- Disable delete buttons when deletion is not allowed
- Prefer early feedback over server-side failure
- Keep delete logic centralized

---

## Error Handling Pattern

When deletion fails:
- show a clear notification
- do not partially delete
- do not retry automatically

---

## Summary

- Deletion must be explicit, safe, and explainable
- Block deletion when dependencies exist
- Never cascade silently
- Prefer refusing to delete over corrupting data
