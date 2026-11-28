#!/usr/bin/env python3
"""
Render theme-adapted frosted-glass Plymouth assets (logo, card, entry pill,
lock icon, bullets, progress track/fill/pulse, and palette-injected script)
from a JSON palette and optional custom SVG logo.
"""

from __future__ import annotations

import argparse
import json
import math
import shutil
import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


def hex_to_rgb(value: str, fallback: tuple[int, int, int]) -> tuple[int, int, int]:
    if not isinstance(value, str):
        return fallback
    s = value.strip().lstrip("#")
    if len(s) != 6:
        return fallback
    try:
        return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16))
    except ValueError:
        return fallback


def rgba(rgb: tuple[int, int, int], alpha: int) -> tuple[int, int, int, int]:
    return (rgb[0], rgb[1], rgb[2], max(0, min(255, alpha)))


def blend(c1: tuple[int, int, int], c2: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return (
        int(round(c1[0] + (c2[0] - c1[0]) * t)),
        int(round(c1[1] + (c2[1] - c1[1]) * t)),
        int(round(c1[2] + (c2[2] - c1[2]) * t)),
    )


def luminance(rgb: tuple[int, int, int]) -> float:
    return (0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]) / 255.0


def ensure_contrast(rgb: tuple[int, int, int], against: tuple[int, int, int], fg: tuple[int, int, int], min_diff: float) -> tuple[int, int, int]:
    if abs(luminance(rgb) - luminance(against)) >= min_diff:
        return rgb
    for step in range(1, 11):
        cand = blend(rgb, fg, step * 0.1)
        if abs(luminance(cand) - luminance(against)) >= min_diff:
            return cand
    return blend(rgb, fg, 0.65)


def load_palette(colors_path: Path) -> dict[str, object]:
    defaults = {
        "mode": "dark",
        "background": "#08090d",
        "lighterBg": "#141824",
        "foreground": "#f1f5f9",
        "secondary": "#94a3b8",
        "muted": "#64748b",
        "accent": "#38bdf8",
        "accentHover": "#60a5fa",
        "red": "#f87171",
    }
    if colors_path.is_file():
        try:
            loaded = json.loads(colors_path.read_text(encoding="utf-8"))
            if isinstance(loaded, dict):
                defaults.update({k: v for k, v in loaded.items() if v})
        except Exception:
            pass
    bg = hex_to_rgb(str(defaults["background"]), (8, 9, 13))
    is_light = str(defaults.get("mode", "")).lower() == "light" or luminance(bg) > 0.55
    lighter_bg = hex_to_rgb(str(defaults["lighterBg"]), blend(bg, (255, 255, 255), 0.08))
    fg = hex_to_rgb(str(defaults["foreground"]), (15, 23, 42) if is_light else (241, 245, 249))
    sec_raw = hex_to_rgb(str(defaults["secondary"]), (71, 85, 105) if is_light else (148, 163, 184))
    mut_raw = hex_to_rgb(str(defaults["muted"]), (100, 116, 139))
    return {
        "is_light": is_light,
        "bg": bg,
        "lighter_bg": lighter_bg,
        "fg": fg,
        "sec": ensure_contrast(sec_raw, lighter_bg, fg, 0.34),
        "muted": ensure_contrast(mut_raw, lighter_bg, fg, 0.24),
        "accent": hex_to_rgb(str(defaults["accent"]), (56, 189, 248)),
        "accent_hover": hex_to_rgb(str(defaults["accentHover"]), (96, 165, 250)),
        "fg_hex": str(defaults["foreground"]),
        "accent_hex": str(defaults["accent"]),
    }


