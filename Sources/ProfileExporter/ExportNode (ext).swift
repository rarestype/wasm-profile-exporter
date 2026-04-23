import D
import ProfileFormats

extension ExportNode {
    /// Renders the node and its children as an indented, multi-line string.
    func render(demangle: Bool, indent depth: Int = 0) -> String {
        let indent: String = .init(repeating: " ", count: depth * 2)
        let name: String
        if  demangle {
            name = SwiftDemangler.demangle(compound: self.name) ?? self.name
        } else {
            name = self.name
        }

        let line: String = """
        \(indent)[\(self.totalFraction[%2]) | \(self.selfFraction[%2])] \(name)
        """
        var result: String = line

        for child: ExportNode in self.children {
            result += "\n"
            result += child.render(demangle: demangle, indent: depth + 1)
        }

        return result
    }
}
