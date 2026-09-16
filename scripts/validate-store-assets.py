#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 KDE e.V.
# SPDX-License-Identifier: GPL-2.0-or-later
"""Validate Minuet's store-listing assets without third-party Python modules."""

from __future__ import annotations

import argparse
import json
import struct
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
ANDROID_SCREENSHOTS = (
    "01-exercise-library.png",
    "02-melodic-interval.png",
    "03-rhythm-with-rests.png",
    "04-read-and-sing.png",
    "05-read-and-clap.png",
    "06-practice-settings.png",
)
WINDOWS_SCREENSHOTS = (
    "minuet-01-exercise-library.png",
    "minuet-02-melodic-interval.png",
    "minuet-03-rhythm-with-rests.png",
    "minuet-04-read-and-sing.png",
    "minuet-05-read-and-clap.png",
    "minuet-06-practice-settings.png",
)
APPLE_SCREENSHOTS = ANDROID_SCREENSHOTS


@dataclass
class PngInfo:
    width: int
    height: int
    color_type: int
    has_transparency_chunk: bool

    @property
    def has_alpha(self) -> bool:
        return self.color_type in (4, 6) or self.has_transparency_chunk


class Validator:
    def __init__(self, require_all: bool) -> None:
        self.require_all = require_all
        self.failures: list[str] = []
        self.warnings: list[str] = []

    def fail(self, message: str) -> None:
        self.failures.append(message)

    def warn(self, message: str) -> None:
        self.warnings.append(message)

    def optional_missing(self, path: Path) -> bool:
        if path.exists():
            return False
        message = f"missing optional asset set: {path}"
        if self.require_all:
            self.fail(message)
        else:
            self.warn(message)
        return True

    def png(self, path: Path) -> PngInfo | None:
        try:
            with path.open("rb") as handle:
                if handle.read(8) != PNG_SIGNATURE:
                    self.fail(f"{path}: not a PNG file")
                    return None
                length = struct.unpack(">I", handle.read(4))[0]
                if handle.read(4) != b"IHDR" or length != 13:
                    self.fail(f"{path}: missing or invalid IHDR")
                    return None
                width, height, bit_depth, color_type, compression, filter_method, interlace = struct.unpack(
                    ">IIBBBBB", handle.read(13)
                )
                if bit_depth != 8 or compression != 0 or filter_method != 0 or interlace not in (0, 1):
                    self.fail(f"{path}: unsupported PNG encoding")
                handle.read(4)  # IHDR CRC
                transparent = False
                while True:
                    length_data = handle.read(4)
                    if not length_data:
                        break
                    chunk_length = struct.unpack(">I", length_data)[0]
                    chunk_type = handle.read(4)
                    handle.seek(chunk_length + 4, 1)
                    if chunk_type == b"tRNS":
                        transparent = True
                    if chunk_type == b"IEND":
                        break
                return PngInfo(width, height, color_type, transparent)
        except (OSError, struct.error) as error:
            self.fail(f"{path}: cannot read PNG ({error})")
            return None

    def image(self, path: Path, width: int, height: int, *, alpha: bool, max_bytes: int | None = None) -> None:
        if not path.is_file():
            self.fail(f"missing image: {path}")
            return
        if max_bytes is not None and path.stat().st_size > max_bytes:
            self.fail(f"{path}: larger than {max_bytes} bytes")
        info = self.png(path)
        if info is None:
            return
        if (info.width, info.height) != (width, height):
            self.fail(f"{path}: expected {width}x{height}, got {info.width}x{info.height}")
        if not alpha and info.has_alpha:
            self.fail(f"{path}: transparency is not permitted")

    def image_set(
        self, directory: Path, names: tuple[str, ...], width: int, height: int, *, alpha: bool, max_bytes: int | None = None
    ) -> None:
        if self.optional_missing(directory):
            return
        found = sorted(path.name for path in directory.glob("*.png"))
        if tuple(found) != names:
            self.fail(f"{directory}: expected PNGs {', '.join(names)}; found {', '.join(found) or 'none'}")
        for name in names:
            self.image(directory / name, width, height, alpha=alpha, max_bytes=max_bytes)


