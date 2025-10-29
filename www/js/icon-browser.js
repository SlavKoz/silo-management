// www/js/admin-grid.js (or wherever your handlers live)
Shiny.addCustomMessageHandler('icons-browser.renderSearch', function(items) {
  const root = document.getElementById('icons-search_results');
  if (!root) return;
  UIGrid.renderTiles(root, items, (it) => {
    Shiny.setInputValue('icons-icon_pick', it.id, {priority:'event'});
  });
});

Shiny.addCustomMessageHandler('icons-browser.renderTrayPreview', function(payload) {
  const el = document.getElementById('icons-tray_preview');
  if (el) el.innerHTML = payload.svg || '';
});

Shiny.addCustomMessageHandler('icons-browser.renderLibrary', function(payload) {
  const grid = document.getElementById('icons-library_grid');
  if (!grid) return;
  UIGrid.renderCards(grid, payload.rows, () => {
    const ids = UIGrid.selectedIds(grid);
    Shiny.setInputValue('icons-lib_selected_ids', ids, {priority:'event'});
  });
});

