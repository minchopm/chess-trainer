import { Path, Shape, Vector2 } from 'three';

/**
 * The toolkit the icon set is drawn with.
 *
 * Every icon is a solid object in one room, lit by one lamp, so the set is
 * consistent by construction rather than by anyone remembering to keep it so.
 * That is the whole argument for making them this way instead of drawing them
 * forty-seven times.
 *
 * Everything below works in a 24-unit box centred on the origin — the same
 * grid Apple's symbols use, so an icon dropped in beside a system one does not
 * sit at a different optical size.
 */

export const GRID = 24;

type Pt = readonly [number, number];

const v = (p: Pt) => new Vector2(p[0], p[1]);
const normalOf = (d: Vector2) => new Vector2(-d.y, d.x);

/** Points along an arc, used for round caps and corners. */
function arc(centre: Vector2, from: number, to: number, radius: number, steps = 8): Vector2[] {
  const out: Vector2[] = [];
  for (let i = 0; i <= steps; i++) {
    const a = from + ((to - from) * i) / steps;
    out.push(new Vector2(centre.x + Math.cos(a) * radius, centre.y + Math.sin(a) * radius));
  }
  return out;
}

/**
 * Turns a polyline into the outline of a stroke of the given width.
 *
 * three's `Shape` is filled, not stroked, so a chevron has to be given a body
 * before it can be extruded. Joins are mitred, with the mitre length clamped —
 * an unclamped mitre on a sharp corner shoots off to infinity, which on a
 * chevron is exactly the corner you have.
 */
export function stroke(points: readonly Pt[], width: number, round = true): Shape {
  const half = width / 2;
  const pts = points.map(v);
  const dirs: Vector2[] = [];
  for (let i = 0; i < pts.length - 1; i++) {
    dirs.push(pts[i + 1].clone().sub(pts[i]).normalize());
  }

  const left: Vector2[] = [];
  const right: Vector2[] = [];

  pts.forEach((p, i) => {
    if (i === 0 || i === pts.length - 1) {
      const n = normalOf(dirs[i === 0 ? 0 : dirs.length - 1]);
      left.push(p.clone().addScaledVector(n, half));
      right.push(p.clone().addScaledVector(n, -half));
      return;
    }
    const n1 = normalOf(dirs[i - 1]);
    const n2 = normalOf(dirs[i]);
    const mitre = n1.clone().add(n2).normalize();
    // Clamped, so a tight corner thickens instead of exploding.
    const reach = half / Math.max(0.4, mitre.dot(n1));
    left.push(p.clone().addScaledVector(mitre, reach));
    right.push(p.clone().addScaledVector(mitre, -reach));
  });

  const contour: Vector2[] = [...left];

  if (round) {
    const end = pts[pts.length - 1];
    const a0 = Math.atan2(left[left.length - 1].y - end.y, left[left.length - 1].x - end.x);
    contour.push(...arc(end, a0, a0 - Math.PI, half));
  }

  contour.push(...right.slice().reverse());

  if (round) {
    const start = pts[0];
    const a0 = Math.atan2(right[0].y - start.y, right[0].x - start.x);
    contour.push(...arc(start, a0, a0 - Math.PI, half));
  }

  const shape = new Shape();
  contour.forEach((p, i) => (i === 0 ? shape.moveTo(p.x, p.y) : shape.lineTo(p.x, p.y)));
  shape.closePath();
  return shape;
}

/** A filled polygon with its corners rounded — the play triangle, and friends. */
export function roundedPolygon(points: readonly Pt[], radius: number): Shape {
  const pts = points.map(v);
  const shape = new Shape();

  pts.forEach((p, i) => {
    const prev = pts[(i - 1 + pts.length) % pts.length];
    const next = pts[(i + 1) % pts.length];
    const toPrev = prev.clone().sub(p).normalize();
    const toNext = next.clone().sub(p).normalize();

    // Never round by more than half the shorter edge, or corners overlap.
    const limit = Math.min(prev.distanceTo(p), next.distanceTo(p)) / 2;
    const angle = Math.acos(Math.max(-1, Math.min(1, toPrev.dot(toNext))));
    const trim = Math.min(radius / Math.tan(angle / 2), limit);

    const a = p.clone().addScaledVector(toPrev, trim);
    const b = p.clone().addScaledVector(toNext, trim);

    if (i === 0) shape.moveTo(a.x, a.y);
    else shape.lineTo(a.x, a.y);
    shape.quadraticCurveTo(p.x, p.y, b.x, b.y);
  });

  shape.closePath();
  return shape;
}

