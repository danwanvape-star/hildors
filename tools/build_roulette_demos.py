"""Build black-background Holo Roulette demo videos for P20 integration tests."""

import math
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / ".codex_tmp" / "holopet_pydeps"))

import av
from PIL import Image, ImageDraw, ImageFilter, ImageFont

WIDTH, HEIGHT, FPS = 1280, 720, 24
OUTPUT = ROOT / "assets" / "videos" / "chaos_party_demo"
FONT_PATH = ROOT / "assets" / "fonts" / "Poppins-Regular.ttf"
CYAN = (0, 236, 255)
MAGENTA = (255, 30, 190)
PURPLE = (145, 62, 255)
ORANGE = (255, 159, 36)

STAGES = {
    "idle": (4, "READY?"),
    "roulette": (4, "WHO'S NEXT?"),
    "thinking": (3, "CHOOSING"),
    "point": (2, "YOU!"),
    "laugh": (3, "HAHA!"),
    "success": (3, "SUCCESS"),
    "fail": (3, "TRY AGAIN"),
    "next": (2, "NEXT ROUND"),
}


def font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_PATH), size)


def glow(base: Image.Image, painter, radius: int = 18) -> None:
    light = Image.new("RGBA", base.size, (0, 0, 0, 0))
    painter(ImageDraw.Draw(light))
    base.alpha_composite(light.filter(ImageFilter.GaussianBlur(radius=radius)))
    base.alpha_composite(light)


def centered_text(draw: ImageDraw.ImageDraw, text: str, y: int, size: int, color) -> None:
    face = font(size)
    box = draw.textbbox((0, 0), text, font=face)
    draw.text(((WIDTH - box[2]) / 2, y), text, font=face, fill=color)


def host(base: Image.Image, phase: float, expression: str = "grin") -> None:
    bob = int(math.sin(phase * math.tau) * 10)
    cx, cy = WIDTH // 2, 330 + bob

    def paint(draw: ImageDraw.ImageDraw) -> None:
        draw.polygon([(cx - 105, cy - 105), (cx - 175, cy - 210), (cx - 55, cy - 150)], fill=MAGENTA + (220,))
        draw.polygon([(cx + 105, cy - 105), (cx + 175, cy - 210), (cx + 55, cy - 150)], fill=CYAN + (220,))
        draw.ellipse((cx - 145, cy - 145, cx + 145, cy + 145), outline=PURPLE + (255,), width=16)
        draw.arc((cx - 185, cy - 115, cx + 185, cy + 115), 190, 350, fill=CYAN + (255,), width=18)
        draw.ellipse((cx - 88, cy - 45, cx - 35, cy + 8), fill=CYAN + (255,))
        draw.ellipse((cx + 35, cy - 45, cx + 88, cy + 8), fill=MAGENTA + (255,))
        if expression == "laugh":
            draw.arc((cx - 72, cy + 10, cx + 72, cy + 115), 0, 180, fill=ORANGE + (255,), width=18)
        elif expression == "sad":
            draw.arc((cx - 65, cy + 55, cx + 65, cy + 125), 180, 360, fill=MAGENTA + (255,), width=16)
        else:
            draw.arc((cx - 62, cy + 15, cx + 62, cy + 82), 0, 180, fill=ORANGE + (255,), width=14)

    glow(base, paint)


def wheel(base: Image.Image, phase: float) -> None:
    cx, cy, radius = WIDTH // 2, 315, 205
    angle = phase * math.tau * 4

    def paint(draw: ImageDraw.ImageDraw) -> None:
        draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), outline=CYAN + (255,), width=12)
        for index in range(12):
            a = angle + index * math.tau / 12
            color = MAGENTA if index % 2 else CYAN
            draw.line((cx, cy, cx + math.cos(a) * radius, cy + math.sin(a) * radius), fill=color + (230,), width=7)
        draw.ellipse((cx - 30, cy - 30, cx + 30, cy + 30), fill=ORANGE + (255,))
        draw.polygon([(cx, cy - radius - 28), (cx - 25, cy - radius - 72), (cx + 25, cy - radius - 72)], fill=ORANGE + (255,))

    glow(base, paint, 14)


