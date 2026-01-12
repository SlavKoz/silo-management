/* ==========================================================================
   Silo Canvas – app-specific glue for Stock Control
   - Wires Engine to DOM
   - Integrates with Shiny (selection, drag, pending positions)
   - Manages labels overlay, grid & snap, zoom/pan
   - Adds: background image layer, ClassRegistry, API.call() method dispatch
   - Adds: Debug HUD (hover id + coords), toggle with 'D' or Shiny setDebug
   ========================================================================== */
(function () {
  const { Engine } = window.SiloCanvas || {};
  if (!Engine) { console.error("SiloCanvas.Engine missing. Include canvas.js first."); return; }

  // -------- helpers --------
  function loadImage(url) {
    return new Promise((resolve, reject) => {
      const img = new Image();
      img.onload = () => resolve(img);
      img.onerror = reject;
      img.src = url;
    });
  }

  // Behavior/class registry (extend as needed)
  const ClassRegistry = {
    defs: Object.create(null),
    register(name, impl) { this.defs[name] = impl; },
    get(name) { return this.defs[name] || {}; }
  };
  ClassRegistry.register("Silo", {
    click(shape, api) { /* hook for opening details */ },
    toggleLabel(shape, api) { shape.showLabel = !shape.showLabel; api.redraw(); },
    setColor(shape, api, color) { shape.fill = color; api.redraw(); }
  });

  // -------- main mount --------
  function mount(nsRootId) {
    const root = document.getElementById(nsRootId);
    if (!root) return console.warn("silo-canvas mount: root not found", nsRootId);

    const canvas = root.querySelector("canvas");
    const labels = root.querySelector('[id$="-labels"]');
    if (!canvas || !labels) return console.warn("silo-canvas mount: missing canvas or labels layer");

    const engine = new Engine(canvas, { scale: 1, minScale: 0.25, maxScale: 6, tx: 0, ty: 0 });

    const state = {
      editMode: false,
      snap: 0,                // grid units (0=off)
      selectedId: null,
      pendingPos: {},         // { id: { x, y } }
      gridOn: false,
      debug: false,
      hoverId: null
    };

    // --- Debug HUD
    const debugHUD = document.createElement("div");
    debugHUD.className = "canvas-debug";
    debugHUD.innerHTML = "<span class='kv'>hover:</span> <span class='id'>—</span> <span class='kv'>| world:</span> 0,0 <span class='kv'>| screen:</span> 0,0";
    root.appendChild(debugHUD);
    function setDebug(on) {
      state.debug = !!on;
      debugHUD.style.display = state.debug ? "block" : "none";
    }
    function updateDebug({ hoverId = state.hoverId, w = { x: 0, y: 0 }, s = { x: 0, y: 0 } } = {}) {
      if (!state.debug) return;
      debugHUD.querySelector(".id").textContent = hoverId == null ? "—" : String(hoverId);
      const kvs = debugHUD.querySelectorAll(".kv");
      if (kvs.length >= 2) {
        kvs[1].nextSibling.textContent = ` ${Math.round(w.x)},${Math.round(w.y)} `;
        kvs[2].nextSibling.textContent = ` ${Math.round(s.x)},${Math.round(s.y)} `;
      }
    }

    // --- background image (screen-space)
    const bg = { img: null, scale: 1, x: 0, y: 0 };
    const _drawBase = engine._draw.bind(engine);
    engine._draw = function () {
      const ctx = this.ctx, ratio = (window.devicePixelRatio || 1);
      ctx.save();
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.clearRect(0, 0, this.width, this.height);
      if (bg.img) {
        ctx.drawImage(
          bg.img,
          bg.x, bg.y,
          bg.img.width * bg.scale * ratio,
          bg.img.height * bg.scale * ratio
        );
      }
      ctx.restore();
      _drawBase(); // draw shapes with world transform
    };

    // --- helpers
    function worldToScreen(pt) {
      const { scale, tx, ty } = engine.state;
      return { x: pt.x * scale + tx, y: pt.y * scale + ty };
    }

    function placeLabelForShape(s) {
      let el = labels.querySelector(`[data-id="${s.id}"]`);
      if (!el) {
        el = document.createElement("div");
        el.className = "canvas-label";
        el.dataset.id = s.id;
        el.tabIndex = 0;
        labels.appendChild(el);
        el.addEventListener("click", () => selectShape(s.id));
      }
      el.style.display = (s.showLabel === false) ? "none" : "block";
      el.classList.toggle("is-selected", !!s.selected);
      el.innerHTML = `<span class="code">${s.code || s.id}</span>`;

      const cx = (s.type === "circle") ? s.x : (s.x + (s.w || 0) / 2);
      const cy = (s.type === "circle") ? s.y : (s.y + (s.h || 0) / 2);
      const p = worldToScreen({ x: cx, y: cy });
      el.style.left = `${p.x}px`;
      el.style.top = `${p.y}px`;
    }

    function refreshLabels() {
      const seen = new Set();
      for (const s of engine.shapes) {
        placeLabelForShape(s);
        seen.add(String(s.id));
      }
      labels.querySelectorAll(".canvas-label").forEach(el => {
        if (!seen.has(el.dataset.id)) el.remove();
      });
    }

    function selectShape(id) {
      state.selectedId = id;
      for (const s of engine.shapes) s.selected = (s.id === id);
      engine.invalidate();
      refreshLabels();
      if (window.Shiny && nsRootId) {
        window.Shiny.setInputValue(`${nsRootId.replace(/-root$/, "")}_selection`, id, { priority: "event" });
      }
    }

    function applySnap(v) {
      const g = Number(state.snap) || 0;
      return g > 0 ? Math.round(v / g) * g : v;
    }

    // --- interactions
    let isPanning = false;
    let panStart = null;

    canvas.addEventListener("wheel", (e) => {
      if (e.ctrlKey || e.metaKey) {
        e.preventDefault();
        const factor = (e.deltaY < 0) ? 1.1 : 0.9;
        engine.zoomAt(
          factor,
          e.offsetX * (window.devicePixelRatio || 1),
          e.offsetY * (window.devicePixelRatio || 1)
        );
        refreshLabels();
      }
    }, { passive: false });

    canvas.addEventListener("mousedown", (e) => {
      const rect = canvas.getBoundingClientRect();
      const ratio = window.devicePixelRatio || 1;
      const sx = (e.clientX - rect.left) * ratio;
      const sy = (e.clientY - rect.top) * ratio;
      const w = engine.toWorld({ x: sx, y: sy });

      if (e.button === 1 || e.button === 2 || e.shiftKey) {
        isPanning = true;
        panStart = { x: e.clientX, y: e.clientY, tx: engine.state.tx, ty: engine.state.ty };
        return;
      }

      const hitId = engine.hitTest(w.x, w.y, 4);
      if (hitId != null) {
        selectShape(hitId);
        if (state.editMode) {
          engine.interaction.dragging = true;
          engine.interaction.dragId = hitId;
          engine.interaction.dragStart = w;
        }
      } else {
        state.selectedId = null;
        for (const s of engine.shapes) s.selected = false;
        engine.invalidate();
        refreshLabels();
        if (window.Shiny && nsRootId) {
          window.Shiny.setInputValue(`${nsRootId.replace(/-root$/, "")}_selection`, null, { priority: "event" });
        }
      }
    });

    window.addEventListener("mousemove", (e) => {
      // Pan path
      if (isPanning && panStart) {
        const dx = e.clientX - panStart.x;
        const dy = e.clientY - panStart.y;
        engine.setView({
          tx: panStart.tx + dx * (window.devicePixelRatio || 1),
          ty: panStart.ty + dy * (window.devicePixelRatio || 1)
        });
        refreshLabels();
        updateDebug();
        return;
      }

      // Hover + drag logic
      const rect = canvas.getBoundingClientRect();
      const ratio = window.devicePixelRatio || 1;
      const sx = (e.clientX - rect.left) * ratio;
      const sy = (e.clientY - rect.top) * ratio;
      const w = engine.toWorld({ x: sx, y: sy });

      // Update hover id when not dragging
      if (!(state.editMode && engine.interaction.dragging)) {
        state.hoverId = engine.hitTest(w.x, w.y, 4);
      }

      if (state.editMode && engine.interaction.dragging && engine.interaction.dragId != null) {
        const s = engine.getShape(engine.interaction.dragId);
        if (s) {
          const dx = applySnap(w.x) - applySnap(engine.interaction.dragStart.x);
          const dy = applySnap(w.y) - applySnap(engine.interaction.dragStart.y);
          engine.updateShape(s.id, { x: applySnap(s.x + dx), y: applySnap(s.y + dy) });
          engine.interaction.dragStart = w;
          refreshLabels();
          state.pendingPos[s.id] = { x: engine.getShape(s.id).x, y: engine.getShape(s.id).y };
          if (window.Shiny) {
            window.Shiny.setInputValue(`${nsRootId.replace(/-root$/, "")}_pending_pos`, state.pendingPos, { priority: "event" });
          }
        }
      }

      updateDebug({ w, s: { x: sx, y: sy } });
    });

    window.addEventListener("mouseup", () => {
      isPanning = false; panStart = null;
      if (engine.interaction.dragging) {
        engine.interaction.dragging = false;
        engine.interaction.dragId = null;
        engine.interaction.dragStart = null;
      }
      updateDebug();
    });

    // Toggle HUD with 'D'
    window.addEventListener("keydown", (e) => {
      if ((e.key === 'd' || e.key === 'D') &&
          (document.activeElement === document.body || root.contains(document.activeElement))) {
        setDebug(!state.debug);
        updateDebug();
      }
    });

    // --- public API for Shiny/messages
    const API = {
      setData(payload) {
        (payload || []).forEach(s => { s.className = s.className || s.type; });
        engine.setShapes(payload || []);
        refreshLabels();
      },
      setBackground(url, opts = {}) {
        if (!url) { bg.img = null; engine.invalidate(); return; }
        loadImage(url).then(img => {
          bg.img = img;
          bg.scale = Number(opts.scale || 1);
          bg.x = Number(opts.x || 0);
          bg.y = Number(opts.y || 0);
          engine.invalidate();
        }).catch(() => { bg.img = null; engine.invalidate(); });
      },
      setEditMode(on) { state.editMode = !!on; },
      setGrid(on) { state.gridOn = !!on; document.querySelector(".canvas-grid")?.classList.toggle("is-off", !on); },
      setSnap(units) { state.snap = Math.max(0, Number(units) || 0); },
      setSelection(id) {
        if (id == null) {
          state.selectedId = null;
          for (const s of engine.shapes) s.selected = false;
          engine.invalidate(); refreshLabels();
        } else {
          selectShape(id);
        }
      },
      zoomTo(factor) { engine.setView({ scale: factor }); refreshLabels(); },
      panBy(dx, dy) { engine.pan(dx, dy); refreshLabels(); },
      fitView(bounds) {
        if (!bounds) return;
        const ratio = window.devicePixelRatio || 1;
        const pad = 20 * ratio;
        const vw = engine.width, vh = engine.height;
        const sx = (vw - pad * 2) / bounds.w;
        const sy = (vh - pad * 2) / bounds.h;
        const scale = Math.max(engine.state.minScale, Math.min(engine.state.maxScale, Math.min(sx, sy)));
        const tx = pad - bounds.x * scale + (vw - bounds.w * scale) / 2 - pad;
        const ty = pad - bounds.y * scale + (vh - bounds.h * scale) / 2 - pad;
        engine.setView({ scale, tx, ty });
        refreshLabels();
      },
      clearPending() {
        state.pendingPos = {};
        if (window.Shiny) {
          window.Shiny.setInputValue(`${nsRootId.replace(/-root$/, "")}_pending_pos`, state.pendingPos, { priority: "event" });
        }
      },
      call(id, method, ...args) {
        const s = engine.getShape(id);
        if (!s) return;
        const klass = ClassRegistry.get(s.className);
        const fn = klass[method];
        if (typeof fn === "function") fn(s, API, ...args);
      },
      redraw() { engine.invalidate(); refreshLabels(); },
      setDebug(on) { setDebug(on); } // expose for Shiny
    };

    // attach API
    root._siloCanvas = API;

    // Shiny message handlers
    if (window.Shiny) {
      const ch = (name, fn) => window.Shiny.addCustomMessageHandler(nsRootId + ":" + name, fn);
      ch("setData",       (msg) => API.setData(msg.data));
      ch("setEditMode",   (msg) => API.setEditMode(!!msg.on));
      ch("setGrid",       (msg) => API.setGrid(!!msg.on));
      ch("setSnap",       (msg) => API.setSnap(msg.units));
      ch("setSelection",  (msg) => API.setSelection(msg.id));
      ch("fitView",       (msg) => API.fitView(msg.bounds));
      ch("clearPending",  ()    => API.clearPending());
      ch("setBackground", (msg) => API.setBackground(msg.url, msg.opts || {}));
      ch("call",          (msg) => API.call(msg.id, msg.method, ...(msg.args || [])));
      ch("setDebug",      (msg) => API.setDebug(!!msg.on));
    }

    // initial state
    setDebug(false);
    refreshLabels();

    return API;
  }

  // Auto-mount all canvases
  function autoMountAll() {
    document.querySelectorAll(".silo-canvas-root").forEach(root => {
      if (!root.id) return;
      if (root._siloCanvas) return;
      try { mount(root.id); } catch (e) { console.error("autoMount error", e); }
    });
  }

  window.SiloCanvas = window.SiloCanvas || {};
  window.SiloCanvas.mount = mount;
  window.addEventListener("load", autoMountAll);
  document.addEventListener("readystatechange", autoMountAll);
})();
