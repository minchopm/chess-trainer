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
import sys


def spans(values):
    out = []
    for value in values:
        if out and value == out[-1][1] + 1:
            out[-1][1] = value
        else:
            out.append([value, value])
    return out


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("image")
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
