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

private final class GoldenCheckerTests {

	// MARK: Lifecycle

	/// 測試收尾清沙盒
	deinit {
		try? FileManager.default.removeItem(at: sandboxDirectoryURL)
	}

	// MARK: Private

	/// 每個測試實例獨立的沙盒目錄（充當「測試檔所在目錄」）
	private let sandboxDirectoryURL = FileManager.default
		.temporaryDirectory
		.appending(path: "GoldenCheckerTests-\(UUID().uuidString)", directoryHint: .isDirectory)

	/// 在沙盒內組一個 golden 落點
	private func makeLocation(name: String? = nil) -> GoldenLocation {
		GoldenLocation(
			testFilePath: sandboxDirectoryURL.appending(path: "SyntheticTests.swift").path(percentEncoded: false),
			testName: "syntheticTest()",
			name: name,
			fileExtension: "txt"
		)
	}

	/// record→re-run→pass 全流程（引擎層）：golden 缺席首跑錄製並回 `recorded`、再跑轉 `pass`。
	@Test
	private func `records golden when missing then passes on re-run`() throws {
		let checker: GoldenChecker = .init()
		let location = makeLocation()
		let firstVerdict = try checker.check(subject: "hello\n", strategy: .text, at: location)
		#expect(firstVerdict == .recorded(GoldenRecordOutcome(reason: .missingGolden, goldenFileURL: location.goldenFileURL)))
		let goldenContent = try GoldenStore().readGolden(at: location)
		#expect(goldenContent == "hello\n")
		let secondVerdict = try checker.check(subject: "hello\n", strategy: .text, at: location)
		#expect(secondVerdict == .pass)
	}

	/// mismatch：回 unified diff、寫 `.actual`。
	@Test
	private func `reports mismatch with diff and writes actual file`() throws {
		let checker: GoldenChecker = .init()
		let location = makeLocation()
		try GoldenStore().writeGolden("a\nb\n", at: location)
		let verdict = try checker.check(subject: "a\nc\n", strategy: .text, at: location)
		guard case let .mismatch(mismatch) = verdict else {
			Issue.record("expected mismatch, got \(verdict)")
			return
		}
		#expect(mismatch.diff.contains("-b"))
		#expect(mismatch.diff.contains("+c"))
		#expect(mismatch.actualFileURL == location.actualFileURL)
		let actualData = try Data(contentsOf: location.actualFileURL)
		let actualContent = try #require(String(bytes: actualData, encoding: .utf8))
		#expect(actualContent == "a\nc\n")
	}

	/// 呼叫點 record：既有 golden 被改寫、裁定仍是 `recorded`（寫入後不默默轉綠）。
	@Test
	private func `record request rewrites existing golden and still reports recorded`() throws {
		let checker: GoldenChecker = .init()
		let location = makeLocation()
		try GoldenStore().writeGolden("v1\n", at: location)
		let verdict = try checker.check(
			subject: "v2\n",
			strategy: .text,
			at: location,
			recordMode: RecordMode(callSiteRecord: true)
		)
		#expect(verdict == .recorded(GoldenRecordOutcome(reason: .recordRequested, goldenFileURL: location.goldenFileURL)))
		#expect(try GoldenStore().readGolden(at: location) == "v2\n")
		let rerunVerdict = try checker.check(subject: "v2\n", strategy: .text, at: location)
		#expect(rerunVerdict == .pass)
	}

	/// 環境變數形 record 模式走同一條改寫路徑。
	@Test
	private func `environment record mode rewrites golden`() throws {
		let checker: GoldenChecker = .init()
		let location = makeLocation()
		try GoldenStore().writeGolden("v1\n", at: location)
		let verdict = try checker.check(
			subject: "v2\n",
			strategy: .text,
			at: location,
			recordMode: RecordMode(environment: ["CHARACTERIZATION_RECORD": "1"])
		)
		#expect(verdict == .recorded(GoldenRecordOutcome(reason: .recordRequested, goldenFileURL: location.goldenFileURL)))
	}

	/// pass 時清掉殘留 `.actual`——舊產物是誤導性殘骸。
	@Test
	private func `pass removes stale actual file`() throws {
		let checker: GoldenChecker = .init()
		let location = makeLocation()
		let store: GoldenStore = .init()
		try store.writeGolden("same\n", at: location)
		try store.writeActual("stale\n", at: location)
		let verdict = try checker.check(subject: "same\n", strategy: .text, at: location)
		#expect(verdict == .pass)
		#expect(!FileManager.default.fileExists(atPath: location.actualFileURL.path(percentEncoded: false)))
	}
}
