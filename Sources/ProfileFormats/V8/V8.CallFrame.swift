public import JSON

extension V8 {
    public struct CallFrame {
        public let functionName: String
        public let url: String?
        public let lineNumber: Int?
        public let columnNumber: Int?
    }
}
extension V8.CallFrame: JSONObjectDecodable {
    @frozen public enum CodingKey: String, Sendable {
        case functionName
        case url
        case lineNumber
        case columnNumber
    }

    public init(json: borrowing JSON.ObjectDecoder<CodingKey>) throws {
        self.init(
            functionName: try json[.functionName].decode(),
            url: try json[.url]?.decode(),
            lineNumber: try json[.lineNumber]?.decode(),
            columnNumber: try json[.columnNumber]?.decode(),
        )
    }
}
