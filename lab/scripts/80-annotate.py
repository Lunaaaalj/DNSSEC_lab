#!/usr/bin/env python3
"""Draw the report highlights (red #d32f2f, 3 px, no fill) on the Wireshark screenshots and crop them.
Originals stay untouched in docs/actividad3/img/originales/; annotated PNGs go to docs/actividad3/img/.
Coordinates are for the 1061x781 originals (Wireshark, 9 px per Info character starting at x=725)."""
from pathlib import Path
from PIL import Image, ImageDraw

IMG = Path(__file__).resolve().parents[2] / "docs/actividad3/img"
RED, W = (211, 47, 47), 3
STATUS = (0, 752, 1061, 781)          # bottom bar: file name + "Displayed: N"
FILTER_Y = 95                          # crop away the menu and toolbar above the filter bar

def info(idx, n, row_y, h=17):         # box around n characters of the Info column starting at char idx
    x0 = 725 + round(idx * 9.05)
    return (x0 - 3, row_y - h // 2 - 1, x0 + round(n * 9.05) + 3, row_y + h // 2)

ROW = lambda i: 153 + 17 * (i - 1)     # y centre of table row i (1-based)
SHOTS = {
  # file: (boxes, bottom of table region to keep)
  "01_Wireshark_AD_recursivo_dnssec.png": ([(26, 99, 222, 119), (6, 145, 1056, 231), (648, 756, 868, 776)], 245),
  "02_Wireshark_AD_recursivo_sin_dnssec.png": ([(26, 99, 222, 119), (648, 756, 868, 776)], 165),
  "03_Wireshark_DNSKEY_recursivo_dnssec.png": ([(26, 99, 560, 119), (922, 145, 1056, 213), (648, 756, 868, 776)], 225),
  "04_Wireshark_DNSKEY_recursivo_sin_dnssec.png": ([(26, 99, 560, 119), (922, 145, 1056, 162), (648, 756, 868, 776)], 175),
  # NS to the root server: highlight the <Root> queries (rows 1,3,5-9 / 1,3) and, in the second shot, the two "unsigned" rows
  "05_Wireshark_NS_raiz_recursivo_dnssec.png": ([info(25, 6, ROW(i)) for i in (1, 3, 5, 6, 7, 8, 9)] + [(648, 756, 868, 776)], 310),
  "06_Wireshark_NS_raiz_recursivo_sin_dnssec.png": ([info(25, 6, ROW(i)) for i in (1, 3)] + [info(25, 8, ROW(i)) for i in (4, 5)] + [(648, 756, 868, 776)], 245),
}

for name, (boxes, bottom) in SHOTS.items():
    im = Image.open(IMG / "originales" / name).convert("RGB")
    d = ImageDraw.Draw(im)
    for b in boxes:
        d.rectangle(b, outline=RED, width=W)
    top = im.crop((0, FILTER_Y, im.width, bottom))
    bar = im.crop(STATUS)
    out = Image.new("RGB", (im.width, top.height + bar.height), (255, 255, 255))
    out.paste(top, (0, 0)); out.paste(bar, (0, top.height))
    out.save(IMG / name)
    print(name, out.size)
