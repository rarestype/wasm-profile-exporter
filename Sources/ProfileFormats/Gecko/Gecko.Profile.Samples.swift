import JSON

extension Gecko.Profile {
    struct Samples {
        let stack: [Int?]
        let time: [Double]
    }
}
extension Gecko.Profile.Samples: JSONObjectDecodable {
    enum CodingKey: String {
        // Array of stack indices for each sample (nullable if idle)
        case stack
        // Array of timestamps
        case time
    }

    init(json: borrowing JSON.ObjectDecoder<CodingKey>) throws {
        self.init(
            stack: try json[.stack].decode(),
            time: try json[.time].decode(),
        )
    }
}
