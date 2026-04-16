public final class CallNode {
    public let name: String
    public var totalSamples: Int
    public var selfSamples: Int
    public var children: [String: CallNode]

    public init(name: String) {
        self.name = name
        self.totalSamples = 0
        self.selfSamples = 0
        self.children = [:]
    }
}
extension CallNode {
    private convenience init(from node: borrowing V8.Node, nodes: borrowing [Int: V8.Node]) {
        self.init(name: node.callFrame.functionName)
        self.selfSamples = node.hitCount
        self.totalSamples = node.hitCount

        for child: Int in node.children {
            if  let child: V8.Node = nodes[child] {
                let child: CallNode = .init(from: child, nodes: nodes)

                // V8 can sometimes have sibling nodes with the exact same function name
                // if they originated from slightly different script contexts.
                // We merge them together in our normalized CallNode tree.
                if  let existing: CallNode = self.children[child.name] {
                    existing.merge(with: child)
                } else {
                    self.children[child.name] = child
                }

                // A parent's total time includes all of its children's total time
                self.totalSamples += child.totalSamples
            }
        }
    }
}
extension CallNode {
    /// Converts the pre-aggregated V8 node graph into a standard `CallNode` tree.
    public static func tree(thread: V8.Profile) throws -> Self {
        // 1. Create a lookup map for O(1) node access by ID, and track all children
        var nodes: [Int: V8.Node] = [:]
        var children: Set<Int> = []

        for node: V8.Node in thread.nodes {
            nodes[node.id] = node
            for child: Int in node.children {
                children.insert(child)
            }
        }

        // 2. Identify root nodes (nodes that are not listed in any node's `children` array)
        let rootIDs: [Int] = thread.nodes.compactMap { (node: V8.Node) -> Int? in
            if children.contains(node.id) {
                return nil
            } else {
                return node.id
            }
        }

        // 3. Create a synthetic root to hold everything
        let root: Self = .init(name: "(root)")

        // 4. Recursively build the tree from the root nodes
        for id: Int in rootIDs {
            if  let v8Root: V8.Node = nodes[id] {
                let childTree: CallNode = .init(from: v8Root, nodes: nodes)

                // Merge into the synthetic root’s children,
                // handling duplicate names if any exist
                if let existing: CallNode = root.children[childTree.name] {
                    existing.merge(with: childTree)
                } else {
                    root.children[childTree.name] = childTree
                }

                root.totalSamples += childTree.totalSamples
            }
        }

        return root
    }

    /// Aggregates all time-series samples into a single call tree.
    public static func tree(
        thread: Gecko.Profile.Thread,
        shared: Gecko.Profile.Shared
    ) throws -> Self {
        let root: Self = .init(name: "(root)")

        // if the stack index is nil, the thread was likely idle during that sample
        for case let index? in thread.samples.stack {
            let frames: [String] = try shared.stack(resolving: index)
            if  frames.isEmpty {
                continue
            }

            root.totalSamples += 1
            var current: CallNode = root

            for frame: String in frames {
                let next: CallNode

                if  let existing: CallNode = current.children[frame] {
                    next = existing
                } else {
                    next = .init(name: frame)
                    current.children[frame] = next
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
extension CallNode {
    /// Returns a new aggregated tree rooted at the given target function name,
    /// or `nil` if the function was never called.
    public func focused(on target: String) -> Self? {
        let newRoot: Self = .init(name: target)
        let found: Bool = self.search(for: target, mergingInto: newRoot)

        if found {
            return newRoot
        } else {
            return nil
        }
    }

    private func search(for target: String, mergingInto newRoot: CallNode) -> Bool {
        if self.name == target {
            newRoot.merge(with: self)
            return true
        }

        var found: Bool = false

        for child: CallNode in self.children.values {
            let foundInChild: Bool = child.search(for: target, mergingInto: newRoot)
            if  foundInChild {
                found = true
            }
        }

        return found
    }

    /// Recursively merges the samples and children of another node into this one.
    private func merge(with other: CallNode) {
        self.totalSamples += other.totalSamples
        self.selfSamples += other.selfSamples

        for (name, child): (String, CallNode) in other.children {
            if let existing: CallNode = self.children[name] {
                existing.merge(with: child)
            } else {
                self.children[name] = child.copy()
            }
        }
    }

    /// Creates an independent, deep clone of the current node and all descendants.
    private func copy() -> CallNode {
        let copy: CallNode = .init(name: self.name)
        copy.totalSamples = self.totalSamples
        copy.selfSamples = self.selfSamples

        for (name, child): (String, CallNode) in self.children {
            copy.children[name] = child.copy()
        }

        return copy
    }
}
extension CallNode {
    /// Converts the node into an ExportNode, calculating fractions against a baseline.
    /// Drops any branches where the total percentage falls below the threshold.
    public func export(baselineSamples: Int, threshold: Double) -> ExportNode? {
        // Use explicit type names and `init` tokens for numeric casts within larger expressions
        let totalFraction: Double = Double.init(self.totalSamples) / Double.init(
            baselineSamples
        )

        // We still compare the threshold against a 0-100 percentage
        // to keep the CLI argument user-friendly (e.g., passing 0.5 for 0.5%)
        let totalPercentage: Double = totalFraction * 100.0

        if totalPercentage < threshold {
            return nil
        }

        let selfFraction: Double = Double.init(self.selfSamples) / Double.init(baselineSamples)

        var exportedChildren: [ExportNode] = []

        for child: CallNode in self.children.values {
            if let exportedChild: ExportNode = child.export(
                    baselineSamples: baselineSamples,
                    threshold: threshold
                ) {
                exportedChildren.append(exportedChild)
            }
        }

        // Sort children descending by total fraction to keep the heaviest hitters first
        exportedChildren.sort {
            $0.totalFraction > $1.totalFraction
        }

        return .init(
            name: self.name,
            totalFraction: totalFraction,
            selfFraction: selfFraction,
            children: exportedChildren
        )
    }
}
