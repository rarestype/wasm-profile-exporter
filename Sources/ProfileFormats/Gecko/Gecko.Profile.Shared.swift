public import JSON

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
extension Gecko.Profile.Shared {
    /// Resolves a stack index into an array of function names.
    ///
    /// The returned array is ordered from the root of the call tree down to the executing leaf.
    func stack(resolving index: Int) throws(Gecko.Profile.SharedReferenceError) -> [String] {
        var frames: [String] = []
        var next: Int? = index

        // The prefix chain points upwards from the leaf to the root.
        // We iterate until there is no parent prefix.
        while let current: Int = next {
            if  self.stackTable.prefix.indices.contains(current) {
                next = self.stackTable.prefix[current]
            } else {
                throw .stack(current, self.stackTable.prefix.indices)
            }
            guard self.stackTable.frame.indices.contains(current) else {
                throw .stack(current, self.stackTable.frame.indices)
            }

            let frame: Int = self.stackTable.frame[current]

            guard self.frameTable.func.indices.contains(frame) else {
                throw .frame(frame, self.frameTable.func.indices)
            }

            let function: Int = self.frameTable.func[frame]

            guard self.funcTable.name.indices.contains(function) else {
                throw .function(function, self.funcTable.name.indices)
            }

            let string: Int = self.funcTable.name[function]

            guard self.stringArray.indices.contains(string) else {
                throw .string(string, self.stringArray.indices)
            }

            let name: String = self.stringArray[string]
            // ignore hex addresses
            if !name.hasPrefix("0x") {
                frames.append(name)
            }
        }

        // The traversal collected frames from leaf -> root.
        // Reversing it gives us the standard root -> leaf call stack order.
        return frames.reversed()
    }
}
