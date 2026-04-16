import ArgumentParser
import JSON
import ProfileFormats
import SystemIO
import System_ArgumentParser

extension Gecko {
    struct ProfileExporter {
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
}

@main extension Gecko.ProfileExporter: ParsableCommand {
    func run() throws {
        let profile: Gecko.Profile = try .load(from: self.input)

        // For demonstration, we'll just print the number of threads in the profile
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

        let root: CallTree = try .tree(
            thread: profile.threads[self.thread],
            shared: profile.shared
        )

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
