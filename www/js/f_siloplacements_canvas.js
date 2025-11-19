// www/js/f_siloplacements_canvas.js
// Simple canvas renderer for SiloPlacements test

(function() {
  'use strict';

  // Canvas state
  const canvases = new Map();

  // Update cursor based on current state and zoom - ACTUAL SIZE PREVIEW
  function updateShapeCursor(state) {
    if (!state.selectedShapeTemplate) {
      state.canvas.style.cursor = state.editMode ? 'move' : 'grab';
      return;
    }

    const template = state.selectedShapeTemplate;
    const shapeType = template.shapeType;
    const zoom = state.zoom;

    // Calculate ACTUAL cursor size based on zoom (no artificial clamping)
    let cursorSize, centerX, centerY, svg;

    if (shapeType === 'CIRCLE') {
      const radius = template.radius || 20;
      const scaledRadius = radius * zoom;

      // Minimal clamping for visibility (2px minimum, 200px max for browser compatibility)
      const displayRadius = Math.max(2, Math.min(200, scaledRadius));
      cursorSize = displayRadius * 2 + 4; // +4 for stroke
      centerX = centerY = cursorSize / 2;

      svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${cursorSize}" height="${cursorSize}">
        <circle cx="${centerX}" cy="${centerY}" r="${displayRadius}" fill="rgba(59,130,246,0.15)" stroke="rgba(59,130,246,0.8)" stroke-width="2"/>
      </svg>`;

    } else if (shapeType === 'RECTANGLE') {
      const width = template.width || 40;
      const height = template.height || 40;
      const scaledWidth = width * zoom;
      const scaledHeight = height * zoom;

      // Minimal clamping for browser compatibility
      const displayWidth = Math.max(4, Math.min(200, scaledWidth));
      const displayHeight = Math.max(4, Math.min(200, scaledHeight));
      cursorSize = Math.max(displayWidth, displayHeight) + 4;
      centerX = cursorSize / 2;
      centerY = cursorSize / 2;

      const rectX = centerX - displayWidth / 2;
      const rectY = centerY - displayHeight / 2;

      svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${cursorSize}" height="${cursorSize}">
        <rect x="${rectX}" y="${rectY}" width="${displayWidth}" height="${displayHeight}" fill="rgba(34,197,94,0.15)" stroke="rgba(34,197,94,0.8)" stroke-width="2"/>
      </svg>`;

    } else if (shapeType === 'TRIANGLE') {
      const radius = template.radius || 20;
      const scaledRadius = radius * zoom;

      const displayRadius = Math.max(2, Math.min(200, scaledRadius));
      cursorSize = displayRadius * 2 + 4;
      centerX = centerY = cursorSize / 2;

      // Triangle points (equilateral, pointing up)
      const p1x = centerX;
      const p1y = centerY - displayRadius;
      const p2x = centerX - displayRadius * 0.866;
      const p2y = centerY + displayRadius * 0.5;
      const p3x = centerX + displayRadius * 0.866;
      const p3y = centerY + displayRadius * 0.5;

      svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${cursorSize}" height="${cursorSize}">
        <polygon points="${p1x},${p1y} ${p2x},${p2y} ${p3x},${p3y}" fill="rgba(168,85,247,0.15)" stroke="rgba(168,85,247,0.8)" stroke-width="2"/>
      </svg>`;

    } else {
      state.canvas.style.cursor = state.editMode ? 'move' : 'grab';
      return;
    }

    const url = 'data:image/svg+xml;base64,' + btoa(svg);
    state.canvas.style.cursor = `url('${url}') ${centerX} ${centerY}, crosshair`;

    console.log('[Canvas] Cursor updated - type:', shapeType, 'zoom:', zoom.toFixed(2), 'size:', cursorSize.toFixed(0), 'actual dims:', template);
  }

  // Initialize canvas when DOM ready
  $(document).on('shiny:connected', function() {
    // Find all canvas elements
    $('canvas[id$="-canvas"]').each(function() {
      const canvas = this;
      const canvasId = canvas.id;
      const ctx = canvas.getContext('2d');

      // Get namespace (remove -canvas suffix)
      const ns = canvasId.replace(/-canvas$/, '');

      console.log('[Canvas] Initializing - canvasId:', canvasId, 'ns:', ns);

      // Initialize state
      const state = {
        canvas: canvas,
        ctx: ctx,
        ns: ns,
        shapes: [],
        tempShape: null,  // Temporary shape with dotted border (before saving)
        selectedId: null,
        isDragging: false,
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

      // Set up event listeners
      setupCanvasEvents(canvas, state);

      console.log('[Canvas] Initialized:', canvasId);
    });

    // Global ESC key handler to deselect shape template
    $(document).on('keydown', function(e) {
      if (e.key === 'Escape') {
        // Find the shape template selector and reset it
        $('#test-shape_template_id').val('').trigger('change');
        console.log('[Canvas] ESC pressed - shape deselected');
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

    // Click to select OR add new placement
    $(canvas).on('click', function(e) {
      if (state.isPanning) return; // Don't select if we were panning

      const rect = canvas.getBoundingClientRect();
      const canvasX = (e.clientX - rect.left) * (canvas.width / rect.width);
      const canvasY = (e.clientY - rect.top) * (canvas.height / rect.height);

      // Transform canvas coords to world coords (only pan and zoom, no rotation)
      const x = (canvasX - state.panX) / state.zoom;
      const y = (canvasY - state.panY) / state.zoom;

      console.log('[Canvas] Click at canvas:', canvasX.toFixed(0), canvasY.toFixed(0), 'world:', x.toFixed(0), y.toFixed(0));
      console.log('[Canvas] Has template?', !!state.selectedShapeTemplate, state.selectedShapeTemplate);

      // If shape template selected, add new placement at click location
      if (state.selectedShapeTemplate) {
        const inputName = state.ns + '-canvas_add_at';
        console.log('[Canvas] Adding placement at:', x.toFixed(2), y.toFixed(2), 'template:', state.selectedShapeTemplate.templateId);
        console.log('[Canvas] Sending to Shiny input:', inputName);

        Shiny.setInputValue(inputName, {
          x: x,
          y: y,
          templateId: state.selectedShapeTemplate.templateId
        }, {priority: 'event'});
        return;
      }

      // Otherwise, select existing shape
      const clickedShape = findShapeAtPoint(state.shapes, x, y);
      console.log('[Canvas] Clicked shape:', clickedShape ? clickedShape.id : 'none');

      if (clickedShape) {
        state.selectedId = clickedShape.id;
        render(state);

        // Send selection to Shiny
        Shiny.setInputValue(state.ns + '-canvas_selection', clickedShape.id, {priority: 'event'});
      } else {
        state.selectedId = null;
        render(state);
        Shiny.setInputValue(state.ns + '-canvas_selection', null, {priority: 'event'});
      }
    });

    // Mouse down - start drag or pan
    $(canvas).on('mousedown', function(e) {
      const rect = canvas.getBoundingClientRect();
      const canvasX = (e.clientX - rect.left) * (canvas.width / rect.width);
      const canvasY = (e.clientY - rect.top) * (canvas.height / rect.height);

      if (state.backgroundPanMode) {
        // Background pan mode: move background offset
        state.isBackgroundPanning = true;
        state.bgPanStart = {
          x: canvasX,
          y: canvasY,
          offsetX: state.backgroundOffsetX,
          offsetY: state.backgroundOffsetY
        };
        canvas.style.cursor = 'grabbing';
      } else if (state.editMode) {
        // Edit mode: drag shapes (no rotation transform needed)
        const worldX = (canvasX - state.panX) / state.zoom;
        const worldY = (canvasY - state.panY) / state.zoom;
        const clickedShape = findShapeAtPoint(state.shapes, worldX, worldY);

        if (clickedShape) {
          state.isDragging = true;
          state.selectedId = clickedShape.id;
          state.dragStart = { x: worldX, y: worldY, shapeX: clickedShape.x, shapeY: clickedShape.y };
          canvas.style.cursor = 'grabbing';
        }
      } else {
        // View mode: pan canvas
        state.isPanning = true;
        state.panStart = { x: canvasX, y: canvasY, panX: state.panX, panY: state.panY };
        canvas.style.cursor = 'grabbing';
      }
    });

    // Mouse move - drag shape or pan
    $(canvas).on('mousemove', function(e) {
      const rect = canvas.getBoundingClientRect();
      const canvasX = (e.clientX - rect.left) * (canvas.width / rect.width);
      const canvasY = (e.clientY - rect.top) * (canvas.height / rect.height);

      if (state.isBackgroundPanning) {
        // Panning background offset
        const dx = (canvasX - state.bgPanStart.x) / state.zoom;
        const dy = (canvasY - state.bgPanStart.y) / state.zoom;

        // Apply rotation transformation to deltas (counter-rotate by current rotation)
        const angle = -state.rotation * Math.PI / 180;
        const rotatedDx = dx * Math.cos(angle) - dy * Math.sin(angle);
        const rotatedDy = dx * Math.sin(angle) + dy * Math.cos(angle);

        state.backgroundOffsetX = state.bgPanStart.offsetX + rotatedDx;
        state.backgroundOffsetY = state.bgPanStart.offsetY + rotatedDy;
        render(state);
      } else if (state.isDragging) {
        // Dragging a shape (no rotation transform needed)
        const worldX = (canvasX - state.panX) / state.zoom;
        const worldY = (canvasY - state.panY) / state.zoom;
        const dx = worldX - state.dragStart.x;
        const dy = worldY - state.dragStart.y;

        const shape = state.shapes.find(s => s.id === state.selectedId);
        if (shape) {
          let newX = state.dragStart.shapeX + dx;
          let newY = state.dragStart.shapeY + dy;

          // Apply grid snap
          if (state.snapGrid > 0) {
            if (shape.type === 'circle') {
              newX = Math.round(newX / state.snapGrid) * state.snapGrid;
              newY = Math.round(newY / state.snapGrid) * state.snapGrid;
            } else {
              newX = Math.round(newX / state.snapGrid) * state.snapGrid;
              newY = Math.round(newY / state.snapGrid) * state.snapGrid;
            }
          }

          shape.x = newX;
          shape.y = newY;
          render(state);
        }
      } else if (state.isPanning) {
        // Panning canvas
        const dx = canvasX - state.panStart.x;
        const dy = canvasY - state.panStart.y;
        state.panX = state.panStart.panX + dx;
        state.panY = state.panStart.panY + dy;
        render(state);
      }
    });

    // Mouse up - end drag or pan
    $(canvas).on('mouseup mouseleave', function(e) {
      if (state.isBackgroundPanning) {
        state.isBackgroundPanning = false;
        canvas.style.cursor = state.backgroundPanMode ? 'move' : 'grab';

        // Send updated background offset to Shiny
        Shiny.setInputValue(state.ns + '-bg_offset_update', {
          x: state.backgroundOffsetX,
          y: state.backgroundOffsetY
        }, {priority: 'event'});
      }

      if (state.isDragging) {
        state.isDragging = false;
        canvas.style.cursor = state.editMode ? 'move' : 'grab';

        // Send updated position to Shiny
        const shape = state.shapes.find(s => s.id === state.selectedId);
        if (shape) {
          const centerX = shape.type === 'circle' ? shape.x : shape.x + shape.w / 2;
          const centerY = shape.type === 'circle' ? shape.y : shape.y + shape.h / 2;

          Shiny.setInputValue(state.ns + '-canvas_moved', {
            id: shape.id,
            x: centerX,
            y: centerY
          }, {priority: 'event'});
        }
      }

      if (state.isPanning) {
        state.isPanning = false;
        canvas.style.cursor = state.editMode ? 'move' : 'grab';
      }
    });
  }

  // Find shape at point
  function findShapeAtPoint(shapes, x, y) {
    // Check in reverse order (top to bottom)
    for (let i = shapes.length - 1; i >= 0; i--) {
      const s = shapes[i];

      if (s.type === 'circle') {
        const dist = Math.sqrt(Math.pow(x - s.x, 2) + Math.pow(y - s.y, 2));
        if (dist <= s.r) return s;
      } else if (s.type === 'rect') {
        if (x >= s.x && x <= s.x + s.w && y >= s.y && y <= s.y + s.h) return s;
      }
    }
    return null;
  }


  // Render shapes on canvas
  function render(state) {
    const ctx = state.ctx;
    const canvas = state.canvas;

    // Clear canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // First layer: Background (rotated)
    ctx.save();
    ctx.translate(state.panX, state.panY);
    ctx.scale(state.zoom, state.zoom);

    // Rotate background only (around world center 0,0)
    if (state.rotation !== 0) {
      ctx.rotate(state.rotation * Math.PI / 180);
    }

    // Draw background image if loaded and visible
    if (state.backgroundImage && state.backgroundLoaded && state.backgroundVisible) {
      const img = state.backgroundImage;

      // Apply uniform background scaling
      if (state.backgroundScale !== 1) {
        ctx.save();
        ctx.scale(state.backgroundScale, state.backgroundScale);
      }

      // Draw centered at 0,0 (world origin) with offset
      const drawX = -img.width / 2 + (state.backgroundOffsetX / state.backgroundScale);
      const drawY = -img.height / 2 + (state.backgroundOffsetY / state.backgroundScale);
      ctx.drawImage(img, drawX, drawY);

      if (state.backgroundScale !== 1) {
        ctx.restore();
      }
    }

    ctx.restore();

    // Second layer: Shapes and grid (NOT rotated - fixed coordinate system)
    ctx.save();
    ctx.translate(state.panX, state.panY);
    ctx.scale(state.zoom, state.zoom);

    // Draw grid if snap enabled (grid doesn't rotate)
    if (state.snapGrid > 0) {
      drawGrid(ctx, canvas.width / state.zoom, canvas.height / state.zoom, state.snapGrid, state.panX, state.panY, state.zoom);
    }

    // Draw shapes (shapes don't rotate)
    state.shapes.forEach(shape => {
      const isSelected = shape.id === state.selectedId;

      ctx.save();

      // Draw shape
      if (shape.type === 'circle') {
        ctx.beginPath();
        ctx.arc(shape.x, shape.y, shape.r, 0, Math.PI * 2);
        ctx.fillStyle = shape.fill || 'rgba(59, 130, 246, 0.2)';
        ctx.fill();
        ctx.strokeStyle = isSelected ? 'rgba(239, 68, 68, 0.9)' : (shape.stroke || 'rgba(59, 130, 246, 0.8)');
        ctx.lineWidth = isSelected ? 3 : (shape.strokeWidth || 2);
        ctx.stroke();

        // Draw label
        if (shape.label) {
          ctx.font = '12px sans-serif';
          ctx.fillStyle = '#333';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          ctx.fillText(shape.label, shape.x, shape.y);
        }
      } else if (shape.type === 'rect') {
        ctx.fillStyle = shape.fill || 'rgba(34, 197, 94, 0.2)';
        ctx.fillRect(shape.x, shape.y, shape.w, shape.h);
        ctx.strokeStyle = isSelected ? 'rgba(239, 68, 68, 0.9)' : (shape.stroke || 'rgba(34, 197, 94, 0.8)');
        ctx.lineWidth = isSelected ? 3 : (shape.strokeWidth || 2);
        ctx.strokeRect(shape.x, shape.y, shape.w, shape.h);

        // Draw label
        if (shape.label) {
          ctx.font = '12px sans-serif';
          ctx.fillStyle = '#333';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          ctx.fillText(shape.label, shape.x + shape.w / 2, shape.y + shape.h / 2);
        }
      }

      ctx.restore();
    });

    // Draw temporary shape (with dotted border)
    if (state.tempShape) {
      const shape = state.tempShape;
      ctx.save();

      // Set dotted line style
      ctx.setLineDash([5, 5]);

      if (shape.type === 'circle') {
        ctx.beginPath();
        ctx.arc(shape.x, shape.y, shape.r, 0, Math.PI * 2);
        ctx.fillStyle = 'rgba(59, 130, 246, 0.1)';
        ctx.fill();
        ctx.strokeStyle = 'rgba(59, 130, 246, 0.6)';
        ctx.lineWidth = 2;
        ctx.stroke();

        // Draw label
        if (shape.label) {
          ctx.setLineDash([]);  // Solid for text
          ctx.font = '12px sans-serif';
          ctx.fillStyle = '#666';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          ctx.fillText(shape.label, shape.x, shape.y);
        }
      } else if (shape.type === 'rect') {
        ctx.fillStyle = 'rgba(34, 197, 94, 0.1)';
        ctx.fillRect(shape.x, shape.y, shape.w, shape.h);
        ctx.strokeStyle = 'rgba(34, 197, 94, 0.6)';
        ctx.lineWidth = 2;
        ctx.strokeRect(shape.x, shape.y, shape.w, shape.h);

        // Draw label
        if (shape.label) {
          ctx.setLineDash([]);  // Solid for text
          ctx.font = '12px sans-serif';
          ctx.fillStyle = '#666';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          ctx.fillText(shape.label, shape.x + shape.w / 2, shape.y + shape.h / 2);
        }
      }

      ctx.restore();
    }

    ctx.restore();
  }

  // Draw grid
  function drawGrid(ctx, width, height, gridSize, panX, panY, zoom) {
    ctx.save();
    ctx.strokeStyle = 'rgba(200, 200, 200, 0.3)';
    ctx.lineWidth = 1 / zoom;

    const startX = Math.floor(-panX / zoom / gridSize) * gridSize;
    const startY = Math.floor(-panY / zoom / gridSize) * gridSize;
    const endX = startX + width + gridSize;
    const endY = startY + height + gridSize;

    for (let x = startX; x <= endX; x += gridSize) {
      ctx.beginPath();
      ctx.moveTo(x, startY);
      ctx.lineTo(x, endY);
      ctx.stroke();
    }

    for (let y = startY; y <= endY; y += gridSize) {
      ctx.beginPath();
      ctx.moveTo(startX, y);
      ctx.lineTo(endX, y);
      ctx.stroke();
    }

    ctx.restore();
  }

  // Custom message handler: set canvas data
  Shiny.addCustomMessageHandler('test-root:setData', function(message) {
    const canvasId = 'test-canvas';
    const state = canvases.get(canvasId);

    if (!state) {
      console.warn('[Canvas] State not found for:', canvasId);
      return;
    }

    state.shapes = message.data || [];
    render(state);

    console.log('[Canvas] Loaded', state.shapes.length, 'shapes');

    // Auto-fit if requested
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

    // Don't override cursor if shape template is selected (cursor shows shape preview)
    if (!state.selectedShapeTemplate) {
      state.canvas.style.cursor = state.editMode ? 'move' : 'grab';
    }

    console.log('[Canvas] Edit mode:', state.editMode, 'has template:', !!state.selectedShapeTemplate);
  });

  // Custom message handler: set snap grid
  Shiny.addCustomMessageHandler('test-root:setSnap', function(message) {
    const canvasId = 'test-canvas';
    const state = canvases.get(canvasId);

    if (!state) return;

    state.snapGrid = message.units || 0;
    render(state);

    console.log('[Canvas] Snap grid:', state.snapGrid);
  });

  // Fit view function
  function fitView(state) {
    if (!state || state.shapes.length === 0) return;

    // Calculate bounds
    let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;

    state.shapes.forEach(s => {
      if (s.type === 'circle') {
        minX = Math.min(minX, s.x - s.r);
        minY = Math.min(minY, s.y - s.r);
        maxX = Math.max(maxX, s.x + s.r);
        maxY = Math.max(maxY, s.y + s.r);
      } else if (s.type === 'rect') {
        minX = Math.min(minX, s.x);
        minY = Math.min(minY, s.y);
        maxX = Math.max(maxX, s.x + s.w);
        maxY = Math.max(maxY, s.y + s.h);
      }
    });

    const boundsWidth = maxX - minX;
    const boundsHeight = maxY - minY;
    const centerX = (minX + maxX) / 2;
    const centerY = (minY + maxY) / 2;

    // Calculate zoom to fit (with 10% padding)
    const zoomX = (state.canvas.width * 0.9) / boundsWidth;
    const zoomY = (state.canvas.height * 0.9) / boundsHeight;
    state.zoom = Math.min(zoomX, zoomY, 2); // Max zoom 2x

    // Center the view
    state.panX = state.canvas.width / 2 - centerX * state.zoom;
    state.panY = state.canvas.height / 2 - centerY * state.zoom;

    render(state);
    updateShapeCursor(state); // Update cursor size with new zoom
    console.log('[Canvas] Fit view - zoom:', state.zoom.toFixed(2), 'center:', centerX.toFixed(0), centerY.toFixed(0));
  }

  // Custom message handler: fit view
  Shiny.addCustomMessageHandler('test-root:fitView', function(message) {
    console.log('[Canvas] Fit view handler called');
    const canvasId = 'test-canvas';
    console.log('[Canvas] Looking for canvas:', canvasId);
    console.log('[Canvas] Available canvases:', Array.from(canvases.keys()));
    const state = canvases.get(canvasId);
    console.log('[Canvas] State found:', state ? 'yes' : 'no');
    if (state) {
      console.log('[Canvas] Calling fitView with', state.shapes.length, 'shapes');
      fitView(state);
    } else {
      console.error('[Canvas] State not found for:', canvasId);
    }
  });

  // Custom message handler: set background image
  Shiny.addCustomMessageHandler('test-root:setBackground', function(message) {
    const canvasId = 'test-canvas';
    const state = canvases.get(canvasId);

    if (!state) return;

    if (!message.image) {
      state.backgroundImage = null;
      state.backgroundLoaded = false;
      render(state);
      return;
    }

    // Load the image
    const img = new Image();
    img.onload = function() {
      state.backgroundImage = img;
      state.backgroundLoaded = true;
      console.log('[Canvas] Background image loaded:', img.width, 'x', img.height);
      render(state);
    };
    img.onerror = function() {
      console.error('[Canvas] Failed to load background image');
      state.backgroundImage = null;
      state.backgroundLoaded = false;
    };
    img.src = message.image;
  });

  // Custom message handler: set rotation
  Shiny.addCustomMessageHandler('test-root:setRotation', function(message) {
    const canvasId = 'test-canvas';
    const state = canvases.get(canvasId);

    if (!state) return;

    state.rotation = message.angle || 0;
    render(state);
  });

  // Custom message handler: set background scale
  Shiny.addCustomMessageHandler('test-root:setBackgroundScale', function(message) {
    const canvasId = 'test-canvas';
    const state = canvases.get(canvasId);

    if (!state) return;

    state.backgroundScale = message.scale || 1;
    render(state);
  });

  // Custom message handler: set background offset
  Shiny.addCustomMessageHandler('test-root:setBackgroundOffset', function(message) {
    const canvasId = 'test-canvas';
    const state = canvases.get(canvasId);

    if (!state) return;

    state.backgroundOffsetX = message.x || 0;
    state.backgroundOffsetY = message.y || 0;
    render(state);
  });

  // Custom message handler: set background pan mode
  Shiny.addCustomMessageHandler('test-root:setBackgroundPanMode', function(message) {
    const canvasId = 'test-canvas';
    const state = canvases.get(canvasId);

    if (!state) return;

    state.backgroundPanMode = message.on || false;
    state.canvas.style.cursor = state.backgroundPanMode ? 'move' : 'grab';
  });

  // Custom message handler: set background visibility
  Shiny.addCustomMessageHandler('test-root:setBackgroundVisible', function(message) {
    const canvasId = 'test-canvas';
    const state = canvases.get(canvasId);

    if (!state) return;

    state.backgroundVisible = message.visible !== false;
    render(state);  // Redraw canvas
  });

  // Custom message handler: zoom
  Shiny.addCustomMessageHandler('test-root:setZoom', function(message) {
    console.log('[Canvas] Zoom handler called, direction:', message.direction);
    const canvasId = 'test-canvas';
    const state = canvases.get(canvasId);

    if (!state) {
      console.error('[Canvas] State not found for zoom');
      return;
    }

    const direction = message.direction; // 'in' or 'out'
    const factor = direction === 'in' ? 1.2 : 0.8;
    console.log('[Canvas] Current zoom:', state.zoom, 'factor:', factor);

    // Zoom towards center
    const centerX = state.canvas.width / 2;
    const centerY = state.canvas.height / 2;
    const newZoom = Math.max(0.1, Math.min(5, state.zoom * factor));

    state.panX = centerX - (centerX - state.panX) * (newZoom / state.zoom);
    state.panY = centerY - (centerY - state.panY) * (newZoom / state.zoom);
    state.zoom = newZoom;

    console.log('[Canvas] New zoom:', state.zoom);
    render(state);
    updateShapeCursor(state); // Update cursor size with new zoom
  });

  // Custom message handler: set shape cursor
  Shiny.addCustomMessageHandler('test-root:setShapeCursor', function(message) {
    const canvasId = 'test-canvas';
    const state = canvases.get(canvasId);

    if (!state) {
      console.error('[Canvas] State not found for setShapeCursor');
      return;
    }

    console.log('[Canvas] setShapeCursor received:', message);

    if (message.shapeType === 'default') {
      state.selectedShapeTemplate = null;
      console.log('[Canvas] Template cleared');
    } else {
      state.selectedShapeTemplate = message;
      console.log('[Canvas] Template set:', message.shapeType, 'ID:', message.templateId);
    }

    updateShapeCursor(state);
  });

  // Set temporary shape (shown with dotted border before saving)
  Shiny.addCustomMessageHandler('test-root:setTempShape', function(message) {
    const canvasId = 'test-canvas';
    const state = canvases.get(canvasId);

    if (!state) {
      console.error('[Canvas] State not found for setTempShape');
      return;
    }

    console.log('[Canvas] setTempShape received:', message);

    state.tempShape = message.shape;
    render(state);

    console.log('[Canvas] Temporary shape set');
  });

  // Clear temporary shape
  Shiny.addCustomMessageHandler('test-root:clearTempShape', function(message) {
    const canvasId = 'test-canvas';
    const state = canvases.get(canvasId);

    if (!state) {
      console.error('[Canvas] State not found for clearTempShape');
      return;
    }

    console.log('[Canvas] clearTempShape called');

    state.tempShape = null;
    render(state);

    console.log('[Canvas] Temporary shape cleared');
  });

  // Open panel in edit mode for new placement
  Shiny.addCustomMessageHandler('test-root:openPanelInEditMode', function(message) {
    console.log('[Canvas] openPanelInEditMode received:', message);

    const rootId = message.rootId;
    const formId = message.formId;
    const formIdJs = message.formIdJs;

    // Open the panel
    const toggleFn = window['togglePanel_' + rootId];
    if (toggleFn) {
      toggleFn(true);
      console.log('[Canvas] Panel opened');
    } else {
      console.error('[Canvas] togglePanel function not found:', 'togglePanel_' + rootId);
      return;
    }

    // Wait for panel animation to complete (500ms) + small buffer for form render
    setTimeout(function() {
      console.log('[Canvas] Attempting to toggle edit mode after animation...');
      console.log('[Canvas] Looking for form:', '#' + formId);
      console.log('[Canvas] Looking for edit button:', '#' + formId + ' .btn-edit');
      console.log('[Canvas] Looking for delete button:', '#' + formId + ' .btn-delete span');

      const form = document.querySelector('#' + formId);
      console.log('[Canvas] Form found:', !!form);

      const editBtn = document.querySelector('#' + formId + ' .btn-edit');
      console.log('[Canvas] Edit button found:', !!editBtn);

      const deleteBtn = document.querySelector('#' + formId + ' .btn-delete span');
      console.log('[Canvas] Delete button found:', !!deleteBtn);

      // Toggle edit mode
      const toggleEditFn = window['toggleEditMode_' + formIdJs];
      if (toggleEditFn) {
        if (editBtn) {
          toggleEditFn(editBtn);
          console.log('[Canvas] Edit mode toggled for new placement');
        } else {
          console.error('[Canvas] Edit button not found!');
        }
      } else {
        console.error('[Canvas] toggleEditMode function not found:', 'toggleEditMode_' + formIdJs);
      }

      // Change delete button text to Reset
      if (deleteBtn) {
        deleteBtn.textContent = ' Reset';
        console.log('[Canvas] Button changed to Reset');
      } else {
        console.error('[Canvas] Delete button not found!');
      }
    }, 700);  // 500ms panel animation + 200ms buffer
  });

})();
