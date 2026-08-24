import {
  BufferGeometry,
  CylinderGeometry,
  ExtrudeGeometry,
  LatheGeometry,
  Path,
  Shape,
  SphereGeometry,
  TorusGeometry,
  Vector2,
} from 'three';
import { mergeGeometries } from 'three/examples/jsm/utils/BufferGeometryUtils.js';

/**
 * Chess pieces, turned rather than modelled.
 *
 * A downloaded glTF set would look better and cost two megabytes and a licence
 * to check. Every piece here is a lathe — the same operation that makes a real
 * Staunton set on a real lathe — plus, for the three pieces a lathe cannot
 * make, a small amount of honest cheating: the knight is an extruded
 * silhouette, the rook's battlements are cut with boxes, the king wears a
 * cross made of two.
 *
 * One square is one unit. Heights follow a real Staunton set's proportions,
 * because a set where the bishop outranks the queen reads as wrong long before
 * anybody works out why.
 */

export type PieceKind = 'pawn' | 'knight' | 'bishop' | 'rook' | 'queen' | 'king';

const SEGMENTS = 48;

/**
 * Merges parts into one geometry.
 *
 * The primitives here disagree about two things `mergeGeometries` will not
 * reconcile on its own: some are indexed and some are not, and they do not all
 * carry the same attributes. Flattening the index and keeping only the three
 * attributes a lit surface needs makes them all mergeable, at the cost of a few
 * thousand duplicated vertices in a scene that has seventeen objects in it.
 */
function merge(parts: readonly BufferGeometry[]): BufferGeometry {
  const flat = parts.map((part) => {
    const plain = part.index ? part.toNonIndexed() : part.clone();
    for (const name of Object.keys(plain.attributes)) {
      if (name !== 'position' && name !== 'normal' && name !== 'uv') {
        plain.deleteAttribute(name);
      }
    }
    plain.clearGroups();
    return plain;
  });

  const merged = mergeGeometries(flat, false);
  if (!merged) throw new Error('chess pieces: geometries could not be merged');
  return merged;
}

/** Same as `turn`, with the segment count first so the call sites read well. */
function turn2(segments: number, points: readonly (readonly [number, number])[]): LatheGeometry {
  return turn(points, segments);
}

/** Turns a `[radius, height]` list into a lathed solid. */
function turn(
  points: readonly (readonly [number, number])[],
  segments: number = SEGMENTS,
): LatheGeometry {
  return new LatheGeometry(
    points.map(([r, y]) => new Vector2(Math.max(r, 0.0001), y)),
    segments,
  );
}

/**
 * The foot every piece stands on: a wide disc that tucks in, then flares out
 * again into the stem. Shared so a set looks like a set.
 */
function foot(scale: number): (readonly [number, number])[] {
  const s = scale;
  return [
    [0.0, 0.0],
    [0.34 * s, 0.0],
    [0.34 * s, 0.035 * s],
    [0.325 * s, 0.075 * s],
    [0.27 * s, 0.1 * s],
    [0.23 * s, 0.13 * s],
    [0.2 * s, 0.19 * s],
    [0.165 * s, 0.28 * s],
  ];
}

function collar(scale: number, y: number, radius: number): (readonly [number, number])[] {
  const s = scale;
  return [
    [radius * s, y * s],
    [(radius + 0.055) * s, (y + 0.03) * s],
    [(radius + 0.045) * s, (y + 0.07) * s],
    [radius * s * 0.92, (y + 0.09) * s],
  ];
}

function pawn(s: number, segments = SEGMENTS): BufferGeometry {
  const body = turn2(segments, [
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
  ]);
  const head = new SphereGeometry(0.155 * s, segments, Math.max(12, segments >> 1));
  head.translate(0, 0.83 * s, 0);
  return merge([body, head]);
}

