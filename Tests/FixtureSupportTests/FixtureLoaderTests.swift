//
//  FixtureSupportTests
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

import FixtureSupport
import Foundation
import Testing

private final class FixtureLoaderTests {

	/// 解碼對象樣本
	private struct SampleUser: Decodable, Equatable {

		/// 使用者識別字
		let identifier: String

		/// 顯示名稱
		let displayName: String
	}

	/// 顯式 bundle 載入原始 Data。
	@Test
	private func `loads fixture data from explicit bundle`() throws {
		let fixtureData = try FixtureLoader.data(named: "sample-user.json", in: .module, subdirectory: "Fixtures")
		#expect(!fixtureData.isEmpty)
	}

	/// 載入並解碼成 Decodable 型別。
	@Test
	private func `decodes fixture into decodable type`() throws {
		let user: SampleUser = try FixtureLoader.load("sample-user.json", in: .module, subdirectory: "Fixtures")
		#expect(user == SampleUser(identifier: "user-001", displayName: "Sample User"))
	}

	/// 省略 bundle 時掃描已載入 bundle（含 SwiftPM 巢狀 resource bundle）也找得到。
	@Test
	private func `finds fixture by scanning loaded bundles when bundle omitted`() throws {
		let user: SampleUser = try FixtureLoader.load("sample-user.json", subdirectory: "Fixtures")
		#expect(user.identifier == "user-001")
	}

	/// 副檔名省略時預設 `json`。
	@Test
	private func `defaults to json extension when omitted`() throws {
		let fixtureData = try FixtureLoader.data(named: "sample-user", in: .module, subdirectory: "Fixtures")
		#expect(!fixtureData.isEmpty)
	}

	/// 載入為 UTF-8 字串。
	@Test
	private func `loads fixture as string`() throws {
		let fixtureText = try FixtureLoader.string(named: "sample-user.json", in: .module, subdirectory: "Fixtures")
		#expect(fixtureText.contains("user-001"))
	}

	/// 找不到時拋 `FixtureError`、訊息帶已搜尋範圍。
	@Test
	private func `throws descriptive error when fixture missing`() {
		#expect(throws: FixtureError.self) {
			try FixtureLoader.data(named: "missing.json", in: Bundle.module, subdirectory: "Fixtures")
		}
	}
}
