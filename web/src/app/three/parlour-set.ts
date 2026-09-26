import { BufferGeometry } from 'three';
import { mergeGeometries } from 'three/examples/jsm/utils/BufferGeometryUtils.js';

import { knightHead, knightMane } from './knight';
import type { PieceKind } from './pieces';
import { Solid, type Turn, type Vec3, revolved, sphere } from './solid';

/**
 * The parlour set: the club Staunton off the lamp table, in boxwood and
 * walnut, with no gilt on it anywhere.
 *
 * Ported from the app's `ParlourSet.swift`, profile for profile. It is a
 * different turning from the banded set in `pieces.ts`, and the reason is
 * proportion rather than decoration: that set is drawn small, a 1.44 king on a
 * foot 0.55 of a square across, so a full back rank has daylight between every
 * piece. A real tournament set is a 95mm king on a 40mm base on 57mm squares,
 * and this one is cut to a real set's heights with the reference's wide feet —
 * the king's foot is 0.79 of its square, which is what leaves a back rank
 * looking crowded rather than sparse, and a board looking like furniture
 * rather than like a diagram.
 *
 * |        | king | queen | bishop | knight | rook | pawn |
 * |--------|------|-------|--------|--------|------|------|
 * | banded | 1.44 | 1.15  | 0.98   | 0.83   | 0.67 | 0.61 |
 * | this   | 1.82 | 1.58  | 1.40   | 1.24   | 1.08 | 0.94 |
 *
 * One thing is not new, on purpose: the knight's head. It is the same mesh and
 * the same relief as the banded set's, scaled — a second horse would be a
 * second helping of the most expensive work in the set.
 *
 * All wood, so each piece is one geometry in one group (index 0): it draws the
 * same with a single material or with the banded set's two-material array.
 */

const SEGMENTS = 48;

/** Total height, in squares, finial included. */
export const PARLOUR_HEIGHTS: Record<PieceKind, number> = {
  pawn: 0.94,
  rook: 1.08,
  knight: 1.24,
  bishop: 1.4,
  queen: 1.58,
  king: 1.82,
};

/** The tallest piece, for framing: the king's cross. */
export const PARLOUR_HEIGHT = 1.82;

/**
 * Base radius, in squares. As wide as it can go before two neighbours touch
 * and the shadow between them closes up.
 */
const FOOT: Record<PieceKind, number> = {
  pawn: 0.31,
  rook: 0.352,
  knight: 0.352,
  bishop: 0.348,
  queen: 0.376,
  king: 0.396,
};

/** Stem radius, where the turning is narrowest above the base. */
const STEM: Record<PieceKind, number> = {
  pawn: 0.104,
  rook: 0.15,
  knight: 0.15,
  bishop: 0.128,
  queen: 0.146,
  king: 0.152,
};

/**
 * The knight's head is drawn on its own scale, in which it stands 1.198 tall
 * and lands its neck at 0.598. Everything the base has to meet is a multiple
 * of this.
 */
const KNIGHT_SCALE = PARLOUR_HEIGHTS.knight / 1.198;

/**
 * The foot every piece shares the shape of: a vertical rim a quarter of the
 * base's height, a short convex roll over it, a long concave cove sweeping in
 * and up — the line that says "turned" — and a bead the stem stands out of.
 *
 * Heights go with the base's own width rather than the piece's height: a turner
 * uses one pattern and grades the diameters.
 */
function base(radius: number, stem: number): Turn[] {
  const top = radius * 0.62;
  return [
    [0.0, 0.0],
    [radius, 0.0],
    [radius, top * 0.3],
    [radius * 0.986, top * 0.42],
    [radius * 0.93, top * 0.52],
    [radius * 0.822, top * 0.62],
    [radius * 0.688, top * 0.71],
    [radius * 0.56, top * 0.8],
    [radius * 0.47, top * 0.88],
    [Math.max(stem * 1.16, radius * 0.425), top],
    // The bead.
    [stem * 1.34, top + radius * 0.085],
    [stem * 1.3, top + radius * 0.145],
    [stem * 1.08, top + radius * 0.185],
    [stem, top + radius * 0.2],
  ];
}

