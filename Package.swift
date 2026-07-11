// swift-tools-version: 6.2
// 平台底線 iOS 26／macOS 26：畫面層（renderer／a11y 樹）只在 iOS 生效，
// macOS 供邏輯層 golden（.json／.text）使用。

import PackageDescription

let package: Package = .init(
	name: "SwiftCharacterizationKit",
	platforms: [
		.iOS("26.0"),
		.macOS("26.0"),
	],
	products: [
		.library(name: "SnapshotCore", targets: ["SnapshotCore"]),
	],
	dependencies: [
		.package(url: "https://github.com/UnpxreTW/SwiftStyleKit.git", from: "2.0.1"),
	],
	targets: [
		.target(
			name: "SnapshotCore",
			plugins: [.plugin(name: "SwiftStyleLint", package: "SwiftStyleKit")]
		),
		.testTarget(
			name: "SnapshotCoreTests",
			dependencies: ["SnapshotCore"],
			plugins: [.plugin(name: "SwiftStyleLint", package: "SwiftStyleKit")]
		),
	],
	swiftLanguageModes: [.v6]
)
