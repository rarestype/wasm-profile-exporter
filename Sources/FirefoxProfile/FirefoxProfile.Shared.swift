import JSON

extension FirefoxProfile {
    public struct Shared: JSONObjectDecodable {
        @frozen public enum CodingKey: String, Sendable {
            case stringArray
            case funcTable
            case frameTable
            case stackTable
        }

        let stringArray: [String]
        let funcTable: FuncTable
        let frameTable: FrameTable
        let stackTable: StackTable

        public init(json: JSON.ObjectDecoder<CodingKey>) throws {
            self.stringArray = try json[.stringArray].decode()
            self.funcTable = try json[.funcTable].decode()
            self.frameTable = try json[.frameTable].decode()
            self.stackTable = try json[.stackTable].decode()
        }
    }
}