/**
 * The flared ring under whatever the piece holds up — the one ornament this set
 * has, worn on every piece, which is what makes six shapes read as one set.
 */
function collar(y: number, radius: number, flare = 1.3): Turn[] {
  return [
    [radius * 1.03, y],
    [radius * flare, y + radius * 0.2],
    [radius * flare * 0.96, y + radius * 0.38],
    [radius * 1.02, y + radius * 0.56],
  ];
}

/**
 * A block of wall between two radii, two heights and two angles, closed on all
 * six sides — `Solid.sector` in the app.
 *
 * Not a partial `revolved`, which closes an open sweep with two faces run to
 * the axis: every merlon would drag a pair of blades through the rook's hollow,
 * a pinwheel of fins from overhead.
 */
function sector(
  inner: number,
  outer: number,
  bottom: number,
  top: number,
  start: number,
  sweep: number,
  segments = 8,
): Solid {
  const solid = new Solid();
  const at = (radius: number, y: number, angle: number): Vec3 => [
    radius * Math.cos(angle),
    y,
    radius * Math.sin(angle),
  ];
  for (let step = 0; step < segments; step++) {
    const a = start + (sweep * step) / segments;
    const b = start + (sweep * (step + 1)) / segments;
    solid.quad(at(outer, top, a), at(outer, top, b), at(outer, bottom, b), at(outer, bottom, a));
    solid.quad(at(inner, top, b), at(inner, top, a), at(inner, bottom, a), at(inner, bottom, b));
    solid.quad(at(inner, top, a), at(inner, top, b), at(outer, top, b), at(outer, top, a));
    // The underside, buried in the rim — drawn so the block is closed.
    solid.quad(at(outer, bottom, a), at(outer, bottom, b), at(inner, bottom, b), at(inner, bottom, a));
  }
  // The two square-cut ends, which are what the gaps between merlons are.
  for (const [angle, opening] of [
    [start, true],
    [start + sweep, false],
  ] as const) {
    const c = [at(inner, bottom, angle), at(outer, bottom, angle), at(outer, top, angle), at(inner, top, angle)];
    if (opening) solid.quad(c[3], c[2], c[1], c[0]);
    else solid.quad(c[0], c[1], c[2], c[3]);
  }
  return solid;
}

/**
 * A capped cylinder centred on its own middle, wound outward on every face.
 *
 * Not `solid.ts`'s `cylinder`, whose caps are wound inward, and whose x-axis
 * form swaps two coordinates — a mirror, which turns the whole bar inside out.
 * The app's has the same mirror and gets away with it because an inside-out
 * cylinder lit through its far wall shades very nearly like the near one; here
 * it is simply built the right way round and turned onto its axis.
 */
function cylinder(radius: number, height: number, at: Vec3, segments: number, axis: 'x' | 'y' = 'y'): BufferGeometry {
  const solid = new Solid();
  const half = height / 2;
  for (let step = 0; step < segments; step++) {
    const a = (step / segments) * Math.PI * 2;
    const b = ((step + 1) / segments) * Math.PI * 2;
    const topA: Vec3 = [Math.cos(a) * radius, half, Math.sin(a) * radius];
    const topB: Vec3 = [Math.cos(b) * radius, half, Math.sin(b) * radius];
    const bottomA: Vec3 = [topA[0], -half, topA[2]];
    const bottomB: Vec3 = [topB[0], -half, topB[2]];
    solid.quad(topA, topB, bottomB, bottomA);
    solid.triangle([0, half, 0], topB, topA);
    solid.triangle([0, -half, 0], bottomA, bottomB);
  }
  const geometry = solid.geometry;
  // A rotation, not a swap of coordinates, so the winding survives.
  if (axis === 'x') geometry.rotateZ(-Math.PI / 2);
  return geometry.translate(at[0], at[1], at[2]);
}

