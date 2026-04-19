internal import JQ
public import JSON

extension Gecko {
    @frozen public struct Profile {
        public let threads: [Thread]
        public let shared: Shared
    }
}
extension Gecko.Profile: SwiftDemanglableProfile {
    public static func resymbolicate(
        json: inout JSON.Node,
        by transform: (consuming String) -> String
    ) throws {
        try json["shared"]["stringArray"][] &? {
            for i: Int in $0.indices {
                $0.elements[i] = .string(transform(try $0[i].decode()))
            }
        }
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
