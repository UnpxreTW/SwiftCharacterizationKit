//
//  SnapshotCore
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

#if canImport(UIKit) && !os(watchOS)

import UIKit

/// 視圖階層序列化：UIView class 名＋frame＋關鍵屬性 → 縮排文字
///
/// UIKit（storyboard VC）結構釘的主力——巨型 storyboard 重構時，
/// 這棵樹釘住「哪些視圖、什麼位置、顯示什麼字」。
/// 注意：SwiftUI hosting 內部的 class 名屬私有實作、跨 OS 版本可能改名，
/// SwiftUI 畫面請改用 `.accessibilityTree` 策略。
@MainActor
public struct ViewHierarchySerializer {

	/// 從根視圖序列化整棵視圖階層
	///
	/// 每行格式：`ClassName frame(x, y, w, h) [屬性…]`；子視圖以 tab 縮排一層、
	/// 結尾帶換行。隱藏視圖仍列出（帶 `hidden` 標記）——結構釘關心的是「存在什麼」。
	public func serialize(rootView: UIView) -> String {
		var lines: [String] = []
		appendLines(for: rootView, depth: 0, into: &lines)
		return lines.joined(separator: "\n") + "\n"
	}

	/// 建立序列化器（無狀態）
	public init() {}

	// MARK: Private

	/// 遞迴輸出視圖與其子視圖
	private func appendLines(for view: UIView, depth: Int, into lines: inout [String]) {
		lines.append(String(repeating: "\t", count: depth) + line(for: view))
		for subview in view.subviews {
			appendLines(for: subview, depth: depth + 1, into: &lines)
		}
	}

	/// 單視圖輸出行：class 名、frame、與有訊號的關鍵屬性
	private func line(for view: UIView) -> String {
		let frame = view.frame
		var fields = [
			String(describing: type(of: view)),
			"frame(\(Int(frame.origin.x.rounded())), \(Int(frame.origin.y.rounded())), "
				+ "\(Int(frame.size.width.rounded())), \(Int(frame.size.height.rounded())))"
		]
		if let text = displayedText(of: view), !text.isEmpty {
			fields.append("text \"\(text)\"")
		}
		if view.isHidden {
			fields.append("hidden")
		}
		if view.alpha < 1 {
			fields.append("alpha \(String(format: "%.2f", view.alpha))")
		}
		return fields.joined(separator: " ")
	}

	/// 取視圖顯示中的文字（label／輸入框／按鈕標題）
	private func displayedText(of view: UIView) -> String? {
		switch view {
		case let label as UILabel:
			label.text
		case let textField as UITextField:
			textField.text?.isEmpty == false ? textField.text : textField.placeholder
		case let textView as UITextView:
			textView.text
		case let button as UIButton:
			button.configuration?.title ?? button.currentTitle
		default:
			nil
		}
	}
}

#endif
