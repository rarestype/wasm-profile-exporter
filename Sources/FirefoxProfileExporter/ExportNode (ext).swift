import D
import FirefoxProfile

extension ExportNode {
    /// Renders the node and its children as an indented, multi-line string.
    var rendered: String {
        let swift: SwiftDemangler? = .init()
        return self.render(depth: 0, swift: swift)
    }

    private func render(depth: Int, swift: SwiftDemangler?) -> String {
        let indent: String = .init(repeating: " ", count: depth * 2)
        let name: String = swift?.demangle(compound: self.name) ?? self.name
        let line: String = """
        \(indent)[\(self.totalFraction[%2]) | \(self.selfFraction[%2])] \(name)
        """
        var result: String = line

        for child: ExportNode in self.children {
            result += "\n"
            result += child.render(depth: depth + 1, swift: swift)
        }

        return result
    }
}
