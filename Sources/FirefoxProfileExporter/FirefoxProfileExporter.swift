import ArgumentParser
import FirefoxProfile
import JSON
import SystemIO
import System_ArgumentParser

struct FirefoxProfileExporter {
    @Argument(
        help: "Path to the Firefox profile JSON file",
    ) var input: FilePath

    @Option(
        name: [.customShort("i")],
        help: "Index of thread",
    ) var thread: Int
    @Option(
        name: [.customShort("f")],
        help: "Name of function",
    ) var function: String
}

@main extension FirefoxProfileExporter: ParsableCommand {
    func run() throws {
        let profile: FirefoxProfile = try .load(from: self.input)

        // For demonstration, we'll just print the number of threads in the profile
        print("Loaded Firefox profile with \(profile.threads.count) threads.")

        let thread: Thread = profile.threads[self.thread]
        let root: CallNode = thread.buildCallTree()
        guard
        let focus: CallNode = root.focused(on: self.function) else {
            print("function not found")
            return
        }

        let baseline: Int = focus.totalSamples
        guard
        let exportData: ExportNode = focus.export(baselineSamples: baseline, threshold: 0.5) else {
            print("failed to export")
            return
        }

        print(exportData.renderAsText())
    }
}
