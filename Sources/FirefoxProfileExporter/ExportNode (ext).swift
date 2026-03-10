import D
import FirefoxProfile

extension ExportNode {
    /// Renders the node and its children as an indented, multi-line string.
    public func renderAsText(depth: Int = 0) -> String {
        let indent: String = .init(repeating: " ", count: depth * 2)

        // Use the `D` library's `[%]` operator to format fractions as percentages
        // with 2 decimal places.
        let totalString: String = "\(self.totalFraction[%2])"
        let selfString: String = "\(self.selfFraction[%2])"

        let line: String = "\(indent)[\(totalString) Total | \(selfString) Self] \(self.name)"

        var result: String = line

        for child: ExportNode in self.children {
            let childText: String = child.renderAsText(depth: depth + 1)
            result += "\n" + childText
        }

        return result
    }
}
