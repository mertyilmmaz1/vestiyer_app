"""
VPS Segment Service - Vestiyer garment background removal.
POST /segment with imageUrl -> returns PNG bytes with garment only (white bg).
"""

import hashlib
import io
import logging
import os
from collections import deque
from typing import Dict, Optional, Tuple

import httpx
from fastapi import FastAPI, Header, HTTPException, Request
from fastapi.responses import FileResponse, Response
from fastapi.staticfiles import StaticFiles
from PIL import Image, ImageFilter
from rembg import new_session, remove

app = FastAPI(title="Vestiyer Segment Service")
app.mount("/static", StaticFiles(directory="static"), name="static")


@app.get("/")
async def index():
    return FileResponse("static/index.html")


@app.get("/privacy-policy")
async def privacy_policy():
    return FileResponse("static/privacy-policy.html")


@app.get("/terms-of-service")
async def terms_of_service():
    return FileResponse("static/terms-of-service.html")


logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

API_KEY = os.environ.get("SEGMENT_API_KEY", "")
MAX_IMAGE_SIZE = 1024
OUTPUT_SIZE = 512
ALPHA_THRESHOLD = 24
MIN_COMPONENT_RATIO = 0.0015  # 0.15%
TARGET_INNER_RATIO = 0.84
PRIMARY_MODEL = os.environ.get("REMBG_PRIMARY_MODEL") or os.environ.get("REMBG_MODEL", "isnet-general-use")
FALLBACK_MODEL = os.environ.get("REMBG_FALLBACK_MODEL", "u2net")
SEGMENT_ALGO_V2 = os.environ.get("SEGMENT_ALGO_V2", "false").strip().lower() in {"1", "true", "yes", "on"}
try:
    SEGMENT_ALGO_V2_CANARY_PERCENT = max(
        0,
        min(100, int(os.environ.get("SEGMENT_ALGO_V2_CANARY_PERCENT", "0"))),
    )
except Exception:
    SEGMENT_ALGO_V2_CANARY_PERCENT = 0

_SESSIONS: Dict[str, object] = {}


def _get_session(model_name: str):
    model = (model_name or "isnet-general-use").strip()
    if model not in _SESSIONS:
        _SESSIONS[model] = new_session(model)
    return _SESSIONS[model]


def _clamp(val: float, low: float, high: float) -> float:
    return max(low, min(high, val))


def verify_api_key(x_api_key: Optional[str] = Header(None)) -> None:
    if API_KEY and x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")


def download_image(url: str) -> bytes:
    with httpx.Client(timeout=30.0) as client:
        resp = client.get(url)
        resp.raise_for_status()
        return resp.content


def _is_v2_enabled(seed: str) -> bool:
    if SEGMENT_ALGO_V2:
        return True
    if SEGMENT_ALGO_V2_CANARY_PERCENT <= 0:
        return False
    bucket = int(hashlib.sha1(seed.encode("utf-8")).hexdigest()[:8], 16) % 100
    return bucket < SEGMENT_ALGO_V2_CANARY_PERCENT


def _remove_with_model(input_img: Image.Image, model_name: str) -> Image.Image:
    session = _get_session(model_name)
    return remove(input_img, session=session)


