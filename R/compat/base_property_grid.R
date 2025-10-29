
# R/compat/base_property_grid.R
.base_grid_warn <- function(fn) {
  warning(sprintf("[DEPRECATED] %s() was called. Replace with react_table_*().", fn),
          call. = FALSE, immediate. = TRUE)
}

# legacy UI/server names you might have used
propertyGridUI <- function(id, ...) {
  .base_grid_warn("propertyGridUI")
  # show something visible so it’s obvious in the UI if it still renders
  ns <- shiny::NS(id)
  shiny::div(class = "alert alert-warning",
             sprintf("Deprecated: propertyGridUI(%s). Replace with react_table_ui().", id))
}

propertyGridServer <- function(id, ...) {
  .base_grid_warn("propertyGridServer")
  # no-op so the app won’t crash; return invisibly
  moduleServer(id, function(input, output, session) { invisible(NULL) })
}

# If you had these names:
rjsfGridUI     <- function(id, ...) { .base_grid_warn("rjsfGridUI");  react_table_ui(id, ...) }
rjsfGridServer <- function(id, ...) { .base_grid_warn("rjsfGridServer"); react_table_server(id, ...) }



propertyGridUI <- function(id, title = NULL, columns = 4, compact = TRUE, ...) {
  dots <- list(...)
  show_layout_toggle <- isTRUE(dots$show_layout_toggle)   # default FALSE
  box_width  <- dots$box_width
  box_height <- dots$box_height
  
  ns <- NS(id)
  
  # Optional inline sizing (only if provided)
  sizing_css <- NULL
  if (!is.null(box_width) || !is.null(box_height)) {
    bw <- if (is.null(box_width))  "auto" else sprintf("%dpx", as.integer(box_width))
    bh <- if (is.null(box_height)) "auto" else sprintf("%dpx", as.integer(box_height))
    sizing_css <- tags$style(HTML(sprintf(
      ".prop-box { width:%s; height:%s; }", bw, bh
    )))
  }
  
  tagList(
    tags$head(sizing_css),   # no-op if NULL
    if (!is.null(title)) h4(title),
    
    # Optional toolbar: preserves old behavior if requested
    if (isTRUE(show_layout_toggle))
      div(class = "pg-toolbar",
          checkboxInput(ns("collapse"), "Single column", value = isTRUE(compact), width = "160px")
      ),
    
    div(class = "prop-box",
        uiOutput(
          ns("grid"),
          container = div,
          class  = paste0("pg-grid", if (compact) " pg-compact" else ""),
          style  = sprintf("--pg-cols:%d;", as.integer(columns))
        )
    )
  )
}


