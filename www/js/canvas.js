/* ==========================================================================
   Canvas Engine (generic)
   - DPR-aware resize
   - Pan/Zoom transforms
   - Draw loop with invalidation
   - Basic shape primitives + hit testing
   Exposes window.SiloCanvas.Engine
   ========================================================================== */

(function () {
  const TAU = Math.PI * 2;

  function dpr() {
    return (window.devicePixelRatio || 1);
  }

  class Engine {
    constructor(canvas, opts = {}) {
      if (!canvas || !(canvas instanceof HTMLCanvasElement)) {
        throw new Error("Engine requires a <canvas> element");
      }
      this.canvas = canvas;
      this.ctx = canvas.getContext("2d", { alpha: true });
      this.width = 0; this.height = 0;

      // world transform (pan/zoom)
      this.state = {
        scale: opts.scale || 1,
        minScale: opts.minScale || 0.25,
        maxScale: opts.maxScale || 4,
        tx: opts.tx || 0,
        ty: opts.ty || 0
      };

      // scene graph (very simple)
      this.shapes = []; // { id, type: 'circle'|'rect', x,y,w,h,r, fill, stroke, selected }
      this._needsRedraw = true;

      // interaction
      this.interaction = {
        dragging: false,
        dragId: null,
        dragStart: null, // {x,y} in world coords
      };

      // pointer cache
      this._lastPointer = { x: 0, y: 0 };

      // bindings
      this._boundResize = this.resize.bind(this);
      window.addEventListener("resize", this._boundResize);
      this.resize();
      this.start();
    }

    destroy() {
      window.removeEventListener("resize", this._boundResize);
      cancelAnimationFrame(this._raf);
    }

    // ----- sizing -----
    resize() {
      const ratio = dpr();
      const rect = this.canvas.getBoundingClientRect();
      const pxW = Math.max(1, Math.floor(rect.width * ratio));
      const pxH = Math.max(1, Math.floor(rect.height * ratio));

      if (pxW !== this.canvas.width || pxH !== this.canvas.height) {
        this.canvas.width = pxW;
        this.canvas.height = pxH;
        this.width = pxW; this.height = pxH;
        this._needsRedraw = true;
      }
    }

    // ----- transform helpers -----
    toScreen(pt) {
      const { scale, tx, ty } = this.state;
      return { x: (pt.x * scale + tx), y: (pt.y * scale + ty) };
    }
    toWorld(pt) {
      const { scale, tx, ty } = this.state;
      return { x: (pt.x - tx) / scale, y: (pt.y - ty) / scale };
    }

    setView({ scale, tx, ty }) {
      let s = (scale != null) ? scale : this.state.scale;
      s = Math.min(this.state.maxScale, Math.max(this.state.minScale, s));
      this.state.scale = s;
      if (tx != null) this.state.tx = tx;
      if (ty != null) this.state.ty = ty;
      this.invalidate();
    }

    zoomAt(factor, screenX, screenY) {
      const before = this.toWorld({ x: screenX, y: screenY });
      const s = Math.min(this.state.maxScale, Math.max(this.state.minScale, this.state.scale * factor));
      this.state.scale = s;
      const after = this.toWorld({ x: screenX, y: screenY });
      // Keep the point under cursor stationary
      this.state.tx += (after.x - before.x) * s;
      this.state.ty += (after.y - before.y) * s;
      this.invalidate();
    }

    pan(dx, dy) {
      this.state.tx += dx;
      this.state.ty += dy;
      this.invalidate();
    }

    // ----- scene management -----
    setShapes(arr) {
      this.shapes = Array.isArray(arr) ? arr.slice() : [];
      this.invalidate();
    }

    updateShape(id, patch) {
      const i = this.shapes.findIndex(s => s.id === id);
      if (i >= 0) { this.shapes[i] = { ...this.shapes[i], ...patch }; this.invalidate(); }
    }

    getShape(id) { return this.shapes.find(s => s.id === id) || null; }

    hitTest(worldX, worldY, padding = 3) {
      // check from top-most to bottom-most (last drawn is top)
      for (let i = this.shapes.length - 1; i >= 0; i--) {
        const s = this.shapes[i];
        if (s.type === "circle") {
          const dx = worldX - s.x, dy = worldY - s.y;
          if ((dx * dx + dy * dy) <= (s.r + padding) * (s.r + padding)) return s.id;
        } else if (s.type === "rect") {
          if (worldX >= s.x - padding && worldX <= s.x + s.w + padding &&
              worldY >= s.y - padding && worldY <= s.y + s.h + padding) return s.id;
        }
      }
      return null;
    }

    // ----- drawing -----
    invalidate() { this._needsRedraw = true; }

    start() {
      const loop = () => {
        this._raf = requestAnimationFrame(loop);
        if (!this._needsRedraw) return;
        this._needsRedraw = false;
        this._draw();
      };
      loop();
    }

    _draw() {
      const ctx = this.ctx;
      const ratio = dpr();
      ctx.save();
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.clearRect(0, 0, this.width, this.height);

      // world transform
      ctx.scale(this.state.scale * ratio, this.state.scale * ratio);
      ctx.translate(this.state.tx / (this.state.scale), this.state.ty / (this.state.scale));

      // draw shapes
      for (const s of this.shapes) {
        ctx.save();
        if (s.type === "circle") {
          ctx.beginPath();
          ctx.arc(s.x, s.y, s.r, 0, TAU);
        } else if (s.type === "rect") {
          ctx.beginPath();
          ctx.rect(s.x, s.y, s.w, s.h);
        }
        ctx.fillStyle = s.fill || "rgba(0,0,0,0.06)";
        ctx.strokeStyle = s.stroke || "rgba(0,0,0,0.5)";
        ctx.lineWidth = 1 / Math.max(0.5, this.state.scale);
        ctx.fill();
        ctx.stroke();

        if (s.selected) {
          ctx.setLineDash([4 / this.state.scale, 3 / this.state.scale]);
          ctx.strokeStyle = "#0d6efd";
          ctx.lineWidth = 2 / Math.max(0.5, this.state.scale);
          ctx.stroke();
        }
        ctx.restore();
      }
      ctx.restore();
    }
  }

  window.SiloCanvas = window.SiloCanvas || {};
  window.SiloCanvas.Engine = Engine;
})();
