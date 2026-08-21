"""Reads a rendered profile back as numbers.

    python3 ios/Tools/knight/measure.py DIR/reference-side.png [--rows 20]

Scans the render row by row and prints, at each height, how far the piece
reaches either side and how wide it is — all in *head-heights*, measured from
the crown down to the collar, which the scan finds as the row where the
silhouette suddenly steps outward.

Two things it is worth knowing before trusting the output. The threshold that
separates piece from background also decides whether thin, shaded parts count:
run it twice at different thresholds and see whether the top of the piece moves.
And a row that reports one wide span may be two things at that height — the
`runs` column keeps them apart, which is how the knight's ears turned out to be
one squared-off mane block and one small ear rather than the two tall triangles
they look like.
"""

import argparse
import math
import sys


def spans(values):
    out = []
    for value in values:
        if out and value == out[-1][1] + 1:
            out[-1][1] = value
        else:
            out.append([value, value])
    return out


def trace(mask, width, height):
    """Walks the outline of the shape, in order.

    Row-by-row extents are enough to read proportions off, but not to draw
    with: where the piece has a notch — the mouth, between the muzzle and the
    throat — a row reports two spans and says nothing about how they join. The
    outline has to be walked to get that.

    Moore neighbourhood tracing: stand on a filled pixel, look round it from
    where you came in, and step onto the first filled pixel you meet.
    """
    start = next(((x, y) for y in range(height) for x in range(width) if mask[y][x]), None)
    if start is None:
        return []

    # Clockwise from due left, which is where the scan came from.
    around = [(-1, 0), (-1, -1), (0, -1), (1, -1), (1, 0), (1, 1), (0, 1), (-1, 1)]

    def filled(point):
        x, y = point
        return 0 <= x < width and 0 <= y < height and mask[y][x]

    here, came_from = start, (start[0] - 1, start[1])
    outline = [start]
    for _ in range(width * height * 4):
        back = (came_from[0] - here[0], came_from[1] - here[1])
        k = around.index(back) if back in around else 0
        stepped = False
        for turn in range(1, 9):
            direction = around[(k + turn) % 8]
            neighbour = (here[0] + direction[0], here[1] + direction[1])
            if filled(neighbour):
                previous = around[(k + turn - 1) % 8]
                came_from = (here[0] + previous[0], here[1] + previous[1])
                here = neighbour
                stepped = True
                break
        if not stepped or here == start:
            break
        outline.append(here)
    return outline


def simplify(points, tolerance):
    """Douglas-Peucker: the fewest points that still tell the same shape."""
    if len(points) < 3:
        return points

    def furthest(lo, hi):
        (x0, y0), (x1, y1) = points[lo], points[hi]
        dx, dy = x1 - x0, y1 - y0
        length = math.hypot(dx, dy) or 1.0
        best, index = -1.0, lo
        for i in range(lo + 1, hi):
            x, y = points[i]
            away = abs(dy * x - dx * y + x1 * y0 - y1 * x0) / length
            if away > best:
                best, index = away, i
        return best, index

    keep = {0, len(points) - 1}
    stack = [(0, len(points) - 1)]
    while stack:
        lo, hi = stack.pop()
        if hi <= lo + 1:
            continue
        away, index = furthest(lo, hi)
        if away > tolerance:
            keep.add(index)
            stack += [(lo, index), (index, hi)]
    return [points[i] for i in sorted(keep)]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("image")
    parser.add_argument("--trace", action="store_true",
                        help="walk the outline and print it as anchors")
    parser.add_argument("--tolerance", type=float, default=0.004)
    parser.add_argument("--mirror", action="store_true",
                        help="the reference faces left; our pieces face right")
    parser.add_argument("--rows", type=int, default=20)
    parser.add_argument("--threshold", type=int, default=150)
    args = parser.parse_args()

    try:
        from PIL import Image
    except ImportError:
        sys.exit("needs Pillow: python3 -m pip install pillow")

    image = Image.open(args.image).convert("L")
    width, height = image.size
    pixels = image.load()

    rows = {y: [x for x in range(width) if pixels[x, y] > args.threshold] for y in range(height)}
    if args.trace:
        mask = [[pixels[x, y] > args.threshold for x in range(width)] for y in range(height)]
        top = next(y for y in range(height) if rows[y])
        widths = [max(rows[y]) - min(rows[y]) if rows[y] else 0 for y in range(height)]
        collar = next((y for y in range(top + 40, height)
                       if widths[y] > widths[y - 1] + 12), height - 1)
        span = collar - top
        centre = (min(rows[collar - 1]) + max(rows[collar - 1])) / 2
        # Only the head: below the collar the outline is the turning's, and the
        # turning is not drawn here.
        for y in range(collar, height):
            for x in range(width):
                mask[y][x] = False
        walked = trace(mask, width, height)
        flip = -1 if args.mirror else 1
        # Into the piece's own frame: the collar sits at 0.500 and the crown at
        # 1.160, which is where the app's knight is drawn.
        scaled = [(flip * -(x - centre) / span * 0.66, 1.16 - (y - top) / span * 0.66)
                  for x, y in walked]
        kept = simplify(scaled, args.tolerance)
        print(f"// traced from {args.image}: {len(walked)} points, kept {len(kept)}")
        for x, y in kept:
            print(f"        ({x:+.3f}, {y:.3f}, false),")
        return

    top = next(y for y in range(height) if rows[y])
    widths = [max(rows[y]) - min(rows[y]) if rows[y] else 0 for y in range(height)]

    # The collar is where the silhouette steps out: the turning below is wider
    # than anything the head does.
    collar = next((y for y in range(top + 40, height) if widths[y] > widths[y - 1] + 12), height - 1)
    span = collar - top
    centre = (min(rows[collar - 1]) + max(rows[collar - 1])) / 2
    print(f"# {args.image}")
    print(f"# crown row {top}, collar row {collar}, head height {span}px")
    print(f"#  t      back     front    width   runs")

    for step in range(args.rows + 1):
        y = top + round(step * span / args.rows)
        if not rows[y]:
            continue
        left, right = min(rows[y]), max(rows[y])
        runs = "  ".join(f"[{(a - centre) / span:+.3f}..{(b - centre) / span:+.3f}]"
                         for a, b in spans(rows[y]))
        print(f"{step / args.rows:5.2f}  {(left - centre) / span:+7.3f} "
              f"{(right - centre) / span:+7.3f} {(right - left) / span:7.3f}   {runs}")


main()
