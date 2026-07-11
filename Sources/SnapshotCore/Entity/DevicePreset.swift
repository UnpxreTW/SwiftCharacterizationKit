//
//  SnapshotCore
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

import CoreGraphics

/// 渲染畫布的裝置尺寸 preset
///
/// 固定尺寸是決定性渲染的一環：畫面 golden 綁定明確畫布、不隨測試機螢幕漂移。
/// 尺寸為 point（非 pixel），文字層序列化不涉及 scale。
public struct DevicePreset: Sendable {

	/// iPhone 直向（393×852 point；iPhone 15–17 標準機身的邏輯尺寸）
	public static let iPhonePortrait: DevicePreset = .init(name: "iPhone-portrait", size: CGSize(width: 393, height: 852))

	/// iPad 直向（834×1194 point；11 吋 iPad Pro 的邏輯尺寸）
	public static let iPadPortrait: DevicePreset = .init(name: "iPad-portrait", size: CGSize(width: 834, height: 1194))

	/// preset 名（供訊息與未來檔名 key 使用）
	public let name: String

	/// 畫布尺寸（point）
	public let size: CGSize

	/// 自訂 preset
	public init(name: String, size: CGSize) {
		self.name = name
		self.size = size
	}

}
