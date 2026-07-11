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

/// 目前是否啟用 `UIView` 動畫（`UIView.areAnimationsEnabled` 的直接轉發）
///
/// 檔案層級 free function：``HostingWindowRenderer/render(viewController:)`` 內部若寫成
/// `let animationsWereEnabled = UIView.areAnimationsEnabled` 這種「型別名.成員」寫法，
/// SwiftStyleKit 的 propertyTypes（explicit 模式）會誤把回傳型別標成 `UIView`（實為
/// `Bool`）而編譯失敗；此處以無型別字首的 free function 回傳、呼叫端不觸發誤判。
private func uiViewAnimationsEnabled() -> Bool {
	UIView.areAnimationsEnabled
}

/// 主渲染路徑：把受測畫面放進固定尺寸 UIWindow、跑完 layout 再交付序列化
///
/// 真 window 是必要條件——輔助功能樹與正確 layout 都依賴視圖真的掛在
/// window hierarchy 上；SwiftUI 經 `UIHostingController` 包裝後走同一條路徑。
/// 渲染期間關閉動畫（決定性控制的一環），結束後還原原設定。
@MainActor
public struct HostingWindowRenderer {

	/// 渲染畫布尺寸（point）
	public let canvasSize: CGSize

	/// 渲染 UIViewController（storyboard VC 的結構釘走此入口）
	public func render(viewController: UIViewController) -> RenderedSurface {
		let window: UIWindow = .init(frame: CGRect(origin: .zero, size: canvasSize))
		let animationsWereEnabled = uiViewAnimationsEnabled()
		UIView.setAnimationsEnabled(false)
		defer { UIView.setAnimationsEnabled(animationsWereEnabled) }
		window.rootViewController = viewController
		// !!!: makeKeyAndVisible 而非單純 isHidden = false——輔助功能樹的掛載
		// 以 key window 為前提，非 key window 上的元素列舉結果不完整。
		window.makeKeyAndVisible()
		window.layoutIfNeeded()
		// !!!: SwiftUI hosting 的輔助功能元素在第一個 run loop pass 後才穩定成形，
		// 純 layoutIfNeeded 不夠——短暫 pump main run loop 讓非同步掛載完成。
		RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.02))
		window.layoutIfNeeded()
		let rootView: UIView = viewController.view ?? window
		return RenderedSurface(window: window, rootView: rootView)
	}

	/// 渲染單一 UIView（包進一個中性 view controller 再走 VC 入口）
	public func render(view: UIView) -> RenderedSurface {
		let containerViewController: UIViewController = .init()
		// !!!: 先把容器 view 定到畫布尺寸、再掛受測視圖——容器初始 frame 是螢幕尺寸，
		// 後掛會讓 autoresizing 在「螢幕 → 畫布」的縮放中把受測視圖擠壞。
		containerViewController.view.frame = CGRect(origin: .zero, size: canvasSize)
		view.frame = containerViewController.view.bounds
		view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		containerViewController.view.addSubview(view)
		let surface = render(viewController: containerViewController)
		return RenderedSurface(window: surface.window, rootView: view)
	}

	/// 渲染 SwiftUI view（包進 `UIHostingController` 再走 VC 入口）
	public func render(view: some View) -> RenderedSurface {
		render(viewController: UIHostingController(rootView: view))
	}

	/// 以裝置 preset 建立 renderer（預設 iPhone 直向 393×852）
	public init(preset: DevicePreset = .iPhonePortrait) {
		self.canvasSize = preset.size
	}

	/// 以自訂畫布尺寸建立 renderer
	public init(canvasSize: CGSize) {
		self.canvasSize = canvasSize
	}
}

#endif
