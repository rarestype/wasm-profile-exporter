#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

public struct SwiftDemangler: Sendable {
    private typealias Function = @convention(c) (
        _ name: UnsafePointer<UInt8>?,
        _ count: Int,
        _ output: UnsafeMutablePointer<UInt8>?,
        _ capacity: UnsafeMutablePointer<Int>?,
        _ flags: UInt32
    ) -> UnsafeMutablePointer<Int8>?

    private let function: Function

    private init(_ function: Function) {
        self.function = function
    }
}
extension SwiftDemangler {
    public init?() {
        #if canImport(Glibc) || canImport(Darwin)
        guard let swift: UnsafeMutableRawPointer = dlopen(nil, RTLD_NOW) else {
            return nil
        }
        guard let symbol: UnsafeMutableRawPointer = dlsym(swift, "swift_demangle") else {
            return nil
        }
        self.init(unsafeBitCast(symbol, to: Function.self))
        #else
        return nil
        #endif
    }
}
extension SwiftDemangler {
    /// The string should look like `engine.wasm.$s11GameEconomy12`
    public func demangle(compound text: String) -> String? {
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
    public func demangle(prefixed symbol: String) -> String? {
        if  let string: UnsafeMutablePointer<Int8> =
            self.function(symbol, symbol.utf8.count, nil, nil, 0) {
            defer {
                string.deallocate()
            }
            return String.init(cString: string)
        } else {
            return nil
        }
    }
}