def render_svg_png(svg_text: str, out_path: Path, size: int) -> None:
    renderer = shutil.which("resvg") or shutil.which("rsvg-convert")
    if not renderer:
        raise RuntimeError("Missing SVG renderer: install resvg or librsvg (rsvg-convert)")
    with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False, encoding="utf-8") as tmp:
        tmp.write(svg_text)
        tmp_path = Path(tmp.name)
    try:
        if Path(renderer).name == "resvg":
            cmd = [renderer, "-w", str(size), "-h", str(size), str(tmp_path), str(out_path)]
        else:
            cmd = [renderer, "-w", str(size), "-h", str(size), "-o", str(out_path), str(tmp_path)]
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    finally:
        tmp_path.unlink(missing_ok=True)


def make_rounded_mask(w: int, h: int, radius: int, scale: int = 4) -> Image.Image:
    big = Image.new("L", (w * scale, h * scale), 0)
    d = ImageDraw.Draw(big)
    d.rounded_rectangle([0, 0, w * scale - 1, h * scale - 1], radius=radius * scale, fill=255)
    return big.resize((w, h), Image.Resampling.LANCZOS)


def render_frosted_card(out_path: Path, pal: dict[str, object], bg_image_path: Path | None) -> None:
    inner_w, inner_h = 420, 276
    pad = 24
    w, h = inner_w + pad * 2, inner_h + pad * 2
    radius = 26

    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle(
        [pad, pad + 6, pad + inner_w - 1, pad + inner_h + 5],
        radius=radius,
        fill=(0, 0, 0, 90 if pal["is_light"] else 145),
    )
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(14)))

    glass = Image.new("RGBA", (inner_w, inner_h), (0, 0, 0, 0))
    px = glass.load()
    top_rgb, bot_rgb, fg_rgb = pal["lighter_bg"], pal["bg"], pal["fg"]
    is_light = bool(pal["is_light"])
    alpha_top = 212 if is_light else 196
    alpha_bot = 228 if is_light else 218

    crop_px = None
    if bg_image_path and bg_image_path.is_file():
        try:
            with Image.open(bg_image_path) as bg_img:
                bg_rgba = bg_img.convert("RGBA").resize((1920, 1080), Image.Resampling.BILINEAR)
                cx = (1920 - inner_w) // 2
                cy = (1080 - inner_h) // 2 + 44
                crop_px = bg_rgba.crop((cx, cy, cx + inner_w, cy + inner_h)).filter(ImageFilter.GaussianBlur(28)).load()
        except Exception:
            crop_px = None

    for y in range(inner_h):
        t = y / max(1, inner_h - 1)
        base_rgb = blend(top_rgb, bot_rgb, t)
        a = int(round(alpha_top + (alpha_bot - alpha_top) * t))
        sheen = max(0.0, 1.0 - t * 2.2) * (0.10 if is_light else 0.055)
        tinted = blend(base_rgb, (255, 255, 255) if is_light else fg_rgb, sheen)
        for x in range(inner_w):
            if crop_px is not None:
                br, bg_c, bb, _ = crop_px[x, y]
                px[x, y] = (
                    int(round(tinted[0] * 0.82 + br * 0.18)),
                    int(round(tinted[1] * 0.82 + bg_c * 0.18)),
                    int(round(tinted[2] * 0.82 + bb * 0.18)),
                    a,
                )
            else:
                px[x, y] = (tinted[0], tinted[1], tinted[2], a)

    mask = make_rounded_mask(inner_w, inner_h, radius)
    glass.putalpha(Image.composite(glass.getchannel("A"), Image.new("L", (inner_w, inner_h), 0), mask))
    canvas.alpha_composite(glass, (pad, pad))

    scale = 2
    borders = Image.new("RGBA", (w * scale, h * scale), (0, 0, 0, 0))
    bd = ImageDraw.Draw(borders)
    rim_color = blend(pal["accent"], fg_rgb, 0.18)
    bd.rounded_rectangle(
        [pad * scale, pad * scale, (pad + inner_w) * scale - 1, (pad + inner_h) * scale - 1],
        radius=radius * scale,
        outline=rgba(rim_color, 110 if is_light else 88),
        width=2,
    )
    spec_color = (255, 255, 255) if is_light else fg_rgb
    bd.rounded_rectangle(
        [(pad + 1) * scale, (pad + 1) * scale, (pad + inner_w - 1) * scale - 1, (pad + inner_h - 1) * scale - 1],
        radius=(radius - 1) * scale,
        outline=rgba(spec_color, 95 if is_light else 36),
        width=2,
    )
    canvas.alpha_composite(borders.resize((w, h), Image.Resampling.LANCZOS))
    canvas.save(out_path)


