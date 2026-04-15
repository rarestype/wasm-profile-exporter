import JSON

extension Gecko.Profile.Shared {
    struct FuncTable {
        let name: [Int]
    }
}
extension Gecko.Profile.Shared.FuncTable: JSONObjectDecodable {
    enum CodingKey: String {
        // Array of indices pointing to `stringArray`
        case name
    }

    init(json: JSON.ObjectDecoder<CodingKey>) throws {
        self.init(name: try json[.name].decode())
    }
}
