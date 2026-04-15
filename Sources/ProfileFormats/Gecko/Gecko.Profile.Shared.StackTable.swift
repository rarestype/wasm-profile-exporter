import JSON

extension Gecko.Profile.Shared {
    struct StackTable {
        let frame: [Int]
        let prefix: [Int?]
    }
}
extension Gecko.Profile.Shared.StackTable: JSONObjectDecodable {
    enum CodingKey: String {
        case frame  // Array of indices pointing to `frameTable`
        case prefix // Array of parent stack indices (nullable)
    }

    init(json: borrowing JSON.ObjectDecoder<CodingKey>) throws {
        self.init(frame: try json[.frame].decode(), prefix: try json[.prefix].decode())
    }
}
