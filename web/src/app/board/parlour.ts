import {
  AmbientLight,
  BackSide,
  BoxGeometry,
  BufferGeometry,
  CanvasTexture,
  Color,
  CylinderGeometry,
  DirectionalLight,
  EquirectangularReflectionMapping,
  Fog,
  Group,
  Material,
  Mesh,
  MeshBasicMaterial,
  MeshPhysicalMaterial,
  MeshStandardMaterial,
  Object3D,
  PlaneGeometry,
  PMREMGenerator,
  RepeatWrapping,
  SpotLight,
  SRGBColorSpace,
  Texture,
  WebGLRenderer,
} from 'three';
import { RoundedBoxGeometry } from 'three/examples/jsm/geometries/RoundedBoxGeometry.js';

import { Canvas2D, scratch } from '../three/board';

/**
 * The app's parlour — Carving `.parlour`, "Boxwood & walnut" in Settings: a
 * framed maple-and-walnut board on a plank table, under a lamp, in a dim room.
 *
 * Ported from `Parlour.swift` (the drawn textures) and the `.parlour` branches
 * of `Stage.swift` (the room, the board, the lamp), with `playable` on: this is
 * the app's LiveBoard, a board somebody reads, not the title sequence.
 *
 * The theatre is an unframed field on a black plinth lit from off-stage. What
 * makes this one look like a photograph of a board instead is three things,
 * none of them the pieces: a frame, the inlay line inside it, and a table to
 * stand on — a board on a void bounces light into nothing; on a table the warm
 * light coming back up off the wood fills the dark side of every piece.
 *
 * Positions are the app's, lifted 0.004 so the squares' top is at y = 0 as the
 * site's boards have it. Lights are the app's, converted with the ratios
 * `scene3d.ts` used for the theatre rig — see `SPOT` and the rest below — and
 * brightened by `PARLOUR_EXPOSURE`, the quarter stop this room's camera is
 * exposed over the theatre's.
 */
export interface ParlourRoom {
  /**
   * Everything in the room except the pieces and the last-move marks: the
   * squares, the frame, the inlaid coordinates, the table and the wall round
   * it. The squares' top is at y = 0.
   */
  readonly group: Group;
  /** The lamp and the light the room gives back, positioned — spot and directional targets included. */
  readonly lights: Object3D[];
  /** PMREM texture for `scene.environment`. */
  readonly environment: Texture;
  readonly environmentIntensity: number;
  readonly fog: Fog | null;
  /** The colour the room clears to — the fog's, as the app's is. */
  readonly background: Color;
  /** Boxwood, for White. */
  readonly light: Material;
  /** Walnut stain, for Black. */
  readonly dark: Material;
  /** The files and ranks inlaid in the frame — one plane, in `group`; toggle `visible`. */
  readonly coordinates: Mesh;
  /** What the camera must keep in frame: the frame's half-width at its outer edge, and its top and bottom. */
  readonly bounds: { half: number; top: number; bottom: number };
  dispose(): void;
}

/**
 * The quarter stop between the two rooms' cameras: the app exposes the parlour
 * at -0.30 and the theatre at -0.55. The site renders both at exposure 1 and
 * the theatre's rig was converted at that, so the difference is folded into
 * every intensity here rather than into the renderer the two rooms share.
 */
export const PARLOUR_EXPOSURE = 2 ** 0.25;

// The theatre's conversions, from `scene3d.ts`: SceneKit's lumens, which do not
// fall off, against three.js's candela, which do. The parlour's lamp stands as
// far from the board as the theatre's key — 11.9 units against 11.8 — so the
// spot's ratio carries over without a distance correction.
/** Key spot 790 → 290, decay 2, distance 36. */
const SPOT = 290 / 790;
/** Directional fill 215 → 0.65. */
const DIRECTIONAL = 0.65 / 215;
/** Environment 0.72 → 0.1. */
const ENVIRONMENT = 0.1 / 0.72;
/**
 * Ambient 405 × #141b2c → 1.6 × #2a3246. The colour moved as well as the
 * number, so the ratio is taken on luminance and the parlour keeps its own
 * warm colour.
 */
