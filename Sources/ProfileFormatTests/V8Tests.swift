import JSON
import ProfileFormats
import SystemIO
import Testing

@Suite struct V8Tests {
    @Test static func ProfileLoading() throws {
        let file: FilePath = "Sources/ProfileFormatTests/profiles/v8.json"
        let json: JSON = .init(utf8: try file.read()[...])
        let _: V8.Profile = try .init(json: try JSON.Node.init(parsing: json))
    }
}
