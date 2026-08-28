import { BufferAttribute, BufferGeometry } from 'three';

/**
 * A bag of triangles with their normals, and the few primitives a chess set is
 * made of.
 *
 * three.js has `LatheGeometry`, `SphereGeometry` and the rest, and for most of
 * this set they would do. The knight is why they will not: its head is an
 * outline swept with **a different depth at every point along it**, and there
 * is no built-in that extrudes unevenly. Once one piece has to be built from
 * triangles it is simpler for all of them to come from the same builder, in the
 * same winding, than to reconcile six primitives that disagree about indexing
 * and attributes on the way into a merge.
 *
 * Ported from the app's `Solids.swift`, so the two sets are the same shapes
 * rather than two drawings of the same idea.
 */

export type Vec3 = readonly [number, number, number];

/** A point on a turning: radius from the axis, and height up it. */
export type Turn = readonly [number, number];

export class Solid {
  private readonly positions: number[] = [];
  private readonly normals: number[] = [];

  /** A triangle with one flat normal taken from its own plane. */
  triangle(a: Vec3, b: Vec3, c: Vec3): void {
    const u: Vec3 = [b[0] - a[0], b[1] - a[1], b[2] - a[2]];
    const v: Vec3 = [c[0] - a[0], c[1] - a[1], c[2] - a[2]];
    const n = normalise([
      u[1] * v[2] - u[2] * v[1],
      u[2] * v[0] - u[0] * v[2],
      u[0] * v[1] - u[1] * v[0],
    ]);
    this.smooth(a, b, c, n, n, n);
  }

  /** A triangle carrying a normal per corner, for surfaces meant to look curved. */
  smooth(a: Vec3, b: Vec3, c: Vec3, na: Vec3, nb: Vec3, nc: Vec3): void {
    this.positions.push(...a, ...b, ...c);
    this.normals.push(...na, ...nb, ...nc);
  }

  quad(a: Vec3, b: Vec3, c: Vec3, d: Vec3): void {
    this.triangle(a, b, c);
    this.triangle(a, c, d);
  }

  append(other: Solid): void {
    this.positions.push(...other.positions);
    this.normals.push(...other.normals);
  }

  get geometry(): BufferGeometry {
    const geometry = new BufferGeometry();
    geometry.setAttribute('position', new BufferAttribute(new Float32Array(this.positions), 3));
    geometry.setAttribute('normal', new BufferAttribute(new Float32Array(this.normals), 3));
    return geometry;
  }
}

export function normalise(v: Vec3): Vec3 {
  const length = Math.hypot(v[0], v[1], v[2]) || 1;
  return [v[0] / length, v[1] / length, v[2] / length];
}

export function cross(a: Vec3, b: Vec3): Vec3 {
  return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
}

