import ProfileFormats
import JSON
import SystemIO

extension Gecko.Profile {
    static func load(from file: FilePath) throws -> Self {
        let json: JSON = .init(utf8: try file.read()[...])
        let root: JSON.Node = try .init(parsing: json)
        return try self.init(json: root)
    }
}
