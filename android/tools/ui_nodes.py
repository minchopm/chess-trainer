#!/usr/bin/env python3
"""Read a uiautomator dump from stdin: list the labelled nodes, or with
--find "<label>" print the centre of the first node whose text or content
description is that label (exact match first, then a prefix)."""
import re
import sys
import xml.etree.ElementTree as ET

nodes = []
for node in ET.fromstring(sys.stdin.read()).iter("node"):
    label = node.get("text") or node.get("content-desc") or ""
    bounds = [int(n) for n in re.findall(r"-?\d+", node.get("bounds", ""))]
    if label and len(bounds) == 4:
        nodes.append((label, bounds))

if len(sys.argv) > 2 and sys.argv[1] == "--find":
    wanted = sys.argv[2]
    match = next((n for n in nodes if n[0] == wanted), None) or next((n for n in nodes if n[0].startswith(wanted)), None)
    if match:
        x0, y0, x1, y1 = match[1]
        print((x0 + x1) // 2, (y0 + y1) // 2)
else:
    for label, (x0, y0, x1, y1) in nodes:
        print(f"{(x0 + x1) // 2:5d} {(y0 + y1) // 2:5d}  {label}")
