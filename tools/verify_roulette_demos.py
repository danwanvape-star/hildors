"""Verify generated roulette MP4 files and create a visual contact sheet."""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / ".codex_tmp" / "holopet_pydeps"))

import av
from PIL import Image, ImageDraw, ImageFont

SOURCE = ROOT / "assets" / "videos" / "chaos_party_demo"
FONT = ImageFont.truetype(str(ROOT / "assets" / "fonts" / "Poppins-Regular.ttf"), 24)


def inspect(path: Path):
    with av.open(str(path)) as container:
        stream = container.streams.video[0]
        frames = list(container.decode(stream))
        assert stream.width == 1280 and stream.height == 720
        assert stream.codec_context.name == "h264"
        assert frames
        middle = frames[len(frames) // 2].to_image().resize((480, 270))
        return stream.codec_context.name, len(frames), float(stream.average_rate), middle


if __name__ == "__main__":
    files = sorted(SOURCE.glob("chaos_*.mp4"))
    assert len(files) == 8, f"expected 8 demos, found {len(files)}"
    sheet = Image.new("RGB", (1000, 1220), "black")
    draw = ImageDraw.Draw(sheet)
    for index, path in enumerate(files):
        codec, count, fps, preview = inspect(path)
        x = 10 + (index % 2) * 500
        y = 10 + (index // 2) * 300
        sheet.paste(preview, (x, y))
        draw.text((x, y + 272), path.stem, font=FONT, fill="white")
        print(f"{path.name}: {codec}, {count} frames, {fps:.0f} fps")
    sheet.save(SOURCE / "roulette_demo_contact_sheet.jpg", quality=92)
