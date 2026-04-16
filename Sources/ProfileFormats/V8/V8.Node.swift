public import JSON

extension V8 {
    @frozen @usableFromInline struct Node {
        let id: Int
        let callFrame: CallFrame
        let hitCount: Int
        let children: [Int]
    }
}
extension V8.Node: JSONObjectDecodable {
    @frozen @usableFromInline enum CodingKey: String, Sendable {
        case id
        case callFrame
        case hitCount
        case children
    }

    @usableFromInline init(json: borrowing JSON.ObjectDecoder<CodingKey>) throws {
        self.init(
            id: try json[.id].decode(),
            callFrame: try json[.callFrame].decode(),
            // Depending on the profiler version, hitCount might be omitted if it's 0,
            // and leaf nodes often omit the children array entirely.
            hitCount: try json[.hitCount]?.decode() ?? 0,
            children: try json[.children]?.decode() ?? [],
        )
    }
}