export function subtract(a: Vec3, b: Vec3): Vec3 {
  return [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
}

/**
 * A profile turned about the Y axis.
 *
 * `start` and `sweep` exist for the rook: its battlements are pieces of the
 * same turning swept through part of a circle instead of all of it, so the gaps
 * between them are square-cut and go down to the rampart. Little cylinders
 * stood on the rim — the cheap way — read as pegs from every angle.
 */
export function revolved(
  profile: readonly Turn[],
  segments = 48,
  start = 0,
  sweep = Math.PI * 2,
): Solid {
  const solid = new Solid();
  if (profile.length < 2) return solid;

  // Never exactly zero: a ring of radius zero collapses to a point and takes
  // its triangles' normals with it.
  const points = profile.map(([r, y]) => [Math.max(r, 0.0001), y] as const);
  const partial = sweep < Math.PI * 2 - 0.0001;

  for (let step = 0; step < segments; step++) {
    const a = start + (step / segments) * sweep;
    const b = start + ((step + 1) / segments) * sweep;
    const [sa, ca] = [Math.sin(a), Math.cos(a)];
    const [sb, cb] = [Math.sin(b), Math.cos(b)];

    for (let i = 0; i < points.length - 1; i++) {
      const [lr, ly] = points[i];
      const [ur, uy] = points[i + 1];
      // Wound so the face normal points away from the axis. The other way
      // round is not a subtle error: the front faces are culled, the inside of
      // the piece is what gets drawn, and a solid ivory rook renders as glass.
      solid.quad(
        [ur * ca, uy, ur * sa],
        [ur * cb, uy, ur * sb],
        [lr * cb, ly, lr * sb],
        [lr * ca, ly, lr * sa],
      );
    }
  }

  if (partial) {
    // The two cut faces, so a battlement is a solid block rather than a shell.
    for (const [angle, flip] of [
      [start, false],
      [start + sweep, true],
    ] as const) {
      const [s, c] = [Math.sin(angle), Math.cos(angle)];
      for (let i = 0; i < points.length - 1; i++) {
        const [lr, ly] = points[i];
        const [ur, uy] = points[i + 1];
        const face: [Vec3, Vec3, Vec3, Vec3] = [
          [lr * c, ly, lr * s],
          [ur * c, uy, ur * s],
          [0.0001 * c, uy, 0.0001 * s],
          [0.0001 * c, ly, 0.0001 * s],
        ];
        if (flip) solid.quad(face[3], face[2], face[1], face[0]);
        else solid.quad(face[0], face[1], face[2], face[3]);
      }
    }
  }

  return solid;
}

export function sphere(radius: number, at: Vec3, segments = 32, rings = 16): Solid {
  const solid = new Solid();
  const point = (phi: number, theta: number): Vec3 => [
    at[0] + radius * Math.sin(theta) * Math.cos(phi),
    at[1] + radius * Math.cos(theta),
    at[2] + radius * Math.sin(theta) * Math.sin(phi),
  ];
  for (let ring = 0; ring < rings; ring++) {
    const t0 = (ring / rings) * Math.PI;
    const t1 = ((ring + 1) / rings) * Math.PI;
    for (let step = 0; step < segments; step++) {
      const p0 = (step / segments) * Math.PI * 2;
      const p1 = ((step + 1) / segments) * Math.PI * 2;
      solid.quad(point(p0, t0), point(p1, t0), point(p1, t1), point(p0, t1));
    }
  }
  return solid;
}

export function cylinder(
  radius: number,
  height: number,
  at: Vec3,
  segments = 12,
  axis: 'x' | 'y' | 'z' = 'y',
): Solid {
  const place = (x: number, y: number, z: number): Vec3 =>
    axis === 'y'
      ? [at[0] + x, at[1] + y, at[2] + z]
      : axis === 'x'
        ? [at[0] + y, at[1] + x, at[2] + z]
        : [at[0] + x, at[1] + z, at[2] + y];

  const solid = new Solid();
  const half = height / 2;
  for (let step = 0; step < segments; step++) {
    const a = (step / segments) * Math.PI * 2;
    const b = ((step + 1) / segments) * Math.PI * 2;
    const [xa, za] = [Math.cos(a) * radius, Math.sin(a) * radius];
    const [xb, zb] = [Math.cos(b) * radius, Math.sin(b) * radius];
    solid.quad(
      place(xa, half, za),
      place(xb, half, zb),
      place(xb, -half, zb),
      place(xa, -half, za),
    );
    solid.triangle(place(0, half, 0), place(xa, half, za), place(xb, half, zb));
    solid.triangle(place(0, -half, 0), place(xb, -half, zb), place(xa, -half, za));
  }
  return solid;
}

/** A torus: the brass bands, and the rook's rim. */
export function ring(radius: number, tube: number, at: Vec3, segments = 32, sides = 12): Solid {
  const solid = new Solid();
  const point = (major: number, minor: number): Vec3 => [
    at[0] + (radius + tube * Math.cos(minor)) * Math.cos(major),
    at[1] + tube * Math.sin(minor),
    at[2] + (radius + tube * Math.cos(minor)) * Math.sin(major),
  ];
  for (let step = 0; step < segments; step++) {
    const a = (step / segments) * Math.PI * 2;
    const b = ((step + 1) / segments) * Math.PI * 2;
    for (let side = 0; side < sides; side++) {
      const c = (side / sides) * Math.PI * 2;
      const d = ((side + 1) / sides) * Math.PI * 2;
      solid.quad(point(a, c), point(b, c), point(b, d), point(a, d));
    }
  }
  return solid;
}
