// www/js/f_siloplacements_canvas.js
// Simple canvas renderer for SiloPlacements test

(function() {
  'use strict';

  // Canvas state
  const canvases = new Map();

  // Centralized function to properly clear shape template selection (Selectize-aware)
  function clearShapeTemplateSelection() {
    const dropdown = $('#test-shape_template_id');

    if (dropdown.length) {
      const selectize = dropdown[0].selectize;
      if (selectize) {
        selectize.clear(true);
      } else {
        dropdown.val('').trigger('change');
      }
    }

    Shiny.setInputValue('test-shape_template_id', '', {priority: 'event'});
  }

  // Update cursor based on current state and zoom - ACTUAL SIZE PREVIEW
  function updateShapeCursor(state) {
    if (!state.selectedShapeTemplate) {
      // Default cursor based on edit mode
      state.canvas.style.cursor = state.editMode ? 'move' : 'grab';
      console.log('[Cursor] Setting default cursor:', state.editMode ? 'move' : 'grab');
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

      // Scale down proportionally if too large
      const scaleFactor = neededSize > MAX_CURSOR ? MAX_CURSOR / neededSize : 1;
      const displayRadius = scaledRadius * scaleFactor;

      cursorSize = Math.min(neededSize, MAX_CURSOR);
      centerX = centerY = cursorSize / 2;

      svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${cursorSize}" height="${cursorSize}">
        <circle cx="${centerX}" cy="${centerY}" r="${displayRadius}" fill="rgba(59,130,246,0.15)" stroke="rgba(59,130,246,0.8)" stroke-width="2"/>
      </svg>`;

    } else if (shapeType === 'RECTANGLE') {
      const width = template.width || 40;
      const height = template.height || 40;
      const scaledWidth = width * zoom;
      const scaledHeight = height * zoom;

      // Calculate needed cursor size
      const neededSize = Math.max(scaledWidth, scaledHeight) + 4;

      // Scale down proportionally if too large
      const scaleFactor = neededSize > MAX_CURSOR ? MAX_CURSOR / neededSize : 1;
      const displayWidth = scaledWidth * scaleFactor;
      const displayHeight = scaledHeight * scaleFactor;

      cursorSize = Math.min(neededSize, MAX_CURSOR);
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

      // Calculate needed cursor size
      const neededSize = scaledRadius * 2 + 4;

      // Scale down proportionally if too large
      const scaleFactor = neededSize > MAX_CURSOR ? MAX_CURSOR / neededSize : 1;
      const displayRadius = scaledRadius * scaleFactor;

      cursorSize = Math.min(neededSize, MAX_CURSOR);
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
    });

    // Global ESC key handler to deselect shape template
    $(document).on('keydown', function(e) {
      if (e.key === 'Escape') {
        console.log('[Cursor] ESC pressed - clearing shape selection');

        // Blur dropdown and move focus
        $('#test-shape_template_id').blur();
        $('#test-edit_mode_toggle').focus();

        // Clear selection using centralized function (Selectize-aware)
        clearShapeTemplateSelection();
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

      // If shape template selected, add new placement at click location
      if (state.selectedShapeTemplate) {
        const inputName = state.ns + '-canvas_add_at';

        Shiny.setInputValue(inputName, {
          x: x,
          y: y,
          templateId: state.selectedShapeTemplate.templateId
        }, {priority: 'event'});
        return;
      }

      // Otherwise, select existing shape
      const clickedShape = findShapeAtPoint(state.shapes, x, y);

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
      } else if (s.type === 'triangle') {
        // Point-in-triangle test using barycentric coordinates
        const r = s.r || 20;
        const p1x = s.x;
        const p1y = s.y - r;
        const p2x = s.x - r * 0.866;
        const p2y = s.y + r * 0.5;
        const p3x = s.x + r * 0.866;
        const p3y = s.y + r * 0.5;

        const denom = ((p2y - p3y) * (p1x - p3x) + (p3x - p2x) * (p1y - p3y));
        const a = ((p2y - p3y) * (x - p3x) + (p3x - p2x) * (y - p3y)) / denom;
        const b = ((p3y - p1y) * (x - p3x) + (p1x - p3x) * (y - p3y)) / denom;
        const c = 1 - a - b;

        if (a >= 0 && a <= 1 && b >= 0 && b <= 1 && c >= 0 && c <= 1) return s;
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
      } else if (shape.type === 'triangle') {
        // Draw equilateral triangle pointing up
        const r = shape.r || 20;
        const p1x = shape.x;
        const p1y = shape.y - r;
        const p2x = shape.x - r * 0.866;
        const p2y = shape.y + r * 0.5;
        const p3x = shape.x + r * 0.866;
        const p3y = shape.y + r * 0.5;

        ctx.beginPath();
        ctx.moveTo(p1x, p1y);
        ctx.lineTo(p2x, p2y);
        ctx.lineTo(p3x, p3y);
        ctx.closePath();

        ctx.fillStyle = shape.fill || 'rgba(168, 85, 247, 0.2)';
        ctx.fill();
        ctx.strokeStyle = isSelected ? 'rgba(239, 68, 68, 0.9)' : (shape.stroke || 'rgba(168, 85, 247, 0.8)');
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
      } else if (shape.type === 'triangle') {
        // Draw equilateral triangle pointing up
        const r = shape.r || 20;
        const p1x = shape.x;
        const p1y = shape.y - r;
        const p2x = shape.x - r * 0.866;
        const p2y = shape.y + r * 0.5;
        const p3x = shape.x + r * 0.866;
        const p3y = shape.y + r * 0.5;

        ctx.beginPath();
        ctx.moveTo(p1x, p1y);
        ctx.lineTo(p2x, p2y);
        ctx.lineTo(p3x, p3y);
        ctx.closePath();

        ctx.fillStyle = 'rgba(168, 85, 247, 0.1)';
        ctx.fill();
        ctx.strokeStyle = 'rgba(168, 85, 247, 0.6)';
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

    // When turning OFF edit mode, clear shape template
    if (!message.on) {
      console.log('[Cursor] Edit mode OFF - clearing shape selection');

      // Blur dropdown and move focus
      $('#test-shape_template_id').blur();
      $('#test-edit_mode_toggle').focus();

      // Clear selection using centralized function (Selectize-aware)
      clearShapeTemplateSelection();
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
  }

  // Custom message handler: fit view
  Shiny.addCustomMessageHandler('test-root:fitView', function(message) {
    const canvasId = 'test-canvas';
    const state = canvases.get(canvasId);
    if (state) {
      fitView(state);
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
    const canvasId = 'test-canvas';
    const state = canvases.get(canvasId);

    if (!state) {
      return;
    }

    const direction = message.direction; // 'in' or 'out'
    const factor = direction === 'in' ? 1.2 : 0.8;

    // Zoom towards center
    const centerX = state.canvas.width / 2;
    const centerY = state.canvas.height / 2;
    const newZoom = Math.max(0.1, Math.min(5, state.zoom * factor));

    state.panX = centerX - (centerX - state.panX) * (newZoom / state.zoom);
    state.panY = centerY - (centerY - state.panY) * (newZoom / state.zoom);
    state.zoom = newZoom;

    render(state);
    updateShapeCursor(state); // Update cursor size with new zoom
  });

  // Custom message handler: set shape cursor
  Shiny.addCustomMessageHandler('test-root:setShapeCursor', function(message) {
    console.log('[Cursor] Received setShapeCursor message:', message);
    const canvasId = 'test-canvas';
    const state = canvases.get(canvasId);

    if (!state) {
      console.warn('[Cursor] Canvas state not found');
      return;
    }

    if (message.shapeType === 'default') {
      console.log('[Cursor] Setting to default cursor');
      state.selectedShapeTemplate = null;
    } else {
      console.log('[Cursor] Setting shape template:', message.shapeType);
      state.selectedShapeTemplate = message;
    }

    updateShapeCursor(state);
  });

  // Set temporary shape (shown with dotted border before saving)
  Shiny.addCustomMessageHandler('test-root:setTempShape', function(message) {
    const canvasId = 'test-canvas';
    const state = canvases.get(canvasId);

    if (!state) {
      return;
    }

    state.tempShape = message.shape;
    render(state);
  });

  // Clear temporary shape
  Shiny.addCustomMessageHandler('test-root:clearTempShape', function(message) {
    const canvasId = 'test-canvas';
    const state = canvases.get(canvasId);

    if (!state) {
      return;
    }

    state.tempShape = null;
    render(state);
  });

  // Open panel in edit mode for new placement
  Shiny.addCustomMessageHandler('test-root:openPanelInEditMode', function(message) {
    const rootId = message.rootId;
    const formId = message.formId;
    const formIdJs = message.formIdJs;

    // Open the panel
    const toggleFn = window['togglePanel_' + rootId];
    if (toggleFn) {
      toggleFn(true);
    } else {
      return;
    }

    // Wait for DOM to settle after panel opens
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        // The actual form container has "-form" appended
        const formContainerId = formId + '-form';
        const editBtnId = formId + '-field_edit_btn';
        const deleteBtnId = formId + '-field_delete_btn';

        console.log('Looking for edit button:', editBtnId);
        console.log('Looking for delete button:', deleteBtnId);

        const editBtn = document.getElementById(editBtnId);
        const deleteBtn = document.getElementById(deleteBtnId);

        console.log('Edit button found:', !!editBtn);
        console.log('Delete button found:', !!deleteBtn);

        if (editBtn) {
          console.log('Edit button classes BEFORE:', editBtn.className);
        }

        // Toggle edit mode - function name is based on the form container ID
        const formContainerIdJs = formIdJs + '_form';
        const toggleEditFn = window['toggleEditMode_' + formContainerIdJs];

        console.log('Looking for function:', 'toggleEditMode_' + formContainerIdJs);
        console.log('Function found:', !!toggleEditFn);

        if (toggleEditFn && editBtn) {
          // Only toggle if button is NOT already in editing mode
          const isEditing = editBtn.classList.contains('editing');
          console.log('Button already in editing mode:', isEditing);

          // Check form container BEFORE
          const formContainer = document.getElementById(formContainerId);
          if (formContainer) {
            console.log('Form container classes BEFORE:', formContainer.className);
          }

          if (!isEditing) {
            toggleEditFn(editBtn);
            console.log('Edit mode toggled to ON');

            // Check if it actually changed
            setTimeout(() => {
              console.log('Edit button classes AFTER (100ms):', editBtn.className);
              const stillEditing = editBtn.classList.contains('editing');
              console.log('Still in editing mode:', stillEditing);

              // Check form container AFTER
              if (formContainer) {
                console.log('Form container classes AFTER (100ms):', formContainer.className);
                const hasEditMode = formContainer.classList.contains('edit-mode');
                console.log('Form has edit-mode class:', hasEditMode);

                // Check if inputs are enabled
                const inputs = formContainer.querySelectorAll('input:not([type="hidden"])');
                const selects = formContainer.querySelectorAll('select');
                console.log('Sample input disabled?', inputs[0]?.disabled, 'readonly?', inputs[0]?.readOnly);
                console.log('Sample select disabled?', selects[0]?.disabled, 'readonly?', selects[0]?.readOnly);
              }
            }, 100);
          } else {
            console.log('Already in edit mode, skipping toggle');
          }
        }

        // Change delete button text to Reset
        if (deleteBtn) {
          const deleteBtnSpan = deleteBtn.querySelector('span');
          if (deleteBtnSpan) {
            console.log('Delete button span text BEFORE:', deleteBtnSpan.textContent);
            deleteBtnSpan.textContent = ' Reset';
            console.log('Delete button span text AFTER:', deleteBtnSpan.textContent);

            // Check if it persists
            setTimeout(() => {
              console.log('Delete button span text (100ms later):', deleteBtnSpan.textContent);
            }, 100);
          } else {
            deleteBtn.textContent = ' Reset';
            console.log('Button text changed to Reset (direct)');
          }
        }
      });
    });
  });

  // Update a single shape on the canvas
  Shiny.addCustomMessageHandler('test-root:updateShape', function(message) {
    const canvasId = 'test-canvas';
    const state = canvases.get(canvasId);

    if (!state) {
      console.warn('[Canvas] State not found for:', canvasId);
      return;
    }

    const updatedShape = message.shape;
    if (!updatedShape || !updatedShape.id) {
      console.warn('[Canvas] Invalid shape data:', message);
      return;
    }

    // Find the shape by ID and update it
    const shapeIndex = state.shapes.findIndex(s => s.id === updatedShape.id);
    if (shapeIndex === -1) {
      console.warn('[Canvas] Shape not found with ID:', updatedShape.id);
      return;
    }

    console.log('[Canvas] Updating shape:', updatedShape.id, 'from', state.shapes[shapeIndex].type, 'to', updatedShape.type);

    // Replace the shape with the updated one
    state.shapes[shapeIndex] = updatedShape;

    // Re-render canvas
    render(state);
  });

})();
