import { BoardConfig, css, lightSquare, STYLES, TONES } from './config';

/**
 * The flat board, drawn: BoardUI/BoardView.swift in a canvas.
 *
 * The same layers in the same order — squares, the walnut photographs over
 * them, the last move, the pieces with their shadow, the files and ranks round
 * the edge — from the same numbers. What is not a picture in the app is not a
 * picture here either: the squares are colour, the glyph set is text, the
 * tone is arithmetic on the light side. The only images are the pieces and
 * the two walnut tiles, which are the app's own, and they are fetched once
 * for the page whatever number of boards it has.
 */

export interface Position2D {
  readonly fen: string;
  readonly last?: { readonly from: string; readonly to: string } | null;
  /** Black at the bottom. */
  readonly flip?: boolean;
}

const images = new Map<string, Promise<HTMLImageElement>>();

function image(src: string): Promise<HTMLImageElement> {
  let pending = images.get(src);
  if (!pending) {
    pending = new Promise((resolve, reject) => {
      const img = new Image();
      img.decoding = 'async';
      img.onload = () => resolve(img);
      img.onerror = reject;
      img.src = src;
    });
    images.set(src, pending);
  }
  return pending;
}

/** The light side shaded by the tone: multiply, then lift — ColorMatrix in BoardView. */
const shaded = new Map<string, Promise<CanvasImageSource>>();

function tinted(src: string, tone: BoardConfig['tone']): Promise<CanvasImageSource> {
  if (tone === 'boxwood') return image(src);
  const key = `${src}|${tone}`;
  let pending = shaded.get(key);
  if (!pending) {
    pending = image(src).then((img) => {
      const canvas = document.createElement('canvas');
      canvas.width = img.naturalWidth;
      canvas.height = img.naturalHeight;
      const ctx = canvas.getContext('2d')!;
      ctx.drawImage(img, 0, 0);
      const data = ctx.getImageData(0, 0, canvas.width, canvas.height);
      const { multiply, lift } = TONES[tone];
      const add = lift * 255;
      for (let i = 0; i < data.data.length; i += 4) {
        data.data[i] = Math.min(255, data.data[i] * multiply[0] + add);
        data.data[i + 1] = Math.min(255, data.data[i + 1] * multiply[1] + add);
        data.data[i + 2] = Math.min(255, data.data[i + 2] * multiply[2] + add);
      }
      ctx.putImageData(data, 0, 0);
      return canvas;
    });
    shaded.set(key, pending);
  }
  return pending;
}

const GLYPHS: Record<string, string> = { k: '♚', q: '♛', r: '♜', b: '♝', n: '♞', p: '♟' };
/** PieceGlyph.rimOffsets: a hairline outline in eight directions. */
const RIM = [
  [1, 0], [-1, 0], [0, 1], [0, -1],
  [0.7, 0.7], [-0.7, 0.7], [0.7, -0.7], [-0.7, -0.7],
] as const;

function pieceSource(code: string, config: BoardConfig): Promise<CanvasImageSource> {
  // The light side is boxwood in every set; the dark side is the set's stain.
  return code[0] === 'w'
    ? tinted(`pieces/${code}.png`, config.tone)
    : image(`pieces/${config.pieces}/${code}.png`);
}

interface Assets {
  readonly tiles: readonly [CanvasImageSource, CanvasImageSource] | null;
  readonly pieces: ReadonlyMap<string, CanvasImageSource>;
}

/** Everything a board needs, fetched before the first stroke so it is drawn in one go. */
async function assets(config: BoardConfig): Promise<Assets> {
  const tiles = STYLES[config.style].textured
    ? ([await tinted('board/wood-light.png', config.tone), await image('board/wood-dark.png')] as const)
    : null;
  const pieces = new Map<string, CanvasImageSource>();
  if (config.pieces !== 'glyph') {
    const codes = [...'KQRBNP'].flatMap((kind) => [`w${kind}`, `b${kind}`]);
    const loaded = await Promise.all(codes.map((code) => pieceSource(code, config)));
    codes.forEach((code, i) => pieces.set(code, loaded[i]));
  }
  return { tiles, pieces };
}

/**
 * Draw a position into a canvas of `side` CSS pixels.
 *
 * Everything is fetched first and then drawn without a pause, so two draws
 * asked for in quick succession — a replay stepping through a game — cannot
 * interleave their strokes. `current` says whether this draw is still the
 * one wanted once the pictures have arrived; one that is not is dropped.
 */
