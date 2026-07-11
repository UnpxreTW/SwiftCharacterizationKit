//
//  SnapshotCoreTests
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

import Foundation
import SnapshotCore
import Testing

private final class GoldenLocationTests {

	/// 由測試檔路徑推導 golden 與 `.actual` 落點（`__Golden__/<測試檔名>/<testName>.<named>.<ext>`）。
	@Test
	private func `derives golden and actual file locations from test file path`() {
		let location: GoldenLocation = .init(
			testFilePath: "/tmp/Example/HomeTests.swift",
			testName: "testHome()",
			name: "default",
			fileExtension: "json"
		)
		#expect(
			location.goldenFileURL.path(percentEncoded: false)
				== "/tmp/Example/__Golden__/HomeTests/testHome.default.json"
		)
		#expect(
			location.actualFileURL.path(percentEncoded: false)
				== "/tmp/Example/__Golden__/HomeTests/testHome.default.actual.json"
		)
		#expect(location.fileStem == "testHome.default")
	}

	/// `named:` 省略時檔名只有測試名段。
	@Test
	private func `omits name segment when name is nil`() {
		let location: GoldenLocation = .init(
			testFilePath: "/tmp/Example/HomeTests.swift",
			testName: "testHome()",
			fileExtension: "txt"
		)
		#expect(location.goldenFileURL.path(percentEncoded: false) == "/tmp/Example/__Golden__/HomeTests/testHome.txt")
		#expect(location.fileStem == "testHome")
	}

	/// Swift Testing 反引號測試名（空白、反引號）清洗成連字號檔名。
	@Test
	private func `sanitizes backticked test name with spaces`() {
		#expect(GoldenLocation.sanitizedTestName("`home screen default state`()") == "home-screen-default-state")
	}

	/// XCTest 慣例測試名保持原樣（僅剝參數括號）。
	@Test
	private func `keeps plain xctest name and strips parentheses`() {
		#expect(GoldenLocation.sanitizedTestName("testStartUpScreen()") == "testStartUpScreen")
	}

	/// 路徑敵意字元收斂成單一連字號、尾端連字號剝除。
	@Test
	private func `collapses hostile characters into single dashes`() {
		#expect(GoldenLocation.sanitizedTestName("test / with: colons!()") == "test-with-colons")
	}

	/// 全空測試名退回固定主幹，不產出無名檔案。
	@Test
	private func `falls back to fixed stem for empty test name`() {
		#expect(GoldenLocation.sanitizedTestName("()") == "test")
	}
}
