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

private final class ViewHierarchySerializerTests {

	/// class 名、frame、label 文字入樹，子視圖 tab 縮排。
	@Test
	@MainActor
	func `serializes class names text and nesting`() {
		let containerView: UIView = .init(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
		let label: UILabel = .init(frame: CGRect(x: 10, y: 5, width: 80, height: 20))
		label.text = "Total"
		containerView.addSubview(label)
		let serialized = ViewHierarchySerializer().serialize(rootView: containerView)
		#expect(serialized == "UIView frame(0, 0, 100, 50)\n\tUILabel frame(10, 5, 80, 20) text \"Total\"\n")
	}

	/// hidden 與半透明視圖帶標記——結構釘連「藏起來的東西」一起釘。
	@Test
	@MainActor
	func `marks hidden and translucent views`() {
		let containerView: UIView = .init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
		let hiddenView: UIView = .init(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
		hiddenView.isHidden = true
		let translucentView: UIView = .init(frame: CGRect(x: 0, y: 10, width: 10, height: 10))
		translucentView.alpha = 0.5
		containerView.addSubview(hiddenView)
		containerView.addSubview(translucentView)
		let serialized = ViewHierarchySerializer().serialize(rootView: containerView)
		#expect(serialized.contains("hidden"))
		#expect(serialized.contains("alpha 0.50"))
	}

	/// 按鈕標題與輸入框 placeholder 也算顯示文字。
	@Test
	@MainActor
	func `captures button title and text field placeholder`() {
		let containerView: UIView = .init(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
		var buttonConfiguration = UIButton.Configuration.plain()
		buttonConfiguration.title = "Submit"
		let button: UIButton = .init(configuration: buttonConfiguration)
		button.frame = CGRect(x: 0, y: 0, width: 100, height: 44)
		let textField: UITextField = .init(frame: CGRect(x: 0, y: 50, width: 100, height: 30))
		textField.placeholder = "Email"
		containerView.addSubview(button)
		containerView.addSubview(textField)
		let serialized = ViewHierarchySerializer().serialize(rootView: containerView)
		#expect(serialized.contains("text \"Submit\""))
		#expect(serialized.contains("text \"Email\""))
	}
}

#endif
