#!/bin/bash
# SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
#
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Generates Assets.xcassets for iOS from the scalable SVG app icon.
# Requires: librsvg (brew install librsvg)
#
# Usage: run from the repository root
#   ./scripts/generate-ios-assets.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SRC="$REPO_ROOT/src/app/icons/128-apps-minuet.svg"
XCASSETS="$REPO_ROOT/src/app/ios/Assets.xcassets"
ICONSET="$XCASSETS/AppIcon.appiconset"
LAUNCHICON="$XCASSETS/LaunchIcon.imageset"

# --- Sanity checks -----------------------------------------------------------

if ! command -v rsvg-convert &> /dev/null; then
    echo "❌ rsvg-convert not found. Install it with: brew install librsvg"
    exit 1
fi

if [[ ! -f "$SRC" ]]; then
    echo "❌ Source SVG not found: $SRC"
    exit 1
fi

# --- Generate app icons ------------------------------------------------------

mkdir -p "$ICONSET"

generate() {
    local SIZE=$1
    local NAME=$2
    rsvg-convert -w "$SIZE" -h "$SIZE" "$SRC" -o "$ICONSET/$NAME"
    echo "  Generated $NAME (${SIZE}x${SIZE})"
}

echo "🎨 Generating app icons from: $SRC"

generate 20   "icon-ipad-20-1x.png"
generate 40   "icon-iphone-20-2x.png"
generate 60   "icon-iphone-20-3x.png"
generate 58   "icon-iphone-29-2x.png"
generate 87   "icon-iphone-29-3x.png"
generate 80   "icon-iphone-40-2x.png"
generate 120  "icon-iphone-40-3x.png"
generate 120  "icon-iphone-60-2x.png"
generate 180  "icon-iphone-60-3x.png"
generate 29   "icon-ipad-29-1x.png"
generate 58   "icon-ipad-29-2x.png"
generate 40   "icon-ipad-40-1x.png"
generate 80   "icon-ipad-40-2x.png"
generate 76   "icon-ipad-76-1x.png"
generate 152  "icon-ipad-76-2x.png"
generate 167  "icon-ipad-83-2x.png"
generate 1024 "icon-ios-marketing.png"

cat > "$ICONSET/Contents.json" << 'JSON'
{
  "images": [
    { "idiom": "ipad",          "size": "20x20",     "scale": "1x", "filename": "icon-ipad-20-1x.png"    },
    { "idiom": "iphone",        "size": "20x20",     "scale": "2x", "filename": "icon-iphone-20-2x.png"  },
    { "idiom": "iphone",        "size": "20x20",     "scale": "3x", "filename": "icon-iphone-20-3x.png"  },
    { "idiom": "iphone",        "size": "29x29",     "scale": "2x", "filename": "icon-iphone-29-2x.png"  },
    { "idiom": "iphone",        "size": "29x29",     "scale": "3x", "filename": "icon-iphone-29-3x.png"  },
    { "idiom": "iphone",        "size": "40x40",     "scale": "2x", "filename": "icon-iphone-40-2x.png"  },
    { "idiom": "iphone",        "size": "40x40",     "scale": "3x", "filename": "icon-iphone-40-3x.png"  },
    { "idiom": "iphone",        "size": "60x60",     "scale": "2x", "filename": "icon-iphone-60-2x.png"  },
    { "idiom": "iphone",        "size": "60x60",     "scale": "3x", "filename": "icon-iphone-60-3x.png"  },
    { "idiom": "ipad",          "size": "29x29",     "scale": "1x", "filename": "icon-ipad-29-1x.png"    },
    { "idiom": "ipad",          "size": "29x29",     "scale": "2x", "filename": "icon-ipad-29-2x.png"    },
    { "idiom": "ipad",          "size": "40x40",     "scale": "1x", "filename": "icon-ipad-40-1x.png"    },
    { "idiom": "ipad",          "size": "40x40",     "scale": "2x", "filename": "icon-ipad-40-2x.png"    },
    { "idiom": "ipad",          "size": "76x76",     "scale": "1x", "filename": "icon-ipad-76-1x.png"    },
    { "idiom": "ipad",          "size": "76x76",     "scale": "2x", "filename": "icon-ipad-76-2x.png"    },
    { "idiom": "ipad",          "size": "83.5x83.5", "scale": "2x", "filename": "icon-ipad-83-2x.png"    },
    { "idiom": "ios-marketing", "size": "1024x1024", "scale": "1x", "filename": "icon-ios-marketing.png" }
  ],
  "info": { "author": "xcode", "version": 1 }
}
JSON

echo "✅ AppIcon.appiconset done"

# --- Generate launch screen icon ---------------------------------------------

mkdir -p "$LAUNCHICON"

echo "🎨 Generating launch screen icon from: $SRC"

rsvg-convert -w 120 -h 120 "$SRC" -o "$LAUNCHICON/launch-icon-1x.png"
echo "  Generated launch-icon-1x.png (120x120)"
rsvg-convert -w 240 -h 240 "$SRC" -o "$LAUNCHICON/launch-icon-2x.png"
echo "  Generated launch-icon-2x.png (240x240)"
rsvg-convert -w 360 -h 360 "$SRC" -o "$LAUNCHICON/launch-icon-3x.png"
echo "  Generated launch-icon-3x.png (360x360)"

cat > "$LAUNCHICON/Contents.json" << 'JSON'
{
  "images": [
    { "idiom": "universal", "scale": "1x", "filename": "launch-icon-1x.png" },
    { "idiom": "universal", "scale": "2x", "filename": "launch-icon-2x.png" },
    { "idiom": "universal", "scale": "3x", "filename": "launch-icon-3x.png" }
  ],
  "info": { "author": "xcode", "version": 1 }
}
JSON

echo "✅ LaunchIcon.imageset done"
echo "✅ All done: $XCASSETS"
