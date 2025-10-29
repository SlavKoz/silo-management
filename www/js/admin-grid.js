// Minimal universal helpers you can reuse anywhere
window.UIGrid = {
  renderTiles: function (root, items, onClick) {
    if (!root) return;
    root.innerHTML = '';
    (items || []).forEach((it) => {
      const tile = document.createElement('button');
      tile.className = 'ui-tile';
      tile.textContent = it.label || it.text || it.id || '';
      tile.onclick = () => onClick && onClick(it, tile);
      root.appendChild(tile);
    });
  },
  renderCards: function (root, rows, onToggle) {
    if (!root) return;
    root.innerHTML = '';
    (rows || []).forEach((r) => {
      const card = document.createElement('div');
      card.className = 'ui-card';
      card.dataset.id = r.id;
      if (r.img) {
        const img = document.createElement('img');
        img.src = r.img;
        card.appendChild(img);
      }
      const label = document.createElement('div');
      label.className = 'ui-label';
      label.textContent = r.label || r.text || `${r.id}`;
      card.appendChild(label);
      card.onclick = () => {
        card.classList.toggle('selected');
        if (onToggle) onToggle(r, card);
      };
      root.appendChild(card);
    });
  },
  selectedIds: function (root) {
    return Array.from((root || document).querySelectorAll('.ui-card.selected'))
      .map(x => x.dataset.id);
  }
};

