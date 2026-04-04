// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PlexusOneiOS",
    platforms: [
        .iOS(.v16),  // iPhone and iPad
    ],
    products: [
        .library(
            name: "PlexusOneiOS",
            targets: ["PlexusOneiOS"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.2.0"),
    ],
    targets: [
        .target(
            name: "PlexusOneiOS",
            dependencies: ["SwiftTerm"],
            path: "Sources/PlexusOneiOS"
        ),
        .testTarget(
            name: "PlexusOneiOSTests",
            dependencies: ["PlexusOneiOS"],
            path: "Tests/PlexusOneiOSTests"
        ),
    ]
)
