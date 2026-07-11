//
//  SnapshotCore
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

#if canImport(UIKit) && !os(watchOS)

import UIKit

/// 一次渲染的產物：window 與受測根視圖
///
/// window 必須隨產物一起持有——它一旦釋放，視圖就脫離 hierarchy，
/// 輔助功能樹與 layout 資訊跟著失效；序列化完成前呼叫端不可丟棄本值。
@MainActor
public struct RenderedSurface {

	/// 承載渲染的固定尺寸 window
	public let window: UIWindow

	/// 受測根視圖（序列化的起點）
	public let rootView: UIView

	/// 以 window 與根視圖建立渲染產物
	public init(window: UIWindow, rootView: UIView) {
		self.window = window
		self.rootView = rootView
	}
}

#endif
