// swift-tools-version:5.2
import PackageDescription

let package = Package(
  name: "ResilientDecoding",
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
