public import JSON

extension Gecko.Profile {
    public struct Thread {
        public let name: String
        let samples: Samples
    }
}
extension Gecko.Profile.Thread: JSONObjectDecodable {
    @frozen public enum CodingKey: String, Sendable {
        case name
        case samples
    }

    public init(json: borrowing JSON.ObjectDecoder<CodingKey>) throws {
        self.init(name: try json[.name].decode(), samples: try json[.samples].decode())
    }
}
