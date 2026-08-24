import { CanvasTexture, LinearFilter, RepeatWrapping, SRGBColorSpace, Texture } from 'three';

/**
 * The board surface, drawn rather than downloaded.
 *
 * A canvas costs nothing to ship and can be re-graded from the palette tokens,
 * which an image cannot. The grain is a few hundred translucent strokes:
 * enough that the squares stop looking like flat colour under a moving light,
 * which is the only job it has.
 *
 * 1024px, not 2048. The board is never more than about twelve hundred pixels
 * wide on screen, so the larger texture bought nothing visible and cost four
 * times the drawing work — on the main thread, during startup, which is the
 * most expensive place in the session to spend it.
 */
/**
 * A canvas to draw a texture on, wherever this happens to be running.
 *
 * The scene renders on a worker when the browser allows it, and a worker has
 * no `document` to create elements in — so the same code has to reach for
 * OffscreenCanvas there. three.js accepts either as a texture source.
 */
export function scratch(width: number, height: number): HTMLCanvasElement | OffscreenCanvas {
  if (typeof document !== 'undefined') {
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    return canvas;
  }
  return new OffscreenCanvas(width, height);
}

export type Canvas2D = CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D;

export function boardTexture(size = 1024): { map: Texture; roughness: Texture } {
  const canvas = scratch(size, size);
  const ctx = canvas.getContext('2d') as Canvas2D;
  const square = size / 8;

  const LIGHT = '#c9bda3';
  const DARK = '#453d30';

  for (let file = 0; file < 8; file++) {
    for (let rank = 0; rank < 8; rank++) {
      const light = (file + rank) % 2 === 0;
      ctx.fillStyle = light ? LIGHT : DARK;
      ctx.fillRect(file * square, rank * square, square, square);

      // Grain, running along the file the square sits in.
      ctx.save();
      ctx.beginPath();
      ctx.rect(file * square, rank * square, square, square);
      ctx.clip();
      ctx.strokeStyle = light ? 'rgba(90,74,48,0.09)' : 'rgba(0,0,0,0.22)';
      ctx.lineWidth = 1.2;
      for (let i = 0; i < 18; i++) {
        const y = rank * square + Math.random() * square;
        ctx.beginPath();
        ctx.moveTo(file * square, y);
        ctx.bezierCurveTo(
          file * square + square * 0.33,
          y + (Math.random() - 0.5) * 7,
          file * square + square * 0.66,
          y + (Math.random() - 0.5) * 7,
          file * square + square,
          y + (Math.random() - 0.5) * 4,
        );
        ctx.stroke();
      }
      ctx.restore();
    }
  }

  // A hairline between the squares, the way an inlaid board actually reads.
  ctx.strokeStyle = 'rgba(0,0,0,0.32)';
  ctx.lineWidth = 2;
  for (let i = 0; i <= 8; i++) {
    ctx.beginPath();
    ctx.moveTo(i * square, 0);
    ctx.lineTo(i * square, size);
    ctx.moveTo(0, i * square);
    ctx.lineTo(size, i * square);
    ctx.stroke();
  }

  const map = new CanvasTexture(canvas as HTMLCanvasElement);
  map.colorSpace = SRGBColorSpace;
  map.anisotropy = 8;
  map.minFilter = LinearFilter;

  // Roughness varies with the grain, so the light travels across the wood.
  const rough = scratch(256, 256);
  const rctx = rough.getContext('2d') as Canvas2D;
  rctx.fillStyle = '#7a7a7a';
  rctx.fillRect(0, 0, 256, 256);
  for (let i = 0; i < 900; i++) {
    rctx.fillStyle = `rgba(255,255,255,${Math.random() * 0.06})`;
    rctx.fillRect(Math.random() * 256, Math.random() * 256, Math.random() * 16 + 3, 1);
  }
  const roughness = new CanvasTexture(rough as HTMLCanvasElement);
  roughness.wrapS = roughness.wrapT = RepeatWrapping;

  return { map, roughness };
}

/** A soft round dot, for dust in the light. */
export function dustTexture(): Texture {
  const canvas = scratch(64, 64);
  const ctx = canvas.getContext('2d') as Canvas2D;
  const g = ctx.createRadialGradient(32, 32, 0, 32, 32, 32);
  g.addColorStop(0, 'rgba(255,255,255,1)');
  g.addColorStop(0.35, 'rgba(255,255,255,0.45)');
  g.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, 64, 64);
  const texture = new CanvasTexture(canvas as HTMLCanvasElement);
  texture.colorSpace = SRGBColorSpace;
  return texture;
}
