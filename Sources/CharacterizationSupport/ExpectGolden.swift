//
//  CharacterizationSupport
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

#if canImport(Testing)

import SnapshotCore
import Testing

/// Swift Testing 薄殼：golden 比對失敗以 `Issue.record` 回報
///
/// 比對機制（record 語意、路徑推導、diff 格式）全在 SnapshotCore——
/// 本函式只負責框架接線：非 `pass` 的裁定轉成 Issue、mismatch 另附完整 diff attachment。
///
/// - Parameters:
///   - subject: 受測主體；型別決定可用的策略（`Encodable` → `.json`、SwiftUI view → `.accessibilityTree`…）。
///   - strategy: 序列化策略，見 ``GoldenStrategy``。
///   - name: 同一測試內多份 golden 的區分名。
///   - record: `true` 時本次改寫 golden（寫入後仍 fail）；整批重錄用環境變數 `CHARACTERIZATION_RECORD=1`。
///   - testName: golden 檔名的測試名段；預設取呼叫端函式名、勿手動傳入。
///   - testFilePath: golden 目錄推導的根；預設取呼叫端檔案路徑、勿手動傳入。
///   - sourceLocation: 失敗標註位置；預設取呼叫點、勿手動傳入。
/// - Throws: 序列化或 golden 檔 IO 失敗時拋出（比對不一致不拋、走 `Issue.record`）。
public func expectGolden<Subject>(
	of subject: Subject,
	as strategy: GoldenStrategy<Subject>,
	named name: String? = nil,
	record: Bool = false,
	testName: String = #function,
	testFilePath: String = #filePath,
	sourceLocation: SourceLocation = #_sourceLocation
) throws {
	let location: GoldenLocation = .init(
		testFilePath: testFilePath,
		testName: testName,
		name: name,
		fileExtension: strategy.fileExtension
	)
	let verdict: GoldenVerdict = try GoldenChecker().check(
		subject: subject,
		strategy: strategy,
		at: location,
		recordMode: RecordMode(callSiteRecord: record)
	)
	guard let failureMessage = verdict.failureMessage else { return }
	if case let .mismatch(mismatch) = verdict {
		Attachment.record(mismatch.diff, named: "\(location.fileStem).diff", sourceLocation: sourceLocation)
	}
	Issue.record("\(failureMessage)", sourceLocation: sourceLocation)
}

#endif
