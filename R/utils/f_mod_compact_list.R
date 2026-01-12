# R/utils/f_mod_compact_list.R
# Reusable compact list selector (isolated from Bootstrap/Fomantic conflicts)

#' Compact List UI
#' @param id Module ID
#' @param show_filter Show filter input (default TRUE)
#' @param filter_placeholder Placeholder text for filter
#' @param add_new_item Show add new button (default TRUE)
compact_list_ui <- function(id, show_filter = TRUE, filter_placeholder = "Filter...", add_new_item = TRUE) {
  ns <- NS(id)

  tagList(
    # Isolated CSS with unique prefix to avoid conflicts
    {
      css_template <- "
      /* Container reset - clear any inherited styles */
      .cl-container-%s {
        all: initial;
        display: block;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Helvetica', 'Arial', sans-serif;
        font-size: 11px;
        line-height: 1.4;
        color: #000;
      }

      /* Filter input with action button (Fomantic UI style) */
      .cl-container-%s .cl-filter {
        margin-bottom: 0.5em;
        display: flex;
      }

      .cl-container-%s .cl-filter .ui.action.input {
        width: 100%%;
      }

      .cl-container-%s .cl-filter input {
        flex: 1;
        padding: 0.4em 0.6em;
        border: 1px solid rgba(34, 36, 38, 0.15);
        border-radius: 0.28571429rem 0 0 0.28571429rem;
        font-size: 11px;
        box-sizing: border-box;
        outline: none;
      }

      .cl-container-%s .cl-filter input:focus {
        border-color: #85b7d9;
        box-shadow: 0 0 0 0.2em rgba(33, 133, 208, 0.1);
      }

      .cl-container-%s .cl-filter .ui.button {
        padding: 0.4em 0.8em;
        background: #21ba45;
        color: white;
        border: none;
        border-radius: 0 0.28571429rem 0.28571429rem 0;
        font-size: 11px;
        font-weight: bold;
        cursor: pointer;
        white-space: nowrap;
        transition: background 0.1s ease;
      }

      .cl-container-%s .cl-filter .ui.button:hover {
        background: #16ab39;
      }

      .cl-container-%s .cl-filter .ui.button:active {
        background: #198f35;
      }

      /* List container */
      .cl-container-%s .cl-list {
        border: 1px solid rgba(34, 36, 38, 0.15);
        border-radius: 0.28571429rem;
        max-height: 70vh;
        overflow-y: auto;
        padding: 0;
        margin: 0;
        list-style: none;
        background: white;
      }

      /* List items */
      .cl-container-%s .cl-item {
        padding: 0.4em 0.6em;
        cursor: pointer;
        border-bottom: 1px solid rgba(34, 36, 38, 0.1);
        display: flex;
        align-items: center;
        transition: background-color 0.1s ease;
        background-color: white;
        margin: 0;
      }

      .cl-container-%s .cl-item:last-child {
        border-bottom: none;
      }

      .cl-container-%s .cl-item:hover {
        background-color: rgba(0, 0, 0, 0.03);
      }

      /* Active/selected state */
      .cl-container-%s .cl-item.cl-active {
        background-color: #2185d0;
        color: white;
      }

      .cl-container-%s .cl-item.cl-active .cl-item-title {
        color: white;
      }

      .cl-container-%s .cl-item.cl-active .cl-item-desc {
        color: rgba(255, 255, 255, 0.85);
      }

      /* Add new style */
      .cl-container-%s .cl-item.cl-addnew {
        border: 2px dashed rgba(34, 36, 38, 0.4) !important;
        background-color: rgba(0, 0, 0, 0.03) !important;
        font-style: italic;
        color: rgba(0, 0, 0, 0.6);
      }

      .cl-container-%s .cl-item.cl-addnew .cl-item-title {
        color: rgba(0, 0, 0, 0.6);
      }

      .cl-container-%s .cl-item.cl-addnew:hover {
        background-color: rgba(0, 0, 0, 0.06) !important;
        border-color: rgba(34, 36, 38, 0.6) !important;
      }

      /* Icon */
      .cl-container-%s .cl-icon {
        font-size: 1em;
        margin-right: 0.5em;
        min-width: 20px;
        text-align: center;
        flex-shrink: 0;
        display: flex;
        align-items: center;
        justify-content: center;
      }

      .cl-container-%s .cl-icon img {
        display: block;
        width: 40px;
        height: 40px;
        object-fit: contain;
      }

      /* Content area */
      .cl-container-%s .cl-content {
        flex: 1;
        min-width: 0;
      }

      .cl-container-%s .cl-item-title {
        font-weight: 500;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        margin: 0;
        line-height: 1.3;
      }

      .cl-container-%s .cl-item-desc {
        font-size: 0.85em;
        color: rgba(0, 0, 0, 0.6);
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        margin: 0;
        margin-top: 0.15em;
        line-height: 1.2;
      }
    "

      # Auto-count placeholders and generate args
      n_css <- length(gregexpr("%s", css_template, fixed = TRUE)[[1]])
      tags$style(HTML(do.call(sprintf, c(list(css_template), rep(list(id), n_css)))))
    },

    div(class = paste0("cl-container-", id),
        if (show_filter) {
          div(class = "cl-filter",
              div(class = "ui action input",
                  tags$input(
                    type = "text",
                    id = ns("filter"),
                    placeholder = filter_placeholder
                  ),
                  if (add_new_item) {
                    tags$button(
                      class = "ui button",
                      id = ns("add_new_btn"),
                      type = "button",
                      tags$i(class = "plus icon", style = "margin: 0;"),
                      "Add New"
                    )
                  }
              )
          )
        },
        div(class = "cl-list",
            uiOutput(ns("list_items"))
        )
    ),

    # JavaScript for click handling and filter
    {
      js_template <- "
      (function() {
        var containerId = '.cl-container-%s';

        // Click handling
        $(document).on('click', containerId + ' .cl-item', function() {
          var value = $(this).data('value');
          if (value !== undefined) {
            Shiny.setInputValue('%s', value, {priority: 'event'});
          }
        });

        // Filter handling
        $(document).on('input', '#%s', function() {
          var value = $(this).val();
          Shiny.setInputValue('%s', value);
        });

        // Add New button handling
        $(document).on('click', '#%s', function() {
          Shiny.setInputValue('%s', '__NEW__', {priority: 'event'});
        });
      })();
    "

      # JavaScript has different values per placeholder, so we list them explicitly
      tags$script(HTML(sprintf(js_template, id, ns("item_clicked"), ns("filter"), ns("filter"), ns("add_new_btn"), ns("item_clicked"))))
    }
  )
}

