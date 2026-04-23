#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

public enum SwiftDemangler: Sendable {}
extension SwiftDemangler {
    /// The string should look like `engine.wasm.$s11GameEconomy12`
    public static func demangle(compound text: String) -> String? {
        let pieces: [Substring] = text.split(separator: ".", omittingEmptySubsequences: false)
        return pieces.lazy.map {
            if case "$" = $0.first,
                let demangled: String = self.demangle(prefixed: String.init($0)) {
                return "'\(demangled)'"[...]
            } else {
                return $0
            }
        }.joined(separator: ".")
    }
    public static func demangle(prefixed symbol: String) -> String? {
        if  let string: UnsafeMutablePointer<Int8> =
            _swift_demangle(symbol, symbol.utf8.count, nil, nil, 0) {
            defer {
                string.deallocate()
            }
            return String.init(cString: string)
        } else {
            return nil
        }
    }
}
