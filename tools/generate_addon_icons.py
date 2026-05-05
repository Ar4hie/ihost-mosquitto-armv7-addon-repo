#!/usr/bin/env python3
"""
Generate simple Home Assistant add-on icon.png files for the custom iHost armv7 repository.
No external dependencies are required: this script writes PNG files with Python stdlib only.
"""
from __future__ import annotations

import math
import os
import struct
import zlib
from pathlib import Path
from typing import Dict, Tuple

RGBA = Tuple[int, int, int, int]

ROOT = Path(__file__).resolve().parents[1]
SIZE = 256

# folder: (style, background RGB)
ADDONS: Dict[str, Tuple[str, Tuple[int, int, int]]] = {
    "mosquitto": ("mqtt", (0, 151, 167)),
    "dnsmasq": ("dns", (30, 136, 229)),
    "file-editor-armv7": ("file", (67, 160, 71)),
    "git-pull-armv7": ("git", (251, 140, 0)),
    "rpc-shutdown-armv7": ("power", (229, 57, 53)),
    "samba-armv7": ("folder", (57, 73, 171)),
    "tailscale-armv7": ("mesh", (69, 90, 100)),
    "hassio-ihost-ewelink-smart-home-patched": ("home", (76, 175, 80)),
    "hassio-ihost-ewelink-remote-patched": ("remote", (0, 150, 136)),
    "hassio-ihost-hardware-control-patched": ("chip", (25, 118, 210)),
    "hassio-ihost-zigbee2mqtt-patched": ("zigbee", (255, 152, 0)),
    "hassio-ihost-matter-bridge-addon-patched": ("matter", (103, 58, 183)),
}


def blank() -> list[list[RGBA]]:
    return [[(0, 0, 0, 0) for _ in range(SIZE)] for _ in range(SIZE)]


def blend_pixel(img, x: int, y: int, color: RGBA) -> None:
    if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
        return
    r, g, b, a = color
    if a >= 255:
        img[y][x] = (r, g, b, 255)
        return
    br, bg, bb, ba = img[y][x]
    alpha = a / 255.0
    out_a = alpha + ba / 255.0 * (1 - alpha)
    if out_a <= 0:
        img[y][x] = (0, 0, 0, 0)
        return
    nr = int((r * alpha + br * (ba / 255.0) * (1 - alpha)) / out_a)
    ng = int((g * alpha + bg * (ba / 255.0) * (1 - alpha)) / out_a)
    nb = int((b * alpha + bb * (ba / 255.0) * (1 - alpha)) / out_a)
    img[y][x] = (nr, ng, nb, int(out_a * 255))