function pawn(): BufferGeometry[] {
  const stem = STEM.pawn;
  const body = revolved(
    [
      ...base(FOOT.pawn, stem),
      [0.104, 0.33],
      [0.098, 0.412],
      ...collar(0.424, 0.104, 1.52),
      // A plain stalk under the widest collar in the set. What tells a pawn is
      // the gap between the collar and the ball, and a swelling body fills it.
      [0.098, 0.54],
      [0.098, 0.64],
      [0.096, 0.686],
      [0.0, 0.7],
    ],
    SEGMENTS,
  );
  // The ball emerges from the stalk a little above its foot rather than
  // sitting on top of it, which is what a turner gets.
  body.append(sphere(0.162, [0, 0.778, 0], SEGMENTS, 26));
  return [body.geometry];
}

function rook(): BufferGeometry[] {
  const stem = STEM.rook;
  const body = revolved(
    [
      ...base(FOOT.rook, stem),
      [0.15, 0.36],
      [0.154, 0.48],
      [0.16, 0.556],
      ...collar(0.568, 0.16, 1.26),
      // The tower rises very nearly straight: the overhang comes from the
      // rampart, not from the tower opening out to meet it.
      [0.176, 0.68],
      [0.186, 0.75],
      [0.194, 0.8],
      [0.196, 0.822],
      // The rampart: a thin course oversailing the wall, and no more.
      [0.24, 0.842],
      [0.24, 0.87],
      // In across the walkway and down inside, so the tower is hollow — onto a
      // floor that is dead level, or it is a cone of facets that renders as a
      // bright star inside the rook.
      [0.186, 0.87],
      [0.186, 0.842],
      [0.0, 0.842],
    ],
    SEGMENTS,
  );

  // Six battlements left standing out of the rim — six, so three face the
  // camera from wherever a player sits. Half wall, half gap, and a couple of
  // thousandths proud of the rim on both faces so no two surfaces coincide.
  const merlons = 6;
  const width = ((Math.PI * 2) / merlons) * 0.52;
  for (let i = 0; i < merlons; i++) {
    const centre = (i / merlons) * Math.PI * 2;
    body.append(sector(0.184, 0.242, 0.86, 1.08, centre - width / 2, width));
  }
  return [body.geometry];
}

function bishop(): BufferGeometry[] {
  const stem = STEM.bishop;
  const body = revolved(
    [
      ...base(FOOT.bishop, stem),
      [0.128, 0.345],
      [0.12, 0.44],
      ...collar(0.452, 0.124, 1.36),
      [0.124, 0.556],
      // The mitre, widest a third of the way up and narrower than it wants to
      // be — drawn to the queen's width it is an egg.
      [0.146, 0.616],
      [0.172, 0.694],
      [0.186, 0.772],
      [0.19, 0.836],
      // The groove where the two halves of the hat meet: a V cut in and out.
      [0.18, 0.874],
      [0.174, 0.888],
      [0.182, 0.902],
      // And a long, nearly straight run to the point.
      [0.174, 0.952],
      [0.152, 1.024],
      [0.126, 1.098],
      [0.096, 1.17],
      [0.066, 1.232],
      [0.04, 1.282],
      [0.02, 1.308],
      [0.0, 1.318],
    ],
    SEGMENTS,
  );
  body.append(sphere(0.055, [0, 1.345, 0], SEGMENTS, 20));
  return [body.geometry];
}

function queen(): BufferGeometry[] {
  const stem = STEM.queen;
  const body = revolved(
    [
      ...base(FOOT.queen, stem),
      [0.148, 0.38],
      [0.14, 0.512],
      ...collar(0.524, 0.144, 1.32),
      [0.148, 0.65],
      // The bowl, fullest low down, so the run into the crown is almost
      // straight and does not read as a cone.
      [0.184, 0.74],
      [0.216, 0.848],
      [0.238, 0.958],
      [0.25, 1.068],
      [0.256, 1.166],
      // A groove under the crown's rim, and then out to it.
      [0.226, 1.222],
      [0.254, 1.268],
      [0.258, 1.318],
      [0.258, 1.356],
      // In across the rim, down inside, and across a dead-level floor.
      [0.204, 1.356],
      [0.204, 1.326],
      [0.06, 1.326],
      [0.052, 1.41],
      [0.0, 1.422],
    ],
    SEGMENTS,
  );
  body.append(sphere(0.086, [0, 1.494, 0], 36, 20));

  // The coronet: nine small pyramids filed off the rim, not a ring of balls.
  const parts = [body.geometry];
  const spike: Turn[] = [
    [0.0, 0.0],
    [0.044, 0.0],
    [0.04, 0.024],
    [0.026, 0.06],
    [0.0, 0.082],
  ];
  const points = 9;
  for (let i = 0; i < points; i++) {
    const angle = (i / points) * Math.PI * 2;
    parts.push(revolved(spike, 14).geometry.translate(Math.cos(angle) * 0.226, 1.35, Math.sin(angle) * 0.226));
  }
  return parts;
}

