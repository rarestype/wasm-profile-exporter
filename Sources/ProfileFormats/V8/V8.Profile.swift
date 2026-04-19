internal import JQ
public import JSON

extension V8 {
    @frozen public struct Profile {
        let startTime: Double?
        let endTime: Double?
        let nodes: [Node]
        let samples: [Int]?
    }
}
extension V8.Profile: SwiftDemanglableProfile {
    public static func resymbolicate(
        json: inout JSON.Node,
        by transform: (consuming String) -> String
    ) throws {
        try json["nodes"][] &? {
            for i: Int in $0.indices {
                try $0.elements[i]["callFrame"]["functionName"] & {
                    if  case .string(let string)? = $0 {
                        $0 = .string(transform(string.value))
                    }
                }
            }
        }
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
