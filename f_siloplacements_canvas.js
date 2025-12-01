// www/js/f_siloplacements_canvas.js
// Simple canvas renderer for SiloPlacements test

(function() {
  'use strict';

  // Canvas state
  const canvases = new Map();
  const registeredNamespaces = new Set();

  // Centralized function to properly clear shape template selection (Selectize-aware)
  function clearShapeTemplateSelection(ns) {
    const dropdown = $(`#${ns}-shape_template_id`);

    if (dropdown.length) {
      const selectize = dropdown[0].selectize;
      if (selectize) {
        selectize.clear(true);
      } else {
        dropdown.val('').trigger('change');
      }
    }

    if (Shiny && Shiny.setInputValue) {
      Shiny.setInputValue(`${ns}-shape_template_id`, '', {priority: 'event'});
    }
  }

  // Update cursor based on current state and zoom - ACTUAL SIZE PREVIEW
  function updateShapeCursor(state) {
    if (!state.selectedShapeTemplate) {
      // Default cursor based on edit mode
      state.canvas.style.cursor = 'grab';
      console.log('[Cursor] Setting default cursor: grab');
      return;
    }

    const template = state.selectedShapeTemplate;
    const shapeType = template.shapeType;
    const zoom = state.zoom;
    const MAX_CURSOR = 120; // Browser cursor limit ~128px, use 120 for safety

    let cursorSize, centerX, centerY, svg;

    if (shapeType === 'CIRCLE') {
      const radius = template.radius || 20;
      const scaledRadius = radius * zoom;

      // Calculate needed cursor size
      const neededSize = scaledRadius * 2 + 4;
@@ -142,66 +143,68 @@
        dragStart: null,
        editMode: false,
        snapGrid: 0,
        // Pan/zoom/rotate state
        panX: 0,
        panY: 0,
        zoom: 1,
        rotation: 0, // degrees
        isPanning: false,
        panStart: null,
        // Background image
        backgroundImage: null,
        backgroundLoaded: false,
        backgroundVisible: true,  // Show/hide background
        backgroundScale: 1,  // Uniform scale
        backgroundOffsetX: 0,
        backgroundOffsetY: 0,
        backgroundPanMode: false,
        isBackgroundPanning: false,
        bgPanStart: null,
        // Selected shape template for cursor
        selectedShapeTemplate: null
      };

      canvases.set(canvasId, state);
      registerNamespaceHandlers(ns);

      // Set up event listeners
      setupCanvasEvents(canvas, state);
    });

    // Global ESC key handler to deselect shape template
    $(document).on('keydown', function(e) {
      if (e.key === 'Escape') {
        console.log('[Cursor] ESC pressed - clearing shape selection');

        // Blur dropdown and move focus
        const ns = Array.from(canvases.values())[0]?.ns || 'test';
        $(`#${ns}-shape_template_id`).blur();
        $(`#${ns}-edit_mode_toggle`).focus();

        // Clear selection using centralized function (Selectize-aware)
        clearShapeTemplateSelection(ns);
      }
    });
  });

  // Set up canvas event handlers
  function setupCanvasEvents(canvas, state) {
    // Mouse wheel zoom
    $(canvas).on('wheel', function(e) {
      e.preventDefault();

      const rect = canvas.getBoundingClientRect();
      const mouseX = (e.originalEvent.clientX - rect.left) * (canvas.width / rect.width);
      const mouseY = (e.originalEvent.clientY - rect.top) * (canvas.height / rect.height);

      const delta = e.originalEvent.deltaY > 0 ? 0.9 : 1.1;
      const newZoom = Math.max(0.1, Math.min(5, state.zoom * delta));

      // Zoom towards mouse position
      state.panX = mouseX - (mouseX - state.panX) * (newZoom / state.zoom);
      state.panY = mouseY - (mouseY - state.panY) * (newZoom / state.zoom);
      state.zoom = newZoom;

      render(state);
      updateShapeCursor(state); // Update cursor size with new zoom
    });
@@ -704,51 +707,51 @@
    if (message.autoFit && state.shapes.length > 0) {
      setTimeout(function() {
        fitView(state);
      }, 50);
    }
  });

  // Custom message handler: set edit mode
  Shiny.addCustomMessageHandler('test-root:setEditMode', function(message) {
    const canvasId = 'test-canvas';
    const state = canvases.get(canvasId);

    if (!state) return;

    state.editMode = message.on;

    // When turning OFF edit mode, clear shape template
    if (!message.on) {
      console.log('[Cursor] Edit mode OFF - clearing shape selection');

      // Blur dropdown and move focus
      $('#test-shape_template_id').blur();
      $('#test-edit_mode_toggle').focus();

      // Clear selection using centralized function (Selectize-aware)
      clearShapeTemplateSelection('test');
    }

    // Update cursor - will be handled by R observer responding to cleared dropdown
    if (!state.selectedShapeTemplate) {
      updateShapeCursor(state);
    }
  });

  // Custom message handler: set snap grid
  Shiny.addCustomMessageHandler('test-root:setSnap', function(message) {
    const canvasId = 'test-canvas';
    const state = canvases.get(canvasId);

    if (!state) return;

    state.snapGrid = message.units || 0;
    render(state);
  });

  // Fit view function
  function fitView(state) {
    if (!state || state.shapes.length === 0) return;

    // Calculate bounds
    let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
@@ -1141,26 +1144,203 @@

    const shapeId = message.shapeId;
    const x = message.x;
    const y = message.y;

    // Find the shape
    const shape = state.shapes.find(s => s.id === shapeId);
    if (!shape) {
      console.warn('[Canvas] Shape not found with ID:', shapeId);
      return;
    }

    // Update position based on shape type
    if (shape.type === 'circle' || shape.type === 'triangle') {
      shape.x = x;
      shape.y = y;
    } else if (shape.type === 'rect') {
      // For rectangles, x,y is top-left, but we store center in DB
      shape.x = x - shape.w / 2;
      shape.y = y - shape.h / 2;
    }

    render(state);
  });

  // Register namespace-aware handlers so the module works under any ID (app or test)
  function registerNamespaceHandlers(ns) {
    if (registeredNamespaces.has(ns)) return;
    registeredNamespaces.add(ns);

    const canvasId = `${ns}-canvas`;
    const prefix = `${ns}-root`;

    const withState = (callback) => function(message) {
      const state = canvases.get(canvasId);
      if (!state) {
        console.warn('[Canvas] State not found for:', canvasId);
        return;
      }
      callback(state, message || {});
    };

    Shiny.addCustomMessageHandler(`${prefix}:setData`, withState((state, message) => {
      state.shapes = message.data || [];

      if ('selectedId' in message) {
        state.selectedId = message.selectedId || null;
      }

      render(state);

      if (message.autoFit && state.shapes.length > 0) {
        setTimeout(function() { fitView(state); }, 50);
      }
    }));

    Shiny.addCustomMessageHandler(`${prefix}:setEditMode`, withState((state, message) => {
      state.editMode = !!message.on;

      if (!message.on) {
        console.log('[Cursor] Edit mode OFF - clearing shape selection');
        $(`#${ns}-shape_template_id`).blur();
        $(`#${ns}-edit_mode_toggle`).focus();
        clearShapeTemplateSelection(ns);
      }

      if (!state.selectedShapeTemplate) {
        updateShapeCursor(state);
      }
    }));

    Shiny.addCustomMessageHandler(`${prefix}:setSnap`, withState((state, message) => {
      state.snapGrid = message.units || 0;
      render(state);
    }));

    Shiny.addCustomMessageHandler(`${prefix}:fitView`, withState((state) => fitView(state)));

    Shiny.addCustomMessageHandler(`${prefix}:centerOnShape`, withState((state, message) => {
      const shapeId = message.id;
      const shape = state.shapes.find(s => s.id === shapeId);
      if (!shape) return;

      state.panX = shape.x;
      state.panY = shape.y;
      render(state);
    }));

    Shiny.addCustomMessageHandler(`${prefix}:setBackground`, withState((state, message) => {
      if (!message.url) {
        state.backgroundImage = null;
        state.backgroundLoaded = false;
        render(state);
        return;
      }

      const img = new Image();
      img.onload = function() {
        state.backgroundImage = img;
        state.backgroundLoaded = true;
        render(state);
      };
      img.src = message.url;
    }));

    Shiny.addCustomMessageHandler(`${prefix}:setRotation`, withState((state, message) => {
      state.rotation = message.deg || 0;
      render(state);
    }));

    Shiny.addCustomMessageHandler(`${prefix}:setBackgroundScale`, withState((state, message) => {
      state.backgroundScale = message.scale || 1;
      render(state);
    }));

    Shiny.addCustomMessageHandler(`${prefix}:setBackgroundOffset`, withState((state, message) => {
      state.backgroundOffsetX = message.x || 0;
      state.backgroundOffsetY = message.y || 0;
      render(state);
    }));

    Shiny.addCustomMessageHandler(`${prefix}:setBackgroundPanMode`, withState((state, message) => {
      state.backgroundPanMode = !!message.enabled;
    }));

    Shiny.addCustomMessageHandler(`${prefix}:setBackgroundVisible`, withState((state, message) => {
      state.backgroundVisible = !!message.visible;
      render(state);
    }));

    Shiny.addCustomMessageHandler(`${prefix}:setZoom`, withState((state, message) => {
      state.zoom = message.zoom || 1;
      render(state);
    }));

    Shiny.addCustomMessageHandler(`${prefix}:setShapeCursor`, withState((state, message) => {
      state.selectedShapeTemplate = message.template || null;
      updateShapeCursor(state);
    }));

    Shiny.addCustomMessageHandler(`${prefix}:setTempShape`, withState((state, message) => {
      state.tempShape = message.shape || null;
      render(state);
    }));

    Shiny.addCustomMessageHandler(`${prefix}:clearTempShape`, withState((state) => {
      state.tempShape = null;
      render(state);
    }));

    Shiny.addCustomMessageHandler(`${prefix}:openPanelInEditMode`, withState(() => {
      const panel = document.getElementById(`${ns}-edit_panel`);
      if (panel) panel.focus();
    }));

    Shiny.addCustomMessageHandler(`${prefix}:updateShape`, withState((state, message) => {
      const updatedShape = message.shape;
      if (!updatedShape || !updatedShape.id) return;

      const index = state.shapes.findIndex(shape => shape.id === updatedShape.id);
      if (index !== -1) {
        state.shapes[index] = updatedShape;
      }
      render(state);
    }));

    Shiny.addCustomMessageHandler(`${prefix}:setMoveMode`, withState((state, message) => {
      const shapeId = message.shapeId;
      if (!shapeId) return;

      state.selectedId = shapeId;

      if (message.enabled) {
        state.isDragging = true;
        state.canvas.style.cursor = 'move';
      } else {
        state.isDragging = false;
        state.canvas.style.cursor = 'grab';
      }
      render(state);
    }));

    Shiny.addCustomMessageHandler(`${prefix}:updateMovePosition`, withState((state, message) => {
      const shapeId = message.shapeId;
      const x = message.x;
      const y = message.y;

      const shape = state.shapes.find(s => s.id === shapeId);
      if (!shape) return;

      if (shape.type === 'circle' || shape.type === 'triangle') {
        shape.x = x;
        shape.y = y;
      } else if (shape.type === 'rect') {
        shape.x = x - shape.w / 2;
        shape.y = y - shape.h / 2;
      }

      render(state);
    }));
  }

})();
