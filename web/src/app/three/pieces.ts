import { BufferGeometry } from 'three';
import { mergeGeometries } from 'three/examples/jsm/utils/BufferGeometryUtils.js';

import { knightHead, knightMane } from './knight';
import { Solid, type Turn, cylinder, revolved, ring, sphere } from './solid';

/**
 * Chess pieces, turned rather than modelled — except the one that cannot be.
 *
 * Every piece here is a lathe, the same operation that makes a real Staunton
 * set on a real lathe, plus the three things a lathe cannot make: the rook's
 * battlements are cut out of a wall by sweeping part of a circle, the king
 * wears a cross of two cylinders, and the knight has a head of its own — see
 * `knight.ts`.
 *
 * The numbers are the app's. Both were fitted against the same photographed
 * set, and a set that is one shape on a phone and another on the website is
 * two products wearing one name.
 *
 * One square is one unit. Heights follow a real Staunton set's proportions,
 * because a set where the bishop outranks the queen reads as wrong long before
 * anybody works out why.
 *
 * This is the app's *banded* set, which is what the app ships by default: the
 * same turning, given gilt collars and gilt finials. So a piece is two things —
 * a body of boxwood or ebony, and the brass on it — and `buildPieceGeometry`
 * hands back one geometry in two groups, body first, so a single mesh can wear
 * both materials.
 */

export type PieceKind = 'pawn' | 'knight' | 'bishop' | 'rook' | 'queen' | 'king';

/** A band, as the height it sits at, its radius, and the thickness of the ring. */
type Turn3 = readonly [number, number, number];

const SEGMENTS = 48;

/**
 * Merges parts into one geometry.
 *
 * Everything here comes from `Solid`, which produces plain non-indexed
 * position-and-normal geometry, so there is nothing left to reconcile — but the
 * guard stays, because a merge that returns null is a piece that silently does
 * not draw.
 */
function merge(parts: readonly BufferGeometry[]): BufferGeometry {
  const merged = mergeGeometries([...parts], false);
  if (!merged) throw new Error('chess pieces: geometries could not be merged');
  return merged;
}

/**
 * The foot every piece stands on: a wide disc that tucks in, then flares out
 * again into the stem. Shared, so a set looks like a set.
 */
function foot(s: number): Turn[] {
  return [
    [0.0, 0.0],
    [0.305 * s, 0.0],
    [0.305 * s, 0.035 * s],
    [0.292 * s, 0.075 * s],
    [0.243 * s, 0.1 * s],
    [0.207 * s, 0.13 * s],
    [0.18 * s, 0.19 * s],
    [0.148 * s, 0.28 * s],
  ];
}

function collar(s: number, y: number, radius: number): Turn[] {
  return [
    [radius * s, y * s],
    [(radius + 0.055) * s, (y + 0.03) * s],
    [(radius + 0.045) * s, (y + 0.07) * s],
    [radius * s * 0.92, (y + 0.09) * s],
  ];
}

function pawn(s: number, segments = SEGMENTS): BufferGeometry {
  const solid = revolved(
    [
      ...foot(s),
      [0.135 * s, 0.36 * s],
      [0.12 * s, 0.44 * s],
      ...collar(s, 0.46, 0.12),
      [0.1 * s, 0.58 * s],
      [0.13 * s, 0.63 * s],
      [0.155 * s, 0.7 * s],
      [0.15 * s, 0.78 * s],
      [0.1 * s, 0.83 * s],
      [0.0, 0.85 * s],
    ],
    segments,
  );
  solid.append(sphere(0.155 * s, [0, 0.83 * s, 0], segments, 24));
  return solid.geometry;
}

function rook(s: number, segments = SEGMENTS): BufferGeometry {
  const solid = revolved(
    [
      ...foot(s),
      [0.185 * s, 0.4 * s],
      [0.18 * s, 0.58 * s],
      ...collar(s, 0.6, 0.185),
      [0.2 * s, 0.72 * s],
      [0.235 * s, 0.78 * s],
      [0.245 * s, 0.86 * s],
      [0.245 * s, 0.9 * s],
      [0.185 * s, 0.9 * s],
      [0.185 * s, 0.86 * s],
      [0.0, 0.86 * s],
    ],
    segments,
  );

  // Battlements cut rather than stacked.
  //
  // Five towers left standing out of a wall, each one a piece of the same
  // turning swept through part of a circle instead of all of it — so the gaps
  // between them are square-cut and go all the way down to the rampart. Little
  // cylinders stood on the rim, which is the cheap way, read as pegs.
  const merlons = 5;
  const wall: Turn[] = [
    [0.185 * s, 0.9 * s],
    [0.245 * s, 0.9 * s],
    [0.245 * s, 1.02 * s],
    [0.185 * s, 1.02 * s],
  ];
  for (let i = 0; i < merlons; i++) {
    const centre = (i / merlons) * Math.PI * 2;
    const width = ((Math.PI * 2) / merlons) * 0.56;
    solid.append(revolved(wall, 8, centre - width / 2, width));
  }
  return solid.geometry;
}

