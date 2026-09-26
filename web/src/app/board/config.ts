/**
 * How a board looks, as the app decides it.
 *
 * The same choices the app offers under Appearance, with the same numbers —
 * ported from ChessTraining/Appearance.swift and BoardUI/BoardTheme.swift, so
 * a position drawn here and the same position in the app are the same board.
 * A board is drawn from this and a position, nothing else: no picture of any
 * board is ever sent, and changing a setting changes every board on the page.
 */

export type BoardStyle = 'wood' | 'lamplight' | 'amber' | 'forest' | 'ocean' | 'ivory' | 'rose' | 'sand' | 'slate';
export type PieceSet = 'ebony' | 'emerald' | 'sapphire' | 'claret' | 'glyph';
export type LightTone = 'snow' | 'chalk' | 'boxwood' | 'frost' | 'mist';
export type Dimension = '2d' | '3d';
/** The turned set in the round — Carving. The flat board's choices do not reach it. */
export type Carving = 'banded' | 'plain' | 'parlour';

export interface BoardConfig {
  readonly dimension: Dimension;
  readonly style: BoardStyle;
  readonly pieces: PieceSet;
  readonly tone: LightTone;
  readonly carving: Carving;
  readonly coordinates: boolean;
}

export const DEFAULT_CONFIG: BoardConfig = {
  dimension: '2d',
  style: 'wood',
  pieces: 'ebony',
  tone: 'boxwood',
  carving: 'banded',
  coordinates: true,
};

type RGB = readonly [number, number, number];

export interface Style {
  readonly name: string;
  /** Squares, 0…1, light and dark — BoardStyle.squares. */
  readonly light: RGB;
  readonly dark: RGB;
  /** The last move, which is chosen per board: one yellow does not read on all nine. */
  readonly lastMove: string;
  /** Photographed squares, drawn over the colour. Only walnut has them. */
  readonly textured: boolean;
}

const WARM = 'rgba(255, 214, 92, 0.5)';

export const STYLES: Record<BoardStyle, Style> = {
  wood: { name: 'Walnut', light: [0.796, 0.608, 0.4], dark: [0.424, 0.263, 0.173], lastMove: WARM, textured: true },
  lamplight: { name: 'Lamplight', light: [0.878, 0.733, 0.557], dark: [0.502, 0.408, 0.302], lastMove: WARM, textured: false },
  amber: { name: 'Amber', light: [0.945, 0.918, 0.859], dark: [0.706, 0.596, 0.455], lastMove: WARM, textured: false },
  forest: { name: 'Forest', light: [0.922, 0.925, 0.816], dark: [0.545, 0.663, 0.435], lastMove: 'rgba(252, 237, 89, 0.55)', textured: false },
  ocean: { name: 'Ocean', light: [0.871, 0.906, 0.925], dark: [0.573, 0.694, 0.769], lastMove: 'rgba(252, 184, 51, 0.5)', textured: false },
  ivory: { name: 'Porcelain', light: [1, 1, 1], dark: [0.788, 0.812, 0.847], lastMove: 'rgba(252, 184, 51, 0.5)', textured: false },
  rose: { name: 'Rosewater', light: [0.961, 0.902, 0.898], dark: [0.796, 0.588, 0.596], lastMove: 'rgba(250, 204, 77, 0.55)', textured: false },
  sand: { name: 'Sand', light: [0.945, 0.894, 0.796], dark: [0.804, 0.694, 0.514], lastMove: WARM, textured: false },
  slate: { name: 'Slate', light: [0.859, 0.875, 0.898], dark: [0.545, 0.588, 0.643], lastMove: 'rgba(252, 184, 51, 0.5)', textured: false },
};

export const PIECE_SETS: Record<PieceSet, { name: string }> = {
  ebony: { name: 'Ivory & ebony' },
  emerald: { name: 'Ivory & emerald' },
  sapphire: { name: 'Ivory & sapphire' },
  claret: { name: 'Ivory & claret' },
  glyph: { name: 'Classic' },
};

/**
 * The sets in the round, as Settings names them. The first two share the lit
 * black room the app opens on; the walnut set brings its own board and its
 * own lamp, because a set and a board are one object in a photograph.
 */
export const CARVINGS: Record<Carving, { name: string }> = {
  banded: { name: 'Brass banded' },
  plain: { name: 'Boxwood & ebony' },
  parlour: { name: 'Boxwood & walnut' },
};

/**
 * The light side's shade — LightTone.shading: multiply, then lift. It moves
 * the light squares and the light pieces together, as the app does, so the
 * pair that was too close for somebody to read stays apart.
 */
export const TONES: Record<LightTone, { name: string; multiply: RGB; lift: number }> = {
  snow: { name: 'Snow', multiply: [1, 1, 1], lift: 0.1 },
  chalk: { name: 'Chalk', multiply: [1, 0.995, 0.985], lift: 0.05 },
  boxwood: { name: 'Boxwood', multiply: [1, 1, 1], lift: 0 },
  frost: { name: 'Frost', multiply: [0.9, 0.96, 1], lift: 0.05 },
  mist: { name: 'Mist', multiply: [0.8, 0.9, 1], lift: 0.1 },
};

export function css([r, g, b]: RGB): string {
  return `rgb(${Math.round(r * 255)}, ${Math.round(g * 255)}, ${Math.round(b * 255)})`;
}

/** A light square's colour with the tone applied, as BoardTheme does. */
export function lightSquare(style: BoardStyle, tone: LightTone): RGB {
  const { light } = STYLES[style];
  const { multiply, lift } = TONES[tone];
  return [0, 1, 2].map((i) => Math.min(1, light[i] * multiply[i] + lift)) as unknown as RGB;
}

/**
 * The board before anything is drawn on it: its two colours as a CSS
 * background, which is all the prerendered page carries. A crawler, a reader
 * without scripts and the first frame all get the right board, empty.
 */
export function placeholder(config: BoardConfig): string {
  const light = css(lightSquare(config.style, config.tone));
  const dark = css(STYLES[config.style].dark);
  // From twelve o'clock: top right dark, top left light — a8 is a light square.
  return `repeating-conic-gradient(${dark} 0% 25%, ${light} 0% 50%) 0 0 / 25% 25%`;
}

const STORAGE = 'bp.board';

/** The viewer's own choice, kept in their browser — and only there. */
export function savedConfig(): BoardConfig {
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE) ?? 'null');
    if (!saved || typeof saved !== 'object') return DEFAULT_CONFIG;
    return {
      dimension: saved.dimension === '3d' ? '3d' : '2d',
      style: saved.style in STYLES ? saved.style : DEFAULT_CONFIG.style,
      pieces: saved.pieces in PIECE_SETS ? saved.pieces : DEFAULT_CONFIG.pieces,
      tone: saved.tone in TONES ? saved.tone : DEFAULT_CONFIG.tone,
      carving: saved.carving in CARVINGS ? saved.carving : DEFAULT_CONFIG.carving,
      coordinates: typeof saved.coordinates === 'boolean' ? saved.coordinates : DEFAULT_CONFIG.coordinates,
    };
  } catch {
    return DEFAULT_CONFIG;
  }
}

export function saveConfig(config: BoardConfig): void {
  try {
    localStorage.setItem(STORAGE, JSON.stringify(config));
  } catch {
    // A private window or blocked storage: the choice lasts the visit.
  }
}