const AMBIENT = (1.6 * luminance(0x2a3246)) / (405 * luminance(0x141b2c));

/** The unlit wall's brightness against its drawn gradient — see `plaster`. */
const WALL = 0.7;

/** The squares' top, as the app has it: its field is 0.02 thick and centred at -0.014. */
const LIFT = 0.004;

const FRAME = 9.1;
const FRAME_DEPTH = 0.3;
const FRAME_TOP = -0.021 + LIFT;

const TEXTURE = 1024;

type Tone = readonly [r: number, g: number, b: number];

// Maple and walnut, as the wood is rather than as the lamp leaves it: warmer
// and more saturated than the theatre's pair, because a warm lamp takes colour
// out of what it hits.
const MAPLE: Tone = [0.847, 0.737, 0.557]; // #d8bc8e
const WALNUT: Tone = [0.427, 0.29, 0.204]; // #6d4a34
/** The frame, a darker cut of the same walnut. */
const FRAME_WOOD: Tone = [0.369, 0.231, 0.153]; // #5e3b27
/** The boxwood line in the inlay, and the letters. */
const INLAY: Tone = [0.878, 0.808, 0.639]; // #e0cea3
/** The table: oak, old, and darker than any of it. */
const OAK: Tone = [0.239, 0.157, 0.106]; // #3d281b
const HAIRLINE: Tone = [0.11, 0.063, 0.031];