function bishop(s: number, segments = SEGMENTS): BufferGeometry {
  const solid = revolved(
    [
      ...foot(s),
      [0.145 * s, 0.4 * s],
      [0.125 * s, 0.5 * s],
      ...collar(s, 0.52, 0.125),
      [0.115 * s, 0.64 * s],
      [0.175 * s, 0.72 * s],
      [0.2 * s, 0.84 * s],
      [0.185 * s, 0.98 * s],
      [0.13 * s, 1.08 * s],
      [0.075 * s, 1.13 * s],
      [0.09 * s, 1.16 * s],
      [0.055 * s, 1.2 * s],
      [0.0, 1.22 * s],
    ],
    segments,
  );
  solid.append(sphere(0.06 * s, [0, 1.26 * s, 0], segments, 20));
  return solid.geometry;
}

function queen(s: number, segments = SEGMENTS): BufferGeometry {
  const solid = revolved(
    [
      ...foot(s),
      [0.17 * s, 0.42 * s],
      [0.145 * s, 0.56 * s],
      ...collar(s, 0.58, 0.145),
      [0.13 * s, 0.72 * s],
      [0.185 * s, 0.86 * s],
      [0.225 * s, 1.02 * s],
      [0.235 * s, 1.14 * s],
      [0.2 * s, 1.2 * s],
      [0.235 * s, 1.24 * s],
      [0.235 * s, 1.3 * s],
      [0.12 * s, 1.3 * s],
      [0.0, 1.28 * s],
    ],
    segments,
  );

  return solid.geometry;
}

function king(s: number, segments = SEGMENTS): BufferGeometry {
  const solid = revolved(
    [
      ...foot(s),
      [0.175 * s, 0.44 * s],
      [0.15 * s, 0.6 * s],
      ...collar(s, 0.62, 0.15),
      [0.135 * s, 0.76 * s],
      [0.19 * s, 0.9 * s],
      [0.23 * s, 1.08 * s],
      [0.24 * s, 1.22 * s],
      [0.205 * s, 1.28 * s],
      [0.24 * s, 1.32 * s],
      [0.235 * s, 1.4 * s],
      [0.13 * s, 1.42 * s],
      [0.0, 1.4 * s],
    ],
    segments,
  );

  return solid.geometry;
}

/**
 * The knight: a turned base with a modelled head standing on it.
 *
 * The base's top is wider than the other pieces' because it carries a neck
 * rather than a stem — the head is at its broadest where it lands, and on a
 * narrower collar the neck hangs over the edge and shows its flat underside
 * from every angle but straight on.
 */
function knight(s: number, segments = SEGMENTS): BufferGeometry {
  const base = revolved(
    [
      ...foot(s),
      [0.175 * s, 0.36 * s],
      [0.165 * s, 0.44 * s],
      ...collar(s, 0.44, 0.165),
      // The lathe only ever climbs: a profile that steps back down is revolved
      // inside out and shows as a ring of torn white triangles round the base.
      //
      // Straight-sided where the brass would sit, not sloping — a torus laid
      // across a cone meets it at a shallow angle and the two interpenetrate.
      [0.193 * s, 0.534 * s],
      [0.193 * s, 0.574 * s],
      // Then out into the shoulder the neck rises from. Wide enough to take the
      // neck's corners and no wider, or it reads as a brim the head is stood on.
      // The corner that matters is the neck's *section*, where its front meets a
      // face at full depth, and that stands further out than the silhouette.
      [0.244 * s, 0.586 * s],
      [0.248 * s, 0.602 * s],
      // Carried up rather than turned over quickly, so the neck is well inside
      // the shoulder before the two surfaces meet.
      [0.238 * s, 0.622 * s],
      [0.208 * s, 0.646 * s],
      [0.152 * s, 0.668 * s],
      [0.086 * s, 0.68 * s],
      [0.0, 0.684 * s],
    ],
    segments,
  );

  const head = knightHead(s);
  // The silhouette is drawn facing along +x and swept through z; a quarter turn
  // stands it across the board, facing the opponent.
  head.rotateY(-Math.PI / 2);
  return merge([base.geometry, head]);
}

/**
 * The gilded step the piece stands on.
 *
 * On the photographed set this is not a ring laid against the base — it is the
 * bottom of the base itself, turned in gold, and it is the widest piece of
 * brass on the piece. A torus in its place either hides inside the wood or
 * stands off it like a bracelet.
 */
function gildedFoot(s: number, segments = SEGMENTS): Solid {
  // A hair proud of the wood it sheathes. Turned to exactly the same profile
  // the two surfaces are coincident, and coincident surfaces fight for the same
  // pixels — the gold flickers, or loses.
  const out = 1.03;
  return revolved(
    [
      [0.0, -0.002 * s],
      [0.305 * s * out, -0.002 * s],
      [0.305 * s * out, 0.035 * s],
      [0.292 * s * out, 0.078 * s],
      [0.276 * s, 0.092 * s],
      [0.276 * s, 0.086 * s],
    ],
    segments,
  );
}