function rook(s: number, segments = SEGMENTS): BufferGeometry {
  const body = turn2(segments, [
    ...foot(s),
    [0.185 * s, 0.4 * s],
    [0.18 * s, 0.58 * s],
    ...collar(s, 0.6, 0.185),
    [0.2 * s, 0.72 * s],
    [0.235 * s, 0.78 * s],
    [0.245 * s, 0.86 * s],
    [0.245 * s, 1.02 * s],
    [0.19 * s, 1.02 * s],
    [0.19 * s, 0.9 * s],
    [0.0, 0.9 * s],
  ]);

  // Battlements: five notches taken out by five little towers left standing.
  const parts: BufferGeometry[] = [body];
  const merlons = 6;
  for (let i = 0; i < merlons; i++) {
    const angle = (i / merlons) * Math.PI * 2;
    const notch = new CylinderGeometry(0.075 * s, 0.075 * s, 0.2 * s, 10);
    notch.translate(Math.cos(angle) * 0.245 * s, 0.99 * s, Math.sin(angle) * 0.245 * s);
    parts.push(notch);
  }
  // The notches read as gaps because the crown ring sits proud of them.
  const ring = new TorusGeometry(0.235 * s, 0.03 * s, 12, 40);
  ring.rotateX(Math.PI / 2);
  ring.translate(0, 0.86 * s, 0);
  parts.push(ring);

  return merge(parts);
}

function bishop(s: number, segments = SEGMENTS): BufferGeometry {
  const body = turn2(segments, [
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
  ]);
  const finial = new SphereGeometry(0.06 * s, segments, Math.max(10, segments >> 1));
  finial.translate(0, 1.26 * s, 0);
  return merge([body, finial]);
}

function queen(s: number, segments = SEGMENTS): BufferGeometry {
  const body = turn2(segments, [
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
  ]);

  const parts: BufferGeometry[] = [body];
  const points = 9;
  for (let i = 0; i < points; i++) {
    const angle = (i / points) * Math.PI * 2;
    const bead = new SphereGeometry(0.048 * s, Math.min(32, segments), 12);
    bead.translate(Math.cos(angle) * 0.215 * s, 1.34 * s, Math.sin(angle) * 0.215 * s);
    parts.push(bead);
  }
  const crown = new SphereGeometry(0.075 * s, Math.min(48, segments), 16);
  crown.translate(0, 1.36 * s, 0);
  parts.push(crown);

  return merge(parts);
}

function king(s: number, segments = SEGMENTS): BufferGeometry {
  const body = turn2(segments, [
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
  ]);

  const upright = new CylinderGeometry(0.042 * s, 0.05 * s, 0.28 * s, 12);
  upright.translate(0, 1.54 * s, 0);
  const bar = new CylinderGeometry(0.036 * s, 0.036 * s, 0.19 * s, 12);
  bar.rotateZ(Math.PI / 2);
  bar.translate(0, 1.58 * s, 0);
  const cap = new SphereGeometry(0.05 * s, Math.min(32, segments), 12);
  cap.translate(0, 1.68 * s, 0);

  return merge([body, upright, bar, cap]);
}

/**
 * The knight, which is the one piece a lathe cannot turn.
 *
 * A silhouette, extruded and bevelled — the way a set is actually stamped when
 * it is not carved. Three things separate a horse from a rabbit, and all three
 * are easy to get wrong: the ears are **short** triangles set back over the
 * poll rather than long blades; the muzzle is **long** and travels forward
 * *and down*, so the nose finishes well below the top of the skull; and the
 * neck arches backwards instead of rising straight. The serrated edge down the
 * back is the mane, and it does more for the read than any amount of detail
 * on the face.
 *
 * The profile below is traced anticlockwise from the base of the neck: up the
 * crest, over the poll, out along the ears, down the forehead and the bridge
 * of the nose, round the muzzle, back under the jaw, and down the throat.
 */
