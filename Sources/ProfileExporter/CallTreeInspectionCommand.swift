import SystemIO
import ArgumentParser
import JSON
import ProfileFormats

protocol CallTreeInspectionCommand: ParsableCommand {
    var function: String? { get }
    var demangle: Bool { get }
    var input: FilePath { get }

    func load(from json: JSON.Node) throws -> CallTree
}
extension CallTreeInspectionCommand {
    func run() throws {
        let json: JSON = .init(utf8: try self.input.read()[...])
        let root: CallTree = try self.load(from: try JSON.Node.init(parsing: json))

        let focus: CallTree

        if  let function: String = self.function {
            guard
            let node: CallTree = root.node.focused(on: function) else {
                print("function not found")
                throw ExitCode.failure
            }

            focus = node
        } else {
            focus = root
        }

        let baseline: Int = focus.node.samples.total
        guard
        let exported: ExportNode = focus.node.export(
            baselineSamples: baseline,
            threshold: 0.5
        ) else {
            print("failed to export")
            throw ExitCode.failure
        }

        let rendered: String
        if  self.demangle {
            let swift: SwiftDemangler? = .init()
            rendered = exported.render(swift: swift)
        } else {
            rendered = exported.render(swift: nil)
        }

        print("[total | self] <function name>")
        print()
        print(rendered)
    }
}
