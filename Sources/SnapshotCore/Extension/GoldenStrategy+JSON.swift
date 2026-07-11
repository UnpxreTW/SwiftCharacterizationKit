//
//  SnapshotCore
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

import Foundation

/// `.json` 策略：邏輯層 characterization 的主力（函式輸出、狀態機、API decode 結果）
extension GoldenStrategy where Subject: Encodable {

	/// `Encodable` → 排序鍵、固定格式的 JSON 文字
	///
	/// 決定性設定全部釘死：`sortedKeys`（dictionary 迭代序不可信）、`prettyPrinted`
	/// （PR diff 逐行可讀）、日期 ISO 8601、Data base64；輸出補一個結尾換行讓
	/// golden 檔對 git 友善。
	public static var json: GoldenStrategy<Subject> {
		GoldenStrategy(fileExtension: "json") { subject in
			let encoder: JSONEncoder = .init()
			encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
			encoder.dateEncodingStrategy = .iso8601
			encoder.dataEncodingStrategy = .base64
			let encodedData = try encoder.encode(subject)
			guard let encoded = String(bytes: encodedData, encoding: .utf8) else {
				throw TextDecodingError.invalidUTF8(context: "JSONEncoder output for \(Subject.self)")
			}
			return encoded + "\n"
		}
	}
}
