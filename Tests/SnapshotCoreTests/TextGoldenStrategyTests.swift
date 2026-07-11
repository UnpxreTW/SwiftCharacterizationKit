//
//  SnapshotCoreTests
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

import SnapshotCore
import Testing

private final class TextGoldenStrategyTests {

	/// 自訂報表型別：`CustomStringConvertible` 主體
	private struct Report: CustomStringConvertible {

		/// 原文即描述
		var description: String { body }

		/// 報表原文
		let body: String
	}

	/// `String` 主體原文入檔、不做任何正規化（含尾換行）。
	@Test
	private func `passes string subject through unchanged`() throws {
		let serialized = try GoldenStrategy<String>.text.serialize("total: 42\nno trailing newline")
		#expect(serialized == "total: 42\nno trailing newline")
	}

	/// `CustomStringConvertible` 主體取 `description` 原文。
	@Test
	private func `uses description of custom string convertible subject`() throws {
		let serialized = try GoldenStrategy<Report>.text.serialize(Report(body: "quarterly summary\n"))
		#expect(serialized == "quarterly summary\n")
	}

	/// 副檔名為 `txt`。
	@Test
	private func `uses txt file extension`() {
		#expect(GoldenStrategy<String>.text.fileExtension == "txt")
	}
}
