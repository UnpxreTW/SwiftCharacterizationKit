//
//  SnapshotCore
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

#if canImport(UIKit) && !os(watchOS)

import SwiftUI
import UIKit

/// `.accessibilityTree` 策略（SwiftUI）：畫面層 golden 的預設選擇
///
/// - Important: SwiftUI 的 a11y 元素只在 **hosted test target**（有 host app 的
///   unit test，app 專案的 test target 天生如此）materialize；unhosted 的
///   SwiftPM 測試 process 實測列舉恆為空（見 kit 自測 `AccessibilitySpikeTests`）。
extension GoldenStrategy where Subject: View {

	/// 渲染 SwiftUI view 後序列化輔助功能樹（預設 iPhone 直向畫布）
	@MainActor
	public static var accessibilityTree: GoldenStrategy<Subject> {
		accessibilityTree(preset: .iPhonePortrait)
	}

	/// 渲染 SwiftUI view 後序列化輔助功能樹（指定畫布 preset）
	///
	/// 序列化閉包內以 `MainActor.assumeIsolated` 收斂 isolation——策略取得點
	/// 已由 `@MainActor` 限定，比對呼叫與序列化同步發生在同一 isolation 上，
	/// 動態斷言只是把這個既定事實交還編譯層看不見的縫。
	@MainActor
	public static func accessibilityTree(preset: DevicePreset) -> GoldenStrategy<Subject> {
		GoldenStrategy(fileExtension: "a11y.txt") { subject in
			MainActor.assumeIsolated {
				let surface = HostingWindowRenderer(preset: preset).render(view: subject)
				return AccessibilityTreeSerializer().serialize(rootView: surface.rootView)
			}
		}
	}
}

/// `.accessibilityTree` 策略（UIViewController）
extension GoldenStrategy where Subject: UIViewController {

	/// 渲染 view controller 後序列化輔助功能樹（預設 iPhone 直向畫布）
	@MainActor
	public static var accessibilityTree: GoldenStrategy<Subject> {
		accessibilityTree(preset: .iPhonePortrait)
	}

	/// 渲染 view controller 後序列化輔助功能樹（指定畫布 preset）
	@MainActor
	public static func accessibilityTree(preset: DevicePreset) -> GoldenStrategy<Subject> {
		GoldenStrategy(fileExtension: "a11y.txt") { subject in
			MainActor.assumeIsolated {
				let surface = HostingWindowRenderer(preset: preset).render(viewController: subject)
				return AccessibilityTreeSerializer().serialize(rootView: surface.rootView)
			}
		}
	}
}

/// `.accessibilityTree` 策略（UIView）
extension GoldenStrategy where Subject: UIView {

	/// 渲染單一 view 後序列化輔助功能樹（預設 iPhone 直向畫布）
	@MainActor
	public static var accessibilityTree: GoldenStrategy<Subject> {
		accessibilityTree(preset: .iPhonePortrait)
	}

	/// 渲染單一 view 後序列化輔助功能樹（指定畫布 preset）
	@MainActor
	public static func accessibilityTree(preset: DevicePreset) -> GoldenStrategy<Subject> {
		GoldenStrategy(fileExtension: "a11y.txt") { subject in
			MainActor.assumeIsolated {
				let surface = HostingWindowRenderer(preset: preset).render(view: subject)
				return AccessibilityTreeSerializer().serialize(rootView: surface.rootView)
			}
		}
	}
}

#endif