/** A circle, as a shape or as a hole. */
export function disc(cx: number, cy: number, r: number): Shape {
  const shape = new Shape();
  shape.absarc(cx, cy, r, 0, Math.PI * 2, false);
  return shape;
}

export function hole(shape: Shape, cx: number, cy: number, r: number): Shape {
  const path = new Path();
  path.absarc(cx, cy, r, 0, Math.PI * 2, true);
  shape.holes.push(path);
  return shape;
}

const smooth = (x: number) => x * x * (3 - 2 * x);

/** A four-pointed sparkle: four tips pinched toward the centre. */
function sparkle(cx: number, cy: number, r: number): Shape {
  const k = r * 0.17;
  const s = new Shape();
  s.moveTo(cx, cy + r);
  s.quadraticCurveTo(cx + k, cy + k, cx + r, cy);
  s.quadraticCurveTo(cx + k, cy - k, cx, cy - r);
  s.quadraticCurveTo(cx - k, cy - k, cx - r, cy);
  s.quadraticCurveTo(cx - k, cy + k, cx, cy + r);
  s.closePath();
  return s;
}

/** Points along a circular arc, for handles and other bent strokes. */
function bend(cx: number, cy: number, r: number, from: number, to: number, steps = 10): Pt[] {
  return Array.from({ length: steps + 1 }, (_, i) => {
    const a = from + ((to - from) * i) / steps;
    return [cx + Math.cos(a) * r, cy + Math.sin(a) * r] as Pt;
  });
}

/**
 * The five proof icons, chosen to cover the whole range of difficulty: a bare
 * stroke, a solid, a complex outline, a real object, and several loose pieces.
 * If these five look like a set, the other forty-two are mechanical.
 */
export const GLYPHS: Record<string, () => Shape[]> = {
  'chevron.right': () => [
    stroke(
      [
        [-3.4, 7.2],
        [3.6, 0],
        [-3.4, -7.2],
      ],
      3.3,
    ),
  ],

  'play.fill': () => [
    roundedPolygon(
      [
        [-5.8, 8.4],
        [8.2, 0],
        [-5.8, -8.4],
      ],
      2.4,
    ),
  ],

  gearshape: () => {
    const teeth = 8;
    const outer = 11;
    const inner = 8.4;
    const shape = new Shape();
    const steps = 480;

    for (let i = 0; i <= steps; i++) {
      const t = (i / steps) * Math.PI * 2;
      const phase = ((t * teeth) / (Math.PI * 2)) % 1;
      // A square wave with its corners eased, so the teeth have roots rather
      // than creases — a crease is where a bevel goes wrong.
      let k: number;
      if (phase < 0.32) k = 1;
      else if (phase < 0.5) k = 1 - smooth((phase - 0.32) / 0.18);
      else if (phase < 0.82) k = 0;
      else k = smooth((phase - 0.82) / 0.18);

      const r = inner + (outer - inner) * k;
      const x = Math.cos(t) * r;
      const y = Math.sin(t) * r;
      if (i === 0) shape.moveTo(x, y);
      else shape.lineTo(x, y);
    }
    shape.closePath();
    hole(shape, 0, 0, 3.9);
    return [shape];
  },

  'trophy.fill': () => {
    const body = new Shape();
    body.moveTo(-6.4, 8.4);
    body.lineTo(6.4, 8.4);
    body.bezierCurveTo(6.4, 3.4, 4.6, 0.3, 1.75, -1.3);
    body.lineTo(1.75, -4.6);
    body.lineTo(5.1, -4.6);
    body.lineTo(5.1, -6.9);
    body.lineTo(-5.1, -6.9);
    body.lineTo(-5.1, -4.6);
    body.lineTo(-1.75, -4.6);
    body.lineTo(-1.75, -1.3);
    body.bezierCurveTo(-4.6, 0.3, -6.4, 3.4, -6.4, 8.4);
    body.closePath();

    // Struck from outside the rim, so they clear the cup and read as handles
    // rather than disappearing into it.
    const rightHandle = stroke(bend(6.0, 4.4, 4.3, Math.PI * 0.5, -Math.PI * 0.5), 1.8);
    const leftHandle = stroke(bend(-6.0, 4.4, 4.3, Math.PI * 0.5, Math.PI * 1.5), 1.8);

    return [body, rightHandle, leftHandle];
  },

  sparkles: () => [sparkle(-4.2, 4.6, 6.4), sparkle(5.4, -2.2, 4.6), sparkle(-3.4, -6.6, 3.4)],
};
