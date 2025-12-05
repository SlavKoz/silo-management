# R/db/reference_config.R
# Reference integrity configuration for delete safety checks

# Define which tables depend on which IDs
# This prevents orphaned records when deleting parent records
REFERENCE_MAP <- list(

  # Icons table - check before deleting icons
  Icons = list(
    id_column = "id",
    dependencies = list(
      list(
        table = "SiloOps.dbo.ContainerTypes",
        foreign_key = "Icon",
        display_name = "Container Type",
        display_name_plural = "Container Types",
        # Which columns to show in error message
        display_columns = c("TypeCode", "TypeName")
      )
    )
  ),

  # ContainerTypes table - check before deleting container types
  ContainerTypes = list(
    id_column = "ContainerTypeID",
    dependencies = list(
      list(
        table = "SiloOps.dbo.Silos",
        foreign_key = "ContainerTypeID",
        display_name = "Silo",
        display_name_plural = "Silos",
        display_columns = c("SiloName")
      )
    )
  )

  # Add more tables as needed:
  # Silos = list(
  #   id_column = "SiloID",
  #   dependencies = list(...)
  # )
)
