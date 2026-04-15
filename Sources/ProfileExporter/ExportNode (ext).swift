import D
import ProfileFormats

extension ExportNode {
    /// Renders the node and its children as an indented, multi-line string.
    func render(swift: SwiftDemangler?, indent depth: Int = 0) -> String {
        let indent: String = .init(repeating: " ", count: depth * 2)
        let name: String = swift?.demangle(compound: self.name) ?? self.name
        let line: String = """
        \(indent)[\(self.totalFraction[%2]) | \(self.selfFraction[%2])] \(name)
        """
        var result: String = line

        for child: ExportNode in self.children {
            result += "\n"
            result += child.render(swift: swift, indent: depth + 1)
        }

        return result
    }
}
