// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Paperclip",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Paperclip", targets: ["Paperclip"])
    ],
    targets: [
        .executableTarget(
            name: "Paperclip",
            path: "Sources/Paperclip"
        )
    ]
)
