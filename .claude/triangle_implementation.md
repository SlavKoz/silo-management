# Triangle Shape Implementation

## Overview
Added TRIANGLE as a third shape type to the ShapeTemplates table, alongside CIRCLE and RECTANGLE.

## Geometry Parameters
Like CIRCLE, TRIANGLE uses the **Radius** parameter:
- **Radius**: The radius of the circumscribed circle (circle that passes through all three vertices)
- For an equilateral triangle inscribed in a circle of radius R:
  - Side length = R × √3
  - Height = 1.5R
  - The triangle is oriented with one vertex pointing up (can be rotated using RotationDeg)

## SQL Changes Required

### 1. Update ShapeType Constraint
```sql
-- Drop old constraint
ALTER TABLE [dbo].[ShapeTemplates] DROP CONSTRAINT [CK_ShapeTemplates_ShapeType];

-- Add new constraint with TRIANGLE
ALTER TABLE [dbo].[ShapeTemplates]  WITH CHECK ADD CONSTRAINT [CK_ShapeTemplates_ShapeType]
CHECK (([ShapeType]='CIRCLE' OR [ShapeType]='RECTANGLE' OR [ShapeType]='TRIANGLE'));
```

### 2. Update Geometry Constraint
```sql
-- Drop old constraint
ALTER TABLE [dbo].[ShapeTemplates] DROP CONSTRAINT [CK_ShapeTemplates_Geom];

-- Add new constraint including TRIANGLE
ALTER TABLE [dbo].[ShapeTemplates]  WITH CHECK ADD CONSTRAINT [CK_ShapeTemplates_Geom]
CHECK ((
  [ShapeType]='CIRCLE' AND [Radius] IS NOT NULL AND [Width] IS NULL AND [Height] IS NULL
  OR
  [ShapeType]='RECTANGLE' AND [Radius] IS NULL AND [Width] IS NOT NULL AND [Height] IS NOT NULL
  OR
  [ShapeType]='TRIANGLE' AND [Radius] IS NOT NULL AND [Width] IS NULL AND [Height] IS NULL
));
```

### 3. Update Positive Values Constraint
```sql
-- Drop old constraint
ALTER TABLE [dbo].[ShapeTemplates] DROP CONSTRAINT [CK_ShapeTemplates_Positive];

-- Add new constraint including TRIANGLE
ALTER TABLE [dbo].[ShapeTemplates]  WITH CHECK ADD CONSTRAINT [CK_ShapeTemplates_Positive]
CHECK ((
  [ShapeType]='CIRCLE' AND [Radius]>(0)
  OR
  [ShapeType]='RECTANGLE' AND [Width]>(0) AND [Height]>(0)
  OR
  [ShapeType]='TRIANGLE' AND [Radius]>(0)
));
```

## Application Code Changes

### Database Layer (`R/db/queries.R`)
- **Updated**: `list_shape_templates()` - now includes DefaultFill, DefaultBorder, DefaultBorderPx, Notes
- **Updated**: `get_shape_template_by_id()` - now includes all graphics fields
- **Created**: `upsert_shape_template()` - handles conditional geometry fields based on ShapeType:
  - CIRCLE/TRIANGLE: Radius required, Width/Height NULL
  - RECTANGLE: Width/Height required, Radius NULL

### Browser Module (`R/browsers/f_browser_shapes.R`)
- **Created**: Complete shapes browser module
- **Icon display**: ⭕ for CIRCLE, ▭ for RECTANGLE, 🔺 for TRIANGLE
- **Required fields**: TemplateCode and ShapeType (not geometry fields)
- **Form schema**: Includes all geometry fields (Radius, Width, Height, RotationDeg)
- **Groups**: Geometry (not collapsible), Graphics (collapsible)
- **Error handling**: User-friendly messages for geometry constraint violations

### UI Layer
- **Updated**: `R/f_app_ui.R` - Added Shapes menu item (first in menu)
- **Updated**: `R/f_app_server.R` - Added shapes route handler
- **Default route**: Changed from #/containers to #/shapes

## Drawing Logic (Future Implementation)
When rendering triangles on canvas:
```javascript
// For equilateral triangle with circumscribed circle radius R
const side = radius * Math.sqrt(3);
const height = radius * 1.5;

// Vertices (before rotation):
const vertices = [
  { x: centerX, y: centerY - radius },           // Top vertex
  { x: centerX - side/2, y: centerY + height/3 }, // Bottom left
  { x: centerX + side/2, y: centerY + height/3 }  // Bottom right
];

// Apply RotationDeg if needed
// Then draw using canvas path or SVG polygon
```

## Testing
Recommended test cases:
1. Create CIRCLE with Radius=30
2. Create RECTANGLE with Width=90, Height=45
3. Create TRIANGLE with Radius=25
4. Verify constraints:
   - Cannot create TRIANGLE without Radius
   - Cannot create TRIANGLE with Width/Height
   - Radius must be > 0
5. Test duplicate TemplateCode error handling
6. Test ShapeType change (should clear incompatible geometry fields)

## Benefits of Using Radius for Triangle
1. **Consistency**: Same parameter as CIRCLE
2. **Uniform scaling**: Easy to create triangles of different sizes
3. **Canvas drawing**: Natural fit for circumscribed circle approach
4. **Rotation**: Combined with RotationDeg, allows triangles pointing in any direction
5. **Database constraints**: Clean validation (positive Radius)
