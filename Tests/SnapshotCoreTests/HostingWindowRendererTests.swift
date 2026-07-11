//
//  SnapshotCoreTests
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

#if canImport(UIKit) && !os(watchOS)

import SnapshotCore
import Testing
import UIKit

private final class HostingWindowRendererTests {

	/// VC 渲染後 root view 尺寸等於 preset 畫布、window 掛載正確。
	@Test
	@MainActor
	func `renders view controller at preset canvas size`() {
		let viewController: UIViewController = .init()
		viewController.view.backgroundColor = .white
		let surface = HostingWindowRenderer().render(viewController: viewController)
		#expect(surface.rootView.bounds.size == DevicePreset.iPhonePortrait.size)
		#expect(surface.window.rootViewController === viewController)
	}

	/// 單一 view 渲染走中性容器、rootView 即傳入視圖、frame 填滿自訂畫布。
	@Test
	@MainActor
	func `renders plain view as root of neutral container`() {
		let label: UILabel = .init()
		label.text = "hello"
		let surface = HostingWindowRenderer(canvasSize: CGSize(width: 200, height: 100)).render(view: label)
		#expect(surface.rootView === label)
		#expect(label.frame.size == CGSize(width: 200, height: 100))
		#expect(label.window === surface.window)
	}
}

#endif
