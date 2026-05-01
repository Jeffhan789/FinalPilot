#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter, ImageOps


ROOT = Path.cwd()
ICON_DIR = ROOT / "FinalPilotApp" / "Assets.xcassets" / "AppIcon.appiconset"
PREVIEW_DIR = ROOT / "design" / "reference_icon"

ICON_SPECS = [
    ("Icon-20@2x.png", 40),
    ("Icon-20@3x.png", 60),
    ("Icon-29@2x.png", 58),
    ("Icon-29@3x.png", 87),
    ("Icon-40@2x.png", 80),
    ("Icon-40@3x.png", 120),
    ("Icon-60@2x.png", 120),
    ("Icon-60@3x.png", 180),
    ("Icon-76.png", 76),
    ("Icon-76@2x.png", 152),
    ("Icon-83.5@2x.png", 167),
    ("Icon-1024.png", 1024),
]

APP_WHITE = np.array([251, 252, 254], dtype=np.uint8)
APP_WHITE_BOTTOM = np.array([245, 248, 255], dtype=np.uint8)


def usage() -> None:
    print("Usage: python3 tools/generate_icon_from_reference.py <reference-image-path>", file=sys.stderr)
    raise SystemExit(2)


def rgb_to_hsb(rgb: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    maximum = rgb.max(axis=2)
    minimum = rgb.min(axis=2)
    delta = maximum - minimum

    hue = np.zeros_like(maximum)
    red, green, blue = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    nonzero = delta > 1e-6

    red_is_max = (maximum == red) & nonzero
    green_is_max = (maximum == green) & nonzero
    blue_is_max = (maximum == blue) & nonzero

    hue[red_is_max] = 60 * np.mod((green[red_is_max] - blue[red_is_max]) / delta[red_is_max], 6)
    hue[green_is_max] = 60 * (((blue[green_is_max] - red[green_is_max]) / delta[green_is_max]) + 2)
    hue[blue_is_max] = 60 * (((red[blue_is_max] - green[blue_is_max]) / delta[blue_is_max]) + 4)

    saturation = np.zeros_like(maximum)
    saturation[maximum > 1e-6] = delta[maximum > 1e-6] / maximum[maximum > 1e-6]
    return hue, saturation, maximum


def blue_score(rgb: np.ndarray) -> np.ndarray:
    red, green, blue = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    hue, saturation, brightness = rgb_to_hsb(rgb)

    base_mask = (
        (hue >= 185)
        & (hue <= 235)
        & (saturation > 0.24)
        & (blue > red * 1.35)
        & (blue > green * 1.03)
        & (brightness > 0.22)
    )

    hue_score = np.clip(1 - np.abs(hue - 207) / 34, 0, 1)
    saturation_score = np.clip((saturation - 0.20) / 0.55, 0, 1)
    dominance_score = np.clip((blue - red * 1.20) / 0.45, 0, 1)
    score = 0.25 + 0.30 * hue_score + 0.30 * saturation_score + 0.15 * dominance_score
    return np.where(base_mask, np.clip(score, 0, 1), 0)


def hex_color(rgb: np.ndarray) -> str:
    values = np.clip(np.round(rgb * 255), 0, 255).astype(int)
    return f"#{values[0]:02X}{values[1]:02X}{values[2]:02X}"


def make_background(size: int) -> Image.Image:
    y = np.linspace(0, 1, size, dtype=np.float32)[:, None]
    top = APP_WHITE.astype(np.float32)
    bottom = APP_WHITE_BOTTOM.astype(np.float32)
    row = (top * (1 - y) + bottom * y).astype(np.uint8)
    background = np.repeat(row[:, None, :], size, axis=1)
    return Image.fromarray(background, mode="RGB").convert("RGBA")


def make_reference_mark(source: Image.Image) -> tuple[Image.Image, np.ndarray, int]:
    rgb = np.asarray(source).astype(np.float32) / 255.0
    score = blue_score(rgb)
    selected = score > 0.20

    if not np.any(selected):
        raise SystemExit("No blue marker region detected in reference image.")

    ys, xs = np.where(selected)
    min_x, max_x = xs.min(), xs.max()
    min_y, max_y = ys.min(), ys.max()

    pad_x = int((max_x - min_x + 1) * 0.025)
    pad_y = int((max_y - min_y + 1) * 0.030)
    min_x = max(0, min_x - pad_x)
    max_x = min(source.width - 1, max_x + pad_x)
    min_y = max(0, min_y - pad_y)
    max_y = min(source.height - 1, max_y + pad_y)

    crop_rgb = rgb[min_y : max_y + 1, min_x : max_x + 1]
    crop_score = score[min_y : max_y + 1, min_x : max_x + 1]

    weights = crop_score[crop_score > 0.20]
    pixels = crop_rgb[crop_score > 0.20]
    sampled = (pixels * weights[:, None]).sum(axis=0) / weights.sum()
    sampled = sampled.copy()
    sampled[0] = max(0.02, sampled[0] * 0.82)
    sampled[1] = min(0.42, sampled[1] * 1.03)
    sampled[2] = min(0.72, sampled[2] * 1.08)

    alpha = np.clip((crop_score**0.62) * 1.10, 0, 1)
    alpha = np.where(crop_score > 0.12, alpha, 0)
    alpha_image = Image.fromarray((alpha * 255).astype(np.uint8), mode="L")
    alpha_image = alpha_image.filter(ImageFilter.GaussianBlur(radius=0.45))

    marker = np.zeros((crop_rgb.shape[0], crop_rgb.shape[1], 4), dtype=np.uint8)
    marker[:, :, :3] = np.clip(np.round(sampled * 255), 0, 255).astype(np.uint8)
    marker[:, :, 3] = np.asarray(alpha_image)

    return Image.fromarray(marker, mode="RGBA"), sampled, int(selected.sum())


def render_icon(size: int, marker: Image.Image, sampled_blue: np.ndarray) -> Image.Image:
    canvas = make_background(size)
    max_side = int(size * 0.84)
    marker_ratio = marker.width / marker.height
    if marker_ratio >= 1:
        target_w = max_side
        target_h = round(max_side / marker_ratio)
    else:
        target_h = max_side
        target_w = round(max_side * marker_ratio)

    resized = marker.resize((target_w, target_h), Image.Resampling.LANCZOS)
    x = (size - target_w) // 2
    y = (size - target_h) // 2 - round(size * 0.01)

    alpha = resized.getchannel("A")
    shadow_alpha = alpha.filter(ImageFilter.GaussianBlur(radius=max(1, size * 0.022)))
    shadow_color = np.clip(np.round(sampled_blue * np.array([0.22, 0.24, 0.35]) * 255), 0, 255).astype(np.uint8)
    shadow = Image.new("RGBA", resized.size, (*shadow_color.tolist(), 0))
    shadow.putalpha(shadow_alpha.point(lambda value: int(value * 0.22)))

    canvas.alpha_composite(shadow, (x, y + round(size * 0.012)))
    canvas.alpha_composite(resized, (x, y))
    return canvas.convert("RGB")


def main() -> None:
    if len(sys.argv) < 2:
        usage()

    source_path = Path(sys.argv[1]).expanduser()
    if not source_path.exists():
        raise SystemExit(f"Reference image not found: {source_path}")

    ICON_DIR.mkdir(parents=True, exist_ok=True)
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)

    source = ImageOps.exif_transpose(Image.open(source_path)).convert("RGB")
    marker, sampled_blue, mask_pixels = make_reference_mark(source)

    for name, size in ICON_SPECS:
        render_icon(size, marker, sampled_blue).save(ICON_DIR / name, "PNG", optimize=True)

    preview = render_icon(1024, marker, sampled_blue)
    preview.save(PREVIEW_DIR / "FinalPilot_reference_extracted_icon.png", "PNG", optimize=True)

    readme = f"""# FinalPilot 手绘参考图标提取

生成日期：2026-05-01

本图标由用户提供的手绘参考图提取蓝色笔迹区域生成。脚本只提交处理后的图标，不提交原始照片。

- 背景白色：`#FBFCFE`
- 提取蓝色：`{hex_color(sampled_blue)}`
- 蓝色像素数量：{mask_pixels}
- 输出预览：`FinalPilot_reference_extracted_icon.png`

正式 AppIcon 已写入：`FinalPilotApp/Assets.xcassets/AppIcon.appiconset/`
"""
    (PREVIEW_DIR / "README.md").write_text(readme, encoding="utf-8")

    print("Generated hand-drawn reference icon.")
    print(f"Sampled blue: {hex_color(sampled_blue)}")
    print(f"Mask pixels: {mask_pixels}")


if __name__ == "__main__":
    main()
