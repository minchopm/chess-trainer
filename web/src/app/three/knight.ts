import { BufferGeometry } from 'three';

import { Solid, type Vec3, cross, normalise, subtract } from './solid';

/**
 * The knight — the one piece a lathe cannot turn, and so the one piece with a
 * front, a back and a shape of its own.
 *
 * It was an extruded silhouette here for a long time: the outline cut out and
 * given an even depth, the way a set is stamped when it is not carved. From the
 * side that reads; from anywhere else it does not. A real knight narrows as it
 * rises — the neck is thick where it meets the collar and the head is barely
 * half that — and a slab of even depth has none of it. Turn one a few degrees
 * and it goes flat.
 *
 * So the outline carries a **depth at every anchor**, not one depth for the
 * piece: full at the base of the neck, thinner through the crest, thinner still
 * at the muzzle. Ported from the app's `Knight.swift`, where it was fitted
 * against a reference from every angle rather than from the side alone.
 */

/** Where the outline goes, whether it turns a corner there, and how deep it is. */
type Anchor = readonly [x: number, y: number, corner: boolean, depth: number];

/** A point on the swept outline. */
type Point = { x: number; y: number; depth: number };

/**
 * The head, as measured anchors, traced anticlockwise from the base of the neck.
 *
 * Three readings of a knight's head look obvious and are wrong. The **ears** are
 * not two tall triangles: what stands above the forehead is mostly the mane, cut
 * off square, with one small ear showing behind it. The **muzzle** does not
 * taper — its front runs all but straight down before it turns under, and a
 * taper there makes a fox. The **neck** is broad, arching back at half height,
 * rather than rising as a stalk.
 */
const ANCHORS: readonly Anchor[] = [
  // Up the crest of the neck, from the collar. The neck is cut off at 0.598,
  // not lower: below that the turning draws in to its collar, and a neck this
  // broad meets it corner-first — the corners came through the side of the base
  // as a ring of torn white triangles. What is cut away is buried anyway.
  [-0.182, 0.598, true, 0.086],
  [-0.189, 0.608, false, 0.094],
  [-0.189, 0.614, false, 0.094],
  [-0.189, 0.668, false, 0.082],
  [-0.196, 0.712, false, 0.078],
  [-0.207, 0.764, false, 0.075],
  [-0.218, 0.818, false, 0.073],
  [-0.225, 0.874, false, 0.073], // the crest at its fullest
  [-0.224, 0.91, false, 0.074],
  [-0.222, 0.946, false, 0.076],
  [-0.207, 1.001, false, 0.079],
  [-0.194, 1.027, false, 0.081],
  [-0.163, 1.068, false, 0.083],
  [-0.136, 1.094, false, 0.082],
  [-0.111, 1.111, false, 0.08],
  // Over the poll, where the mane is cut off square. The ears are not drawn
  // into this outline: in profile they are a bump a hundredth of a unit high,
  // a quarter of what the rolled edge takes, so cut in here they come out as
  // shards. They are turned separately and stood on the poll, splayed.
  [-0.088, 1.13, false, 0.07],
  [-0.046, 1.143, true, 0.058],
  [0.006, 1.152, true, 0.058],
  [0.058, 1.161, true, 0.056],
  // Down the face, which falls forward faster than it looks as if it should.
  [0.062, 1.104, false, 0.074],
  [0.094, 1.072, false, 0.084],
  [0.135, 1.038, false, 0.086],
  [0.179, 1.003, false, 0.082],
  [0.22, 0.975, false, 0.076],
  [0.261, 0.948, false, 0.068],
  // The muzzle: blunt, and the thinnest of the head. It sits at the same height
  // as the neck behind it and is cut half as deep, which is the whole reason
  // the depth follows the outline rather than the height.
  [0.273, 0.936, false, 0.063],
  [0.279, 0.923, false, 0.059],
  [0.28, 0.895, false, 0.056],
  [0.27, 0.874, false, 0.057],
  [0.244, 0.851, true, 0.058],
  // Back up the underside of the jaw. The mouth is a V cut up into the head at
  // some forty degrees, not the flat slot it was — it is most of what tells a
  // horse's head from a boot.
  [0.204, 0.854, false, 0.062],
  [0.155, 0.872, false, 0.066],
  [0.113, 0.89, false, 0.069],
  [0.076, 0.9, true, 0.072],
  // And down the throat, pinched in tight behind the jaw before the chest.
  [0.055, 0.893, false, 0.075],
  [0.03, 0.865, true, 0.078],
  [0.052, 0.828, false, 0.078],
  [0.088, 0.786, false, 0.078],
  [0.14, 0.735, false, 0.079],
  [0.173, 0.688, false, 0.081],
  [0.192, 0.653, false, 0.084],
  [0.205, 0.614, false, 0.09],
  [0.208, 0.608, false, 0.094],
  [0.196, 0.598, true, 0.086],
];

