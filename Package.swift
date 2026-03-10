// swift-tools-version:6.2
import PackageDescription

let package: Package = .init(
    name: "wasm-profile-exporter",
    platforms: [.macOS(.v15), .iOS(.v18), .tvOS(.v18), .visionOS(.v2), .watchOS(.v11)],
    products: [
    ],
    dependencies: [
        .package(url: "https://github.com/tayloraswift/d", from: "0.7.0"),
        .package(url: "https://github.com/tayloraswift/swift-json", from: "2.3.0"),
        .package(url: "https://github.com/tayloraswift/swift-io", from: "0.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "FirefoxProfileExporter",
            dependencies: [
                .target(name: "FirefoxProfile"),

                .product(name: "D", package: "d"),
                .product(name: "JSON", package: "swift-json"),
                .product(name: "SystemIO", package: "swift-io"),
                .product(name: "System_ArgumentParser", package: "swift-io"),
            ],
        ),
        .target(
            name: "FirefoxProfile",
            dependencies: [
                .product(name: "JSON", package: "swift-json"),
            ],
        ),
    ]
)

for target: Target in package.targets {
    {
        $0 = ($0 ?? []) + [
            .enableUpcomingFeature("ExistentialAny")
        ]
    }(&target.swiftSettings)
}
