# 🔗 Hash-Based Routing & Deep-Linking in Shiny

### Overview
Your Shiny app uses a **hash-router** (URLs like `#/sites`, `#/siloes`, etc.).  
This system lets each page or subpage have its own unique address without reloading the app.

With a small extension, you can also deep-link directly to **individual items** within a page — for example:
- `#/siloes/SL-101` → opens the *Siloes* page and preselects silo **SL-101**  
- `#/sites?item=NorthYard` → opens the *Sites* page and shows site **NorthYard**

This approach enables:
- Bookmarking and sharing of specific items or views  
- Browser back/forward navigation between items  
- Automatic state restoration when reloading a bookmarked link  

---

## 1. URL Structure

You can use either **path parameters** or **query parameters**.

| Type | Example | When to Use |
|------|----------|-------------|
| **Path** | `#/siloes/SL-101` | Clean URLs for single ID lookups |
| **Query** | `#/siloes?item=SL-101&tab=details` | When you may have multiple parameters (e.g., filters, tabs) |

Both formats work with the same parsing helper.

---

## 2. Hash Parsing Helpers

Add this to `R/f_router_helpers.R`:

```r
# Parse "#/section/sub?key=val&item=123" into list(parts=..., qs=list(...))
f_hash_parse <- function(h, default = "#/sites") {
  h <- f_or(h, default)
  h <- sub("^#/", "", h)
  parts_q <- strsplit(h, "?", fixed = TRUE)[[1]]
  path <- parts_q[1]
  qs   <- parts_q[2]
  parts <- Filter(nzchar, strsplit(path, "/", fixed = TRUE)[[1]])
  qs_list <- list()
  if (!is.na(qs) && nzchar(qs)) {
    kv <- strsplit(qs, "&", fixed = TRUE)[[1]]
    for (p in kv) {
      y <- strsplit(p, "=", fixed = TRUE)[[1]]
      if (length(y) >= 1) {
        k <- utils::URLdecode(y[1])
        v <- utils::URLdecode(ifelse(length(y) >= 2, y[2], ""))
        qs_list[[k]] <- v
      }
    }
  }
  list(parts = parts, qs = qs_list)
}

# Build a hash from parts and optional query list
f_hash_build <- function(parts, qs = NULL) {
  p <- paste(c("", parts), collapse = "/")
  if (!is.null(qs) && length(qs)) {
    q <- paste(paste0(names(qs), "=", utils::URLencode(as.character(qs), reserved = TRUE)), collapse = "&")
    paste0("#", p, "?", q)
  } else paste0("#", p)
}
```

---

## 3. Universal Deep-Link Helper

Also in `R/f_router_helpers.R`:

```r
# Enable deep-linking for a module.
# route_root: e.g. "siloes" or c("sites","areas")
# get_id(): returns current selected ID
# set_id(id): selects an item by ID
# id_param = FALSE → use path (#/siloes/ID)
# id_param = TRUE  → use query (#/siloes?item=ID)
enable_deeplink <- function(session, route_root, get_id, set_id, id_param = FALSE) {
  root <- as.character(route_root)

  # 1) URL → select item
  observeEvent(session$input$f_route, ignoreInit = TRUE, {
    h  <- session$input$f_route
    ph <- f_hash_parse(h)
    parts <- ph$parts
    if (length(parts) >= length(root) && identical(parts[seq_along(root)], root)) {
      id <- NULL
      if (isTRUE(id_param)) {
        id <- ph$qs$item %||% NULL
      } else if (length(parts) >= length(root) + 1) {
        id <- parts[length(root) + 1]
      }
      if (!is.null(id) && !identical(get_id(), id)) {
        set_id(id)
      }
    }
  })

  # 2) Selection → URL
  observe({
    id <- get_id()
    if (is.null(id) || is.na(id) || identical(id, "")) return()
    h <- if (isTRUE(id_param)) {
      f_hash_build(root, qs = list(item = id))
    } else {
      f_hash_build(c(root, id))
    }
    session$sendCustomMessage("set-hash", list(h = h))
  })
}
```

---

## 4. Using Deep-Linking in a Module

Example for your **Siloes** browser module:

```r
f_browser_siloes_server <- function(id, pool) {
  moduleServer(id, function(input, output, session) {
    selected_id <- reactiveVal(NULL)

    # --- Example: user clicks in a table ---
    # observeEvent(input$tbl_rows_selected, {
    #   selected_id(df$SiloID[input$tbl_rows_selected])
    # })

    get_id <- function() selected_id()
    set_id <- function(id) {
      selected_id(id)
      # (Optional) visually select row in DT table
      # DT::dataTableProxy(session$ns("tbl")) %>%
      #   DT::selectRows(which(df$SiloID == id))
    }

    # Enable deep-linking: URLs like #/siloes/SL-101
    enable_deeplink(session,
                    route_root = "siloes",
                    get_id = get_id,
                    set_id = set_id,
                    id_param = FALSE)
  })
}
```

Now:
- Selecting an item updates the URL (`#/siloes/<id>`)  
- Loading that URL later (or using browser back/forward) restores the selection

---

## 5. Minimal JavaScript for URL Sync

Add this once (you already have a script block for routing):

```js
Shiny.addCustomMessageHandler('set-hash', function(msg){
  if (msg && msg.h && location.hash !== msg.h) location.hash = msg.h;
});
```

Your global `hashchange` listener already triggers the server update via `input$f_route`.

---

## 6. Behavior Summary

| Action | Effect |
|--------|---------|
| User clicks an item | The URL changes to `#/section/<id>` |
| User copies/bookmarks the URL | On reload, the same page and item reopen |
| Browser Back / Forward | Navigates between previously selected items |
| Programmatic selection | Also updates the URL automatically |

---

## 7. Notes & Best Practices
- Always validate IDs from the URL before using them.  
- Avoid putting sensitive info in hashes; URLs may be shared.  
- Path form (`#/section/id`) is cleanest for unique IDs; query form works best for compound states.  
- You can add extra query parameters (`#/sites?item=1&tab=summary`) if a page has tabs.  
- Works fully client-side; no server reloads needed.  

---

### ✅ Summary

You only need to:
1. Include `f_router_helpers.R` once in your project.  
2. For each form or browser module, define a `selected_id` reactive and two simple functions (`get_id`, `set_id`).  
3. Call `enable_deeplink(session, route_root, get_id, set_id)` inside that module.  

That’s it — now every subpage and item in your app can be directly addressed, bookmarked, and reopened via URL hash.