propertyGridServer <- function(id, schema, initial_values = list(),
                               initial_choices = list(), max_fields = 20, ...) {
  dots <- list(...)
  group_order        <- dots$group_order
  group_labels       <- dots$group_labels
  groups_collapsible <- if (!is.null(dots$groups_collapsible)) isTRUE(dots$groups_collapsible) else TRUE
  
  `%||%` <- function(a, b) if (is.null(a)) b else a
  
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    
    rv_modes <- reactiveVal({
      # default modes: "editable" unless schema item says editable = FALSE
      modes <- setNames(rep("editable", length(schema)), vapply(schema, `[[`, "", "id"))
      for (i in seq_along(schema)) {
        if (isFALSE(schema[[i]]$editable)) modes[[ schema[[i]]$id ]] <- "static"
      }
      modes
    })
    
    current    <- reactiveValues(values = initial_values)
    rv_choices <- reactiveValues()
    # if (length(initial_choices)) for (nm in names(initial_choices)) {
    #   ch <- initial_choices[[nm]]
    #   ch <- as.character(ch); if (!is.null(names(ch))) names(ch) <- as.character(names(ch))
    #   rv_choices[[nm]] <- ch
    # }
    
    if (length(initial_choices)) {
      for (nm in names(initial_choices)) {
        ch <- initial_choices[[nm]]
        # normalize to what selectInput expects
        if (is.list(ch)) {
          rv_choices[[nm]] <- ch
        } else if (is.atomic(ch)) {
          # named vector -> list of values, names used as labels
          labs <- names(ch)
          vals <- as.character(ch)
          li   <- as.list(vals)
          if (!is.null(labs)) names(li) <- labs
          rv_choices[[nm]] <- li
        }
      }
    }
    
    normalize_choices <- function(ch) {
      if (is.null(ch)) return(list())
      if (is.list(ch) && !is.null(names(ch))) {
        out <- lapply(ch, function(x) as.character(if (length(x)) x[[1]] else "")); names(out) <- as.character(names(ch)); return(out)
      }
      if (is.atomic(ch)) {
        lbls <- names(ch); vals <- as.character(ch); out <- as.list(vals); if (!is.null(lbls)) names(out) <- as.character(lbls); return(out)
      }
      list()
    }
    
    build_control <- function(p, value, choices = NULL) {
      inputId <- ns(p$id)
      switch(p$type,
             "text"   = textInput(inputId, NULL, value = as.character(value %||% ""), width = "100%"),
             "number" = numericInput(inputId, NULL,
                                     value = suppressWarnings(as.numeric(value)),
                                     min = p$min %||% NA, max = p$max %||% NA, step = p$step %||% NA, width = "100%"),
             "bool"   = checkboxInput(inputId, NULL, value = isTRUE(value)),
             # "select" = {
             #   ch <- normalize_choices(choices %||% (p$choices %||% character(0)))
             #   selectInput(inputId, NULL, choices = ch, selected = as.character(value %||% ""), width = "100%", selectize = FALSE)
             # },
             "select" = {
               # pick from rv_choices first, then schema’s p$choices
               ch <- rv_choices[[p$id]]
               if (is.null(ch)) ch <- p$choices
               # (optional) normalize like above if needed
               selectInput(inputId, NULL,
                           choices = ch %||% list(),
                           selected = as.character(value %||% ""),
                           width = "100%", selectize = FALSE)
             },
             "color"  = tags$input(type = "color", id = inputId,
                                   value = as.character(value %||% "#ffffff"),
                                   oninput = sprintf("Shiny.setInputValue('%s', this.value, {priority: 'event'})", inputId)),
             "slider" = tags$input(type = "range", id = inputId,
                                   min = p$min %||% 0, max = p$max %||% 100, step = p$step %||% 1,
                                   value = as.integer(value %||% 0),
                                   oninput = sprintf("Shiny.setInputValue('%s', parseInt(this.value), {priority: 'event'})", inputId)),
             "date"   = tags$input(type = "date", id = inputId,
                                   value = if (!is.null(value)) format(as.Date(value), "%Y-%m-%d") else "",
                                   oninput = sprintf("Shiny.setInputValue('%s', this.value, {priority: 'event'})", inputId)),
             textInput(inputId, NULL, value = as.character(value %||% ""), width = "100%")
      )
    }
    
    # Optional grouping
    has_group_field <- any(vapply(schema, function(p) !is.null(p$group), logical(1)))
    use_groups <- isTRUE(has_group_field || length(group_order) || length(group_labels))
    
    group_key   <- function(p) p$group %||% "Ungrouped"
    groups_list <- if (use_groups) split(schema, vapply(schema, group_key, "")) else list(All = schema)
    order_names <- names(groups_list)
    if (use_groups && length(group_order)) {
      leftovers  <- setdiff(order_names, group_order)
      order_names <- c(group_order, leftovers)
    }
    
    output$grid <- renderUI({
      #vals_snapshot <- as.list(current$values)
      vals_snapshot <- isolate(as.list(current$values))
      ch_snapshot   <- reactiveValuesToList(rv_choices)
      
      make_one_field <- function(p) {
        #val <- vals_snapshot[[p$id]]
        val <- current$values[[p$id]]
        ch  <- normalize_choices(ch_snapshot[[p$id]] %||% p$choices)
        mode  <- rv_modes()[[p$id]] %||% "editable"
        
        if (identical(mode, "hidden")) return(NULL)
        
        # static => show read-only text instead of an input
        control_ui <- if (identical(mode, "static")) {
          # pretty print for common types
          display <- if (p$type %in% c("number","slider")) {
            as.character(suppressWarnings(as.numeric(val)))
          } else if (p$type %in% c("bool")) {
            if (isTRUE(val)) "TRUE" else "FALSE"
          } else {
            as.character(val %||% "")
          }
          div(class = "prop-static", display)
        } else {
          build_control(p, val, ch)  # your existing input builder
        }
        
        div(class="prop-row",
            div(class="prop-label",  p$label),
            div(class="prop-control", control_ui)
        )
      }
      
      if (!use_groups) {
        tagList(lapply(schema, make_one_field))
      } else {
        do.call(tagList, lapply(order_names, function(g) {
          items <- groups_list[[g]]; if (is.null(items)) return(NULL)
          label <- if (!is.null(group_labels) && !is.null(group_labels[[g]])) group_labels[[g]] else g
          inner <- tagList(lapply(items, make_one_field))
          if (isTRUE(groups_collapsible)) {
            tags$details(open = NA, class = "prop-group",
                         tags$summary(tagList(span(class = "chev", "▸"), label)),
                         inner
            )
          } else {
            tagList(div(class = "prop-group", label), inner)
          }
        }))
      }
    })
    
    # setters / choices (unchanged)
    set_values <- function(values = list()) {
      for (p in schema) {
        id <- p$id
        if (!id %in% names(values)) next
        val <- values[[id]]
        if (p$type == "select") {
          updateSelectInput(session, id, selected = as.character(val %||% "")); current$values[[id]] <- val
        } else if (p$type == "text") {
          updateTextInput(session, id, value = as.character(val %||% "")); current$values[[id]] <- val
        } else if (p$type == "number") {
          updateNumericInput(session, id, value = suppressWarnings(as.numeric(val))); current$values[[id]] <- suppressWarnings(as.numeric(val))
        } else if (p$type == "bool") {
          updateCheckboxInput(session, id, value = isTRUE(val)); current$values[[id]] <- isTRUE(val)
        } else if (p$type == "color") {
          session$sendInputMessage(id, list(value = as.character(val %||% "#ffffff"))); current$values[[id]] <- val
        } else if (p$type == "slider") {
          session$sendInputMessage(id, list(value = as.integer(val %||% 0))); current$values[[id]] <- suppressWarnings(as.integer(val %||% 0))
        } else if (p$type == "date") {
          session$sendInputMessage(id, list(value = if (!is.null(val)) format(as.Date(val), "%Y-%m-%d") else "")); current$values[[id]] <- val
        } else {
          updateTextInput(session, id, value = as.character(val %||% "")); current$values[[id]] <- val
        }
      }
    }
    
    set_field_mode <- function(ids, mode = c("editable","static","hidden")) {
      mode <- match.arg(mode)
      m <- rv_modes()
      for (id in ids) if (id %in% names(m)) m[[id]] <- mode
      rv_modes(m)                 
      invisible(TRUE)
    }
    
    
    set_choices <- function(choices = list()) {
      for (nm in names(choices)) {
        ch <- normalize_choices(choices[[nm]])
        rv_choices[[nm]] <- ch
        cur <- isolate(as.character(current$values[[nm]] %||% ""))
        if (!nzchar(cur) || !(cur %in% unlist(ch, use.names = FALSE))) cur <- ""
        updateSelectInput(session, nm, choices = ch, selected = cur)
      }
    }
    
    # inputs -> values
    observe({
      lapply(schema, function(p) {
        v <- input[[p$id]]
        if (!is.null(v)) {
          if (p$type %in% c("number","slider")) v <- suppressWarnings(as.numeric(v))
          if (p$type == "bool")                 v <- isTRUE(v)
          if (p$type == "date" && nzchar(v))    v <- as.Date(v)
          current$values[[p$id]] <- v
        }
      })
    })
    
    list(values = reactive(current$values),
         set_values = set_values,
         set_choices = set_choices,
         set_field_mode = set_field_mode)
  })
}

