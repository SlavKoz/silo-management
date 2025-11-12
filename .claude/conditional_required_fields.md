# Conditional Required Fields Feature

## Overview
The `requiredIf` parameter allows fields to become required based on the value of another field. This is fully declarative and reusable across all forms.

## Usage

### DSL Syntax
```r
field("Radius", "number",
      requiredIf = list(field = "ShapeType", values = c("CIRCLE", "TRIANGLE")))
```

**Parameters:**
- `field`: Name of the dependent field to watch
- `values`: Single value or array of values that trigger the requirement

### Example: Shapes Browser
```r
field("TemplateCode", "text", title="Code", required = TRUE),  # Always required
field("ShapeType", "select", title="Type",
      enum=c("CIRCLE", "RECTANGLE", "TRIANGLE"), required = TRUE),

# Conditional geometry fields
field("Radius", "number", title="Radius",
      requiredIf = list(field = "ShapeType", values = c("CIRCLE", "TRIANGLE"))),
field("Width", "number", title="Width",
      requiredIf = list(field = "ShapeType", values = "RECTANGLE")),
field("Height", "number", title="Height",
      requiredIf = list(field = "ShapeType", values = "RECTANGLE")),
field("RotationDeg", "number", title="Rotation (deg)",
      requiredIf = list(field = "ShapeType", values = c("RECTANGLE", "TRIANGLE")))
```

**Behavior:**
- **CIRCLE selected** → Radius required (red border if empty)
- **RECTANGLE selected** → Width, Height, RotationDeg required
- **TRIANGLE selected** → Radius, RotationDeg required
- Save button disabled until all currently-required fields are filled

## Implementation Details

### 1. DSL Layer (`react_table_dsl.R`)
- Added `requiredIf` parameter to `field()` function
- Passes through to `ui:options$requiredIf`

### 2. Form Renderer (`html_form_renderer.R`)
- Extracts `requiredIf` from `ui:options`
- Converts to JSON and adds as `data-required-if` attribute on inputs
- Works with all input types: text, number, select, textarea, icon picker

### 3. JavaScript (`mod_html_form.R`)
- **`setupConditionalRequired()`** function:
  - Finds all fields with `data-required-if` attribute
  - Parses JSON condition
  - Locates dependent field
  - Sets up change listeners on dependent field
  - Updates `data-required` attribute dynamically
  - Re-runs validation on change
- **Called on edit mode entry** alongside regular validation setup

### 4. Dynamic Behavior
```javascript
// When user changes ShapeType to "CIRCLE":
1. setupConditionalRequired() detects change
2. Checks Radius field's requiredIf: {field: "ShapeType", values: ["CIRCLE", "TRIANGLE"]}
3. Current value "CIRCLE" is in values array → isRequired = true
4. Sets Radius: data-required="true"
5. validateRequiredFields() runs
6. If Radius is empty → adds 'field-invalid' class (red border)
7. updateSaveButtonState() disables save button

// When user fills in Radius:
1. Input event fires
2. validateRequiredFields() runs
3. Radius has value → removes 'field-invalid' class
4. All required fields filled → save button enables
```

## Visual Feedback
- **Empty required field**: Red 2px border
- **Filled required field**: Normal gray border
- **Not currently required**: No special styling
- **Save button**: Disabled (grayed, 50% opacity) when any required field is empty

## Benefits
1. **Declarative**: Define rules in R DSL, not JavaScript
2. **Reusable**: Works across all forms automatically
3. **Dynamic**: Updates in real-time as user changes fields
4. **Type-agnostic**: Works with any field type
5. **Composable**: Can have multiple conditional fields watching same or different fields
6. **User-friendly**: Clear visual feedback, prevents invalid saves

## Future Extensions
This pattern can be extended for:
- **`visibleIf`**: Show/hide fields conditionally
- **`disabledIf`**: Enable/disable fields conditionally
- **`minIf` / `maxIf`**: Dynamic validation ranges
- **Complex conditions**: Multiple dependent fields, AND/OR logic

## Testing Checklist
1. Select CIRCLE → Radius shows red border if empty
2. Fill Radius → red border disappears
3. Select RECTANGLE → Width, Height, RotationDeg show red borders
4. Select TRIANGLE → Radius, RotationDeg show red borders
5. Save button disabled until all currently-required fields filled
6. Switch between types → correct fields become required/optional
7. Save failure recovery still works
8. Works in both "add new" and "edit existing" modes
