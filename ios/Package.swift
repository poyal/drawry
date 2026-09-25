// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DrawryCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "DrawryCore", targets: ["DrawryCore"]), .executable(name: "CoreCheck", targets: ["CoreCheck"])],
    targets: [
        .target(name: "DrawryCore", path: "Core"),
        .executableTarget(name: "CoreCheck", dependencies: ["DrawryCore"], path: "CoreCheck"),
        .testTarget(name: "DrawryCoreTests", dependencies: ["DrawryCore"], path: "CoreTests")
    ]
)