def fill_circle(img, cx: int, cy: int, radius: int, color: RGBA) -> None:
    r2 = radius * radius
    for y in range(cy - radius, cy + radius + 1):
        for x in range(cx - radius, cx + radius + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r2:
                blend_pixel(img, x, y, color)


def fill_rect(img, x0: int, y0: int, x1: int, y1: int, color: RGBA) -> None:
    for y in range(max(0, y0), min(SIZE, y1)):
        for x in range(max(0, x0), min(SIZE, x1)):
            blend_pixel(img, x, y, color)


def rounded_rect(img, x0: int, y0: int, x1: int, y1: int, radius: int, color: RGBA) -> None:
    fill_rect(img, x0 + radius, y0, x1 - radius, y1, color)
    fill_rect(img, x0, y0 + radius, x1, y1 - radius, color)
    fill_circle(img, x0 + radius, y0 + radius, radius, color)
    fill_circle(img, x1 - radius - 1, y0 + radius, radius, color)
    fill_circle(img, x0 + radius, y1 - radius - 1, radius, color)
    fill_circle(img, x1 - radius - 1, y1 - radius - 1, radius, color)


def line(img, x0: int, y0: int, x1: int, y1: int, color: RGBA, thickness: int = 8) -> None:
    dx = x1 - x0
    dy = y1 - y0
    steps = max(abs(dx), abs(dy), 1)
    for i in range(steps + 1):
        t = i / steps
        x = int(round(x0 + dx * t))
        y = int(round(y0 + dy * t))
        fill_circle(img, x, y, max(1, thickness // 2), color)


def arc(img, cx: int, cy: int, radius: int, start_deg: int, end_deg: int, color: RGBA, thickness: int = 8) -> None:
    for deg in range(start_deg, end_deg + 1):
        rad = math.radians(deg)
        x = int(round(cx + math.cos(rad) * radius))
        y = int(round(cy + math.sin(rad) * radius))
        fill_circle(img, x, y, max(1, thickness // 2), color)


def polygon(img, points, color: RGBA) -> None:
    # Simple scanline fill.
    ys = [p[1] for p in points]
    for y in range(max(0, min(ys)), min(SIZE, max(ys) + 1)):
        nodes = []
        j = len(points) - 1
        for i in range(len(points)):
            xi, yi = points[i]
            xj, yj = points[j]
            if (yi < y <= yj) or (yj < y <= yi):
                if yj != yi:
                    nodes.append(int(xi + (y - yi) / (yj - yi) * (xj - xi)))
            j = i
        nodes.sort()
        for a, b in zip(nodes[0::2], nodes[1::2]):
            fill_rect(img, a, y, b + 1, y + 1, color)


def draw_base(img, bg: Tuple[int, int, int]) -> None:
    rounded_rect(img, 16, 16, 240, 240, 48, (*bg, 255))
    # subtle highlight
    arc(img, 126, 126, 96, 205, 330, (255, 255, 255, 30), 6)


def glyph_mqtt(img):
    white = (255, 255, 255, 235)
    for r in (34, 58, 82):
        arc(img, 96, 154, r, 215, 325, white, 11)
    fill_circle(img, 96, 154, 10, white)
    fill_rect(img, 138, 78, 190, 120, white)
    fill_rect(img, 164, 120, 174, 162, white)
    fill_rect(img, 130, 162, 204, 174, white)
    fill_circle(img, 130, 168, 11, white)
    fill_circle(img, 204, 168, 11, white)


def glyph_dns(img):
    white = (255, 255, 255, 235)
    fill_circle(img, 128, 128, 62, (255, 255, 255, 46))
    arc(img, 128, 128, 62, 0, 360, white, 8)
    arc(img, 128, 128, 38, 0, 360, white, 5)
    line(img, 66, 128, 190, 128, white, 6)
    line(img, 128, 66, 128, 190, white, 6)
    line(img, 74, 98, 182, 98, white, 4)
    line(img, 74, 158, 182, 158, white, 4)


def glyph_file(img):
    white = (255, 255, 255, 235)
    polygon(img, [(78, 58), (154, 58), (190, 94), (190, 198), (78, 198)], white)
    polygon(img, [(154, 58), (190, 94), (154, 94)], (220, 220, 220, 255))
    line(img, 98, 116, 168, 116, (50, 50, 50, 120), 8)
    line(img, 98, 142, 168, 142, (50, 50, 50, 120), 8)
    line(img, 112, 180, 176, 116, (255, 193, 7, 255), 12)
    fill_circle(img, 181, 111, 8, (255, 193, 7, 255))


def glyph_git(img):
    white = (255, 255, 255, 235)
    fill_circle(img, 88, 76, 15, white)
    fill_circle(img, 88, 180, 15, white)
    fill_circle(img, 174, 134, 15, white)
    line(img, 88, 91, 88, 165, white, 9)
    line(img, 88, 105, 160, 134, white, 9)


def glyph_power(img):
    white = (255, 255, 255, 235)
    arc(img, 128, 134, 62, 130, 410, white, 14)
    line(img, 128, 58, 128, 130, white, 16)


def glyph_folder(img):
    white = (255, 255, 255, 235)
    rounded_rect(img, 58, 92, 198, 184, 16, white)
    rounded_rect(img, 58, 72, 122, 112, 14, white)
    fill_rect(img, 88, 84, 154, 112, white)
    line(img, 76, 126, 180, 126, (40, 40, 40, 90), 6)


def glyph_mesh(img):
    white = (255, 255, 255, 235)
    pts = [(90, 84), (166, 84), (90, 172), (166, 172)]
    for a, b in ((0, 1), (0, 2), (1, 3), (2, 3), (0, 3), (1, 2)):
        line(img, *pts[a], *pts[b], white, 5)
    for x, y in pts:
        fill_circle(img, x, y, 14, white)


def glyph_home(img):
    white = (255, 255, 255, 235)
    polygon(img, [(54, 126), (128, 64), (202, 126), (188, 142), (188, 198), (68, 198), (68, 142)], white)
    fill_rect(img, 112, 148, 144, 198, (60, 60, 60, 120))
    fill_rect(img, 82, 138, 108, 164, (60, 60, 60, 90))
    fill_rect(img, 150, 138, 176, 164, (60, 60, 60, 90))


def glyph_remote(img):
    white = (255, 255, 255, 235)
    rounded_rect(img, 92, 54, 164, 202, 24, white)
    fill_circle(img, 128, 86, 14, (40, 40, 40, 120))
    fill_circle(img, 128, 132, 10, (40, 40, 40, 120))
    fill_circle(img, 108, 158, 8, (40, 40, 40, 120))
    fill_circle(img, 148, 158, 8, (40, 40, 40, 120))
    arc(img, 128, 60, 62, 215, 325, white, 8)


def glyph_chip(img):
    white = (255, 255, 255, 235)
    rounded_rect(img, 78, 78, 178, 178, 18, white)
    for p in range(88, 174, 24):
        line(img, p, 58, p, 78, white, 8)
        line(img, p, 178, p, 198, white, 8)
        line(img, 58, p, 78, p, white, 8)
        line(img, 178, p, 198, p, white, 8)
    fill_circle(img, 128, 128, 28, (25, 118, 210, 170))
    fill_circle(img, 128, 128, 12, white)


def glyph_zigbee(img):
    white = (255, 255, 255, 235)
    line(img, 76, 76, 180, 76, white, 18)
    line(img, 180, 76, 76, 180, white, 18)
    line(img, 76, 180, 180, 180, white, 18)
    arc(img, 128, 128, 86, 300, 420, (255, 255, 255, 120), 8)
    arc(img, 128, 128, 86, 120, 240, (255, 255, 255, 120), 8)


def glyph_matter(img):
    white = (255, 255, 255, 225)
    fill_circle(img, 128, 76, 24, white)
    fill_circle(img, 82, 154, 24, white)
    fill_circle(img, 174, 154, 24, white)
    line(img, 128, 100, 92, 136, white, 12)
    line(img, 128, 100, 164, 136, white, 12)
    line(img, 106, 154, 150, 154, white, 12)


def draw_icon(style: str, bg: Tuple[int, int, int]) -> list[list[RGBA]]:
    img = blank()
    draw_base(img, bg)
    globals()[f"glyph_{style}"](img)
    return img


def png_bytes(img) -> bytes:
    raw = bytearray()
    for row in img:
        raw.append(0)  # no filter
        for r, g, b, a in row:
            raw.extend(bytes((r, g, b, a)))
    def chunk(kind: bytes, data: bytes) -> bytes:
        return struct.pack("!I", len(data)) + kind + data + struct.pack("!I", zlib.crc32(kind + data) & 0xFFFFFFFF)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack("!IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")


def main() -> None:
    generated = []
    for folder, (style, bg) in ADDONS.items():
        addon_dir = ROOT / folder
        if not addon_dir.is_dir():
            continue
        out = addon_dir / "icon.png"
        out.write_bytes(png_bytes(draw_icon(style, bg)))
        generated.append(str(out.relative_to(ROOT)))
    print("Generated icons:")
    for item in generated:
        print(f" - {item}")
    if not generated:
        print("No matching add-on folders found.")


if __name__ == "__main__":
    main()
