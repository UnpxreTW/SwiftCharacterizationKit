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

private final class AccessibilityTreeSerializerTests {

	/// identifier／label／value／traits／frame 全欄位輸出、欄位順序固定。
	@Test
	@MainActor
	func `collects identifier label value traits and frame`() {
		let containerView: UIView = .init(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
		let elementView: UIView = .init(frame: CGRect(x: 10, y: 20, width: 100, height: 44))
		elementView.isAccessibilityElement = true
		elementView.accessibilityIdentifier = "sign-in"
		elementView.accessibilityLabel = "Sign In"
		elementView.accessibilityValue = "enabled"
		elementView.accessibilityTraits = .button
		elementView.accessibilityFrame = CGRect(x: 10, y: 20, width: 100, height: 44)
		containerView.addSubview(elementView)
		let serialized = AccessibilityTreeSerializer().serialize(rootView: containerView)
		#expect(
			serialized
				== "- identifier \"sign-in\" label \"Sign In\" value \"enabled\" traits [button] frame (10, 20, 100, 44)\n"
		)
	}

	/// 帶 identifier 的非元素容器也輸出、其子元素縮排一層。
	@Test
	@MainActor
	func `emits identified container with indented children`() {
		let groupView: UIView = .init(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
		groupView.accessibilityIdentifier = "form-group"
		groupView.accessibilityFrame = CGRect(x: 0, y: 0, width: 200, height: 100)
		let childView: UIView = .init(frame: CGRect(x: 0, y: 0, width: 50, height: 20))
		childView.isAccessibilityElement = true
		childView.accessibilityLabel = "Name"
		childView.accessibilityFrame = CGRect(x: 0, y: 0, width: 50, height: 20)
		groupView.addSubview(childView)
		let serialized = AccessibilityTreeSerializer().serialize(rootView: groupView)
		let expected = "- identifier \"form-group\" frame (0, 0, 200, 100)\n"
			+ "\t- label \"Name\" frame (0, 0, 50, 20)\n"
		#expect(serialized == expected)
	}

	/// 隱藏視圖整枝略過——看不見的東西不屬於輔助功能樹。
	@Test
	@MainActor
	func `skips hidden branches`() {
		let containerView: UIView = .init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
		let hiddenBranch: UIView = .init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
		hiddenBranch.isHidden = true
		let invisibleElement: UIView = .init(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
		invisibleElement.isAccessibilityElement = true
		invisibleElement.accessibilityLabel = "should not appear"
		hiddenBranch.addSubview(invisibleElement)
		containerView.addSubview(hiddenBranch)
		let serialized = AccessibilityTreeSerializer().serialize(rootView: containerView)
		#expect(serialized == "(no accessibility elements)\n")
	}
}

#endif
