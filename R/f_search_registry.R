# f_search_registry.R - Global search registry for forms and items

# Static form/page entries that can be navigated to
SEARCH_FORMS <- list(
  list(id = "home",         label = "Home",             category = "forms", route = "#/home"),
  list(id = "sites",        label = "Sites",            category = "forms", route = "#/sites"),
  list(id = "sites_areas",  label = "Site Areas",       category = "forms", route = "#/sites/areas"),
  list(id = "siloes",       label = "Siloes",           category = "forms", route = "#/siloes"),
  list(id = "offline",      label = "Offline Reasons",  category = "forms", route = "#/actions/offline_reasons"),
  list(id = "operations",   label = "Operations",       category = "forms", route = "#/actions/operations"),
  list(id = "shapes",       label = "Shapes",           category = "forms", route = "#/shapes"),
  list(id = "icons",        label = "Icons",            category = "forms", route = "#/icons"),
  list(id = "containers",   label = "Containers",       category = "forms", route = "#/containers"),
  list(id = "placements",   label = "Placements",       category = "forms", route = "#/placements"),
  list(id = "canvases",     label = "Canvases",         category = "forms", route = "#/canvases")
)

# Get search items based on category and optional query filter
# Returns list of items with: id, label, category, route
f_get_search_items <- function(category = "forms", query = "", pool = NULL, limit = 50) {
  items <- list()

  # Forms category - return static form list
  if (category == "forms") {
    items <- SEARCH_FORMS
  }

  # Dynamic categories - fetch from database
  else if (!is.null(pool)) {
    tryCatch({
      if (category == "containers") {
        # Fetch container types
        if (nzchar(query)) {
          # Escape single quotes in query
          safe_query <- gsub("'", "''", query)
          sql <- sprintf(
            "SELECT TOP %d TypeCode, TypeName FROM SiloOps.dbo.ContainerTypes WHERE TypeCode LIKE '%%%s%%' OR TypeName LIKE '%%%s%%'",
            limit, safe_query, safe_query
          )
        } else {
          sql <- sprintf(
            "SELECT TOP %d TypeCode, TypeName FROM SiloOps.dbo.ContainerTypes",
            limit
          )
        }
        df <- DBI::dbGetQuery(pool, sql)

        if (nrow(df) > 0) {
          items <- lapply(1:nrow(df), function(i) {
            list(
              id = df$TypeCode[i],
              label = paste0(df$TypeCode[i], " - ", df$TypeName[i]),
              category = "containers",
              route = paste0("#/containers/", df$TypeCode[i])
            )
          })
        }
      }

      else if (category == "shapes") {
        # Fetch shape templates
        if (nzchar(query)) {
          safe_query <- gsub("'", "''", query)
          sql <- sprintf(
            "SELECT TOP %d TemplateCode, ShapeType FROM SiloOps.dbo.ShapeTemplates WHERE TemplateCode LIKE '%%%s%%' OR ShapeType LIKE '%%%s%%'",
            limit, safe_query, safe_query
          )
        } else {
          sql <- sprintf(
            "SELECT TOP %d TemplateCode, ShapeType FROM SiloOps.dbo.ShapeTemplates",
            limit
          )
        }
        df <- DBI::dbGetQuery(pool, sql)

        if (nrow(df) > 0) {
          items <- lapply(1:nrow(df), function(i) {
            list(
              id = df$TemplateCode[i],
              label = paste0(df$TemplateCode[i], " - ", df$ShapeType[i]),
              category = "shapes",
              route = paste0("#/shapes/", df$TemplateCode[i])
            )
          })
        }
      }

      else if (category == "siloes") {
        # Fetch siloes
        if (nzchar(query)) {
          safe_query <- gsub("'", "''", query)
          sql <- sprintf(
            "SELECT TOP %d SiloID, SiloName FROM SiloOps.dbo.Silos WHERE SiloID LIKE '%%%s%%' OR SiloName LIKE '%%%s%%'",
            limit, safe_query, safe_query
          )
        } else {
          sql <- sprintf(
            "SELECT TOP %d SiloID, SiloName FROM SiloOps.dbo.Silos",
            limit
          )
        }
        df <- DBI::dbGetQuery(pool, sql)

        if (nrow(df) > 0) {
          items <- lapply(1:nrow(df), function(i) {
            list(
              id = df$SiloID[i],
              label = paste0(df$SiloID[i], " - ", df$SiloName[i]),
              category = "siloes",
              route = paste0("#/siloes/", df$SiloID[i])
            )
          })
        }
      }

      else if (category == "sites") {
        # Fetch sites
        if (nzchar(query)) {
          safe_query <- gsub("'", "''", query)
          sql <- sprintf(
            "SELECT TOP %d SiteCode, SiteName FROM SiloOps.dbo.Sites WHERE SiteCode LIKE '%%%s%%' OR SiteName LIKE '%%%s%%'",
            limit, safe_query, safe_query
          )
        } else {
          sql <- sprintf(
            "SELECT TOP %d SiteCode, SiteName FROM SiloOps.dbo.Sites",
            limit
          )
        }
        df <- DBI::dbGetQuery(pool, sql)

        if (nrow(df) > 0) {
          items <- lapply(1:nrow(df), function(i) {
            list(
              id = df$SiteCode[i],
              label = paste0(df$SiteCode[i], " - ", df$SiteName[i]),
              category = "sites",
              route = paste0("#/sites/", df$SiteCode[i])
            )
          })
        }
      }

      else if (category == "areas") {
        # Fetch areas with composite code (SiteCode-AreaCode)
        if (nzchar(query)) {
          safe_query <- gsub("'", "''", query)

          # Check if query looks like a composite code (contains hyphen)
          site_filter <- NULL
          area_filter <- NULL
          if (grepl("-", query, fixed = TRUE)) {
            parts <- strsplit(query, "-", fixed = TRUE)[[1]]
            if (length(parts) >= 2) {
              site_filter <- gsub("'", "''", trimws(parts[1]))
              area_filter <- gsub("'", "''", trimws(paste(parts[-1], collapse = "-")))
            }
          }

          if (!is.null(site_filter) && !is.null(area_filter)) {
            # Search for specific site+area combination
            sql <- sprintf(
              "SELECT TOP %d a.AreaCode, a.AreaName, s.SiteCode
               FROM SiloOps.dbo.SiteAreas a
               LEFT JOIN SiloOps.dbo.Sites s ON a.SiteID = s.SiteID
               WHERE (s.SiteCode LIKE '%%%s%%' AND a.AreaCode LIKE '%%%s%%')
                  OR a.AreaName LIKE '%%%s%%'
                  OR a.AreaCode LIKE '%%%s%%'
                  OR s.SiteCode LIKE '%%%s%%'",
              limit, site_filter, area_filter, safe_query, safe_query, safe_query
            )
          } else {
            # General search
            sql <- sprintf(
              "SELECT TOP %d a.AreaCode, a.AreaName, s.SiteCode
               FROM SiloOps.dbo.SiteAreas a
               LEFT JOIN SiloOps.dbo.Sites s ON a.SiteID = s.SiteID
               WHERE a.AreaCode LIKE '%%%s%%' OR a.AreaName LIKE '%%%s%%' OR s.SiteCode LIKE '%%%s%%'",
              limit, safe_query, safe_query, safe_query
            )
          }
        } else {
          sql <- sprintf(
            "SELECT TOP %d a.AreaCode, a.AreaName, s.SiteCode
             FROM SiloOps.dbo.SiteAreas a
             LEFT JOIN SiloOps.dbo.Sites s ON a.SiteID = s.SiteID",
            limit
          )
        }
        df <- DBI::dbGetQuery(pool, sql)

        if (nrow(df) > 0) {
          items <- lapply(1:nrow(df), function(i) {
            composite_code <- paste0(df$SiteCode[i], "-", df$AreaCode[i])
            list(
              id = composite_code,
              label = paste0(composite_code, " - ", df$AreaName[i]),
              category = "areas",
              route = paste0("#/areas/", composite_code)
            )
          })
        }
      }

      else if (category == "operations") {
        # Fetch operations
        if (nzchar(query)) {
          safe_query <- gsub("'", "''", query)
          sql <- sprintf(
            "SELECT TOP %d OpCode, OpName FROM SiloOps.dbo.Operations WHERE OpCode LIKE '%%%s%%' OR OpName LIKE '%%%s%%'",
            limit, safe_query, safe_query
          )
        } else {
          sql <- sprintf(
            "SELECT TOP %d OpCode, OpName FROM SiloOps.dbo.Operations",
            limit
          )
        }
        df <- DBI::dbGetQuery(pool, sql)

        if (nrow(df) > 0) {
          items <- lapply(1:nrow(df), function(i) {
            list(
              id = df$OpCode[i],
              label = paste0(df$OpCode[i], " - ", df$OpName[i]),
              category = "operations",
              route = paste0("#/actions/operations/", df$OpCode[i])
            )
          })
        }
      }
    }, error = function(e) {
      warning("Search query error: ", conditionMessage(e))
    })
  }

  # Filter by query if provided (for forms category or additional filtering)
  if (nzchar(query) && category == "forms") {
    items <- Filter(function(x) grepl(query, x$label, ignore.case = TRUE), items)
  }

  items
}

# Get available categories for the search dropdown
f_get_search_categories <- function() {
  list(
    list(value = "forms",      label = "Forms"),
    list(value = "containers", label = "Containers"),
    list(value = "shapes",     label = "Shapes"),
    list(value = "siloes",     label = "Siloes"),
    list(value = "sites",      label = "Sites"),
    list(value = "areas",      label = "Areas"),
    list(value = "operations", label = "Operations")
  )
}
