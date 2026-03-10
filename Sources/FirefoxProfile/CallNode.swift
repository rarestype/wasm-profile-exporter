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
    /// Returns a new aggregated tree rooted at the given target function name,
    /// or `nil` if the function was never called.
    public func focused(on target: String) -> CallNode? {
        let newRoot: CallNode = .init(name: target)
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
            if foundInChild {
                found = true
            }
        }

        return found
    }

    /// Recursively merges the samples and children of another node into this one.
    public func merge(with other: CallNode) {
        self.totalSamples += other.totalSamples
        self.selfSamples += other.selfSamples

        for (name, child): (String, CallNode) in other.children {
            if let existing: CallNode = self.children[name] {
                existing.merge(with: child)
            } else {
                self.children[name] = child.deepCopy()
            }
        }
    }

    /// Creates an independent, deep clone of the current node and all descendants.
    public func deepCopy() -> CallNode {
        let copy: CallNode = .init(name: self.name)
        copy.totalSamples = self.totalSamples
        copy.selfSamples = self.selfSamples

        for (name, child): (String, CallNode) in self.children {
            copy.children[name] = child.deepCopy()
        }

        return copy
    }
}
extension CallNode {
    /// Converts the node into an ExportNode, calculating fractions against a baseline.
    /// Drops any branches where the total percentage falls below the threshold.
    public func export(baselineSamples: Int, threshold: Double) -> ExportNode? {
        // Use explicit type names and `init` tokens for numeric casts within larger expressions
        let totalFraction: Double = Double.init(self.totalSamples) / Double.init(baselineSamples)

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