export function parlourRoom(renderer: WebGLRenderer): ParlourRoom {
  const disposables: { dispose(): void }[] = [];
  const keep = <T extends { dispose(): void }>(item: T): T => {
    disposables.push(item);
    return item;
  };
  const anisotropy = Math.min(8, renderer.capabilities.getMaxAnisotropy());
  const group = new Group();
  group.name = 'parlour';

  // The squares: sixty-four and nothing else, an 8×8 box with no frame drawn
  // into it, so a1's corner is the texture's corner.
  const fieldMap = keep(texture(field(TEXTURE)));
  fieldMap.anisotropy = anisotropy;
  const fieldRoughness = keep(texture(roughness(256), false));
  const fieldMaterial = keep(
    new MeshPhysicalMaterial({
      map: fieldMap,
      roughnessMap: fieldRoughness,
      // The map is the roughness, as SceneKit reads it; three.js multiplies.
      roughness: 1,
      metalness: 0,
      // Waxed, title or not: a tight coat gives a lamp one hot spot on the
      // squares, and a bright pool in the middle of the board is where the
      // pieces are.
      clearcoat: 0.1,
      clearcoatRoughness: 0.68,
    }),
  );
  const surface = new Mesh(keep(new BoxGeometry(8, 0.02, 8)), fieldMaterial);
  surface.name = 'board-surface';
  surface.position.y = -0.014 + LIFT;
  surface.castShadow = true;
  surface.receiveShadow = true;

  // The frame the field is set into: walnut, thicker than the theatre's
  // plinth because a board on a table is an object with a side to it. Six
  // materials, because the inlay drawn down the edge would be a stripe round a
  // plinth: the top gets the frame, the sides end grain, darker and duller, as
  // a sawn edge is.
  const borderMap = keep(texture(border(TEXTURE)));
  borderMap.anisotropy = anisotropy;
  const edge = keep(
    new MeshPhysicalMaterial({
      color: 0x40261a,
      roughness: 0.58,
      metalness: 0,
      clearcoat: 0.22,
      clearcoatRoughness: 0.46,
    }),
  );
  const face = keep(
    new MeshPhysicalMaterial({
      map: borderMap,
      roughness: 0.42,
      metalness: 0,
      // French polish on the frame and wax on the field: the frame is handled
      // and the squares are played on, and it keeps the frame the darker,
      // glossier thing next to the outer rank.
      clearcoat: 0.4,
      clearcoatRoughness: 0.24,
    }),
  );
  const under = keep(new MeshPhysicalMaterial({ color: 0x2a180f, roughness: 0.86, metalness: 0 }));
  // three.js orders a box's faces +x, -x, +y, -y, +z, -z.
  const frame = new Mesh(keep(chamferedBox(FRAME, FRAME_DEPTH, FRAME, 0.02)), [edge, edge, face, under, edge, edge]);
  frame.name = 'board-frame';
  frame.position.y = FRAME_TOP - FRAME_DEPTH / 2;
  frame.castShadow = true;
  frame.receiveShadow = true;

  // The files and ranks, inlaid in the same boxwood as the line — and lit, so
  // they dim with the frame round them where the lamp does not reach, as wood
  // does and a printed label does not. A decal casts nothing.
  const lettersMap = keep(texture(letters(TEXTURE)));
  lettersMap.anisotropy = anisotropy;
  const paint = keep(
    new MeshStandardMaterial({
      map: lettersMap,
      transparent: true,
      depthWrite: false,
      roughness: 0.44,
      metalness: 0,
    }),
  );
  const coordinates = new Mesh(keep(new PlaneGeometry(FRAME, FRAME)), paint);
  coordinates.name = 'board-coordinates';
  coordinates.rotation.x = -Math.PI / 2;
  // Just clear of the frame's top — further than the theatre's, because this
  // plane is lit and has a shaded surface of its own to be confused with.
  coordinates.position.y = -0.0182 + LIFT;
  coordinates.receiveShadow = true;

  // The table: a box, because it is seen from below its own top edge, and
  // wide enough that its far edge is in the fog. Tiled so the planks come out
  // about three units across; offset so the tiles start where SceneKit's do,
  // at the texture's top-left corner rather than three.js's bottom-left.
  const planksMap = keep(texture(planks(TEXTURE)));
  planksMap.wrapS = planksMap.wrapT = RepeatWrapping;
  planksMap.repeat.set(2.2, 1.7);
  planksMap.offset.set(0, 0.3);
  planksMap.anisotropy = anisotropy;
  const wood = keep(
    new MeshPhysicalMaterial({
      map: planksMap,
      roughness: 0.72,
      metalness: 0,
      // Old wax, not varnish: enough sheen for the lamp to find the grain.
      clearcoat: 0.12,
      clearcoatRoughness: 0.7,
    }),
  );
  const table = new Mesh(keep(chamferedBox(34, 0.9, 26, 0.02)), wood);
  table.name = 'table';
  // Its top a few thousandths under the frame's underside, so the two never
  // fight for the same pixels along the join.
  table.position.y = -0.775 + LIFT;
  table.receiveShadow = true;

  // The room, as one cylinder seen from inside: no corners to notice as the
  // board turns, and something behind the table for it to be seen against.
  // Unlit — the lamp's falloff is painted into the gradient. Sunk, so the
  // warmest part of the gradient meets the table.
  const wallMap = keep(texture(wall(256, 256)));
  const plaster = keep(
    new MeshBasicMaterial({
      map: wallMap,
      side: BackSide,
      // Unlit, so no light ratio reaches it: this is the app's picture
      // matched instead. SceneKit exposes it down by 0.30 of a stop and
      // three.js's filmic curve lifts it, and at 0.7 the wall lands on the
      // app's render to within a level from the table's edge to the top.
      color: new Color(WALL, WALL, WALL),
    }),
  );
  const room = new Mesh(keep(new CylinderGeometry(34, 34, 40, 48, 1)), plaster);
  room.name = 'room';
  room.position.y = 14 + LIFT;

  group.add(room, table, frame, surface, coordinates);

  // Something for the boxwood to reflect: a lit room rather than a lit stage.
  const equirect = texture(environment(512, 256));
  equirect.mapping = EquirectangularReflectionMapping;
  const pmrem = new PMREMGenerator(renderer);
  const environmentMap = keep(pmrem.fromEquirectangular(equirect).texture);
  equirect.dispose();
  pmrem.dispose();

  // The pieces, oiled and waxed rather than lacquered: the sheen is broad and
  // low. The dark side is a walnut stain, not black — it lets the grain
  // through, and a near-black piece under a lamp is a silhouette.
  const light = keep(
    new MeshPhysicalMaterial({
      name: 'boxwood',
      color: 0xe6d8b4,
      roughness: 0.46,
      metalness: 0,
      clearcoat: 0.16,
      clearcoatRoughness: 0.58,
    }),
  );
  const dark = keep(
    new MeshPhysicalMaterial({
      name: 'walnut',
      color: 0x53321f,
      roughness: 0.42,
      metalness: 0,
      clearcoat: 0.2,
      clearcoatRoughness: 0.52,
    }),
  );

  const lights = lamp();
  // The lamp's shadow map, and whatever else a light holds on the GPU.
  for (const light of lights) if ('dispose' in light && typeof light.dispose === 'function') keep(light as Object3D & { dispose(): void });

  return {
    group,
    lights,
    environment: environmentMap,
    environmentIntensity: 0.55 * ENVIRONMENT * PARLOUR_EXPOSURE,
    // A dim room rather than a black stage: the fog closes the table off into
    // it. SceneKit's fog has an exponent of 1.2 as well; three.js's is linear.
    fog: new Fog(0x191310, 20, 62),
    background: new Color(0x191310),
    light,
    dark,
    coordinates,
    bounds: { half: FRAME / 2, top: FRAME_TOP, bottom: FRAME_TOP - FRAME_DEPTH },
    dispose() {
      for (const item of disposables) item.dispose();
    },
  };
}

