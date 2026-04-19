import SystemIO
import ArgumentParser
import JSON
import ProfileFormats

protocol CallTreeInspectionCommand: ParsableCommand {
    associatedtype PerformanceProfile: JSONDecodable, SwiftDemanglableProfile

    var function: String? { get }
    var demangle: SwiftDemangleOptions { get }
    var input: FilePath { get }

    func load(from profile: PerformanceProfile) throws -> CallTree
}
extension CallTreeInspectionCommand {
    func run() throws {
        let json: JSON = .init(utf8: try self.input.read()[...])
        let jsonAST: JSON.Node = try JSON.Node.init(parsing: json)
        if  let output: FilePath = self.demangle.output {
            guard
            let swift: SwiftDemangler = .init() else {
                print("could not load demangler")
                throw ExitCode.failure
            }

            var jsonAST: JSON.Node = consume jsonAST
            try PerformanceProfile.resymbolicate(json: &jsonAST) {
                swift.demangle(compound: $0) ?? $0
            }

            try output.overwrite(with: "\(jsonAST)".utf8)
            return
        }

        let profile: PerformanceProfile = try .init(json: jsonAST)
        let root: CallTree = try self.load(from: profile)

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
        if  self.demangle.enabled {
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
