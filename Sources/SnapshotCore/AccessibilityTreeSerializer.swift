//
//  SnapshotCore
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

#if canImport(UIKit) && !os(watchOS)

import UIKit

/// 輔助功能樹序列化：遍歷視圖樹收 identifier／label／value／traits／frame → 縮排文字
///
/// 畫面層 golden 的主力策略——文字、無像素、跨機穩定；順帶盤出畫面的
/// a11y identifier 覆蓋缺口（識別字空白的元素一眼可見），是 XCUITest 的前置資產。
/// 只讀公開 API（`UIAccessibility` 系列），不觸碰 SwiftUI 私有內部。
@MainActor
public struct AccessibilityTreeSerializer {

	// MARK: Public

	/// 從根視圖序列化整棵輔助功能樹
	///
	/// 節點收錄規則：`isAccessibilityElement == true`、或雖非元素但帶有
	/// accessibility identifier 的容器（SwiftUI `.accessibilityElement(children: .contain)`
	/// 產物）；隱藏視圖整枝略過。輸出以 tab 縮排表達巢狀深度、結尾帶換行。
	public func serialize(rootView: UIView) -> String {
		var lines: [String] = []
		appendLines(for: rootView, depth: 0, into: &lines)
		guard !lines.isEmpty else { return "(no accessibility elements)\n" }
		return lines.joined(separator: "\n") + "\n"
	}

	/// 建立序列化器（無狀態）
	public init() {}

	// MARK: Private

	/// 已知 traits 的名稱對照（表序固定＝輸出序固定；未知 bit 以 raw 值列出）
	private static let traitNameTable: [(trait: UIAccessibilityTraits, name: String)] = [
		(.button, "button"),
		(.link, "link"),
		(.header, "header"),
		(.searchField, "searchField"),
		(.image, "image"),
		(.selected, "selected"),
		(.playsSound, "playsSound"),
		(.keyboardKey, "keyboardKey"),
		(.staticText, "staticText"),
		(.summaryElement, "summaryElement"),
		(.notEnabled, "notEnabled"),
		(.updatesFrequently, "updatesFrequently"),
		(.startsMediaSession, "startsMediaSession"),
		(.adjustable, "adjustable"),
		(.allowsDirectInteraction, "allowsDirectInteraction"),
		(.causesPageTurn, "causesPageTurn"),
		(.tabBar, "tabBar"),
		(.toggleButton, "toggleButton"),
		(.supportsZoom, "supportsZoom")
	]

	/// 把 traits OptionSet 轉成穩定排序的名稱清單
	///
	/// 不設 `static`（不碰 self、邏輯上可以是）：`static` 會強迫呼叫端寫
	/// `Self.names(of:...)`，SwiftStyleKit 的 propertyTypes（explicit 模式）
	/// 會把回傳型別誤標成 `Self`（實為 `[String]`）而編譯失敗；instance method
	/// 呼叫端用隱式 self、不帶型別字首即可繞過此已知誤判。
	private func names(of traits: UIAccessibilityTraits) -> [String] {
		var names: [String] = []
		var knownBits: UIAccessibilityTraits = []
		for entry in Self.traitNameTable where traits.contains(entry.trait) {
			names.append(entry.name)
			knownBits.insert(entry.trait)
		}
		let unknownBits = traits.rawValue & ~knownBits.rawValue
		if unknownBits != 0 {
			names.append("raw(0x\(String(unknownBits, radix: 16)))")
		}
		return names
	}

	/// 遞迴遍歷：命中收錄規則的節點輸出一行、其子節點縮排一層
	private func appendLines(for node: NSObject, depth: Int, into lines: inout [String]) {
		if let view = node as? UIView, view.isHidden {
			return
		}
		var childDepth = depth
		if shouldEmit(node) {
			lines.append(String(repeating: "\t", count: depth) + line(for: node))
			childDepth += 1
		}
		for child in accessibilityChildren(of: node) {
			appendLines(for: child, depth: childDepth, into: &lines)
		}
	}

	/// 節點是否輸出：a11y 元素、或帶 identifier 的容器
	private func shouldEmit(_ node: NSObject) -> Bool {
		if node.isAccessibilityElement {
			return true
		}
		if let identifier = accessibilityIdentifier(of: node), !identifier.isEmpty {
			return true
		}
		return false
	}

	/// 取子節點：優先 `accessibilityElements`、次之 container 協定、最後 UIView 子視圖
	private func accessibilityChildren(of node: NSObject) -> [NSObject] {
		if let elements = node.accessibilityElements {
			return elements.compactMap { $0 as? NSObject }
		}
		let elementCount = node.accessibilityElementCount()
		if elementCount != NSNotFound, elementCount > 0 {
			return (0 ..< elementCount).compactMap { node.accessibilityElement(at: $0) as? NSObject }
		}
		if let view = node as? UIView {
			return view.subviews
		}
		return []
	}

	/// 單節點輸出行：只列有值的欄位，欄位順序固定（identifier → label → value → traits → frame）
	private func line(for node: NSObject) -> String {
		var fields: [String] = ["-"]
		if let identifier = accessibilityIdentifier(of: node), !identifier.isEmpty {
			fields.append("identifier \"\(identifier)\"")
		}
		if let label = node.accessibilityLabel, !label.isEmpty {
			fields.append("label \"\(label)\"")
		}
		if let value = node.accessibilityValue, !value.isEmpty {
			fields.append("value \"\(value)\"")
		}
		let traitNames = names(of: node.accessibilityTraits)
		if !traitNames.isEmpty {
			fields.append("traits [\(traitNames.joined(separator: ", "))]")
		}
		let frame = node.accessibilityFrame
		fields.append("frame (\(Int(frame.origin.x.rounded())), \(Int(frame.origin.y.rounded())), "
			+ "\(Int(frame.size.width.rounded())), \(Int(frame.size.height.rounded())))")
		return fields.joined(separator: " ")
	}

	/// 取 accessibility identifier
	///
	/// 兩段 fallback：UIView 直讀 → KVC（responds 檢查後取值）。
	/// `// !!!:` 不可用 `as? UIAccessibilityIdentification`——iOS 27 sim 實測該轉型
	/// 對 UIView 直接 runtime trap（`Could not cast value…`、整個測試 process 崩潰），
	/// 非單純回 nil；KVC 段接住 `UIAccessibilityElement` 與 SwiftUI 私有元素類等節點。
	private func accessibilityIdentifier(of node: NSObject) -> String? {
		if let view = node as? UIView {
			return view.accessibilityIdentifier
		}
		if node.responds(to: NSSelectorFromString("accessibilityIdentifier")) {
			return node.value(forKey: "accessibilityIdentifier") as? String
		}
		return nil
	}
}

#endif