/**
 * One lamp in the room, and what the room gives back — `Stage.buildLamp`.
 *
 * One warm source and no cold light anywhere, because a table lamp is the only
 * thing on in the room; what replaces the theatre's two cold lights is bounce,
 * off the ceiling and off the table.
 */
function lamp(): Object3D[] {
  // Close, high, behind the board and off to the right: the only side it can
  // stand on, since a lamp on the player's side throws every shadow away from
  // the camera and the set looks pasted onto the squares.
  //
  // A narrow inner cone in a wide one, 32° inside 80° across, so the light
  // falls off across the board; three.js takes half the outer angle, and the
  // soft part as a fraction of it.
  const key = new SpotLight(0xffc98a, 1080 * SPOT * PARLOUR_EXPOSURE, 36, (40 * Math.PI) / 180, 1 - 32 / 80, 2);
  key.name = 'lamp';
  key.position.set(8.2, 8.6, -1.2);
  key.target.position.set(-0.8, 0, 0.2);
  key.castShadow = true;
  key.shadow.mapSize.set(2048, 2048);
  key.shadow.camera.near = 1;
  key.shadow.camera.far = 40;
  // Under half the theatre's bias, as the app has it (1.1 against 2.4): bias
  // pushes the shadow away from what casts it, and what that costs first is
  // the contact shadow round each base.
  key.shadow.bias = -0.0012 * (1.1 / 2.4);
  key.shadow.normalBias = 0.022 * (1.1 / 2.4);
  // A lampshade is a big diffuser close by: a little softer than the theatre.
  key.shadow.radius = 2.6;
  // SceneKit's shadow is #1a0e06 at 0.76, drawn deferred: every shadowed pixel
  // is mixed three-quarters of the way to that brown, whatever lit it — which
  // leaves shadowed wood at 0.29 of its lit brightness, measured off the app's
  // render. three.js can only take the lamp's own light away, and the bounce
  // and the room still fill the shadow in: taking 0.87 of it lands on the same
  // 0.29 (0.76 gives 0.38, all of it 0.19).
  key.shadow.intensity = 0.87;

  // The room coming back off the ceiling, from the corner opposite the lamp —
  // the near left, facing whichever chair the board is read from.
  const ceiling = new DirectionalLight(0xcbb69e, 200 * DIRECTIONAL * PARLOUR_EXPOSURE);
  ceiling.name = 'ceiling';
  ceiling.position.set(-5.5, 6.5, 5.5);
  ceiling.target.position.set(0, 0, 0);

  // And off the table, from below: light under the bases and into the
  // underside of the knight's jaw.
  const table = new DirectionalLight(0xb98a5c, 90 * DIRECTIONAL * PARLOUR_EXPOSURE);
  table.name = 'table-bounce';
  table.position.set(2, -3, 4);
  table.target.position.set(0, 0.5, 0);

  const ambient = new AmbientLight(0x282018, 330 * AMBIENT * PARLOUR_EXPOSURE);
  ambient.name = 'room';

  return [key, key.target, ceiling, ceiling.target, table, table.target, ambient];
}

// MARK: - Textures