function king(): BufferGeometry[] {
  const stem = STEM.king;
  const body = revolved(
    [
      ...base(FOOT.king, stem),
      [0.154, 0.4],
      [0.146, 0.545],
      ...collar(0.558, 0.15, 1.3),
      [0.154, 0.7],
      [0.186, 0.8],
      [0.22, 0.916],
      [0.244, 1.04],
      [0.258, 1.162],
      [0.264, 1.262],
      // The crown, no wider than the bowl under it — wider is a hat's brim.
      [0.232, 1.318],
      [0.256, 1.362],
      [0.258, 1.408],
      [0.258, 1.444],
      [0.204, 1.444],
      [0.204, 1.412],
      [0.07, 1.412],
      [0.06, 1.468],
      [0.0, 1.48],
    ],
    SEGMENTS,
  );
  // A Staunton cross is short and stands on the crown; tall, it is a mast.
  return [
    body.geometry,
    cylinder(0.052, 0.36, [0, 1.64, 0], 20),
    cylinder(0.044, 0.196, [0, 1.694, 0], 20, 'x'),
  ];
}

/**
 * The knight's base, and the head on it.
 *
 * Everything above the collar is dictated by the head: straight-sided where
 * the neck lands, so the two surfaces cross in one clean circle, and a
 * shoulder written on the head's own scale so the two stay registered.
 */
function knight(): BufferGeometry[] {
  const s = KNIGHT_SCALE;
  const body = revolved(
    [
      ...base(FOOT.knight, STEM.knight),
      [0.158, 0.36],
      [0.166, 0.442],
      ...collar(0.452, 0.164, 1.26),
      [0.2, 0.556],
      [0.2, 0.578],
      // The shoulder, on the head's scale.
      [0.244 * s, 0.586 * s],
      [0.248 * s, 0.602 * s],
      [0.238 * s, 0.622 * s],
      [0.208 * s, 0.646 * s],
      [0.152 * s, 0.668 * s],
      [0.086 * s, 0.68 * s],
      [0.0, 0.684 * s],
    ],
    SEGMENTS,
  );
  // Drawn facing +x and swept through z; a quarter turn stands it across the
  // board, facing the opponent — the banded knight's turn, so the same
  // rotation rule faces both sets the same way.
  const head = knightHead(s);
  head.rotateY(-Math.PI / 2);
  // The mane, in wood rather than brass: carving, cut into the crest.
  const mane = knightMane(s);
  mane.rotateY(-Math.PI / 2);
  return [body.geometry, head, mane];
}

const BUILD: Record<PieceKind, () => BufferGeometry[]> = { pawn, knight, bishop, rook, queen, king };

/** One kind: base at y = 0, in squares, one group. */
export function buildParlourGeometry(kind: PieceKind): BufferGeometry {
  const parts = BUILD[kind]();
  const merged = mergeGeometries(parts, false);
  if (!merged) throw new Error(`parlour set: ${kind} could not be merged`);
  for (const part of parts) part.dispose();
  merged.addGroup(0, merged.getAttribute('position').count, 0);
  return merged;
}

/** All six. */
export function buildParlourGeometries(): Record<PieceKind, BufferGeometry> {
  const out = {} as Record<PieceKind, BufferGeometry>;
  for (const kind of Object.keys(BUILD) as PieceKind[]) out[kind] = buildParlourGeometry(kind);
  return out;
}
