public import JSON

public protocol SwiftDemanglableProfile {
    static func resymbolicate(
        json: inout JSON.Node,
        by transform: (consuming String) -> String
    ) throws
}
