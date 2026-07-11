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

private final class JSONGoldenStrategyTests {

	/// 受測樣本：欄位刻意亂序宣告，驗證 `sortedKeys` 收斂宣告序
	private struct SampleSubject: Encodable {

		/// 排序上最後的欄位、刻意放最前
		let zebra: Int

		/// 布林欄位
		let apple: Bool

		/// 含 `/` 的字串（驗證 `withoutEscapingSlashes`）
		let name: String

		/// 固定日期（驗證 ISO 8601 決定性）
		let createdAt: Date
	}

	/// 鍵排序、縮排、日期格式全數釘死成固定輸出。
	@Test
	private func `serializes encodable with sorted keys and fixed format`() throws {
		let subject: SampleSubject = .init(
			zebra: 3,
			apple: true,
			name: "x/y",
			createdAt: Date(timeIntervalSince1970: 0)
		)
		let serialized = try GoldenStrategy<SampleSubject>.json.serialize(subject)
		let expected = """
			{
			  "apple" : true,
			  "createdAt" : "1970-01-01T00:00:00Z",
			  "name" : "x/y",
			  "zebra" : 3
			}

			"""
		#expect(serialized == expected)
	}

	/// dictionary 迭代序不可信——多鍵字典輸出仍穩定排序。
	@Test
	private func `sorts dictionary keys deterministically`() throws {
		let subject = ["delta": 4, "alpha": 1, "charlie": 3, "bravo": 2]
		let strategy: GoldenStrategy<[String: Int]> = .json
		let firstPass = try strategy.serialize(subject)
		let secondPass = try strategy.serialize(subject)
		#expect(firstPass == secondPass)
		let expected = """
			{
			  "alpha" : 1,
			  "bravo" : 2,
			  "charlie" : 3,
			  "delta" : 4
			}

			"""
		#expect(firstPass == expected)
	}

	/// 副檔名為 `json`。
	@Test
	private func `uses json file extension`() {
		#expect(GoldenStrategy<[String: Int]>.json.fileExtension == "json")
	}
}
