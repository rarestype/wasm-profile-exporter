import ArgumentParser
import JSON
import ProfileFormats
import SystemIO
import System_ArgumentParser

struct ExportV8 {
    @Argument(
        help: "path to the V8 JSON profile",
    ) var input: FilePath

    @Option(
        name: [.customShort("f")],
        help: "name of function to focus on",
    ) var function: String?

    @Flag(
        name: [.customShort("s"), .long],
        help: "demangle Swift symbols",
    ) var demangle: Bool = false
}
extension ExportV8: ParsableCommand {
    static var configuration: CommandConfiguration {
        .init(commandName: "v8")
    }
}
extension ExportV8: CallTreeInspectionCommand {
    func load(from json: JSON.Node) throws -> CallTree {
        let profile: V8.Profile = try .init(json: json)
        return try .tree(thread: profile)
    }
}