def _component_stats_from_mask(mask: Image.Image) -> Tuple[Image.Image, dict]:
    w, h = mask.size
    total = w * h
    raw = list(mask.getdata())
    visited = bytearray(total)
    min_area = max(1, int(total * MIN_COMPONENT_RATIO))
    components = []

    for idx in range(total):
        if raw[idx] == 0 or visited[idx]:
            continue

        q = deque([idx])
        visited[idx] = 1
        pixels = []
        area = 0
        sum_x = 0
        sum_y = 0
        min_x = w
        min_y = h
        max_x = 0
        max_y = 0

        while q:
            cur = q.popleft()
            pixels.append(cur)
            area += 1
            x = cur % w
            y = cur // w
            sum_x += x
            sum_y += y
            if x < min_x:
                min_x = x
            if y < min_y:
                min_y = y
            if x > max_x:
                max_x = x
            if y > max_y:
                max_y = y

            if x > 0:
                n = cur - 1
                if raw[n] and not visited[n]:
                    visited[n] = 1
                    q.append(n)
            if x < w - 1:
                n = cur + 1
                if raw[n] and not visited[n]:
                    visited[n] = 1
                    q.append(n)
            if y > 0:
                n = cur - w
                if raw[n] and not visited[n]:
                    visited[n] = 1
                    q.append(n)
            if y < h - 1:
                n = cur + w
                if raw[n] and not visited[n]:
                    visited[n] = 1
                    q.append(n)

        components.append(
            {
                "area": area,
                "sum_x": sum_x,
                "sum_y": sum_y,
                "bbox": (min_x, min_y, max_x, max_y),
                "pixels": pixels,
            }
        )

    if not components:
        cleaned = Image.new("L", (w, h), 0)
        return cleaned, {
            "foreground_pixels": 0,
            "foreground_ratio": 0.0,
            "components_count": 0,
            "largest_component_ratio": 0.0,
            "bbox": None,
            "centroid": (w / 2.0, h / 2.0),
            "bbox_center": (w / 2.0, h / 2.0),
        }

    kept = [c for c in components if c["area"] >= min_area]
    if not kept:
        kept = [max(components, key=lambda c: c["area"])]

    cleaned_raw = bytearray(total)
    fg = 0
    sum_x = 0
    sum_y = 0
    min_x = w
    min_y = h
    max_x = 0
    max_y = 0
    largest = 0

    for comp in kept:
        area = comp["area"]
        largest = max(largest, area)
        fg += area
        sum_x += comp["sum_x"]
        sum_y += comp["sum_y"]
        bx1, by1, bx2, by2 = comp["bbox"]
        min_x = min(min_x, bx1)
        min_y = min(min_y, by1)
        max_x = max(max_x, bx2)
        max_y = max(max_y, by2)
        for p in comp["pixels"]:
            cleaned_raw[p] = 255

    cleaned = Image.frombytes("L", (w, h), bytes(cleaned_raw))
    foreground_ratio = fg / total if total > 0 else 0.0
    largest_component_ratio = (largest / fg) if fg > 0 else 0.0
    centroid_x = (sum_x / fg) if fg > 0 else (w / 2.0)
    centroid_y = (sum_y / fg) if fg > 0 else (h / 2.0)
    bbox_center = ((min_x + max_x) / 2.0, (min_y + max_y) / 2.0)

    return cleaned, {
        "foreground_pixels": fg,
        "foreground_ratio": foreground_ratio,
        "components_count": len(kept),
        "largest_component_ratio": largest_component_ratio,
        "bbox": (min_x, min_y, max_x, max_y),
        "centroid": (centroid_x, centroid_y),
        "bbox_center": bbox_center,
    }


def _compute_boundary_edge_energy(mask: Image.Image, source_rgb: Image.Image) -> float:
    w, h = mask.size
    if w < 3 or h < 3:
        return 0.0

    mask_raw = list(mask.getdata())
    lum = source_rgb.convert("L")
    px = lum.load()
    total_energy = 0.0
    boundary_count = 0

    for y in range(1, h - 1):
        row = y * w
        for x in range(1, w - 1):
            idx = row + x
            if mask_raw[idx] == 0:
                continue
            if (
                mask_raw[idx - 1] > 0
                and mask_raw[idx + 1] > 0
                and mask_raw[idx - w] > 0
                and mask_raw[idx + w] > 0
            ):
                continue

            gx = abs(int(px[x + 1, y]) - int(px[x - 1, y]))
            gy = abs(int(px[x, y + 1]) - int(px[x, y - 1]))
            total_energy += (gx + gy) / 2.0
            boundary_count += 1

    if boundary_count == 0:
        return 0.0
    return total_energy / boundary_count


def _confidence_from_stats(stats: dict) -> Tuple[float, bool]:
    fg_ratio = stats["foreground_ratio"]
    largest_ratio = stats["largest_component_ratio"]
    edge_energy = stats["edge_energy"]

    low_fg = fg_ratio < 0.03 or fg_ratio > 0.85
    weak_component = largest_ratio < 0.6
    weak_edge = edge_energy < 7.0

    score = 1.0
    if low_fg:
        score -= 0.45
    if weak_component:
        score -= 0.25
    if weak_edge:
        score -= 0.25
    if stats["components_count"] > 10:
        score -= 0.10

    return _clamp(score, 0.0, 1.0), bool(low_fg or weak_component or weak_edge)


def _quality_score(stats: dict) -> float:
    fg_ratio = stats["foreground_ratio"]
    edge_norm = _clamp(stats["edge_energy"] / 24.0, 0.0, 1.0)
    component_norm = _clamp(stats["largest_component_ratio"] / 0.9, 0.0, 1.0)
    fg_penalty = 0.0 if (0.05 <= fg_ratio <= 0.70) else 0.15
    return _clamp((0.6 * edge_norm) + (0.4 * component_norm) - fg_penalty, 0.0, 1.0)


