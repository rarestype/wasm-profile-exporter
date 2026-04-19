import ArgumentParser
import JSON
import ProfileFormats
import SystemIO
import System_ArgumentParser

struct ExportV8 {
    @Argument(
        help: "path to the V8 JSON profile",
    ) var input: FilePath

    @OptionGroup var demangle: SwiftDemangleOptions

    @Option(
        name: [.customShort("f")],
        help: "name of function to focus on",
    ) var function: String?
}
extension ExportV8: ParsableCommand {
    static var configuration: CommandConfiguration {
        .init(commandName: "v8")
    }
}
extension ExportV8: CallTreeInspectionCommand {
    func load(from profile: V8.Profile) throws -> CallTree {
        try .tree(thread: profile)
    }
}
