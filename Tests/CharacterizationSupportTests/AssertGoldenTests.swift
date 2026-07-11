//
//  CharacterizationSupportTests
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

import CharacterizationSupport
import Foundation
import XCTest

/// XCTest 薄殼驗證——本檔刻意用 XCTest（受測物即 XCTest 接線），與 Swift Testing 同 target 共存。
///
/// 不可標 `private`：XCTest 靠執行期反射探索 test case，`private` 類別的測試會被靜默跳過、不會失敗。
final class AssertGoldenTests: XCTestCase {

	/// 測試收尾清沙盒
	override func tearDown() {
		try? FileManager.default.removeItem(at: sandboxDirectoryURL)
		super.tearDown()
	}

	/// record→re-run→pass 全流程（XCTest 薄殼層）：首錄以 XCTFail 回報（XCTExpectFailure 收下）、再跑轉綠。
	func testRecordThenRerunPassesThroughXCTestShell() throws {
		XCTExpectFailure("golden 首錄必 fail（recorded — re-run to verify）") {
			try? assertGolden(
				of: "hello\n",
				as: .text,
				named: "greeting",
				testName: "synthetic()",
				testFilePath: syntheticFilePath
			)
		}
		try assertGolden(
			of: "hello\n",
			as: .text,
			named: "greeting",
			testName: "synthetic()",
			testFilePath: syntheticFilePath
		)
	}

	/// mismatch 以 XCTFail 回報、訊息帶 diff 摘要。
	func testMismatchFailsWithDiffSummary() throws {
		let location: GoldenLocation = .init(
			testFilePath: syntheticFilePath,
			testName: "synthetic()",
			name: "mismatch",
			fileExtension: "txt"
		)
		try GoldenStore().writeGolden("a\nb\n", at: location)
		XCTExpectFailure("golden 不一致必 fail（帶 unified diff 摘要）") {
			try? assertGolden(
				of: "a\nc\n",
				as: .text,
				named: "mismatch",
				testName: "synthetic()",
				testFilePath: syntheticFilePath
			)
		}
		XCTAssertTrue(FileManager.default.fileExists(atPath: location.actualFileURL.path(percentEncoded: false)))
	}

	/// 沙盒內虛構測試檔路徑（golden 目錄推導的根）
	private var syntheticFilePath: String {
		sandboxDirectoryURL.appending(path: "SyntheticSuite.swift").path(percentEncoded: false)
	}

	/// 每個測試實例獨立的沙盒目錄（充當「測試檔所在目錄」）
	private let sandboxDirectoryURL: URL = FileManager.default
		.temporaryDirectory
		.appending(path: "AssertGoldenTests-\(UUID().uuidString)", directoryHint: .isDirectory)
}