def _normalize_to_canvas(output_rgba: Image.Image, clean_mask: Image.Image, stats: dict) -> Image.Image:
    bbox = stats["bbox"]
    if not bbox:
        white = Image.new("RGB", (OUTPUT_SIZE, OUTPUT_SIZE), (255, 255, 255))
        return white

    min_x, min_y, max_x, max_y = bbox
    obj_w = max_x - min_x + 1
    obj_h = max_y - min_y + 1
    short_side = min(obj_w, obj_h)
    pad = int(_clamp(short_side * 0.08, 6, 28))

    w, h = output_rgba.size
    left = max(0, min_x - pad)
    top = max(0, min_y - pad)
    right = min(w - 1, max_x + pad)
    bottom = min(h - 1, max_y + pad)

    crop_box = (left, top, right + 1, bottom + 1)
    cropped_rgba = output_rgba.crop(crop_box)
    cropped_mask = clean_mask.crop(crop_box)

    cw, ch = cropped_rgba.size
    if cw <= 0 or ch <= 0:
        white = Image.new("RGB", (OUTPUT_SIZE, OUTPUT_SIZE), (255, 255, 255))
        return white

    target_inner = int(OUTPUT_SIZE * TARGET_INNER_RATIO)
    scale = target_inner / float(max(cw, ch))
    new_w = max(1, int(round(cw * scale)))
    new_h = max(1, int(round(ch * scale)))

    resized_rgba = cropped_rgba.resize((new_w, new_h), Image.Resampling.LANCZOS)
    resized_mask = cropped_mask.resize((new_w, new_h), Image.Resampling.BILINEAR)
    resized_rgba.putalpha(resized_mask)

    centroid_x, centroid_y = stats["centroid"]
    bbox_center_x, bbox_center_y = stats["bbox_center"]

    local_centroid_x = (centroid_x - left) * scale
    local_centroid_y = (centroid_y - top) * scale
    local_bbox_x = (bbox_center_x - left) * scale
    local_bbox_y = (bbox_center_y - top) * scale

    mixed_x = (0.7 * local_centroid_x) + (0.3 * local_bbox_x)
    mixed_y = (0.7 * local_centroid_y) + (0.3 * local_bbox_y)

    center = (OUTPUT_SIZE - 1) / 2.0
    x_off = int(round(center - mixed_x))
    y_off = int(round(center - mixed_y))

    x_off = int(_clamp(x_off, -new_w + 1, OUTPUT_SIZE - 1))
    y_off = int(_clamp(y_off, -new_h + 1, OUTPUT_SIZE - 1))

    transparent = Image.new("RGBA", (OUTPUT_SIZE, OUTPUT_SIZE), (0, 0, 0, 0))
    transparent.paste(resized_rgba, (x_off, y_off), resized_rgba.split()[3])

    white_bg = Image.new("RGBA", (OUTPUT_SIZE, OUTPUT_SIZE), (255, 255, 255, 255))
    white_bg.alpha_composite(transparent)
    return white_bg.convert("RGB")


def _process_with_model(input_img: Image.Image, source_rgb: Image.Image, model_name: str) -> dict:
    output_rgba = _remove_with_model(input_img, model_name)
    alpha = output_rgba.split()[3]
    binary = alpha.point(lambda p: 255 if p >= ALPHA_THRESHOLD else 0, mode="L")
    clean = binary.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(3))

    clean_mask, stats = _component_stats_from_mask(clean)
    stats["edge_energy"] = _compute_boundary_edge_energy(clean_mask, source_rgb)
    confidence_score, low_conf = _confidence_from_stats(stats)
    stats["confidence_score"] = confidence_score
    stats["low_confidence"] = low_conf
    stats["quality_score"] = _quality_score(stats)

    final_rgb = _normalize_to_canvas(output_rgba, clean_mask, stats)
    buf = io.BytesIO()
    final_rgb.save(buf, format="PNG", optimize=True)

    return {
        "image_bytes": buf.getvalue(),
        "model": model_name,
        "stats": stats,
    }


