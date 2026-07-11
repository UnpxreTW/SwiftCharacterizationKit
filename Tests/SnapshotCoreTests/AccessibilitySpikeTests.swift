//
//  SnapshotCoreTests
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

#if canImport(UIKit) && !os(watchOS)

import SnapshotCore
import SwiftUI
import Testing
import UIKit

/// SwiftUI 輔助功能樹可列舉性 spike
///
/// 問題：「SwiftUI 經 `UIHostingController` 暴露的 a11y 元素能否以公開 API 穩定遍歷取得
/// identifier／label／value／traits」——結論決定 `.accessibilityTree` 對 SwiftUI 的可用性。
///
/// **實測結論（iOS 27 sim、unhosted SwiftPM 測試 process）**：不可行。
/// 即使 key window、appearance transition、`CATransaction.flush()`、1 秒 run loop 輪詢齊上，
/// `_UIHostingView.accessibilityElements` 恆為空陣列（bridge 有回應、零元素）、無 UIKit 子視圖可退。
/// UIKit 視圖樹（`AccessibilityTreeSerializerTests`）同 API 全數可取——限制只在
/// 「SwiftUI × 無 host app 的測試 process」這個交點；hosted test target（app unit test
/// 天生 hosted）預期可行、屬待 pilot 驗證的推論。本 suite 把此限制釘成 characterization：
/// 哪天 OS 讓它 materialize 了，測試會轉紅通知我們解除限制。
private final class AccessibilitySpikeTests {

	/// 釘住現況：unhosted process 裡 SwiftUI 的 a11y 元素不可列舉（空樹）。
	@Test @MainActor
	func `swiftui accessibility elements are not enumerable in unhosted test process`() {
		let hostingController: UIHostingController = .init(rootView: SpikeScreen())
		let surface = HostingWindowRenderer().render(viewController: hostingController)
		hostingController.beginAppearanceTransition(true, animated: false)
		hostingController.endAppearanceTransition()
		CATransaction.flush()
		var attemptIndex = 0
		while attemptIndex < 10, (hostingController.view.accessibilityElements ?? []).isEmpty {
			RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
			CATransaction.flush()
			attemptIndex += 1
		}
		let serialized = AccessibilityTreeSerializer().serialize(rootView: surface.rootView)
		print("=== SwiftUI a11y spike (unhosted) ===")
		print("window key: \(surface.window.isKeyWindow), poll attempts: \(attemptIndex)")
		print("hosting accessibilityElements: \(hostingController.view.accessibilityElements?.count ?? -1)")
		print("serialized tree:\n\(serialized)=== spike end ===")
		#expect(surface.window.isKeyWindow)
		#expect(hostingController.view.accessibilityElements?.isEmpty == true)
		#expect(serialized == "(no accessibility elements)\n")
	}

	/// 診斷用：hosting 子樹的原始結構 dump（class／subviews／a11y 元素數）留檔測試 log。
	@Test @MainActor
	func `diagnostic dump of hosting subtree`() {
		let surface = HostingWindowRenderer().render(view: SpikeScreen())
		var lines: [String] = []
		dump(node: surface.window, depth: 0, into: &lines)
		print("=== raw hosting dump begin ===\n\(lines.joined(separator: "\n"))\n=== raw hosting dump end ===")
		#expect(!lines.isEmpty)
	}

	/// spike 受測畫面：涵蓋 identifier、label、value、trait 與巢狀 container
	private struct SpikeScreen: View {

		/// 元素齊備的固定畫面（`.constant` 綁定確保決定性）
		var body: some View {
			VStack(spacing: 12) {
				Text("Characterization")
					.accessibilityIdentifier("title-text")
				Button("Sign In") {}
					.accessibilityIdentifier("sign-in-button")
				Toggle("Notifications", isOn: .constant(true))
					.accessibilityIdentifier("notification-toggle")
				Slider(value: .constant(0.5))
					.accessibilityIdentifier("volume-slider")
				VStack {
					Text("Nested First")
					Text("Nested Second")
				}
				.accessibilityElement(children: .contain)
				.accessibilityIdentifier("nested-group")
			}
		}
	}

	/// 遞迴 dump：subviews 與 accessibilityElements 兩條軸都走
	@MainActor
	private func dump(node: NSObject, depth: Int, into lines: inout [String]) {
		guard depth < 12 else { return }
		let indent: String = .init(repeating: "  ", count: depth)
		let elementsCount = node.accessibilityElements?.count ?? -1
		let identifier = (node as? UIView)?.accessibilityIdentifier ?? "-"
		lines.append(indent + "\(type(of: node)) isElement=\(node.isAccessibilityElement) elements=\(elementsCount) "
			+ "count=\(node.accessibilityElementCount()) identifier=\(identifier) label=\(node.accessibilityLabel ?? "-")")
		if let elements = node.accessibilityElements {
			for element in elements.compactMap({ $0 as? NSObject }) {
				dump(node: element, depth: depth + 1, into: &lines)
			}
		} else if let view = node as? UIView {
			for subview in view.subviews {
				dump(node: subview, depth: depth + 1, into: &lines)
			}
		}
	}
}

#endif