function knight(s: number, segments = SEGMENTS): BufferGeometry {
  const base = turn2(segments, [
    ...foot(s),
    [0.175 * s, 0.36 * s],
    [0.165 * s, 0.44 * s],
    ...collar(s, 0.44, 0.165),
    [0.16 * s, 0.56 * s],
    [0.0, 0.56 * s],
  ]);

  const shape = new Shape();
  const p = (x: number, y: number): [number, number] => [x * s, y * s];

  shape.moveTo(...p(-0.185, 0.5));

  // The crest of the neck, arching back before it rises.
  shape.bezierCurveTo(...p(-0.275, 0.63), ...p(-0.285, 0.8), ...p(-0.245, 0.925));

  // The mane: seven shallow scallops up the back of the neck. Shallow is the
  // whole trick — deep ones read as spikes, and they must stop short of the
  // poll so they do not merge with the ears into a crown.
  shape.lineTo(...p(-0.208, 0.945));
  shape.lineTo(...p(-0.232, 0.966));
  shape.lineTo(...p(-0.196, 0.982));
  shape.lineTo(...p(-0.22, 1.003));
  shape.lineTo(...p(-0.184, 1.019));
  shape.lineTo(...p(-0.208, 1.04));
  shape.lineTo(...p(-0.17, 1.056));
  shape.bezierCurveTo(...p(-0.15, 1.075), ...p(-0.115, 1.092), ...p(-0.078, 1.098));

  // Ears: two short nubs with one notch between them. Anything taller than
  // this is a rabbit, and anything without the notch is a horn.
  shape.lineTo(...p(-0.088, 1.158));
  shape.lineTo(...p(-0.03, 1.104));
  shape.lineTo(...p(0.014, 1.156));
  shape.lineTo(...p(0.046, 1.092));

  // Forehead, then the face falling forward and down.
  shape.bezierCurveTo(...p(0.096, 1.07), ...p(0.138, 1.028), ...p(0.162, 0.972));
  shape.bezierCurveTo(...p(0.198, 0.906), ...p(0.238, 0.858), ...p(0.272, 0.828));

  // The muzzle, cut off square and short. A long tapering one makes a fox.
  shape.lineTo(...p(0.298, 0.812));
  shape.lineTo(...p(0.302, 0.772));
  shape.lineTo(...p(0.268, 0.76));
  shape.lineTo(...p(0.276, 0.734));
  shape.lineTo(...p(0.226, 0.722));

  // The cheek: a heavy round mass hanging below and behind the mouth, and the
  // throat notch tucked in behind it. This is the piece of anatomy that stops
  // a horse's head looking like a greyhound's.
  shape.bezierCurveTo(...p(0.17, 0.688), ...p(0.09, 0.672), ...p(0.036, 0.712));
  shape.bezierCurveTo(...p(-0.008, 0.746), ...p(-0.028, 0.79), ...p(-0.02, 0.822));

  // And down the throat into the chest.
  shape.bezierCurveTo(...p(0.008, 0.76), ...p(0.04, 0.64), ...p(0.098, 0.52));

  shape.closePath();

  // The eye, cut clean through — it catches the key light and does more for
  // the read than another thousand triangles would.
  const eye = new Path();
  eye.absarc(0.055 * s, 0.985 * s, 0.024 * s, 0, Math.PI * 2, true);
  shape.holes.push(eye);

  const head = new ExtrudeGeometry(shape, {
    depth: 0.27 * s,
    bevelEnabled: true,
    bevelThickness: 0.03 * s,
    bevelSize: 0.03 * s,
    bevelSegments: 4,
    curveSegments: 24,
  });
  head.translate(0, 0, -0.135 * s);
  head.rotateY(-Math.PI / 2);

  return merge([base, head]);
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
  const geometry = BUILD[kind](HEIGHT[kind], segments);
  geometry.computeVertexNormals();
  return geometry;
}

/** All six, in one go. Convenient, and blocking — prefer the staged form. */
export function buildPieceGeometries(): Record<PieceKind, BufferGeometry> {
  const out = {} as Record<PieceKind, BufferGeometry>;
  for (const kind of PIECE_KINDS) out[kind] = buildPieceGeometry(kind);
  return out;
}
