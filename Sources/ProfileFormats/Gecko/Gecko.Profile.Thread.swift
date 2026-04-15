public import JSON

extension Gecko.Profile {
    public struct Thread {
        public let name: String
        let samples: Samples
    }
}
extension Gecko.Profile.Thread {
    /// Resolves a stack index into an array of function names.
    /// The resulting array is ordered from the root of the call tree down to the executing leaf.
    public func resolveStack(index: Int?, shared: Gecko.Profile.Shared) -> [String] {
        // If the stack index is nil, the thread was likely idle during this sample.
        guard var currentIndex = index else {
            return []
        }

        var frames: [String] = []

        // The prefix chain points upwards from the leaf to the root.
        // We iterate until there is no parent prefix.
        while true {
            let frameIndex: Int = shared.stackTable.frame[currentIndex]
            let funcIndex: Int = shared.frameTable.func[frameIndex]
            let nameIndex: Int = shared.funcTable.name[funcIndex]

            let function: String = shared.stringArray[nameIndex]
            // ignore hex addresses
            if !function.hasPrefix("0x") {
                frames.append(function)
            }

            if let parentIndex = shared.stackTable.prefix[currentIndex] {
                currentIndex = parentIndex
            } else {
                break
            }
        }

        // The traversal collected frames from leaf -> root.
        // Reversing it gives us the standard root -> leaf call stack order.
        return frames.reversed()
    }

    /// Aggregates all time-series samples into a single call tree.
    public func buildCallTree(shared: Gecko.Profile.Shared) -> Gecko.CallNode {
        let root: Gecko.CallNode = .init(name: "(root)")

        for stackIndex: Int? in self.samples.stack {
            let frames: [String] = self.resolveStack(index: stackIndex, shared: shared)
            if frames.isEmpty {
                continue
            }

            root.totalSamples += 1
            var current: Gecko.CallNode = root

            for frame: String in frames {
                let next: Gecko.CallNode

                if let existing: Gecko.CallNode = current.children[frame] {
                    next = existing
                } else {
                    let newChild: Gecko.CallNode = .init(name: frame)
                    current.children[frame] = newChild
                    next = newChild
                }

                next.totalSamples += 1
                current = next
            }

            // The last frame in the stack is the currently executing function
            current.selfSamples += 1
        }

        return root
    }
}
extension Gecko.Profile.Thread: JSONObjectDecodable {
    @frozen public enum CodingKey: String, Sendable {
        case name
        case samples
    }

    public init(json: borrowing JSON.ObjectDecoder<CodingKey>) throws {
        self.init(name: try json[.name].decode(), samples: try json[.samples].decode())
    }
}
