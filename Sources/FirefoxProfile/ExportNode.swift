public struct ExportNode {
    public let name: String
    public let totalFraction: Double
    public let selfFraction: Double
    public let children: [ExportNode]

    public init(
        name: String,
        totalFraction: Double,
        selfFraction: Double,
        children: [ExportNode]
    ) {
        self.name = name
        self.totalFraction = totalFraction
        self.selfFraction = selfFraction
        self.children = children
    }
}
