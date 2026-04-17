import ArgumentParser
import ProfileFormats

@main struct Export: ParsableCommand {
    static var configuration: CommandConfiguration {
        .init(subcommands: [ExportV8.self, ExportGecko.self])
    }
}
