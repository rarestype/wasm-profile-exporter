import JSON
import ProfileFormats
import SystemIO
import Testing

@Suite struct ProfileLoadingTests {
    @Test static func Gecko() throws {
        let file: FilePath = "Sources/ProfileFormatTests/profiles/gecko.json"
        let json: JSON = .init(utf8: try file.read()[...])
        let profile: Gecko.Profile = try .init(json: try JSON.Node.init(parsing: json))

        #expect(profile.threads.count == 6)

        let thread: Int = 4

        guard profile.threads.indices.contains(thread) else {
            return
        }

        let root: CallTree = try .tree(thread: profile.threads[thread], shared: profile.shared)
        let node: CallTree? = root.node.focused(
            on: "y2k.wasm.$s10GameEngine0A7SessionC5StateV4tickyyKF"
        )

        #expect(node != nil)
    }

    @Test static func V8() throws {
        let file: FilePath = "Sources/ProfileFormatTests/profiles/v8.json"
        let json: JSON = .init(utf8: try file.read()[...])
        let thread: V8.Profile = try .init(json: try JSON.Node.init(parsing: json))

        let root: CallTree = try .tree(thread: thread)
        let node: CallTree? = root.node.focused(
            on: "$s10GameEngine0A7SessionC5StateV4tickyyKF"
        )

        #expect(node != nil)
    }
}
