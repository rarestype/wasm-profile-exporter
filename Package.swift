// swift-tools-version:6.2
import PackageDescription

let package: Package = .init(
    name: "wasm-profile-exporter",
    platforms: [.macOS(.v15), .iOS(.v18), .tvOS(.v18), .visionOS(.v2), .watchOS(.v11)],
    products: [
        .executable(name: "wasm-profile-exporter", targets: ["ProfileExporter"]),
        .library(name: "ProfileFormats", targets: ["ProfileFormats"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ordo-one/dollup", from: "1.0.1"),

        .package(url: "https://github.com/tayloraswift/d", from: "0.7.1"),
        .package(url: "https://github.com/rarestype/swift-io", from: "1.2.0"),
        .package(url: "https://github.com/rarestype/swift-json", from: "2.3.2"),
    ],
    targets: [
        .executableTarget(
            name: "ProfileExporter",
            dependencies: [
                .target(name: "ProfileFormats"),

                .product(name: "D", package: "d"),
                .product(name: "JSON", package: "swift-json"),
                .product(name: "SystemIO", package: "swift-io"),
                .product(name: "System_ArgumentParser", package: "swift-io"),
            ],
        ),
        .target(
            name: "ProfileFormats",
            dependencies: [
                .product(name: "JSON", package: "swift-json"),
            ],
        ),
        .testTarget(
            name: "ProfileFormatTests",
            dependencies: [
                .target(name: "ProfileFormats"),
                .product(name: "SystemIO", package: "swift-io"),
            ],
            exclude: [
                "profiles",
            ]
        ),
    ]
)

for target: Target in package.targets {
    {
        var settings: [SwiftSetting] = $0 ?? []

        settings.append(.enableUpcomingFeature("ExistentialAny"))
        settings.append(.enableUpcomingFeature("InternalImportsByDefault"))
        settings.append(.enableExperimentalFeature("StrictConcurrency"))

        $0 = settings
    } (&target.swiftSettings)
}