export async function draw(
  canvas: HTMLCanvasElement,
  side: number,
  position: Position2D,
  config: BoardConfig,
  current: () => boolean = () => true,
): Promise<void> {
  const loaded = await assets(config);
  if (!current()) return;
  paint(canvas, side, position, config, loaded);
}

function paint(canvas: HTMLCanvasElement, side: number, position: Position2D, config: BoardConfig, loaded: Assets): void {
  const ratio = Math.min(3, window.devicePixelRatio || 1);
  canvas.width = Math.round(side * ratio);
  canvas.height = Math.round(side * ratio);
  const ctx = canvas.getContext('2d')!;
  ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
  ctx.clearRect(0, 0, side, side);

  // The rim the files and ranks are written in, taken out of the board rather
  // than added round it — BoardView's `max(12, full * 0.052)`.
  const rim = config.coordinates ? Math.max(12, side * 0.052) : 0;
  const board = side - rim;
  const square = board / 8;
  const flip = !!position.flip;
  const style = STYLES[config.style];
  const light = css(lightSquare(config.style, config.tone));
  const dark = css(style.dark);

  const origin = (file: number, rank: number) => ({
    x: rim + (flip ? 7 - file : file) * square,
    y: (flip ? rank : 7 - rank) * square,
  });

  const tiles = loaded.tiles;
  for (let file = 0; file < 8; file++) {
    for (let rank = 0; rank < 8; rank++) {
      const isLight = (file + rank) % 2 === 1;
      const { x, y } = origin(file, rank);
      ctx.fillStyle = isLight ? light : dark;
      ctx.fillRect(x, y, square + 0.5, square + 0.5);
      if (tiles) ctx.drawImage(tiles[isLight ? 0 : 1], x, y, square + 0.5, square + 0.5);
    }
  }

  if (position.last) {
    ctx.fillStyle = style.lastMove;
    for (const name of [position.last.from, position.last.to]) {
      const { x, y } = origin(name.charCodeAt(0) - 97, Number(name[1]) - 1);
      ctx.fillRect(x, y, square, square);
    }
  }

  // The pieces, under one shadow — BoardView's `.shadow(radius: 0.045, y: 0.03)`.
  ctx.save();
  ctx.shadowColor = 'rgba(0, 0, 0, 0.35)';
  ctx.shadowBlur = square * 0.09;
  ctx.shadowOffsetY = square * 0.03;
  const rows = position.fen.split(' ')[0].split('/');
  for (let r = 0; r < 8; r++) {
    let file = 0;
    for (const ch of rows[r] ?? '') {
      if (/\d/.test(ch)) {
        file += Number(ch);
        continue;
      }
      const white = ch === ch.toUpperCase();
      const { x, y } = origin(file, 7 - r);
      if (config.pieces === 'glyph') {
        const size = square * 0.78;
        ctx.font = `${size}px "Apple Symbols", "Segoe UI Symbol", "DejaVu Sans", serif`;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        const glyph = GLYPHS[ch.toLowerCase()] + '︎';
        const cx = x + square / 2;
        const cy = y + square / 2 + square * 0.02;
        const width = Math.max(0.7, square * 0.022);
        ctx.fillStyle = white ? 'rgb(26, 26, 26)' : 'rgb(242, 242, 242)';
        for (const [dx, dy] of RIM) ctx.fillText(glyph, cx + dx * width, cy + dy * width);
        ctx.fillStyle = white ? 'rgb(250, 250, 250)' : 'rgb(26, 26, 26)';
        ctx.fillText(glyph, cx, cy);
      } else {
        // The art is centred on its own square canvas, so the board square is
        // the frame and nothing is nudged.
        const art = loaded.pieces.get((white ? 'w' : 'b') + ch.toUpperCase());
        if (art) ctx.drawImage(art, x, y, square, square);
      }
      file++;
    }
  }
  ctx.restore();

  if (rim) {
    ctx.fillStyle = 'rgba(233, 228, 216, 0.58)';
    ctx.font = `600 ${Math.max(8, rim * 0.62)}px "JetBrains Mono", ui-monospace, monospace`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    for (let i = 0; i < 8; i++) {
      const file = flip ? 7 - i : i;
      const rank = flip ? i : 7 - i;
      ctx.fillText(String.fromCharCode(65 + file), rim + i * square + square / 2, board + rim / 2);
      ctx.fillText(String(rank + 1), rim / 2, i * square + square / 2);
    }
  }
}
