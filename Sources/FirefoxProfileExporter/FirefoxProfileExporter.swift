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

        for (index, thread): (Int, FirefoxProfile.Thread) in zip(
                profile.threads.indices,
                profile.threads
            ) {
            print("Thread \(index): \(thread.name)")
        }

        guard profile.threads.indices ~= self.thread else {
            print("invalid thread index")
            return
        }

        let root: CallNode = profile.threads[self.thread].buildCallTree(shared: profile.shared)

        guard
        let focus: CallNode = root.focused(on: self.function) else {
            print("function not found")
            return
        }

        let baseline: Int = focus.totalSamples
        guard
        let exportData: ExportNode = focus.export(
            baselineSamples: baseline,
            threshold: 0.5
        ) else {
            print("failed to export")
            return
        }

        print(exportData.renderAsText())
    }
}
