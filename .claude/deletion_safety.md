# Deletion Safety Pattern (Referential Integrity)

## Overview

Prevents orphaned records by checking if a record is referenced elsewhere before allowing deletion. Uses a **metadata-driven approach** that's easy to extend and provides detailed user feedback.

## Architecture

### 1. Configuration (`R/db/reference_config.R`)

Defines which tables depend on which IDs. This is the **single source of truth** for referential integrity checks.

```r
REFERENCE_MAP <- list(
  Icons = list(
    id_column = "id",
    dependencies = list(
      list(
        table = "SiloOps.dbo.ContainerTypes",
        foreign_key = "Icon",
        display_name = "Container Type",
        display_name_plural = "Container Types",
        display_columns = c("TypeCode", "TypeName")
      )
    )
  )
)
```

**Configuration Fields:**
- `id_column`: Primary key column in the parent table
- `dependencies`: List of tables that reference this table
  - `table`: Full table name (schema.table)
  - `foreign_key`: Column name in the dependent table
  - `display_name`: Singular name for error messages
  - `display_name_plural`: Plural name for error messages
  - `display_columns`: Columns to show in detailed error message (which specific records are using it)

### 2. Check Function (`R/db/queries.R`)

Generic function `check_deletion_safety(table_name, record_id)` that:
1. Loads the reference configuration
2. Queries each dependency to find actual records
3. Returns detailed results with user-friendly messages

**Return Value:**
```r
list(
  can_delete = FALSE,  # TRUE if safe, FALSE if blocked
  usage = list(        # Actual records using this ID (data.frames)
    "Container Types" = data.frame(TypeCode = "...", TypeName = "...")
  ),
  message = "Cannot delete: used by 3 Container Types",  # Plain text
  message_html = "<strong>Cannot delete...</strong>..."  # HTML with details
)
```

### 3. Usage in Delete Handlers

**Pattern for all delete handlers:**

```r
observeEvent(input$delete_btn, {
  record_id <- get_current_id()

  # Check deletion safety
  safety_check <- check_deletion_safety("TableName", record_id)

  if (!safety_check$can_delete) {
    # Show detailed error with which records are blocking deletion
    showNotification(
      HTML(safety_check$message_html),
      type = "warning",
      duration = NULL  # Keep visible until dismissed
    )
    return()
  }

  # Safe to delete - proceed
  tryCatch({
    delete_record(record_id)
    showNotification("Deleted successfully", type = "message")
    refresh_list()
  }, error = function(e) {
    showNotification(paste("Delete failed:", conditionMessage(e)), type = "error")
  })
})
```

## User Experience

When deletion is blocked, the user sees:

```
⚠ Cannot delete this record

It is currently used by 2 Container Types:

Container Types:
• BULKTANK - Bulk Tank Storage
• SILO1 - Standard Grain Silo

Please remove or reassign these references before deleting.
```

Shows **which specific records** are preventing deletion (up to 5, then "... and N more").

## Adding New Protected Tables

**Step 1:** Add configuration to `R/db/reference_config.R`

```r
REFERENCE_MAP <- list(
  # ... existing entries ...

  # New protected table
  Silos = list(
    id_column = "SiloID",
    dependencies = list(
      list(
        table = "SiloOps.dbo.Operations",
        foreign_key = "SiloID",
        display_name = "Operation",
        display_name_plural = "Operations",
        display_columns = c("OperationID", "OperationType", "CreatedAt")
      ),
      list(
        table = "SiloOps.dbo.Placements",
        foreign_key = "SiloID",
        display_name = "Placement",
        display_name_plural = "Placements",
        display_columns = c("PlacementID", "LayoutID")
      )
    )
  )
)
```

**Step 2:** Update delete handler to use the check

```r
safety_check <- check_deletion_safety("Silos", silo_id)
```

That's it! No changes to the core function needed.

## Benefits

✅ **Centralized Configuration**: All dependencies in one place
✅ **Detailed Feedback**: Shows which specific records are blocking deletion
✅ **Easy to Extend**: Just add to REFERENCE_MAP
✅ **User-Friendly**: Clear error messages with actionable information
✅ **Type-Safe**: Works even if database doesn't have FK constraints
✅ **Performance**: Only queries when needed, limits to 5 shown records

## Why This Over Database Foreign Keys?

1. **More Control**: Choose which relationships to enforce (soft dependencies)
2. **Better Messages**: Custom user-friendly names and details
3. **Cross-Schema**: Works across different databases/schemas
4. **Flexible**: Can add business logic checks beyond simple FK constraints
5. **Portable**: Works regardless of DB FK constraint configuration

## Example: Icon Deletion

**Scenario**: User tries to delete an icon that's used in 2 container types.

**What Happens:**
1. User clicks delete on icon #42
2. `check_deletion_safety("Icons", 42)` runs
3. Queries `ContainerTypes WHERE Icon = 42`
4. Finds: `BULKTANK` and `SILO1`
5. Shows error with specific container type codes/names
6. User knows exactly what to change before deletion can proceed

## Testing

```r
# Test in R console
source("R/db/reference_config.R", local = TRUE)
source("R/db/queries.R", local = TRUE)

# Check if icon 42 can be deleted
result <- check_deletion_safety("Icons", 42)
print(result$can_delete)
print(result$message_html)

# Check all dependencies for a table
config <- REFERENCE_MAP$Icons
print(config$dependencies)
```

## Future Enhancements

Possible additions (not yet implemented):
- **Cascade options**: Optionally delete dependent records
- **Reassignment**: UI to reassign references before deletion
- **Soft delete**: Mark as deleted instead of physical removal
- **Audit trail**: Log deletion attempts and blocks
