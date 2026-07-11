//
//  CharacterizationSupport
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

#if canImport(XCTest)

import SnapshotCore
import XCTest

/// XCTest 相容薄殼：golden 比對失敗以 `XCTFail` 回報
///
/// 與 ``expectGolden(of:as:named:record:testName:testFilePath:sourceLocation:)`` 同引擎、
/// 同 record 語意——給既有 XCTest target（storyboard VC 場景大宗）直接採用，
/// 不必為了掛安全網先遷移測試框架。
///
/// - Parameters:
///   - subject: 受測主體；型別決定可用的策略。
///   - strategy: 序列化策略，見 ``GoldenStrategy``。
///   - name: 同一測試內多份 golden 的區分名。
///   - record: `true` 時本次改寫 golden（寫入後仍 fail）；整批重錄用環境變數 `CHARACTERIZATION_RECORD=1`。
///   - testName: golden 檔名的測試名段；預設取呼叫端函式名、勿手動傳入。
///   - testFilePath: golden 目錄推導的根；預設取呼叫端檔案路徑、勿手動傳入。
///   - file: 失敗標註檔案；預設取呼叫點、勿手動傳入。
///   - line: 失敗標註行號；預設取呼叫點、勿手動傳入。
/// - Throws: 序列化或 golden 檔 IO 失敗時拋出（比對不一致不拋、走 `XCTFail`）。
public func assertGolden<Subject>(
	of subject: Subject,
	as strategy: GoldenStrategy<Subject>,
	named name: String? = nil,
	record: Bool = false,
	testName: String = #function,
	testFilePath: String = #filePath,
	file: StaticString = #filePath,
	line: UInt = #line
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
	XCTFail(failureMessage, file: file, line: line)
}

#endif
