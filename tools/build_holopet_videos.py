"""Build 720p black-background HOLOPET motion loops from approved key art."""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / ".codex_tmp" / "holopet_pydeps"))

import av
from PIL import Image

WIDTH, HEIGHT, FPS, SECONDS = 1280, 720, 30, 6
ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "holopet"


def smooth(value: float) -> float:
    return value * value * (3 - 2 * value)


def motion(kind: str, phase: float) -> tuple[float, float, float, float, bool]:
    wave = math.sin(phase * math.tau)
    depth = (1 - math.cos(phase * math.tau)) / 2
    if kind == "greet":
        # Walk left-to-right while approaching, then return seamlessly.
        return wave * 190, -depth * 30, 0.72 + depth * 0.25, wave * 2.5, wave < -0.05
    if kind == "feed":
        # Approach the viewer and bowl, pause near the front, then step back.
        pulse = smooth(depth)
        return wave * 55, -pulse * 42, 0.70 + pulse * 0.31, wave * 1.2, False
    if kind == "play":
        # A broad elliptical orbit; scale creates front/back depth.
        front = (math.cos(phase * math.tau) + 1) / 2
        return wave * 235, (1 - front) * -70, 0.68 + front * 0.34, -wave * 4.0, wave < 0
    # Sleeping pet stays calm but breathes and subtly rolls in depth.
    breath = (math.sin(phase * math.tau * 3) + 1) / 2
    return wave * 26, -breath * 8, 0.82 + breath * 0.025, wave * 1.2, False


def render(kind: str) -> Path:
    source = Image.open(ASSETS / f"holopet_{kind}.png").convert("RGB")
    output = ASSETS / f"holopet_{kind}.mp4"
    container = av.open(str(output), mode="w")
    stream = container.add_stream("libx264", rate=FPS)
    stream.width = WIDTH
    stream.height = HEIGHT
    stream.pix_fmt = "yuv420p"
    stream.options = {"crf": "18", "preset": "medium", "profile": "high"}

    for index in range(FPS * SECONDS):
        phase = index / (FPS * SECONDS)
        x, y, scale, angle, mirror = motion(kind, phase)
        image = source.transpose(Image.Transpose.FLIP_LEFT_RIGHT) if mirror else source
        target_h = int(HEIGHT * scale)
        target_w = int(image.width * target_h / image.height)
        image = image.resize((target_w, target_h), Image.Resampling.LANCZOS)
        if angle:
            image = image.rotate(angle, Image.Resampling.BICUBIC, expand=True, fillcolor=(0, 0, 0))
        canvas = Image.new("RGB", (WIDTH, HEIGHT), (0, 0, 0))
        left = int((WIDTH - image.width) / 2 + x)
        top = int((HEIGHT - image.height) / 2 + y)
        canvas.paste(image, (left, top))
        frame = av.VideoFrame.from_image(canvas)
        frame.pts = index
        for packet in stream.encode(frame):
            container.mux(packet)

    for packet in stream.encode():
        container.mux(packet)
    container.close()
    return output


if __name__ == "__main__":
    for action in ("greet", "feed", "play", "sleep"):
        print(render(action))