def validate_appstream(validator: Validator, root: Path) -> None:
    metadata = root / "org.kde.minuet.metainfo.xml"
    try:
        component = ET.parse(metadata).getroot()
    except (ET.ParseError, OSError) as error:
        validator.fail(f"{metadata}: invalid AppStream XML ({error})")
        return

    custom = {value.get("key"): (value.text or "") for value in component.findall("./custom/value")}
    for obsolete in ("KDE::windows_store::StoreLogo9x16", "KDE::windows_store::StoreLogoSquare"):
        if obsolete in custom:
            validator.fail(f"{metadata}: obsolete Microsoft artwork key {obsolete}")
    for required in ("KDE::windows_store::Icon", "KDE::windows_store::PromotionalArt16x9"):
        if not custom.get(required, "").startswith("https://"):
            validator.fail(f"{metadata}: missing HTTPS value for {required}")

    screenshots = component.findall("./screenshots/screenshot")
    defaults = [item for item in screenshots if item.get("type") == "default"]
    if len(defaults) != 1:
        validator.fail(f"{metadata}: exactly one default screenshot is required")
    windows = [item for item in screenshots if item.get("environment") == "windows"]
    if validator.require_all:
        if len(windows) != 6:
            validator.fail(f"{metadata}: expected six Windows screenshots, got {len(windows)}")
        if defaults and defaults[0].get("environment") != "windows":
            validator.fail(f"{metadata}: default screenshot must be a Windows screenshot")
    elif len(windows) != 6:
        validator.warn(f"{metadata}: final six Windows screenshot entries are not configured yet")

    for screenshot in windows:
        image = screenshot.findtext("image", default="")
        if not image.startswith("https://cdn.kde.org/screenshots/minuet/"):
            validator.fail(f"{metadata}: Windows screenshot is not a KDE CDN URL: {image}")
        caption = screenshot.findtext("caption", default="")
        if len(caption) > 200:
            validator.fail(f"{metadata}: screenshot caption exceeds 200 characters")

    summary = component.findtext("summary", default="")
    if len(summary) > 80:
        validator.fail(f"{metadata}: English summary exceeds 80 characters")
    description = "".join(component.find("description").itertext()) if component.find("description") is not None else ""
    if len(description) > 4000:
        validator.fail(f"{metadata}: English description exceeds 4000 characters")


def validate_catalog(validator: Validator, catalog: Path, expected: dict[str, int]) -> None:
    contents = catalog / "Contents.json"
    try:
        images = json.loads(contents.read_text(encoding="utf-8"))["images"]
    except (OSError, json.JSONDecodeError, KeyError) as error:
        validator.fail(f"{contents}: invalid asset catalog ({error})")
        return
    names = {entry.get("filename") for entry in images}
    if names != set(expected):
        validator.fail(f"{contents}: unexpected icon inventory")
    for name, size in expected.items():
        validator.image(catalog / name, size, size, alpha=False)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--product-screenshots-root", type=Path)
    parser.add_argument("--apple-staging-root", type=Path)
    parser.add_argument("--require-all", action="store_true", help="fail for missing external or staged asset sets")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    validator = Validator(args.require_all)

    android_images = root / "fastlane/metadata/org.kde.minuet/en-US/images"
    validator.image(android_images / "icon.png", 512, 512, alpha=True, max_bytes=1_000_000)
    validator.image(android_images / "featureGraphic.png", 1024, 500, alpha=False)
    validator.image_set(android_images / "phoneScreenshots", ANDROID_SCREENSHOTS, 1080, 1920, alpha=False)
    validator.image(root / "src/app/icons/windows/icon-300x300.png", 300, 300, alpha=True, max_bytes=50_000_000)
    validator.image(root / "src/app/icons/windows/promoimage-1920x1080.png", 1920, 1080, alpha=False, max_bytes=50_000_000)
    validate_appstream(validator, root)

    ios_catalog = root / "src/app/ios/Assets.xcassets/AppIcon.appiconset"
    ios_sizes = {
        "icon-ipad-20-1x.png": 20, "icon-iphone-20-2x.png": 40, "icon-iphone-20-3x.png": 60,
        "icon-iphone-29-2x.png": 58, "icon-iphone-29-3x.png": 87, "icon-iphone-40-2x.png": 80,
        "icon-iphone-40-3x.png": 120, "icon-iphone-60-2x.png": 120, "icon-iphone-60-3x.png": 180,
        "icon-ipad-29-1x.png": 29, "icon-ipad-29-2x.png": 58, "icon-ipad-40-1x.png": 40,
        "icon-ipad-40-2x.png": 80, "icon-ipad-76-1x.png": 76, "icon-ipad-76-2x.png": 152,
        "icon-ipad-83-2x.png": 167, "icon-ios-marketing.png": 1024,
    }
    validate_catalog(validator, ios_catalog, ios_sizes)
    mac_catalog = root / "src/app/macos/Assets.xcassets/AppIcon.appiconset"
    mac_sizes = {"icon_16x16.png": 16, "icon_16x16@2x.png": 32, "icon_32x32.png": 32, "icon_32x32@2x.png": 64,
                 "icon_128x128.png": 128, "icon_128x128@2x.png": 256, "icon_256x256.png": 256,
                 "icon_256x256@2x.png": 512, "icon_512x512.png": 512, "icon_512x512@2x.png": 1024}
    validate_catalog(validator, mac_catalog, mac_sizes)

    if args.product_screenshots_root is not None:
        validator.image_set(args.product_screenshots_root / "minuet", WINDOWS_SCREENSHOTS, 1920, 1080, alpha=False, max_bytes=50_000_000)
    if args.apple_staging_root is not None:
        validator.image_set(args.apple_staging_root / "iphone", APPLE_SCREENSHOTS, 1320, 2868, alpha=False)
        validator.image_set(args.apple_staging_root / "ipad", APPLE_SCREENSHOTS, 2064, 2752, alpha=False)
        validator.image_set(args.apple_staging_root / "macos", APPLE_SCREENSHOTS, 2880, 1800, alpha=False)

    for warning in validator.warnings:
        print(f"WARNING: {warning}")
    for failure in validator.failures:
        print(f"ERROR: {failure}")
    if validator.failures:
        print(f"Store asset validation failed with {len(validator.failures)} error(s).")
        return 1
    print("Store asset validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
