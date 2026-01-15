# DOM Inspection First — Debugging Doctrine

This document contains the **detailed rules, examples, and lessons learned**
for debugging JavaScript and Shiny DOM-related issues.

This is a **reference document**.
Only the **summary rule** belongs in `.claude/conventions.md`.

---

## Golden Rule (NON-NEGOTIABLE)

**Always inspect the actual DOM before adding delays, retries, or workarounds.**

If JavaScript “cannot find” an element, then one of the following is true:

1. The element does not exist
2. The element exists but has a different ID
3. The element exists in a different namespace
4. The element is not rendered (`suspendWhenHidden = TRUE`)

Delays do **not** fix any of these.

---

## Critical First Step (ALWAYS DO THIS)

Before trying `setTimeout`, timing fixes, or complex logic:

### 1. List actual DOM elements

```javascript
const allElements = document.querySelectorAll('[id*="form"]');
console.log(
  'All form elements:',
  Array.from(allElements).map(el => el.id)
);
```

### 2. Verify your target exists

```javascript
const target = document.getElementById('expected-id');
console.log('Target exists:', !!target);
```

### 3. Verify required JS functions exist

```javascript
console.log(
  'Function exists:',
  typeof window['expectedFunctionName']
);
```

---

## Common Root Causes

### Shiny module double namespacing

Shiny modules always namespace outputs twice:

```
module-id + "-" + output-id
```

Example:
- ❌ `test-form`
- ✅ `test-form-form`

Never assume IDs — inspect them.

---

### Hidden outputs do not render

Hidden outputs (`suspendWhenHidden = TRUE`) do not exist in the DOM.

Fix:
```r
outputOptions(output, "form_content", suspendWhenHidden = FALSE)
```

---

## Why setTimeout Is Almost Always Wrong

Delays mask real problems, create race conditions, and waste time.
Fix the DOM, not the timing.

---

## Debug Template

```javascript
const elements = document.querySelectorAll('[id*="keyword"]');
console.log(
  'Found elements:',
  Array.from(elements).map(el => ({
    id: el.id,
    classes: el.className,
    tag: el.tagName
  }))
);

const target = document.getElementById('your-id');
console.log('Target found:', !!target);

console.log(
  'Function exists:',
  typeof window['function_name_here']
);
```

---

## Final Rule

If JavaScript cannot find an element, the DOM is wrong — not the timing.
Inspect first. Fix the root cause.