def _process_v1(image_bytes: bytes) -> Tuple[bytes, dict]:
    input_img = Image.open(io.BytesIO(image_bytes)).convert("RGBA")
    input_img.thumbnail((MAX_IMAGE_SIZE, MAX_IMAGE_SIZE), Image.Resampling.LANCZOS)

    output_img = _remove_with_model(input_img, PRIMARY_MODEL)

    white_bg = Image.new("RGBA", output_img.size, (255, 255, 255, 255))
    white_bg.paste(output_img, mask=output_img.split()[3])
    result = white_bg.convert("RGB")

    pixels = result.load()
    w, h = result.size
    min_x, min_y = w, h
    max_x, max_y = 0, 0
    for x in range(w):
        for y in range(h):
            r, g, b = pixels[x, y]
            if r < 250 or g < 250 or b < 250:
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)

    if max_x <= min_x or max_y <= min_y:
        cropped = result
    else:
        obj_w = max_x - min_x
        obj_h = max_y - min_y
        pad_x = int(obj_w * 0.05)
        pad_y = int(obj_h * 0.05)
        min_x = max(0, min_x - pad_x)
        min_y = max(0, min_y - pad_y)
        max_x = min(w, max_x + pad_x)
        max_y = min(h, max_y + pad_y)
        cropped = result.crop((min_x, min_y, max_x, max_y))

    cw, ch = cropped.size
    target_inner_size = int(OUTPUT_SIZE * 0.85)
    scale = target_inner_size / max(cw, ch)
    new_w = int(cw * scale)
    new_h = int(ch * scale)
    cropped_resized = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)

    new_img = Image.new("RGB", (OUTPUT_SIZE, OUTPUT_SIZE), (255, 255, 255))
    x_off = (OUTPUT_SIZE - new_w) // 2
    y_off = (OUTPUT_SIZE - new_h) // 2
    new_img.paste(cropped_resized, (x_off, y_off))

    buf = io.BytesIO()
    new_img.save(buf, format="PNG", optimize=True)
    telemetry = {
        "model_used": PRIMARY_MODEL,
        "fallback_used": False,
        "foreground_ratio": 0.0,
        "components_count": 0,
        "confidence_score": 0.5,
        "largest_component_ratio": 0.0,
        "edge_energy": 0.0,
        "algo_version": "v1",
    }
    return buf.getvalue(), telemetry


def remove_background_and_crop(image_bytes: bytes, canary_seed: str) -> Tuple[bytes, dict]:
    if not _is_v2_enabled(canary_seed):
        return _process_v1(image_bytes)

    input_img = Image.open(io.BytesIO(image_bytes)).convert("RGBA")
    input_img.thumbnail((MAX_IMAGE_SIZE, MAX_IMAGE_SIZE), Image.Resampling.LANCZOS)
    source_rgb = input_img.convert("RGB")

    primary = _process_with_model(input_img, source_rgb, PRIMARY_MODEL)
    chosen = primary
    fallback_used = False

    if primary["stats"]["low_confidence"] and FALLBACK_MODEL != PRIMARY_MODEL:
        fallback = _process_with_model(input_img, source_rgb, FALLBACK_MODEL)
        if fallback["stats"]["quality_score"] >= primary["stats"]["quality_score"]:
            chosen = fallback
        fallback_used = True

    telemetry = {
        "model_used": chosen["model"],
        "fallback_used": fallback_used,
        "foreground_ratio": round(chosen["stats"]["foreground_ratio"], 4),
        "components_count": chosen["stats"]["components_count"],
        "confidence_score": round(chosen["stats"]["confidence_score"], 4),
        "largest_component_ratio": round(chosen["stats"]["largest_component_ratio"], 4),
        "edge_energy": round(chosen["stats"]["edge_energy"], 4),
        "algo_version": "v2",
    }
    return chosen["image_bytes"], telemetry


@app.get("/health")
async def health():
    return {
        "status": "ok",
        "algo": "v2" if SEGMENT_ALGO_V2 else "v1_or_canary",
        "v2_canary_percent": SEGMENT_ALGO_V2_CANARY_PERCENT,
    }


@app.post("/segment")
async def segment(
    request: Request,
    x_api_key: Optional[str] = Header(None),
):
    import time

    verify_api_key(x_api_key)

    body = await request.json()
    image_url = body.get("imageUrl")
    if not image_url or not isinstance(image_url, str):
        raise HTTPException(status_code=400, detail="imageUrl required")

    canary_seed = image_url
    logging.info("Segment request received. URL length: %s", len(image_url))

    try:
        t0 = time.time()
        image_bytes = download_image(image_url)
        dl_ms = int((time.time() - t0) * 1000)
        logging.info("Image downloaded: %s bytes in %sms", len(image_bytes), dl_ms)
    except Exception as e:
        logging.error("Image download failed: %s", e)
        raise HTTPException(status_code=400, detail=f"Failed to fetch image: {e}")

    try:
        t0 = time.time()
        result_png, telemetry = remove_background_and_crop(image_bytes, canary_seed=canary_seed)
        proc_ms = int((time.time() - t0) * 1000)
        telemetry["process_ms"] = proc_ms
        telemetry["input_size"] = len(image_bytes)
        telemetry["output_size"] = len(result_png)
        logging.info("Segment telemetry: %s", telemetry)
    except Exception as e:
        logging.error("Background removal failed: %s", e)
        raise HTTPException(status_code=500, detail=f"Background removal failed: {e}")

    headers = {
        "X-Segment-Model": str(telemetry.get("model_used", "unknown")),
        "X-Segment-Confidence": str(telemetry.get("confidence_score", 0.0)),
        "X-Segment-Fallback": "true" if telemetry.get("fallback_used") else "false",
    }
    return Response(content=result_png, media_type="image/png", headers=headers)
