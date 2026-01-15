# Fomantic / Selectize Dropdown Rules

This document contains **detailed, non-obvious rules and failure modes**
for working with Fomantic UI dropdowns and Shiny's Selectize-based inputs.

This is a **reference document**.
Only a short summary rule belongs in `.claude/conventions.md`.

---

## Core Rule (DO NOT VIOLATE)

**Never manipulate Selectize-based inputs using plain jQuery alone.**
Always use the Selectize API when available.

---

## Why This Matters

Shiny's `selectInput()` uses **Selectize.js** internally.

Problems caused by incorrect handling:
- Observers not firing on re-selecting the same value
- Dropdowns appearing cleared but not actually reset
- Race conditions masked by `setTimeout`
- UI and server state going out of sync

---

## Common Wrong Approaches

### ❌ Clearing with jQuery

```javascript
$('#my-select').val('').trigger('change');
```

Why this fails:
- Selectize maintains internal state
- DOM value changes do not reset Selectize state
- Shiny observers may not fire

---

## Correct Clearing Pattern (MANDATORY)

```javascript
function clearSelectizeInput(id) {
  const el = document.getElementById(id);
  if (!el) return;

  const selectize = el.selectize;
  if (selectize) {
    selectize.clear(true);
  } else {
    el.value = '';
    el.dispatchEvent(new Event('change'));
  }

  Shiny.setInputValue(id, '', { priority: 'event' });
}
```

Key points:
1. Check if Selectize exists
2. Use `selectize.clear(true)`
3. Always notify Shiny explicitly
4. No delays

---

## Absolutely Forbidden Patterns

- Adding `setTimeout` to "wait for Selectize"
- Clearing and re-setting the same value to force observers
- Manipulating `.selectize-input` DOM directly
- Multiple competing clear/reset functions

---

## Debugging Dropdown Issues

When dropdown behavior is wrong:

1. Inspect DOM to confirm Selectize initialization
2. Check `el.selectize` exists
3. Verify correct input ID (namespaced)
4. Confirm observers depend on the input

If it fails, the issue is **state**, not timing.

---

## Summary

- Selectize ≠ normal `<select>`
- Use the Selectize API
- Notify Shiny explicitly
- Never fight reactivity with timing hacks