/** Where the bands sit: at the waist of the base, and on each collar. */
function bands(kind: PieceKind, s: number): Turn3[] {
  const waist: Turn3[] = [[0.132 * s, 0.208 * s, 0.019 * s]];
  const collars: Record<PieceKind, Turn3[]> = {
    pawn: [
      [0.5 * s, 0.152 * s, 0.019 * s],
      [0.772 * s, 0.158 * s, 0.017 * s],
    ],
    rook: [
      [0.645 * s, 0.218 * s, 0.022 * s],
      [0.79 * s, 0.238 * s, 0.02 * s],
    ],
    bishop: [
      [0.565 * s, 0.158 * s, 0.02 * s],
      [0.715 * s, 0.181 * s, 0.019 * s],
    ],
    knight: [[0.552 * s, 0.193 * s, 0.014 * s]],
    queen: [
      [0.625 * s, 0.178 * s, 0.022 * s],
      [1.285 * s, 0.238 * s, 0.021 * s],
    ],
    king: [
      [0.665 * s, 0.183 * s, 0.022 * s],
      [1.31 * s, 0.243 * s, 0.022 * s],
      [1.395 * s, 0.222 * s, 0.019 * s],
    ],
  };
  return [...waist, ...collars[kind]];
}

/**
 * The gilt on top: the finial the turning already ends in, in brass rather
 * than in the body's own material.
 */
function finial(kind: PieceKind, s: number): Solid | null {
  switch (kind) {
    case 'pawn':
    case 'knight':
      return null;

    case 'bishop':
      return sphere(0.062 * s, [0, 1.26 * s, 0], 32, 20);

    case 'rook':
      return ring(0.237 * s, 0.032 * s, [0, 0.86 * s, 0]);

    case 'queen': {
      const crown = sphere(0.077 * s, [0, 1.36 * s, 0], 32, 16);
      const points = 9;
      for (let i = 0; i < points; i++) {
        const angle = (i / points) * Math.PI * 2;
        crown.append(
          sphere(
            0.05 * s,
            [Math.cos(angle) * 0.215 * s, 1.34 * s, Math.sin(angle) * 0.215 * s],
            20,
            12,
          ),
        );
      }
      return crown;
    }

    case 'king': {
      // A Staunton cross is short and stands on the crown. Drawn tall it reads
      // as a mast, and the piece stops being a king.
      const cross = cylinder(0.052 * s, 0.2 * s, [0, 1.5 * s, 0]);
      cross.append(cylinder(0.044 * s, 0.17 * s, [0, 1.52 * s, 0], 12, 'x'));
      return cross;
    }
  }
}

/** Everything on a piece that is brass rather than wood. */
function trim(kind: PieceKind, s: number, segments = SEGMENTS): BufferGeometry {
  const solid = gildedFoot(s, segments);
  for (const [y, radius, tube] of bands(kind, s)) {
    solid.append(ring(radius, tube, [0, y, 0]));
  }
  const top = finial(kind, s);
  if (top) solid.append(top);
  if (kind === 'knight') {
    const mane = knightMane(s);
    mane.rotateY(-Math.PI / 2);
    return merge([solid.geometry, mane]);
  }
  return solid.geometry;
}

const HEIGHT: Record<PieceKind, number> = {
  pawn: 0.62,
  knight: 0.72,
  bishop: 0.74,
  rook: 0.66,
  queen: 0.82,
  king: 0.9,
};

const BUILD: Record<PieceKind, (s: number, segments?: number) => BufferGeometry> = {
  pawn,
  knight,
  bishop,
  rook,
  queen,
  king,
};

export const PIECE_KINDS = Object.keys(BUILD) as PieceKind[];

/**
 * Builds the geometry for one kind.
 *
 * One at a time rather than all six together, because turning a lathe and
 * merging the parts is a few tens of milliseconds each — long enough that
 * doing all six in a row is one task the browser cannot interrupt, and short
 * enough that doing them separately is not.
 */
export function buildPieceGeometry(kind: PieceKind, segments = SEGMENTS): BufferGeometry {
  const s = HEIGHT[kind];
  // Merged *with* groups: one geometry, two draw ranges, so a piece is still a
  // single mesh with a single transform and the brass is simply the second
  // material on it. Two meshes per piece would have to be moved, lifted, taken
  // and put back in step with each other, thirty-two times over.
  //
  // Given one material instead of two the groups both draw with it, which is
  // what the icon page wants — a pawn in solid brass.
  const merged = mergeGeometries([BUILD[kind](s, segments), trim(kind, s, segments)], true);
  if (!merged) throw new Error(`chess pieces: ${kind} could not be merged`);
  return merged;
}

/** All six, in one go. Convenient, and blocking — prefer the staged form. */
export function buildPieceGeometries(): Record<PieceKind, BufferGeometry> {
  const out = {} as Record<PieceKind, BufferGeometry>;
  for (const kind of PIECE_KINDS) out[kind] = buildPieceGeometry(kind);
  return out;
}