const spline = (p0: number, p1: number, p2: number, p3: number, t: number): number => {
  const t2 = t * t;
  const t3 = t2 * t;
  return (
    0.5 *
    (2 * p1 +
      (p2 - p0) * t +
      (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 +
      (-p0 + 3 * p1 - 3 * p2 + p3) * t3)
  );
};

/**
 * A closed curve through every anchor, breaking at the corners, carrying the
 * depth along with the position.
 *
 * Fitted to the anchors rather than steered by handles, because the anchors are
 * measurements: with beziers, moving one point of the outline meant moving four
 * numbers.
 */
function through(anchors: readonly Anchor[], steps = 5): Point[] {
  const points: Point[] = [];
  const n = anchors.length;

  for (let i = 0; i < n; i++) {
    const b = anchors[i];
    const c = anchors[(i + 1) % n];
    const a = anchors[(i - 1 + n) % n];
    const d = anchors[(i + 2) % n];
    points.push({ x: b[0], y: b[1], depth: b[3] });

    if (b[2] || c[2]) {
      // Straight into and out of every corner, and sampled all the way. A
      // corner is a cut, and a curve run up to one swings past it: the closing
      // run is the width of the piece long, and a curve leaving it dipped below
      // the foot, which came out as a fin hanging through the collar. Sampled,
      // because left as one long edge it is the only edge on the piece a
      // hundred times the length of its neighbours, and the cap over it tears.
      const span = Math.hypot(c[0] - b[0], c[1] - b[1]);
      const cuts = Math.max(1, Math.floor(span / 0.008));
      for (let cut = 1; cut < Math.max(2, cuts); cut++) {
        const t = cut / cuts;
        points.push({
          x: b[0] + (c[0] - b[0]) * t,
          y: b[1] + (c[1] - b[1]) * t,
          depth: b[3] + (c[3] - b[3]) * t,
        });
      }
      continue;
    }

    for (let step = 1; step < steps; step++) {
      const t = step / steps;
      points.push({
        x: spline(a[0], b[0], c[0], d[0], t),
        y: spline(a[1], b[1], c[1], d[1], t),
        depth: Math.max(0.02, spline(a[3], b[3], c[3], d[3], t)),
      });
    }
  }
  return counterclockwise(points);
}

/** The outline in a known direction, so a normal turned off it points outward. */
function counterclockwise(points: Point[]): Point[] {
  return signedArea(points) < 0 ? [...points].reverse() : points;
}

function signedArea(ring: readonly Point[]): number {
  let total = 0;
  for (let i = 0; i < ring.length; i++) {
    const a = ring[i];
    const b = ring[(i + 1) % ring.length];
    total += a.x * b.y - b.x * a.y;
  }
  return total / 2;
}

/**
 * Triangulates a closed outline by clipping ears off it.
 *
 * Needed because the outline is *concave* — the throat is notched in behind the
 * jaw, and there is a nick between the ear and the mane. Handed to anything that
 * assumes convexity, both get filled straight across and the head comes out with
 * a web of ivory hanging under its jaw.
 */
function earClip(points: readonly { x: number; y: number }[]): [number, number, number][] {
  if (points.length < 3) return [];
  if (points.length === 3) return [[0, 1, 2]];

  let area = 0;
  for (let i = 0; i < points.length; i++) {
    const a = points[i];
    const b = points[(i + 1) % points.length];
    area += a.x * b.y - b.x * a.y;
  }
  const remaining = points.map((_, i) => i);
  if (area < 0) remaining.reverse();

  const turnAt = (a: number, b: number, c: number): number =>
    (points[b].x - points[a].x) * (points[c].y - points[a].y) -
    (points[b].y - points[a].y) * (points[c].x - points[a].x);

  const triangles: [number, number, number][] = [];

  while (remaining.length > 3) {
    let clipped = false;
    let best = { turn: -Infinity, at: 0 };

    for (let k = 0; k < remaining.length; k++) {
      const i0 = remaining[(k - 1 + remaining.length) % remaining.length];
      const i1 = remaining[k];
      const i2 = remaining[(k + 1) % remaining.length];
      const turn = turnAt(i0, i1, i2);
      if (turn > best.turn) best = { turn, at: k };
      if (turn <= 0) continue; // a reflex corner is no ear

      // An ear may not have any other corner of the outline inside it.
      let swallows = false;
      for (const j of remaining) {
        if (j === i0 || j === i1 || j === i2) continue;
        if (turnAt(i0, i1, j) >= 0 && turnAt(i1, i2, j) >= 0 && turnAt(i2, i0, j) >= 0) {
          swallows = true;
          break;
        }
      }
      if (swallows) continue;

      triangles.push([i0, i1, i2]);
      remaining.splice(k, 1);
      clipped = true;
      break;
    }

    // Nothing clean left: take the best corner anyway rather than stop.
    //
    // Stopping is what a straight reading of the algorithm does, and it hands
    // back part of a face. Part of a face is a hole — and the rings this is
    // asked to cut are exactly the awkward cases: nearly straight runs where
    // every corner turns by almost nothing, and rings drawn in far enough to
    // have crossed themselves. A few triangles overlapping inside the piece
    // cost nothing; a hole in the neck one can see through costs the piece.
    //
    // This was the bug on the way in: stopping left the cap 53 triangles short
    // of the 252 the outline needs, and the head came out as a torn shell.
    if (!clipped) {
      const k = best.at;
      const i0 = remaining[(k - 1 + remaining.length) % remaining.length];
      const i1 = remaining[k];
      const i2 = remaining[(k + 1) % remaining.length];
      triangles.push([i0, i1, i2]);
      remaining.splice(k, 1);
    }
  }

  if (remaining.length === 3) triangles.push([remaining[0], remaining[1], remaining[2]]);
  return triangles;
}

export const KNIGHT_OUTLINE: Point[] = through(ANCHORS);

/** One inward step of a ring, smoothed, with any fold put back where it was. */
function drawIn(ring: readonly Point[], step: number): Point[] {
  const n = ring.length;
  const moved: Point[] = [];
  for (let i = 0; i < n; i++) {
    const before = ring[(i - 1 + n) % n];
    const after = ring[(i + 1) % n];
    const tx = after.x - before.x;
    const ty = after.y - before.y;
    const length = Math.max(1e-6, Math.hypot(tx, ty));
    moved.push({
      x: ring[i].x + (ty / length) * -step,
      y: ring[i].y - (tx / length) * -step,
      depth: ring[i].depth,
    });
  }

  let smoothed = moved;
  for (let pass = 0; pass < 2; pass++) {
    const next = smoothed.map((point, i) => {
      const before = smoothed[(i - 1 + n) % n];
      const after = smoothed[(i + 1) % n];
      return {
        x: point.x * 0.5 + (before.x + after.x) * 0.25,
        y: point.y * 0.5 + (before.y + after.y) * 0.25,
        depth: point.depth * 0.5 + (before.depth + after.depth) * 0.25,
      };
    });
    smoothed = next;
  }

  // Anywhere the step has turned an edge back on itself, put both its ends
  // back. The area of the whole ring cannot see this: a narrow part folds
  // through itself long before the ring as a whole has lost much size, and the
  // folded part is then skinned inside out — a torn hole one can see into the
  // piece through.
  let held = smoothed;
  for (let pass = 0; pass < 2; pass++) {
    const next = [...held];
    for (let i = 0; i < n; i++) {
      const j = (i + 1) % n;
      const wasX = ring[j].x - ring[i].x;
      const wasY = ring[j].y - ring[i].y;
      const nowX = held[j].x - held[i].x;
      const nowY = held[j].y - held[i].y;
      if (wasX * nowX + wasY * nowY <= 0) {
        next[i] = ring[i];
        next[j] = ring[j];
      }
    }
    held = next;
  }
  return held;
}

/**
 * The relief laid over the swept shape: the parts of a head that are not in its
 * outline at all.
 */
function modelling(x: number, y: number): number {
  /** Full at the middle, nothing at the edge, and flat where it meets the
      surface either side so it leaves no seam. */
  const patch = (cx: number, cy: number, spread: number): number => {
    const away = Math.hypot(x - cx, y - cy) / spread;
    if (away >= 1) return 0;
    const t = 1 - away;
    return t * t * (3 - 2 * t);
  };

  let relief = 0;
  relief += patch(0.03, 0.925, 0.13) * 0.03; // the cheek, the fullest part of the head
  relief += patch(0.145, 0.985, 0.055) * 0.014; // the bone running down from the eye
  relief -= patch(0.1, 1.055, 0.05) * 0.01; // the dish above it
  relief -= patch(0.048, 1.048, 0.042) * 0.024; // the socket
  relief += patch(0.052, 1.042, 0.019) * 0.011; // and the eye sitting in it
  relief -= patch(0.235, 0.945, 0.055) * 0.012; // the flat down the nose
  relief += patch(-0.09, 0.7, 0.1) * 0.01; // the shoulder of the neck
  return relief;
}

/**
 * Stitches a stack of rings into a surface, closing both ends with `cap`.
 *
 * Normals are taken along the ring first and then across to the next one. The
 * other way round gives the same plane with the sign flipped, and a surface lit
 * from inside itself looks hollow rather than wrong.
 */
function skin(rings: readonly Vec3[][], cap: readonly [number, number, number][]): Solid {
  const solid = new Solid();
  if (rings.length < 2) return solid;
  const count = rings[0].length;

  const normals = rings.map((ring, k) =>
    ring.map((_, i) => {
      const along = subtract(ring[(i + 1) % count], ring[(i - 1 + count) % count]);
      const across = subtract(
        rings[Math.min(k + 1, rings.length - 1)][i],
        rings[Math.max(k - 1, 0)][i],
      );
      const normal = cross(along, across);
      const length = Math.hypot(...normal);
      // Where a ring has drawn itself down to nothing its neighbours sit on top
      // of each other and there is no plane to take.
      return length > 1e-9 ? (normalise(normal) as Vec3) : ([0, 0, 1] as Vec3);
    }),
  );

  for (let k = 0; k < rings.length - 1; k++) {
    for (let i = 0; i < count; i++) {
      const j = (i + 1) % count;
      solid.smooth(
        rings[k][i],
        rings[k][j],
        rings[k + 1][j],
        normals[k][i],
        normals[k][j],
        normals[k + 1][j],
      );
      solid.smooth(
        rings[k][i],
        rings[k + 1][j],
        rings[k + 1][i],
        normals[k][i],
        normals[k + 1][j],
        normals[k + 1][i],
      );
    }
  }

  const first = 0;
  const last = rings.length - 1;
  for (const [a, b, c] of cap) {
    solid.smooth(
      rings[last][a],
      rings[last][b],
      rings[last][c],
      normals[last][a],
      normals[last][b],
      normals[last][c],
    );
    solid.smooth(
      rings[first][c],
      rings[first][b],
      rings[first][a],
      normals[first][c],
      normals[first][b],
      normals[first][a],
    );
  }
  return solid;
}

/**
 * The head: the outline swept with its own depth, rolled over at the rim, and
 * modelled on the way in.
 */
function shell(
  outline: readonly Point[],
  s: number,
  roll: number,
  bulge: number,
  rimSteps = 6,
): Solid {
  const count = outline.length;

  const normals: [number, number][] = [];
  for (let i = 0; i < count; i++) {
    const a = outline[(i - 1 + count) % count];
    const b = outline[(i + 1) % count];
    const tx = b.x - a.x;
    const ty = b.y - a.y;
    const length = Math.max(1e-6, Math.hypot(tx, ty));
    normals.push([ty / length, -tx / length]);
  }

  // How far the edge may roll in, point by point.
  //
  // A roll is an inset, and an inset wider than the place it is rolling through
  // has nowhere to go: the two sides of a narrow spot roll into each other and
  // come out as a tube hanging off the piece. The mouth did that. One figure
  // for the whole outline is no use — it would have to suit the narrowest place
  // and would leave the neck square — so it is measured where it is used.
  const reach = outline.map((point) => Math.min(roll, point.depth * 0.9));
  for (let i = 0; i < count; i++) {
    let nearest = Infinity;
    for (let j = 0; j < count; j++) {
      const apart = Math.min(Math.abs(i - j), count - Math.abs(i - j));
      if (apart <= 14) continue; // its own neighbourhood is always close
      nearest = Math.min(
        nearest,
        Math.hypot(outline[j].x - outline[i].x, outline[j].y - outline[i].y),
      );
    }
    reach[i] = Math.min(reach[i], nearest * 0.45);
  }

  const full = signedArea(outline);
  const faces: Point[][] = [
    outline.map((point, i) => ({
      x: point.x - normals[i][0] * reach[i],
      y: point.y - normals[i][1] * reach[i],
      depth: point.depth,
    })),
  ];
  while (faces.length < 10) {
    const next = drawIn(faces[faces.length - 1], 0.012);
    if (signedArea(next) <= full * 0.12) break;
    faces.push(next);
  }

  // The face is closed with the **outline's** triangulation, not the innermost
  // ring's. Drawing a ring in folds the thin parts long before the wide ones —
  // the nick between the ear and the mane is thirteen thousandths wide — and a
  // ring that crosses itself cannot be triangulated at all: ear clipping stalls
  // and hands back part of a face, which is a hole. Every ring holds the same
  // points in the same order, so the cut made on the outline fits all of them.
  const cap = earClip(outline);

  const lift = (k: number): number =>
    faces.length > 1 ? 1 + bulge * Math.sin(((k / (faces.length - 1)) * Math.PI) / 2) : 1;

  // Nothing below the foot. Drawing a ring in creeps outwards round a sharp
  // corner, and at the two corners where the neck is cut off that is downwards:
  // three hundred vertices ended up below the cut, sweeping the depth of the
  // piece as they went — a fin of ivory hanging through the collar.
  const foot = Math.min(...outline.map((point) => point.y));

  const place = (ring: readonly Point[], sign: number, k: number): Vec3[] => {
    // The modelling is faded in from the edge — nothing at the rim, so the
    // silhouette and the roll are left exactly as drawn — but all of it within
    // two rings. Spread across the whole face it only reaches full strength
    // deep in the middle, and the eye and the cheekbone sit a fifth of the way
    // in from the edge: they came out as smudges.
    const ramp = Math.min(1, k / 2);
    const inward = ramp * ramp * (3 - 2 * ramp);
    return ring.map((point) => [
      point.x * s,
      Math.max(foot, point.y) * s,
      sign * (point.depth * lift(k) + modelling(point.x, point.y) * inward) * s,
    ]);
  };

  const rings: Vec3[][] = [];
  for (let k = faces.length - 1; k >= 1; k--) rings.push(place(faces[k], -1, k));
  for (let step = 0; step <= rimSteps; step++) {
    const angle = -Math.PI / 2 + (Math.PI * step) / rimSteps;
    rings.push(
      outline.map((point, i) => {
        const inset = reach[i] * (1 - Math.cos(angle));
        return [
          (point.x - normals[i][0] * inset) * s,
          Math.max(foot, point.y - normals[i][1] * inset) * s,
          point.depth * Math.sin(angle) * s,
        ] as Vec3;
      }),
    );
  }
  for (let k = 1; k < faces.length; k++) rings.push(place(faces[k], 1, k));

  return skin(rings, cap);
}

/**
 * One ear: long, splayed, and rooted well down inside the head.
 *
 * The width falls away on a quarter ellipse rather than a straight taper, so
 * the last of it turns over into a dome the way an ear does. Drawn to a point
 * it comes out as a spine, and two spines over a horse's head read as horns.
 */
function ear(s: number, side: number): Solid {
  const root: Vec3 = [-0.018, 0.962, side * 0.034];
  const tip: Vec3 = [-0.074, 1.198, side * 0.132];
  const steps = 11;
  const segments = 12;

  const axis = normalise(subtract(tip, root));
  const aside = normalise(cross(axis, [0, 0, 1]));
  const other = cross(axis, aside);

  const rings: Vec3[][] = [];
  for (let step = 0; step <= steps; step++) {
    const along = step / steps;
    const centre: Vec3 = [
      root[0] + (tip[0] - root[0]) * along,
      root[1] + (tip[1] - root[1]) * along,
      root[2] + (tip[2] - root[2]) * along,
    ];
    const radius = 0.056 * Math.sqrt(1 - along * along) * (1 - along * 0.42) + 0.001;
    rings.push(
      Array.from({ length: segments }, (_, segment) => {
        const angle = (2 * Math.PI * segment) / segments;
        const a = radius * Math.cos(angle) * 0.78;
        const b = radius * Math.sin(angle);
        return [
          (centre[0] + aside[0] * a + other[0] * b) * s,
          (centre[1] + aside[1] * a + other[1] * b) * s,
          (centre[2] + aside[2] * a + other[2] * b) * s,
        ] as Vec3;
      }),
    );
  }
  const fan = Array.from(
    { length: segments - 2 },
    (_, i) => [0, i + 1, i + 2] as [number, number, number],
  );
  return skin(rings, fan);
}

/** The head and its two ears, facing along +x and swept through z. */
export function knightHead(s: number): BufferGeometry {
  const head = shell(KNIGHT_OUTLINE, s, 0.038, 0.24);
  head.append(ear(s, 1));
  head.append(ear(s, -1));
  return head.geometry;
}

/** The run of anchors the mane sits on, resampled. */
function crest(steps: number, first: number, last: number): Point[] {
  const run = ANCHORS.slice(first, last + 1);
  const points: Point[] = [];
  for (let i = 0; i < run.length; i++) {
    const a = run[Math.max(0, i - 1)];
    const b = run[i];
    const c = run[Math.min(run.length - 1, i + 1)];
    const d = run[Math.min(run.length - 1, i + 2)];
    points.push({ x: b[0], y: b[1], depth: b[3] });
    if (i === run.length - 1) break;
    for (let step = 1; step < steps; step++) {
      const t = step / steps;
      points.push({
        x: spline(a[0], b[0], c[0], d[0], t),
        y: spline(a[1], b[1], c[1], d[1], t),
        depth: spline(a[3], b[3], c[3], d[3], t),
      });
    }
  }
  return points;
}

/**
 * The mane: a ridge standing proud of the crest, dying away at both ends.
 *
 * A ridge of even height stops dead where the run does, and a mane that ends in
 * mid-air reads as a blade stuck on the back. Both axes of the section die away
 * together — fading the height alone leaves the ends as flat slivers, and a
 * sliver skins into a tangle that tears open the neck.
 */
export function knightMane(s: number): BufferGeometry {
  const run = crest(7, 2, 14);
  if (run.length < 3) return new Solid().geometry;

  const segments = 14;
  const stand = 0.012; // how far the ridge sits proud of the edge
  const sink = 0.007; // and how far its root is buried

  const rings: Vec3[][] = run.map((point, i) => {
    const along = i / (run.length - 1);
    const fade = Math.min(1, Math.min(along, 1 - along) / 0.18);
    const taper = 0.16 + 0.84 * (fade * fade * (3 - 2 * fade));
    const rise = stand * taper;
    const before = run[Math.max(0, i - 1)];
    const after = run[Math.min(run.length - 1, i + 1)];
    const tx = after.x - before.x;
    const ty = after.y - before.y;
    const length = Math.max(1e-6, Math.hypot(tx, ty));
    const outward: [number, number] = [ty / length, -tx / length];
    const across = point.depth * 0.72 * taper;

    return Array.from({ length: segments }, (_, step) => {
      const angle = (2 * Math.PI * step) / segments;
      const out = rise * Math.cos(angle) - sink;
      return [
        (point.x + outward[0] * out) * s,
        (point.y + outward[1] * out) * s,
        across * Math.sin(angle) * s,
      ] as Vec3;
    });
  });

  const fan = Array.from(
    { length: segments - 2 },
    (_, i) => [0, i + 1, i + 2] as [number, number, number],
  );
  return skin(rings, fan).geometry;
}
