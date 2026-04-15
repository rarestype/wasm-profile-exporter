import JSON

extension Gecko {
    @frozen public struct Profile {
        public let threads: [Thread]
        public let shared: Shared
    }
}
extension Gecko.Profile: JSONObjectDecodable {
    @frozen public enum CodingKey: String, Sendable {
        case threads
        case shared
    }

    public init(json: borrowing JSON.ObjectDecoder<CodingKey>) throws {
        self.init(
            threads: try json[.threads].decode(),
            shared: try json[.shared].decode()
        )
    }
}