/** The linear luminance of an sRGB hex colour, as three.js holds it. */
function luminance(hex: number): number {
  const { r, g, b } = new Color(hex);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function texture(canvas: HTMLCanvasElement | OffscreenCanvas, colour = true): CanvasTexture {
  const map = new CanvasTexture(canvas as HTMLCanvasElement);
  if (colour) map.colorSpace = SRGBColorSpace;
  return map;
}

function canvas(width: number, height: number): { canvas: HTMLCanvasElement | OffscreenCanvas; ctx: Canvas2D } {
  const surface = scratch(width, height);
  return { canvas: surface, ctx: surface.getContext('2d') as Canvas2D };
}

/**
 * Draw from here on in CGContext's coordinates: origin bottom-left, y up.
 *
 * So every number below is the Swift's, and so is every rotation — CG's
 * rotation matrix is canvas's, and it is only the y axis that differs.
 */
function likeCoreGraphics(ctx: Canvas2D, height: number): void {
  ctx.setTransform(1, 0, 0, -1, 0, height);
}

function rgba([r, g, b]: Tone, alpha = 1): string {
  return `rgba(${Math.round(r * 255)}, ${Math.round(g * 255)}, ${Math.round(b * 255)}, ${alpha})`;
}

/**
 * A fixed sequence, so the board is the same board every time — the app's
 * `Parlour.Grain`, an xorshift64, draw for draw. Every texture is drawn from
 * the same seeds in the same order as the Swift's.
 */
class Grain {
  private state: bigint;
  constructor(seed: bigint) {
    this.state = BigInt.asUintN(64, seed);
  }
  next(): bigint {
    let state = this.state;
    state ^= BigInt.asUintN(64, state << 13n);
    state ^= state >> 7n;
    state ^= BigInt.asUintN(64, state << 17n);
    this.state = state;
    return state;
  }
  unit(): number {
    return Number(this.next() >> 11n) / 2 ** 53;
  }
  signed(): number {
    return this.unit() - 0.5;
  }
}

interface Rect {
  readonly x: number;
  readonly y: number;
  readonly width: number;
  readonly height: number;
}

/**
 * Grain: a handful of long translucent strokes, drifting as they run — along
 * something, so the square reads as sawn wood rather than as sandpaper.
 */
function grain(
  ctx: Canvas2D,
  rect: Rect,
  random: Grain,
  strokes: number,
  alpha: number,
  dark: boolean,
  vertical: boolean,
): void {
  ctx.save();
  ctx.beginPath();
  ctx.rect(rect.x, rect.y, rect.width, rect.height);
  ctx.clip();
  ctx.strokeStyle = dark ? `rgba(0, 0, 0, ${alpha})` : rgba([0.404, 0.29, 0.161], alpha);
  ctx.lineWidth = Math.max(0.8, rect.width / 90);
  const run = vertical ? rect.height : rect.width;
  const across = vertical ? rect.width : rect.height;
  for (let i = 0; i < strokes; i++) {
    const offset = random.unit() * across;
    const point = (along: number, wander: number): [number, number] =>
      vertical ? [rect.x + offset + wander, rect.y + along] : [rect.x + along, rect.y + offset + wander];
    const sway = across * 0.06;
    // The Swift's argument order, which is the order the draws are taken in.
    const to = point(run, random.signed() * sway);
    const one = point(run * 0.33, random.signed() * sway * 2);
    const two = point(run * 0.66, random.signed() * sway * 2);
    ctx.beginPath();
    ctx.moveTo(...point(0, 0));
    ctx.bezierCurveTo(one[0], one[1], two[0], two[1], to[0], to[1]);
    ctx.stroke();
  }
  ctx.restore();
}

/**
 * The playing field — `Parlour.field`.
 *
 * The one texture drawn in the canvas's own coordinates rather than CG's, and
 * on purpose. CG's origin is the bottom-left, so the app's image has its light
 * corner square at the bottom-left, where SceneKit lays a1 — the app's
 * parlour has a light square on a1. Drawn with the same numbers from the top
 * the image is the app's mirrored top to bottom: a8 light and a1 dark, as a
 * board is, with every square's grain still running the way it did.
 */
function field(size: number): HTMLCanvasElement | OffscreenCanvas {
  const { canvas: surface, ctx } = canvas(size, size);
  const random = new Grain(0x9e3779b97f4a7c15n);
  const square = size / 8;

  for (let file = 0; file < 8; file++) {
    for (let rank = 0; rank < 8; rank++) {
      const light = (file + rank) % 2 === 0;
      const cell = { x: file * square, y: rank * square, width: square, height: square };
      ctx.fillStyle = rgba(light ? MAPLE : WALNUT);
      ctx.fillRect(cell.x, cell.y, cell.width, cell.height);
      // Along the file on light squares and across it on dark ones, which is
      // how a board is veneered: alternate squares turned ninety degrees.
      grain(ctx, cell, random, 16, light ? 0.1 : 0.17, !light, light);
    }
  }

  // A hairline between the squares, the way an inlaid board reads.
  ctx.strokeStyle = rgba([0.11, 0.06, 0.03], 0.3);
  ctx.lineWidth = (1.6 * size) / 1024;
  ctx.beginPath();
  for (let i = 0; i <= 8; i++) {
    const offset = i * square;
    ctx.moveTo(offset, 0);
    ctx.lineTo(offset, size);
    ctx.moveTo(0, offset);
    ctx.lineTo(size, offset);
  }
  ctx.stroke();
  return surface;
}

/**
 * Roughness, varying with the grain so the light travels across the wood —
 * `BoardSurface.roughness`, with its own fixed seed. Drawn the same way up as
 * the field it lies under.
 */
function roughness(size: number): HTMLCanvasElement | OffscreenCanvas {
  const { canvas: surface, ctx } = canvas(size, size);
  const random = new Grain(0x2545f4914f6cdd1dn);
  ctx.fillStyle = rgba([0.478, 0.478, 0.478]);
  ctx.fillRect(0, 0, size, size);
  for (let i = 0; i < 900; i++) {
    ctx.fillStyle = `rgba(255, 255, 255, ${random.unit() * 0.06})`;
    const x = random.unit() * size;
    const y = random.unit() * size;
    const width = random.unit() * 16 + 3;
    ctx.fillRect(x, y, width, 1);
  }
  return surface;
}

/**
 * The frame, drawn on the whole top of the frame's box — `Parlour.border`.
 *
 * Mitred: the grain on each side runs along that side and the four meet on the
 * diagonals, which is what says "made" from any angle that shows two sides.
 * Then the inlay — a dark hairline, a band of boxwood, a second hairline —
 * measured in squares from the outer edge.
 */
function border(size: number, share = 8 / 9.1): HTMLCanvasElement | OffscreenCanvas {
  const { canvas: surface, ctx } = canvas(size, size);
  likeCoreGraphics(ctx, size);
  const side = size;
  const rim = (side * (1 - share)) / 2;
  const random = new Grain(0xd1b54a32d192ed03n);

  ctx.fillStyle = rgba(FRAME_WOOD);
  ctx.fillRect(0, 0, side, side);

  for (let edge = 0; edge < 4; edge++) {
    ctx.save();
    ctx.translate(side / 2, side / 2);
    ctx.rotate((edge * Math.PI) / 2);
    ctx.translate(-side / 2, -side / 2);
    // The trapezoid this side owns, closing at forty-five degrees at both ends.
    ctx.beginPath();
    ctx.moveTo(0, 0);
    ctx.lineTo(side, 0);
    ctx.lineTo(side - rim, rim);
    ctx.lineTo(rim, rim);
    ctx.closePath();
    ctx.clip();
    grain(ctx, { x: 0, y: 0, width: side, height: rim }, random, 22, 0.2, true, false);
    // A soft highlight along the outer edge, where a moulded rim catches the
    // light whichever way the board is turned.
    ctx.strokeStyle = rgba([0.71, 0.52, 0.35], 0.34);
    ctx.lineWidth = rim * 0.16;
    ctx.beginPath();
    ctx.moveTo(0, rim * 0.08);
    ctx.lineTo(side, rim * 0.08);
    ctx.stroke();
    ctx.restore();
  }

  const unit = (side * share) / 8;
  const band = (from: number, through: number, tone: Tone, alpha: number) => {
    const middle = ((from + through) / 2) * unit;
    ctx.strokeStyle = rgba(tone, alpha);
    ctx.lineWidth = (through - from) * unit;
    ctx.strokeRect(middle, middle, side - 2 * middle, side - 2 * middle);
  };
  band(0.445, 0.465, HAIRLINE, 0.88);
  band(0.465, 0.525, INLAY, 1.0);
  band(0.525, 0.55, HAIRLINE, 0.88);
  return surface;
}

/**
 * The files and ranks, cut from the inlay's boxwood — `Parlour.letters`,
 * which is `BoardSurface.coordinates` in that ink: capitals along the two
 * ranks' edges, digits along the files', each side reading from outside the
 * board looking in. The theatre's plinth carries the same letters in its own
 * ink, which is why the ink is a parameter.
 */
export function letters(size: number, ink = rgba(INLAY, 0.88), share = 8 / 9.1): HTMLCanvasElement | OffscreenCanvas {
  const { canvas: surface, ctx } = canvas(size, size);
  likeCoreGraphics(ctx, size);
  const side = size;
  const rim = (side * (1 - share)) / 2;
  const square = (side - rim * 2) / 8;
  ctx.fillStyle = ink;
  ctx.font = `${rim * 0.44}px Menlo, "SF Mono", ui-monospace, "DejaVu Sans Mono", Consolas, monospace`;

  const draw = (text: string, x: number, y: number, turned: number) => {
    ctx.save();
    ctx.translate(x, y);
    ctx.rotate(turned);
    // CoreText sets glyphs upright in CG's y-up space; canvas sets them in its
    // own y-down one, so they are turned back the right way up here.
    ctx.scale(1, -1);
    const m = ctx.measureText(text);
    ctx.fillText(
      text,
      -(m.actualBoundingBoxRight - m.actualBoundingBoxLeft) / 2,
      (m.actualBoundingBoxAscent - m.actualBoundingBoxDescent) / 2,
    );
    ctx.restore();
  };

  const files = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
  for (let index = 0; index < 8; index++) {
    const along = rim + square * (index + 0.5);
    draw(files[index], along, rim / 2, 0);
    draw(files[index], along, side - rim / 2, Math.PI);
    const rank = String(index + 1);
    draw(rank, rim / 2, along, Math.PI / 2);
    draw(rank, side - rim / 2, along, -Math.PI / 2);
  }
  return surface;
}

/**
 * The table, in sawn planks — `Parlour.planks`: wide boards a shade apart, a
 * dark seam between each, and a knot or two, drawn as rings because a filled
 * ellipse reads as a stain.
 */
function planks(size: number, boards = 5): HTMLCanvasElement | OffscreenCanvas {
  const { canvas: surface, ctx } = canvas(size, size);
  likeCoreGraphics(ctx, size);
  const side = size;
  const random = new Grain(0x2545f4914f6cdd1dn);
  ctx.fillStyle = rgba(OAK);
  ctx.fillRect(0, 0, side, side);

  const plank = side / boards;
  for (let board = 0; board < boards; board++) {
    const strip = { x: 0, y: board * plank, width: side, height: plank };
    // Half a stop between planks reads as separate boards; a whole one and
    // the table is stripes, competing with the squares.
    const shade = 0.9 + random.unit() * 0.18;
    ctx.fillStyle = rgba([OAK[0] * shade, OAK[1] * shade, OAK[2] * shade]);
    ctx.fillRect(strip.x, strip.y, strip.width, strip.height);
    grain(ctx, strip, random, 26, 0.26, true, false);

    if (random.unit() > 0.45) {
      const cx = random.unit() * side;
      const cy = strip.y + plank / 2 + random.signed() * plank * 0.5;
      ctx.save();
      ctx.beginPath();
      ctx.rect(strip.x, strip.y, strip.width, strip.height);
      ctx.clip();
      for (let ring = 0; ring < 5; ring++) {
        const radius = plank * (0.05 + ring * 0.035);
        ctx.strokeStyle = `rgba(0, 0, 0, ${0.3 - ring * 0.05})`;
        ctx.lineWidth = Math.max(1, plank * 0.018);
        ctx.beginPath();
        ctx.ellipse(cx, cy, radius * 1.7, radius, 0, 0, Math.PI * 2);
        ctx.stroke();
      }
      ctx.restore();
    }

    // The seam, and the light on the lip of the plank below it.
    ctx.strokeStyle = 'rgba(0, 0, 0, 0.62)';
    ctx.lineWidth = Math.max(1.5, side / 420);
    ctx.beginPath();
    ctx.moveTo(0, strip.y);
    ctx.lineTo(side, strip.y);
    ctx.stroke();
    ctx.strokeStyle = rgba([0.51, 0.36, 0.24], 0.16);
    ctx.lineWidth = Math.max(1, side / 640);
    ctx.beginPath();
    ctx.moveTo(0, strip.y + side / 380);
    ctx.lineTo(side, strip.y + side / 380);
    ctx.stroke();
  }
  return surface;
}

/** A vertical gradient in CG's convention: the first stop at the top of the image. */
function gradient(
  width: number,
  height: number,
  stops: readonly (readonly [number, number, number, number])[],
): HTMLCanvasElement | OffscreenCanvas {
  const { canvas: surface, ctx } = canvas(width, height);
  likeCoreGraphics(ctx, height);
  const fill = ctx.createLinearGradient(0, height, 0, 0);
  for (const [at, r, g, b] of stops) fill.addColorStop(at, rgba([r, g, b]));
  ctx.fillStyle = fill;
  ctx.fillRect(0, 0, width, height);
  return surface;
}

/**
 * The wall behind, as the lamp lights it — `Parlour.wall`. Brightest at the
 * bottom, where the lamp is: a lamp on a side table lights the wall from
 * below its shade, and the pool falls off upwards.
 */
function wall(width: number, height: number): HTMLCanvasElement | OffscreenCanvas {
  return gradient(width, height, [
    [0.0, 0.086, 0.071, 0.059],
    [0.42, 0.18, 0.145, 0.114],
    [0.74, 0.31, 0.251, 0.192],
    [1.0, 0.408, 0.333, 0.255],
  ]);
}

/** Something for the boxwood to reflect: a lit room rather than a lit stage — `Parlour.environment`. */
function environment(width: number, height: number): HTMLCanvasElement | OffscreenCanvas {
  return gradient(width, height, [
    [0.0, 0.988, 0.933, 0.824], // the ceiling the lamp is throwing at
    [0.3, 0.706, 0.62, 0.502],
    [0.52, 0.404, 0.333, 0.263],
    [0.74, 0.204, 0.163, 0.125],
    [1.0, 0.106, 0.086, 0.067], // the table, which is what is under it
  ]);
}

/**
 * SceneKit's `SCNBox` with a chamfer: three.js's rounded box, given the flat
 * box's texture coordinates.
 *
 * `RoundedBoxGeometry` keeps the six groups but lays its own coordinates over
 * each face, bent round the rounding — and on the flat middle of a face they
 * come down to floating-point noise. Projected straight down each face
 * instead, the frame's texture spans its 9.1 units exactly as the Swift's
 * inlay measurements assume.
 */
function chamferedBox(width: number, height: number, depth: number, radius: number): BufferGeometry {
  const geometry = new RoundedBoxGeometry(width, height, depth, 2, radius);
  const position = geometry.getAttribute('position');
  const uv = geometry.getAttribute('uv');
  const [w, h, d] = [width / 2, height / 2, depth / 2];
  for (const { start, count, materialIndex } of geometry.groups) {
    for (let i = start; i < start + count; i++) {
      const x = position.getX(i);
      const y = position.getY(i);
      const z = position.getZ(i);
      // BoxGeometry's own mapping, face by face.
      const [u, v] = [
        [(d - z) / depth, (y + h) / height], // +x
        [(z + d) / depth, (y + h) / height], // -x
        [(x + w) / width, (d - z) / depth], // +y
        [(x + w) / width, (z + d) / depth], // -y
        [(x + w) / width, (y + h) / height], // +z
        [(w - x) / width, (y + h) / height], // -z
      ][materialIndex ?? 0];
      uv.setXY(i, u, v);
    }
  }
  uv.needsUpdate = true;
  return geometry;
}
