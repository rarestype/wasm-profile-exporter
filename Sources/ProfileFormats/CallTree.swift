public final class CallTree {
    var _node: CallNode
    init(node: consuming CallNode) {
        self._node = node
    }
}
extension CallTree {
    static func new(name: String) -> Self { .init(node: .init(name: name)) }

    public var node: CallNode { _read { yield self._node } }
}
extension CallTree {
    /// Aggregates all time-series samples into a single call tree.
    public static func tree(
        thread: V8.Profile
    ) throws -> Self {
        .init(node: .tree(thread: thread))
    }
    /// Aggregates all time-series samples into a single call tree.
    public static func tree(
        thread: Gecko.Profile.Thread,
        shared: Gecko.Profile.Shared
    ) throws -> Self {
        let root: Self = .new(name: "(root)")

        // if the stack index is nil, the thread was likely idle during that sample
        for case let index? in thread.samples.stack {
            let frames: [String] = try shared.stack(resolving: index)
            if  frames.isEmpty {
                continue
            }

            root._node.total += 1
            var current: CallTree = root

            for frame: String in frames {
                let next: CallTree = current._node.child(name: frame)
                next._node.total += 1
                current = next
            }

            // The last frame in the stack is the currently executing function
            current._node.`self` += 1
        }

        return root
    }
}
