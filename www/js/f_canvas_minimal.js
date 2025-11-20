// Minimal canvas JavaScript - just rendering shapes

(function() {
  'use strict';

  let canvasState = null;

  $(document).on('shiny:connected', function() {
    const canvas = document.getElementById('test-canvas');
    if (!canvas) {
      console.warn('[Canvas] Canvas element not found');
      return;
    }

    const ctx = canvas.getContext('2d');

    canvasState = {
      canvas: canvas,
      ctx: ctx,
      shapes: []
    };

    // Click handler
    $(canvas).on('click', function(e) {
      const rect = canvas.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;

      const clickedShape = findShapeAtPoint(canvasState.shapes, x, y);

      if (clickedShape) {
        console.log('[Canvas] Clicked shape:', clickedShape.id);
        Shiny.setInputValue('test-shape_clicked', clickedShape.id, {priority: 'event'});
      }
    });

    console.log('[Canvas] Initialized');
  });

  // Find shape at point
  function findShapeAtPoint(shapes, x, y) {
    for (let i = shapes.length - 1; i >= 0; i--) {
      const s = shapes[i];

      if (s.type === 'circle') {
        const dist = Math.sqrt(Math.pow(x - s.x, 2) + Math.pow(y - s.y, 2));
        if (dist <= s.r) return s;
      } else if (s.type === 'rect') {
        if (x >= s.x && x <= s.x + s.w && y >= s.y && y <= s.y + s.h) return s;
      } else if (s.type === 'triangle') {
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

  // Render shapes
  function render(state) {
    if (!state) return;

    const ctx = state.ctx;
    const canvas = state.canvas;

    // Clear canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    console.log('[Canvas] Rendering', state.shapes.length, 'shapes');

    // Draw shapes
    state.shapes.forEach(shape => {
      ctx.save();

      if (shape.type === 'circle') {
        ctx.beginPath();
        ctx.arc(shape.x, shape.y, shape.r, 0, Math.PI * 2);
        ctx.fillStyle = 'rgba(59, 130, 246, 0.2)';
        ctx.fill();
        ctx.strokeStyle = 'rgba(59, 130, 246, 0.8)';
        ctx.lineWidth = 2;
        ctx.stroke();

        // Label
        if (shape.label) {
          ctx.font = '12px sans-serif';
          ctx.fillStyle = '#333';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          ctx.fillText(shape.label, shape.x, shape.y);
        }
      } else if (shape.type === 'rect') {
        ctx.fillStyle = 'rgba(34, 197, 94, 0.2)';
        ctx.fillRect(shape.x, shape.y, shape.w, shape.h);
        ctx.strokeStyle = 'rgba(34, 197, 94, 0.8)';
        ctx.lineWidth = 2;
        ctx.strokeRect(shape.x, shape.y, shape.w, shape.h);

        // Label
        if (shape.label) {
          ctx.font = '12px sans-serif';
          ctx.fillStyle = '#333';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          ctx.fillText(shape.label, shape.x + shape.w / 2, shape.y + shape.h / 2);
        }
      } else if (shape.type === 'triangle') {
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

        ctx.fillStyle = 'rgba(168, 85, 247, 0.2)';
        ctx.fill();
        ctx.strokeStyle = 'rgba(168, 85, 247, 0.8)';
        ctx.lineWidth = 2;
        ctx.stroke();

        // Label
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
  }

  // Set shapes handler
  Shiny.addCustomMessageHandler('test-root:setShapes', function(message) {
    console.log('[Canvas] setShapes called with', message.shapes?.length, 'shapes');

    if (!canvasState) {
      console.warn('[Canvas] Canvas not initialized');
      return;
    }

    canvasState.shapes = message.shapes || [];
    render(canvasState);
  });

})();
