import ArgumentParser
import JSON
import ProfileFormats
import SystemIO
import System_ArgumentParser

struct ExportGecko {
    @Argument(
        help: "path to the Gecko JSON profile",
    ) var input: FilePath

    @Option(
        name: [.customShort("i")],
        help: "index of thread",
    ) var thread: Int
    @Option(
        name: [.customShort("f")],
        help: "name of function to focus on",
    ) var function: String?

    @Flag(
        name: [.customShort("s"), .long],
        help: "demangle Swift symbols",
    ) var demangle: Bool = false
}
extension ExportGecko: ParsableCommand {
    static var configuration: CommandConfiguration {
        .init(commandName: "gecko")
    }
}
extension ExportGecko: CallTreeInspectionCommand {
    func load(from json: JSON.Node) throws -> CallTree {
        let profile: Gecko.Profile = try .init(json: json)

        print("loaded Gecko profile with \(profile.threads.count) threads:")

        for (index, thread): (Int, Gecko.Profile.Thread) in zip(
                profile.threads.indices,
                profile.threads
            ) {
            print("thread \(index): \(thread.name)")
        }

        guard profile.threads.indices ~= self.thread else {
            print("invalid thread index")
            throw ExitCode.failure
        }

        return try .tree(
            thread: profile.threads[self.thread],
            shared: profile.shared
        )
    }
}
