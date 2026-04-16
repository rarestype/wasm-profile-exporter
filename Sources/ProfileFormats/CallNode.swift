public struct CallNode: ~Copyable {
    public let name: String
    var total: Int
    var `self`: Int
    private(set) var children: [String: CallTree]
}
extension CallNode {
    init(name: String) {
        self.init(name: name, total: 0, self: 0, children: [:])
    }
}
extension CallNode {
    init(from node: borrowing V8.Node, nodes: borrowing [Int: V8.Node]) {
        self.init(name: node.callFrame.functionName)
        self.`self` = node.hitCount
        self.total = node.hitCount

        for child: Int in node.children {
            if  let child: V8.Node = nodes[child] {
                let child: CallTree = .init(node: .init(from: child, nodes: nodes))

                // V8 can sometimes have sibling nodes with the exact same function name
                // if they originated from slightly different script contexts.
                // We merge them together in our normalized CallNode tree.
                child.node.merge(into: &self[child.node.name])

                // A parent's total time includes all of its children's total time
                self.total += child.node.total
            }
        }
    }
}
extension CallNode {
    subscript(name: String) -> Self {
        _read {
            if  let existing: CallTree = self.children[name] {
                yield existing._node
            } else {
                let ephemeral: Self = .init(name: name)
                yield ephemeral
            }
        }
        _modify {
            if  let existing: CallTree = self.children[name] {
                yield &existing._node
            } else {
                var new: Self = .init(name: name)
                yield &new
                self.children[name] = .init(node: new)
            }
        }
    }

    mutating func child(name: String) -> CallTree {
        { $0 } (&self.children[name, default: .new(name: name)])
    }
}
extension CallNode {
    public var samples: (self: Int, total: Int) {
        // it’s always about me
        (self: self.`self`, self.total)
    }

    /// Converts the pre-aggregated V8 node graph into a standard `CallNode` tree.
    public static func tree(thread: V8.Profile) -> Self {
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
        var root: Self = .init(name: "(root)")

        // 4. Recursively build the tree from the root nodes
        for id: Int in rootIDs {
            if  let v8Root: V8.Node = nodes[id] {
                let child: CallNode = .init(from: v8Root, nodes: nodes)

                // Merge into the synthetic root’s children,
                // handling duplicate names if any exist
                child.merge(into: &root[child.name])

                root.total += child.total
            }
        }

        return root
    }
}
extension CallNode {
    private func search(for target: String, mergingInto newRoot: inout CallNode) -> Bool {
        if self.name == target {
            self.merge(into: &newRoot)
            return true
        }

        var found: Bool = false

        for child: CallTree in self.children.values {
            let foundInChild: Bool = child.node.search(for: target, mergingInto: &newRoot)
            if  foundInChild {
                found = true
            }
        }

        return found
    }

    func merge(into node: inout Self) {
        node.total += self.total
        node.`self` += self.`self`

        for (name, child): (String, CallTree) in self.children {
            child.node.merge(into: &node[name])
        }
    }
}
extension CallNode {
    /// Returns a new aggregated tree rooted at the given target function name,
    /// or `nil` if the function was never called.
    public func focused(on target: String) -> CallTree? {
        var fresh: Self = .init(name: target)
        let found: Bool = self.search(for: target, mergingInto: &fresh)
        if  found {
            return .init(node: fresh)
        } else {
            return nil
        }
    }
    /// Converts the node into an ExportNode, calculating fractions against a baseline.
    /// Drops any branches where the total percentage falls below the threshold.
    public func export(baselineSamples: Int, threshold: Double) -> ExportNode? {
        // Use explicit type names and `init` tokens for numeric casts within larger expressions
        let totalFraction: Double = Double.init(self.total) / Double.init(
            baselineSamples
        )

        // We still compare the threshold against a 0-100 percentage
        // to keep the CLI argument user-friendly (e.g., passing 0.5 for 0.5%)
        let totalPercentage: Double = totalFraction * 100.0

        if totalPercentage < threshold {
            return nil
        }

        let selfFraction: Double = Double.init(self.`self`) / Double.init(baselineSamples)

        var exportedChildren: [ExportNode] = []

        for child: CallTree in self.children.values {
            if  let exportedChild: ExportNode = child.node.export(
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
