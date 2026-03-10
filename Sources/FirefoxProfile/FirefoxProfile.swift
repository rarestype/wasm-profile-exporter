import JSON

public struct FirefoxProfile: JSONObjectDecodable {
    @frozen public enum CodingKey: String, Sendable {
        case threads
        case shared
    }

    public let threads: [Thread]
    public let shared: Shared

    public init(json: JSON.ObjectDecoder<CodingKey>) throws {
        self.threads = try json[.threads].decode()
        self.shared = try json[.shared].decode()
    }
}
