import ArgumentParser
import SystemIO
import System_ArgumentParser

struct SwiftDemangleOptions: ParsableArguments {
    @Flag(
        name: [.customShort("s"), .long],
        help: "demangle Swift symbols",
    ) var enabled: Bool = false
    @Option(
        name: [.customShort("o")],
        help: "path to write output when resymbolicating",
    ) var output: FilePath?
}
