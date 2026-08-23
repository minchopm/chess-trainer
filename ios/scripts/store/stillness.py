"""The longest stretch of a preview in which nothing moves, in seconds.

Frames compared rather than thresholded. `freezedetect` needs a noise figure,
and there is no figure that both catches the recorder repeating its first frame
and spares a camera orbiting a few pixels a second: strict enough for the one
was blind to the other. Whole frames, downscaled and hashed, are neither.
"""
import hashlib, subprocess, sys

FPS, SIDE = 4, 96

head_only = "--head" in sys.argv
path = sys.argv[1]
raw = subprocess.run(
    ["ffmpeg", "-v", "error", "-i", path,
     "-vf", f"fps={FPS},scale={SIDE}:{SIDE},format=gray", "-f", "rawvideo", "-"],
    capture_output=True).stdout

size = SIDE * SIDE
hashes = [hashlib.blake2b(raw[i:i + size], digest_size=8).digest()
          for i in range(0, len(raw) - size + 1, size)]

longest, start, run, run_start = 0.0, 0.0, 1, 0
for i in range(1, len(hashes)):
    if hashes[i] == hashes[i - 1]:
        run += 1
    else:
        if run / FPS > longest:
            longest, start = run / FPS, run_start / FPS
        run, run_start = 1, i
if run / FPS > longest:
    longest, start = run / FPS, run_start / FPS

if head_only:
    # How long the recorder repeated its first frame before it began writing
    # properly. Anywhere between two and fourteen seconds, so the front of the
    # file cannot be cut to a fixed number.
    lead = 1
    while lead < len(hashes) and hashes[lead] == hashes[0]:
        lead += 1
    print(f"{lead / FPS:.2f}")
else:
    print(f"{longest:.1f} {start:.1f}")
