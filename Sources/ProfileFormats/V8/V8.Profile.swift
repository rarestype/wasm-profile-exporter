public import JSON

extension V8 {
    public struct Profile {
        public let startTime: Double?
        public let endTime: Double?
        public let nodes: [Node]
        public let samples: [Int]?
    }
}
extension V8.Profile: JSONObjectDecodable {
    @frozen public enum CodingKey: String, Sendable {
        case startTime
        case endTime
        case nodes
        case samples
    }

    public init(json: borrowing JSON.ObjectDecoder<CodingKey>) throws {
        self.init(
            startTime: try json[.startTime]?.decode(),
            endTime: try json[.endTime]?.decode(),
            nodes: try json[.nodes].decode(),
            samples: try json[.samples]?.decode(),
        )
    }
}
