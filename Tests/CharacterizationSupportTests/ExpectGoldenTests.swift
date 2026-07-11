//
//  CharacterizationSupportTests
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

import CharacterizationSupport
import Foundation
import Testing

private final class ExpectGoldenTests {

	/// 測試收尾清沙盒
	deinit {
		try? FileManager.default.removeItem(at: sandboxDirectoryURL)
	}

	/// 已提交 golden 樣本
	private struct CommittedSample: Encodable {

		/// 固定狀態欄位
		let status: String

		/// 固定版本欄位
		let version: Int
	}

	/// 沙盒內虛構測試檔路徑（golden 目錄推導的根）
	private var syntheticFilePath: String {
		sandboxDirectoryURL.appending(path: "SyntheticSuite.swift").path(percentEncoded: false)
	}

	/// 每個測試實例獨立的沙盒目錄（充當「測試檔所在目錄」）
	private let sandboxDirectoryURL: URL = FileManager.default
		.temporaryDirectory
		.appending(path: "ExpectGoldenTests-\(UUID().uuidString)", directoryHint: .isDirectory)

	/// record→re-run→pass 全流程（Swift Testing 薄殼層）：首跑錄製並以 Issue 回報、再跑轉綠。
	@Test
	private func `record then re-run passes through the swift testing shell`() throws {
		try withKnownIssue {
			try expectGolden(
				of: "hello\n",
				as: .text,
				named: "greeting",
				testName: "synthetic()",
				testFilePath: syntheticFilePath
			)
		} matching: { issue in
			issue.comments.first?.rawValue.contains("recorded — re-run to verify") == true
		}
		try expectGolden(
			of: "hello\n",
			as: .text,
			named: "greeting",
			testName: "synthetic()",
			testFilePath: syntheticFilePath
		)
	}

	/// mismatch：Issue 訊息帶 diff 摘要、`.actual` 寫出。
	@Test
	private func `mismatch records issue with diff summary and writes actual`() throws {
		let location: GoldenLocation = .init(
			testFilePath: syntheticFilePath,
			testName: "synthetic()",
			name: "mismatch",
			fileExtension: "txt"
		)
		try GoldenStore().writeGolden("a\nb\n", at: location)
		try withKnownIssue {
			try expectGolden(
				of: "a\nc\n",
				as: .text,
				named: "mismatch",
				testName: "synthetic()",
				testFilePath: syntheticFilePath
			)
		} matching: { issue in
			let message = issue.comments.first?.rawValue ?? ""
			return message.contains("Golden mismatch") && message.contains("-b") && message.contains("+c")
		}
		#expect(FileManager.default.fileExists(atPath: location.actualFileURL.path(percentEncoded: false)))
	}

	/// 針對真實 `#filePath` 的已提交 golden：正常執行直接綠（record→re-run 產物入庫的實證）。
	@Test
	private func `committed golden passes on normal run`() throws {
		try expectGolden(of: CommittedSample(status: "stable", version: 1), as: .json, named: "committed")
	}
}
