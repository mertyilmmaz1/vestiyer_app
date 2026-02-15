"""
VPS Segment Service – Vestiyer garment background removal.
POST /segment with imageUrl → returns base64 PNG with garment only (white bg).
"""

import base64
import logging
import io
import os
from typing import Optional

import httpx
from fastapi import FastAPI, Header, HTTPException, Request
from PIL import Image
from rembg import remove, new_session

app = FastAPI(title="Vestiyer Segment Service")
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

API_KEY = os.environ.get("SEGMENT_API_KEY", "")
REMBG_MODEL = os.environ.get("REMBG_MODEL", "u2net")  # u2net, u2netp, isnet-general-use
_rembg_session = new_session(REMBG_MODEL)
MAX_IMAGE_SIZE = 1024
OUTPUT_SIZE = 512


def verify_api_key(x_api_key: Optional[str] = Header(None)) -> None:
    if API_KEY and x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")


def download_image(url: str) -> bytes:
    with httpx.Client(timeout=30.0) as client:
        resp = client.get(url)
        resp.raise_for_status()
        return resp.content


def remove_background_and_crop(image_bytes: bytes) -> bytes:
    input_img = Image.open(io.BytesIO(image_bytes)).convert("RGBA")
    input_img.thumbnail((MAX_IMAGE_SIZE, MAX_IMAGE_SIZE), Image.Resampling.LANCZOS)

    output_img = remove(input_img, session=_rembg_session)

    # Composite onto white background
    white_bg = Image.new("RGBA", output_img.size, (255, 255, 255, 255))
    white_bg.paste(output_img, mask=output_img.split()[3])
    result = white_bg.convert("RGB")

    # Get bounding box of non-white pixels (garment)
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
        logging.warning(
            "Segment: no garment pixels found (empty bbox), using full image. "
            "rembg may have failed or image was blank."
        )
        cropped = result
    else:
        padding = 10
        min_x = max(0, min_x - padding)
        min_y = max(0, min_y - padding)
        max_x = min(w, max_x + padding)
        max_y = min(h, max_y + padding)
        cropped = result.crop((min_x, min_y, max_x, max_y))

    # Resize to square (1:1), max OUTPUT_SIZE
    cw, ch = cropped.size
    side = min(max(cw, ch), OUTPUT_SIZE)
    new_img = Image.new("RGB", (side, side), (255, 255, 255))
    cropped.thumbnail((side, side), Image.Resampling.LANCZOS)
    ncw, nch = cropped.size
    x_off = (side - ncw) // 2
    y_off = (side - nch) // 2
    new_img.paste(cropped, (x_off, y_off))

    buf = io.BytesIO()
    new_img.save(buf, format="PNG", optimize=True)
    return buf.getvalue()


@app.get("/health")
async def health():
    return {"status": "ok"}


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

    logging.info(f"Segment request received. URL length: {len(image_url)}")

    try:
        t0 = time.time()
        image_bytes = download_image(image_url)
        dl_ms = int((time.time() - t0) * 1000)
        logging.info(f"Image downloaded: {len(image_bytes)} bytes in {dl_ms}ms")
    except Exception as e:
        logging.error(f"Image download failed: {e}")
        raise HTTPException(status_code=400, detail=f"Failed to fetch image: {e}")

    try:
        t0 = time.time()
        result_png = remove_background_and_crop(image_bytes)
        proc_ms = int((time.time() - t0) * 1000)
        logging.info(f"Background removal done: {len(result_png)} bytes in {proc_ms}ms")
    except Exception as e:
        logging.error(f"Background removal failed: {e}")
        raise HTTPException(status_code=500, detail=f"Background removal failed: {e}")

    b64 = base64.b64encode(result_png).decode("utf-8")
    logging.info(f"Segment complete. Base64 length: {len(b64)}")
    return {"success": True, "imageBase64": f"data:image/png;base64,{b64}"}
