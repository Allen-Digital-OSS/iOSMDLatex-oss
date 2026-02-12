// swift-tools-version: 5.7
// MDLatex v2.0.1 - Enhanced table support for LaTeX and Markdown
import PackageDescription

let package = Package(
    name: "MDLatex",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "MDLatex",
            targets: ["MDLatex"]
        ),
    ],
    dependencies: [
        // Add any dependencies your package requires
        .package(url: "https://github.com/johnxnguyen/Down.git", .upToNextMajor(from: "0.11.0")) // Markdown parsing
    ],
    targets: [
        .target(
            name: "MDLatex",
            dependencies: ["Down"],
            resources: [
                .process("Resources") // Include HTML templates or other assets
            ]
        ),
        .testTarget(
            name: "MDLatexTests",
            dependencies: ["MDLatex"]
        ),
    ]
)
