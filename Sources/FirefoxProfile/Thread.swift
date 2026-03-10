import JSON

public struct Thread: JSONObjectDecodable {
    public enum CodingKey: String, Sendable {
        case name
        case stringArray
        case funcTable
        case frameTable
        case stackTable
        case samples
    }

    let name: String
    let stringArray: [String]?

    let funcTable: FuncTable?
    let frameTable: FrameTable?
    let stackTable: StackTable?
    let samples: Samples

    public init(json: JSON.ObjectDecoder<CodingKey>) throws {
        self.name = try json[.name].decode()
        self.stringArray = try json[.stringArray]?.decode() ?? []
        self.funcTable = try json[.funcTable]?.decode()
        self.frameTable = try json[.frameTable]?.decode()
        self.stackTable = try json[.stackTable]?.decode()
        self.samples = try json[.samples].decode()
    }
}
extension Thread {
    /// Resolves a stack index into an array of function names.
    /// The resulting array is ordered from the root of the call tree down to the executing leaf.
    public func resolveStack(index: Int?) -> [String] {
        // If the stack index is nil, the thread was likely idle during this sample.
        guard var currentIndex = index else {
            return []
        }

        // Ensure all necessary lookup tables are present in the profile.
        guard let stackTable = self.stackTable,
              let frameTable = self.frameTable,
              let funcTable = self.funcTable,
              let strings = self.stringArray else {
            return []
        }

        var frames: [String] = []

        // The prefix chain points upwards from the leaf to the root.
        // We iterate until there is no parent prefix.
        while true {
            // 1. Look up the frame index for this stack entry
            let frameIndex = stackTable.frame[currentIndex]

            // 2. Look up the function index for this frame
            let funcIndex = frameTable.`func`[frameIndex]

            // 3. Look up the string index for this function's name
            let nameIndex = funcTable.name[funcIndex]

            // 4. Resolve the actual text
            let functionName = strings[nameIndex]
            frames.append(functionName)

            // 5. Move up to the parent stack frame, or break if at the root
            if let parentIndex = stackTable.prefix[currentIndex] {
                currentIndex = parentIndex
            } else {
                break
            }
        }

        // The traversal collected frames from leaf -> root.
        // Reversing it gives us the standard root -> leaf call stack order.
        return frames.reversed()
    }
}
extension Thread {
    /// Aggregates all time-series samples into a single call tree.
    public func buildCallTree() -> CallNode {
        let root: CallNode = .init(name: "(root)")

        for stackIndex: Int? in self.samples.stack {
            let frames: [String] = self.resolveStack(index: stackIndex)
            if frames.isEmpty {
                continue
            }

            root.totalSamples += 1
            var current: CallNode = root

            for frame: String in frames {
                let next: CallNode

                if let existing: CallNode = current.children[frame] {
                    next = existing
                } else {
                    let newChild: CallNode = .init(name: frame)
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
