//
//  SnapshotCore
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

#if canImport(UIKit) && !os(watchOS)

import UIKit

/// `.viewHierarchy` 策略（UIViewController）：UIKit／storyboard VC 的結構釘
extension GoldenStrategy where Subject: UIViewController {

	/// 渲染 view controller 後序列化視圖階層（預設 iPhone 直向畫布）
	@MainActor
	public static var viewHierarchy: GoldenStrategy<Subject> {
		viewHierarchy(preset: .iPhonePortrait)
	}

	/// 渲染 view controller 後序列化視圖階層（指定畫布 preset）
	///
	/// isolation 收斂方式同 `.accessibilityTree`——取得點 `@MainActor` 限定、
	/// 閉包內 `MainActor.assumeIsolated` 交還同步事實。
	@MainActor
	public static func viewHierarchy(preset: DevicePreset) -> GoldenStrategy<Subject> {
		GoldenStrategy(fileExtension: "hierarchy.txt") { subject in
			MainActor.assumeIsolated {
				let surface = HostingWindowRenderer(preset: preset).render(viewController: subject)
				return ViewHierarchySerializer().serialize(rootView: surface.rootView)
			}
		}
	}
}

/// `.viewHierarchy` 策略（UIView）
extension GoldenStrategy where Subject: UIView {

	/// 渲染單一 view 後序列化視圖階層（預設 iPhone 直向畫布）
	@MainActor
	public static var viewHierarchy: GoldenStrategy<Subject> {
		viewHierarchy(preset: .iPhonePortrait)
	}

	/// 渲染單一 view 後序列化視圖階層（指定畫布 preset）
	@MainActor
	public static func viewHierarchy(preset: DevicePreset) -> GoldenStrategy<Subject> {
		GoldenStrategy(fileExtension: "hierarchy.txt") { subject in
			MainActor.assumeIsolated {
				let surface = HostingWindowRenderer(preset: preset).render(view: subject)
				return ViewHierarchySerializer().serialize(rootView: surface.rootView)
			}
		}
	}
}

#endif
