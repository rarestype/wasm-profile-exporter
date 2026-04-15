import JSON
import ProfileFormats
import SystemIO
import Testing

@Suite struct GeckoTests {
    @Test static func ProfileLoading() throws {
        let file: FilePath = "Sources/ProfileFormatTests/profiles/gecko.json"
        let json: JSON = .init(utf8: try file.read()[...])
        let profile: Gecko.Profile = try .init(json: try JSON.Node.init(parsing: json))

        #expect(profile.threads.count == 6)

        let thread: Int = 4

        guard profile.threads.indices.contains(thread) else {
            return
        }

        let root: Gecko.CallNode = profile.threads[thread].buildCallTree(shared: profile.shared)
        let node: Gecko.CallNode? = root.focused(
            on: "y2k.wasm.$s10GameEngine0A7SessionC5StateV4tickyyKF"
        )

        #expect(node != nil)
    }
}