#' Compact List Server
#' @param id Module ID
#' @param items Reactive that returns a data.frame with columns: id, icon, title, description
#' @param add_new_item Show "add new" item at bottom (default TRUE)
#' @param add_new_label Label for add new item
#' @param add_new_icon Icon for add new item
#' @param initial_selection Initial selection on first load: "first" (default), "none", or numeric ID
#' @return List with selected_id reactive
compact_list_server <- function(id, items, add_new_item = TRUE,
                                 add_new_label = "<<add new>>", add_new_icon = "",
                                 initial_selection = "first") {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    selected_id <- reactiveVal(NULL)
    initial_load_done <- reactiveVal(FALSE)
    pending_selection <- reactiveVal(NULL)  # For delayed selection

    # Filter items based on search
    filtered_items <- reactive({
      df <- items()
      filter_text <- input$filter

      if (is.null(filter_text) || !nzchar(trimws(filter_text))) {
        return(df)
      }

      filter_lower <- tolower(trimws(filter_text))
      keep <- grepl(filter_lower, tolower(df$title)) |
              grepl(filter_lower, tolower(df$description))
      df[keep, , drop = FALSE]
    })

    # Render list items
    output$list_items <- renderUI({
      df <- filtered_items()
      cur <- selected_id()  # Don't isolate - we want re-render on selection change
      cur_chr <- if (is.null(cur) || is.na(cur)) NA_character_ else as.character(cur)

      item_list <- list()

      if (nrow(df) > 0) {
        for (i in seq_len(nrow(df))) {
          id_chr <- as.character(df$id[i])
          is_active <- !is.na(cur_chr) && cur_chr == id_chr

          classes <- c("cl-item")
          if (is_active) classes <- c(classes, "cl-active")

          icon_html <- df$icon[i]
          # If icon contains HTML, render directly; otherwise treat as class name
          icon_node <- if (grepl("^<", icon_html)) {
            HTML(icon_html)
          } else {
            tags$i(class = paste(icon_html, "icon"))
          }

          item_list[[length(item_list) + 1]] <- tags$div(
            class = paste(classes, collapse = " "),
            `data-value` = id_chr,
            div(class = "cl-icon", icon_node),
            div(class = "cl-content",
                div(class = "cl-item-title", df$title[i]),
                if (nzchar(df$description[i])) {
                  div(class = "cl-item-desc", df$description[i])
                }
            )
          )
        }
      }

      # Add new item
      if (add_new_item) {
        classes <- c("cl-item", "cl-addnew")
        if (isTRUE(is.na(cur_chr))) classes <- c(classes, "cl-active")

        item_list[[length(item_list) + 1]] <- tags$div(
          class = paste(classes, collapse = " "),
          `data-value` = "__NEW__",
          div(class = "cl-icon", add_new_icon),
          div(class = "cl-content",
              div(class = "cl-item-title", add_new_label)
          )
        )
      }

      tagList(item_list)
    })

    # Handle clicks
    observeEvent(input$item_clicked, {
      val <- input$item_clicked
      cat("\n[CompactList] item_clicked:", val, "\n")

      if (is.null(val) || !nzchar(val)) {
        selected_id(NULL)
      } else if (identical(val, "__NEW__")) {
        selected_id(NA_integer_)
      } else {
        selected_id(as.integer(val))
      }

      cat("[CompactList] selected_id now:", selected_id(), "\n")
    }, ignoreInit = TRUE)

    # Handle initial selection on first load
    observe({
      if (!initial_load_done()) {
        df <- items()

        # Only proceed if we have data
        if (!is.null(df) && nrow(df) > 0) {
          if (identical(initial_selection, "first")) {
            # Select first item in list
            first_id <- as.integer(df$id[1])
            selected_id(first_id)
          } else if (is.numeric(initial_selection)) {
            # Select specific ID if it exists
            if (initial_selection %in% df$id) {
              selected_id(as.integer(initial_selection))
            }
          }
          # If "none" or any other value, leave as NULL

          initial_load_done(TRUE)
        }
      }
    })

    # Handle pending selections - wait for item to appear in list
    observe({
      pending <- pending_selection()
      if (!is.null(pending)) {
        df <- items()
        if (!is.null(df) && nrow(df) > 0) {
          # Check if the pending item is now in the list
          if (pending %in% df$id) {
            cat("[CompactList] Pending selection found in list:", pending, "\n")
            selected_id(as.integer(pending))
            pending_selection(NULL)  # Clear pending
          } else {
            cat("[CompactList] Pending selection not yet in list:", pending, "\n")
          }
        }
      }
    })

    # Programmatic selection method - returns immediately, waits for item if needed
    select_item <- function(item_id) {
      if (is.null(item_id) || is.na(item_id)) {
        selected_id(NULL)
        return()
      }

      # Check if item is already in list
      df <- isolate(items())
      if (!is.null(df) && nrow(df) > 0 && item_id %in% df$id) {
        # Item exists, select immediately
        cat("[CompactList] Selecting item immediately:", item_id, "\n")
        selected_id(as.integer(item_id))
      } else {
        # Item not in list yet, set as pending
        cat("[CompactList] Setting pending selection:", item_id, "\n")
        pending_selection(as.integer(item_id))
      }
    }

    return(list(
      selected_id = selected_id,
      select_item = select_item  # Expose selection method
    ))
  })
}
