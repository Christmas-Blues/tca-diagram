// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "TCADiagram",
  platforms: [
    .macOS(.v13),
  ],
  products: [
    .library(name: "tca-diagram-lib", targets: ["TCADiagramLib"]),
    .executable(name: "tca-diagram", targets: ["TCADiagram"]),
  ],
  dependencies: [
    .package(url: "git@github.com:apple/swift-syntax.git", branch: "main"),
    .package(url: "git@github.com:apple/swift-argument-parser.git", from: "1.2.0"),
  ],
  targets: [
    .target(
      name: "TCADiagramLib",
      dependencies: [
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "TCADiagramLibTests",
      dependencies: [
        "TCADiagramLib"
      ]
    ),
    .executableTarget(
      name: "TCADiagram",
      dependencies: [
        "TCADiagramLib",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),
  ]
)
