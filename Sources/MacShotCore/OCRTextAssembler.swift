import CoreGraphics

/// Orders recognized fragments into readable text: split into columns by large
/// horizontal gaps, columns left→right, lines within a column top→bottom.
/// boundingBox origin is bottom-left (Vision convention), so larger y = higher.
public enum OCRTextAssembler {
    public static func assemble(_ observations: [OCRObservation]) -> String {
        let items = observations.filter { !$0.text.isEmpty }
        guard !items.isEmpty else { return "" }
        let columns = clusterColumns(items)
        return columns
            .map { col in col.sorted { $0.boundingBox.midY > $1.boundingBox.midY }.map(\.text).joined(separator: "\n") }
            .joined(separator: "\n")
    }

    /// Group by x using a gap threshold relative to typical fragment width.
    private static func clusterColumns(_ items: [OCRObservation]) -> [[OCRObservation]] {
        let sorted = items.sorted { $0.boundingBox.minX < $1.boundingBox.minX }
        let avgWidth = items.reduce(0) { $0 + $1.boundingBox.width } / CGFloat(items.count)
        let gap = max(avgWidth * 1.5, 30)     // ponytail: a new column starts after a wide horizontal gap
        var columns: [[OCRObservation]] = []
        var current: [OCRObservation] = []
        var lastMaxX: CGFloat = -.greatestFiniteMagnitude
        for o in sorted {
            if !current.isEmpty, o.boundingBox.minX - lastMaxX > gap {
                columns.append(current); current = []
            }
            current.append(o)
            lastMaxX = max(lastMaxX, o.boundingBox.maxX)
        }
        if !current.isEmpty { columns.append(current) }
        return columns
    }
}
