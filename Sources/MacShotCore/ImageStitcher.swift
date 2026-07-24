import CoreGraphics

/// Stitches overlapping scroll frames into one tall image via per-row signature overlap.
public enum ImageStitcher {
    /// FNV-1a hash per pixel row (top→bottom), so identical rows share a signature.
    public static func rowSignatures(_ image: CGImage) -> [UInt64] {
        let w = image.width, h = image.height
        var buf = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(data: &buf, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return [] }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        var sigs = [UInt64](); sigs.reserveCapacity(h)
        for topRow in 0..<h {
            // ponytail: CGImage from bytesPerRow:0 context flips on ctx.draw; buf[y=0] = visual top
            let y = topRow
            var hash: UInt64 = 0xcbf29ce484222325
            for x in 0..<(w * 4) { hash = (hash ^ UInt64(buf[y * w * 4 + x])) &* 0x100000001b3 }
            sigs.append(hash)
        }
        return sigs   // index 0 = top row
    }

    /// Largest k where a.suffix(k) == b.prefix(k).
    public static func overlap(_ a: [UInt64], _ b: [UInt64]) -> Int {
        var k = min(a.count, b.count)
        while k > 0 {
            if Array(a.suffix(k)) == Array(b.prefix(k)) { return k }
            k -= 1
        }
        return 0
    }

    /// Composite frames top→bottom, appending only each next frame's non-overlapping rows.
    public static func stitch(_ frames: [CGImage]) -> CGImage? {
        guard let first = frames.first else { return nil }
        if frames.count == 1 { return first }
        let width = first.width
        var sigs = rowSignatures(first)
        var totalRows = first.height
        var newRowsPerFrame: [Int] = []
        for next in frames.dropFirst() {
            let nSig = rowSignatures(next)
            let ov = overlap(sigs, nSig)
            let newRows = next.height - ov
            newRowsPerFrame.append(newRows)
            totalRows += newRows
            sigs = nSig
        }
        guard let ctx = CGContext(data: nil, width: width, height: totalRows, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        var topOffset = 0
        ctx.draw(first, in: CGRect(x: 0, y: totalRows - first.height, width: width, height: first.height))
        topOffset += first.height
        for (i, next) in frames.dropFirst().enumerated() {
            let newRows = newRowsPerFrame[i]
            // cropping(to:) uses top-left origin; new (non-overlap) rows are at the BOTTOM of next
            // ponytail: overlap rows are the top prefix of next; new rows are the bottom suffix
            let cropped = next.cropping(to: CGRect(x: 0, y: next.height - newRows, width: width, height: newRows)) ?? next
            ctx.draw(cropped, in: CGRect(x: 0, y: totalRows - topOffset - newRows, width: width, height: newRows))
            topOffset += newRows
        }
        return ctx.makeImage()
    }
}
