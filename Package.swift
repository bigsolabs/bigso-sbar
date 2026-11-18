// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScriptBar",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "ScriptBar", targets: ["ScriptBar"])],
    targets: [.executableTarget(name: "ScriptBar", path: "Sources/ScriptBar")]
)
