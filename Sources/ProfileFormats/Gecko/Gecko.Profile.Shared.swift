import JSON

extension Gecko.Profile {
    public struct Shared {
        let stringArray: [String]
        let funcTable: FuncTable
        let frameTable: FrameTable
        let stackTable: StackTable
    }
}
extension Gecko.Profile.Shared: JSONObjectDecodable {
    @frozen public enum CodingKey: String, Sendable {
        case stringArray
        case funcTable
        case frameTable
        case stackTable
    }

    public init(json: borrowing JSON.ObjectDecoder<CodingKey>) throws {
        self.init(
            stringArray: try json[.stringArray].decode(),
            funcTable: try json[.funcTable].decode(),
            frameTable: try json[.frameTable].decode(),
            stackTable: try json[.stackTable].decode()
        )
    }
}
