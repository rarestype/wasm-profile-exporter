import JSON

extension Gecko.Profile.Shared {
    struct FrameTable {
        let `func`: [Int]
    }
}
extension Gecko.Profile.Shared.FrameTable: JSONObjectDecodable {
    enum CodingKey: String {
        // Array of indices pointing to `funcTable`
        case `func`
    }

    init(json: borrowing JSON.ObjectDecoder<CodingKey>) throws {
        self.init(func: try json[.func].decode())
    }
}