def render_entry_pill(out_path: Path, pal: dict[str, object]) -> None:
    w, h, scale = 312, 48, 4
    img = Image.new("RGBA", (w * scale, h * scale), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    is_light = bool(pal["is_light"])
    fill_rgb = blend(pal["lighter_bg"], (255, 255, 255), 0.45) if is_light else blend(pal["bg"], (0, 0, 0), 0.35)
    d.rounded_rectangle(
        [2, 2, w * scale - 3, h * scale - 3],
        radius=14 * scale,
        fill=rgba(fill_rgb, 175 if is_light else 155),
        outline=rgba(pal["accent"], 150 if is_light else 120),
        width=4,
    )
    img.resize((w, h), Image.Resampling.LANCZOS).save(out_path)


def render_bullet(out_path: Path, pal: dict[str, object]) -> None:
    size, scale = 16, 4
    img = Image.new("RGBA", (size * scale, size * scale), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([4, 4, size * scale - 5, size * scale - 5], fill=rgba(blend(pal["fg"], pal["accent"], 0.25), 245))
    img.resize((size, size), Image.Resampling.LANCZOS).save(out_path)


def render_progress_assets(box_path: Path, bar_path: Path, pulse_path: Path, pal: dict[str, object]) -> None:
    w, h, scale = 260, 6, 4
    is_light = bool(pal["is_light"])
    box = Image.new("RGBA", (w * scale, h * scale), (0, 0, 0, 0))
    ImageDraw.Draw(box).rounded_rectangle(
        [0, 0, w * scale - 1, h * scale - 1],
        radius=(h * scale) // 2,
        fill=rgba(pal["muted"], 90 if is_light else 110),
    )
    box.resize((w, h), Image.Resampling.LANCZOS).save(box_path)

    bar = Image.new("RGBA", (w * scale, h * scale), (0, 0, 0, 0))
    bpx = bar.load()
    for x in range(w * scale):
        c = blend(pal["accent"], pal["accent_hover"], x / max(1, w * scale - 1))
        for y in range(h * scale):
            bpx[x, y] = rgba(c, 245)
    bar.putalpha(make_rounded_mask(w * scale, h * scale, (h * scale) // 2, scale=1))
    bar.resize((w, h), Image.Resampling.LANCZOS).save(bar_path)

    pw, ph = 84, 6
    pulse = Image.new("RGBA", (pw * scale, ph * scale), (0, 0, 0, 0))
    ppx = pulse.load()
    hi = blend(pal["accent_hover"], pal["fg"], 0.25)
    for x in range(pw * scale):
        u = x / max(1, pw * scale - 1)
        env = math.sin(u * math.pi)
        c = blend(pal["accent"], hi, env)
        a = int(round(245 * (env ** 0.6)))
        for y in range(ph * scale):
            ppx[x, y] = rgba(c, a)
    pmask = make_rounded_mask(pw * scale, ph * scale, (ph * scale) // 2, scale=1)
    pulse.putalpha(Image.composite(pulse.getchannel("A"), Image.new("L", (pw * scale, ph * scale), 0), pmask))
    pulse.resize((pw, ph), Image.Resampling.LANCZOS).save(pulse_path)


def render_lock_icon(out_path: Path, pal: dict[str, object]) -> None:
    lock_svg = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="{pal['accent_hex']}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
  <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
</svg>"""
    render_svg_png(lock_svg, out_path, 28)


def write_plymouth_script(script_tpl_path: Path, out_script_path: Path, pal: dict[str, object], brand_title: str, crypt_label: str) -> None:
    def f3(rgb: tuple[int, int, int]) -> tuple[str, str, str]:
        return (f"{rgb[0] / 255.0:.4f}", f"{rgb[1] / 255.0:.4f}", f"{rgb[2] / 255.0:.4f}")

    bg_r, bg_g, bg_b = f3(pal["bg"])
    fg_r, fg_g, fg_b = f3(pal["fg"])
    sec_r, sec_g, sec_b = f3(pal["sec"])
    mut_r, mut_g, mut_b = f3(pal["muted"])
    acc_r, acc_g, acc_b = f3(pal["accent"])

    tpl = script_tpl_path.read_text(encoding="utf-8")
    rendered = (
        tpl.replace("{{BG_R}}", bg_r).replace("{{BG_G}}", bg_g).replace("{{BG_B}}", bg_b)
        .replace("{{FG_R}}", fg_r).replace("{{FG_G}}", fg_g).replace("{{FG_B}}", fg_b)
        .replace("{{SEC_R}}", sec_r).replace("{{SEC_G}}", sec_g).replace("{{SEC_B}}", sec_b)
        .replace("{{MUT_R}}", mut_r).replace("{{MUT_G}}", mut_g).replace("{{MUT_B}}", mut_b)
        .replace("{{ACC_R}}", acc_r).replace("{{ACC_G}}", acc_g).replace("{{ACC_B}}", acc_b)
        .replace("{{BRAND_WORDMARK}}", " ".join(brand_title.upper()))
        .replace("{{CRYPT_LABEL}}", crypt_label)
    )
    out_script_path.write_text(rendered, encoding="utf-8")


def main() -> None:
    root = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--colors", default="/var/cache/multienv/colors.json")
    parser.add_argument("--logo-tpl", default=str(root / "multienv-logo.svg.tpl"))
    parser.add_argument("--script-tpl", default=str(root / "multienv.script.tpl"))
    parser.add_argument("--out-dir", default="/usr/share/plymouth/themes/multienv-monolith")
    parser.add_argument("--bg-image", default="")
    parser.add_argument("--brand", default="MULTIENV")
    parser.add_argument("--crypt-label", default="LUKS2 Encrypted Root")
    args = parser.parse_args()

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    pal = load_palette(Path(args.colors))

    logo_tpl_path = Path(args.logo_tpl)
    if logo_tpl_path.suffix == ".tpl" or "{FG}" in logo_tpl_path.read_text(encoding="utf-8"):
        logo_svg = logo_tpl_path.read_text(encoding="utf-8").format(FG=pal["fg_hex"], ACCENT=pal["accent_hex"])
    else:
        logo_svg = logo_tpl_path.read_text(encoding="utf-8")
    render_svg_png(logo_svg, out_dir / "logo.png", 96)

    bg_path = Path(args.bg_image) if args.bg_image else (out_dir / "background.png")
    if not bg_path.is_file():
        # Create solid theme canvas fallback if no wallpaper is supplied
        Image.new("RGBA", (1920, 1080), rgba(pal["bg"], 255)).save(out_dir / "background.png")
        bg_path = out_dir / "background.png"

    render_frosted_card(out_dir / "card.png", pal, bg_path)
    render_entry_pill(out_dir / "entry.png", pal)
    render_lock_icon(out_dir / "lock.png", pal)
    render_bullet(out_dir / "bullet.png", pal)
    render_progress_assets(
        out_dir / "progress_box.png",
        out_dir / "progress_bar.png",
        out_dir / "pulse_pill.png",
        pal,
    )

    script_tpl = Path(args.script_tpl)
    if script_tpl.is_file():
        write_plymouth_script(script_tpl, out_dir / "multienv-monolith.script", pal, args.brand, args.crypt_label)


if __name__ == "__main__":
    main()
