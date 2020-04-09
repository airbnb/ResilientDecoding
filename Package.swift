// swift-tools-version:5.2
import PackageDescription

let package = Package(
  name: "ResilientDecoding",
  platforms: [
      .iOS(.v12),
      .tvOS(.v12),
      .watchOS(.v5),
      .macOS(.v10_14),
  ],
  products: [
    .library(
      name: "ResilientDecoding",
      targets: ["ResilientDecoding"]),
  ],
  targets: [
    .target(
      name: "ResilientDecoding",
      dependencies: []),
    .testTarget(
      name: "ResilientDecodingTests",
      dependencies: ["ResilientDecoding"]),
  ]
)