def decorate(base: Image.Image, stage: str, phase: float) -> None:
    draw = ImageDraw.Draw(base)
    if stage == "roulette":
        wheel(base, phase)
    elif stage == "thinking":
        host(base, phase)
        for index in range(3):
            pulse = 10 + 10 * ((phase * 3 - index / 3) % 1)
            x = WIDTH // 2 - 80 + index * 80
            draw.ellipse((x - pulse, 545 - pulse, x + pulse, 545 + pulse), fill=CYAN if index % 2 == 0 else MAGENTA)
    elif stage == "point":
        host(base, phase)
        length = int(250 + 180 * min(1, phase * 3))
        draw.line((WIDTH // 2, 350, WIDTH // 2, 350 + length), fill=ORANGE, width=38)
        draw.polygon([(WIDTH // 2, 650), (WIDTH // 2 - 70, 550), (WIDTH // 2 + 70, 550)], fill=ORANGE)
    elif stage == "laugh":
        host(base, phase * 3, "laugh")
        for side in (-1, 1):
            draw.arc((WIDTH // 2 + side * 210 - 70, 250, WIDTH // 2 + side * 210 + 70, 390), 210 if side < 0 else 30, 330 if side < 0 else 150, fill=CYAN, width=12)
    elif stage == "success":
        host(base, phase * 2, "laugh")
        rng = random.Random(41)
        for _ in range(45):
            x = rng.randrange(120, WIDTH - 120)
            y = int((rng.randrange(HEIGHT) + phase * HEIGHT) % HEIGHT)
            color = [CYAN, MAGENTA, ORANGE][rng.randrange(3)]
            draw.rectangle((x, y, x + 10, y + 24), fill=color)
    elif stage == "fail":
        host(base, phase, "sad")
        size = 70 + int(12 * math.sin(phase * math.tau * 2))
        draw.line((WIDTH // 2 - size, 540 - size, WIDTH // 2 + size, 540 + size), fill=MAGENTA, width=22)
        draw.line((WIDTH // 2 + size, 540 - size, WIDTH // 2 - size, 540 + size), fill=MAGENTA, width=22)
    elif stage == "next":
        offset = int((phase * 180) % 180)
        for index in range(4):
            x = 300 + index * 180 + offset
            draw.line((x, 250, x + 110, 360), fill=CYAN if index % 2 == 0 else MAGENTA, width=28)
            draw.line((x + 110, 360, x, 470), fill=CYAN if index % 2 == 0 else MAGENTA, width=28)
    else:
        host(base, phase)
        draw.arc((WIDTH // 2 - 245, 565, WIDTH // 2 + 245, 690), 190, 350, fill=CYAN, width=10)


def frame(stage: str, label: str, phase: float) -> Image.Image:
    base = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 255))
    decorate(base, stage, phase)
    overlay = Image.new("RGBA", base.size, (0, 0, 0, 0))

    def paint(draw: ImageDraw.ImageDraw) -> None:
        centered_text(draw, label, 590 if stage not in {"idle", "next"} else 545, 48, CYAN + (255,))

    glow(overlay, paint, 12)
    base.alpha_composite(overlay)
    return base.convert("RGB")


def render(stage: str, seconds: int, label: str) -> Path:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    path = OUTPUT / f"chaos_{stage}.mp4"
    container = av.open(str(path), mode="w")
    stream = container.add_stream("libx264", rate=FPS)
    stream.width = WIDTH
    stream.height = HEIGHT
    stream.pix_fmt = "yuv420p"
    stream.options = {"crf": "20", "preset": "medium", "profile": "high"}
    total = seconds * FPS
    for index in range(total):
        image = frame(stage, label, index / total)
        video_frame = av.VideoFrame.from_image(image)
        video_frame.pts = index
        for packet in stream.encode(video_frame):
            container.mux(packet)
    for packet in stream.encode():
        container.mux(packet)
    container.close()
    return path


if __name__ == "__main__":
    for name, (duration, text) in STAGES.items():
        print(render(name, duration, text))
