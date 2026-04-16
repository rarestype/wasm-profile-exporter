public import JSON

extension V8 {
    @frozen @usableFromInline struct CallFrame {
        let functionName: String
        let url: String?
        let lineNumber: Int?
        let columnNumber: Int?
    }
}
extension V8.CallFrame: JSONObjectDecodable {
    @frozen @usableFromInline enum CodingKey: String, Sendable {
        case functionName
        case url
        case lineNumber
        case columnNumber
    }

    @usableFromInline init(json: borrowing JSON.ObjectDecoder<CodingKey>) throws {
        self.init(
            functionName: try json[.functionName].decode(),
            url: try json[.url]?.decode(),
            lineNumber: try json[.lineNumber]?.decode(),
            columnNumber: try json[.columnNumber]?.decode(),
        )
    }
}
