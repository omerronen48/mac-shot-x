#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICONSET="$SCRIPT_DIR/AppIcon.iconset"
ICNS="$SCRIPT_DIR/AppIcon.icns"

echo "Generating placeholder icon..."

# Render 1024x1024 PNG using Swift + CoreGraphics
swift - <<'SWIFT'
import CoreGraphics
import Foundation

let size = CGSize(width: 1024, height: 1024)
let colorSpace = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(data: nil, width: 1024, height: 1024,
                   bitsPerComponent: 8, bytesPerRow: 0,
                   space: colorSpace,
                   bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

// Background: dark blue rounded rect
ctx.setFillColor(CGColor(red: 0.1, green: 0.2, blue: 0.6, alpha: 1.0))
let inset: CGFloat = 40
let rect = CGRect(x: inset, y: inset, width: 1024 - inset*2, height: 1024 - inset*2)
let path = CGPath(roundedRect: rect, cornerWidth: 180, cornerHeight: 180, transform: nil)
ctx.addPath(path)
ctx.fillPath()

// Letter "M" centered in white
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.boldSystemFont(ofSize: 680),
    .foregroundColor: NSColor.white,
]
let str = NSAttributedString(string: "M", attributes: attrs)
let line = CTLineCreateWithAttributedString(str)
let bounds = CTLineGetBoundsWithOptions(line, [])
let x = (1024 - bounds.width) / 2 - bounds.origin.x
let y = (1024 - bounds.height) / 2 - bounds.origin.y
ctx.textPosition = CGPoint(x: x, y: y)
CTLineDraw(line, ctx)

let image = ctx.makeImage()!
let url = URL(fileURLWithPath: "/tmp/macshot_icon_1024.png")
let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("Rendered 1024x1024 PNG")
SWIFT

mkdir -p "$ICONSET"

# Standard iconset sizes
sips -z 16   16   /tmp/macshot_icon_1024.png --out "$ICONSET/icon_16x16.png"     > /dev/null
sips -z 32   32   /tmp/macshot_icon_1024.png --out "$ICONSET/icon_16x16@2x.png"  > /dev/null
sips -z 32   32   /tmp/macshot_icon_1024.png --out "$ICONSET/icon_32x32.png"     > /dev/null
sips -z 64   64   /tmp/macshot_icon_1024.png --out "$ICONSET/icon_32x32@2x.png"  > /dev/null
sips -z 128  128  /tmp/macshot_icon_1024.png --out "$ICONSET/icon_128x128.png"   > /dev/null
sips -z 256  256  /tmp/macshot_icon_1024.png --out "$ICONSET/icon_128x128@2x.png" > /dev/null
sips -z 256  256  /tmp/macshot_icon_1024.png --out "$ICONSET/icon_256x256.png"   > /dev/null
sips -z 512  512  /tmp/macshot_icon_1024.png --out "$ICONSET/icon_256x256@2x.png" > /dev/null
sips -z 512  512  /tmp/macshot_icon_1024.png --out "$ICONSET/icon_512x512.png"   > /dev/null
sips -z 1024 1024 /tmp/macshot_icon_1024.png --out "$ICONSET/icon_512x512@2x.png" > /dev/null

iconutil -c icns "$ICONSET" -o "$ICNS"
rm -rf "$ICONSET" /tmp/macshot_icon_1024.png

echo "Icon: $ICNS"
