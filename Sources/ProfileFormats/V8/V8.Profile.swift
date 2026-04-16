public import JSON

extension V8 {
    @frozen public struct Profile {
        let startTime: Double?
        let endTime: Double?
        let nodes: [Node]
        let samples: [Int]?
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
