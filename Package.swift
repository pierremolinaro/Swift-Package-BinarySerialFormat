// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
//--------------------------------------------------------------------------------------------------

import PackageDescription

//--------------------------------------------------------------------------------------------------

let package = Package (
  name: "BinarySerialFormat",
  platforms: [.macOS (.v15)],
  products: [
    .library (name: "BinarySerialFormat", targets: ["BinarySerialFormat"]),
  ],
  targets: [
    .target (name: "BinarySerialFormat"),
    .testTarget (
      name: "TestF32",
      dependencies: ["BinarySerialFormat"],
    ),
  ]
)

//--------------------------------------------------------------------------------------------------
