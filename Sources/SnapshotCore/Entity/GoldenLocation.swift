//
//  SnapshotCore
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

import Foundation

/// 把 `#function` 產出的測試名清洗成可入檔名的形式
///
/// 規則：截去第一個 `(` 起的參數段（`testHome()` → `testHome`）、丟棄反引號
/// （Swift Testing 原始識別字測試名）、非字母數字與 `_` `-` 的字元收斂成單一 `-`。
/// 全空時退回 `test`，避免產出無主幹的檔名。
///
/// 檔案層級 free function（非 `GoldenLocation` 的 static
/// member）：``GoldenLocation/init(testFilePath:testName:name:fileExtension:)``
/// 內部需要呼叫這段邏輯，若改成 `Self.sanitizedTestName(...)` 這種「型別名.成員」寫法，
/// SwiftStyleKit 的 propertyTypes（explicit 模式）會誤把回傳型別標成 `Self`（實為 `String`）
/// 而編譯失敗；無型別字首的 free function 呼叫不會誤判。
private func sanitizeRawTestName(_ rawTestName: String) -> String {
	let baseName = rawTestName.prefix { $0 != "(" }
	var sanitized = ""
	var previousWasDash = false
	for character in baseName {
		if character.isLetter || character.isNumber || character == "_" || character == "-" {
			sanitized.append(character)
			previousWasDash = false
		} else if character == "`" {
			continue
		} else if !previousWasDash, !sanitized.isEmpty {
			sanitized.append("-")
			previousWasDash = true
		}
	}
	while sanitized.hasSuffix("-") {
		sanitized.removeLast()
	}
	return sanitized.isEmpty ? "test" : sanitized
}

// MARK: - GoldenLocation

/// golden 檔與 `.actual` 檔的落點
///
/// 由測試檔路徑（`#filePath`）推導：`<測試檔所在目錄>/__Golden__/<測試檔名>/<testName>.<named>.<ext>`。
/// golden 與測試檔同 repo 同目錄、進 git（golden 即規格、diff 即 review 面）；
/// `.actual` 是 mismatch 時的產物、應進 gitignore。
public struct GoldenLocation: Equatable, Sendable {

	/// 把 `#function` 產出的測試名清洗成可入檔名的形式（規則見 ``sanitizeRawTestName(_:)``）
	public static func sanitizedTestName(_ rawTestName: String) -> String {
		sanitizeRawTestName(rawTestName)
	}

	/// golden 檔完整路徑
	public let goldenFileURL: URL

	/// mismatch 時寫出的 `.actual` 檔完整路徑（與 golden 同目錄、字尾插入 `.actual`）
	public let actualFileURL: URL

	/// 檔名主幹（`<testName>` 或 `<testName>.<named>`）——供失敗訊息指名是哪份 golden
	public let fileStem: String

	/// 由測試檔路徑與測試名推導落點
	///
	/// - Parameters:
	///   - testFilePath: 測試檔完整路徑，呼叫端以 `#filePath` 預設值帶入。
	///   - testName: 測試函式名，呼叫端以 `#function` 預設值帶入；會經 ``sanitizedTestName(_:)`` 清洗。
	///   - name: 同一測試內多份 golden 的區分名；`nil` 時檔名只有 testName 段。
	///   - fileExtension: golden 檔副檔名，由 ``GoldenStrategy`` 提供。
	public init(testFilePath: String, testName: String, name: String? = nil, fileExtension: String) {
		let testFileURL: URL = .init(filePath: testFilePath)
		let testFileName = testFileURL.deletingPathExtension().lastPathComponent
		let goldenDirectoryURL = testFileURL
			.deletingLastPathComponent()
			.appending(path: "__Golden__", directoryHint: .isDirectory)
			.appending(path: testFileName, directoryHint: .isDirectory)
		let sanitizedTestName = sanitizeRawTestName(testName)
		let stem: String = if let name { "\(sanitizedTestName).\(name)" } else { sanitizedTestName }
		self.fileStem = stem
		self.goldenFileURL = goldenDirectoryURL.appending(path: "\(stem).\(fileExtension)", directoryHint: .notDirectory)
		self.actualFileURL = goldenDirectoryURL
			.appending(path: "\(stem).actual.\(fileExtension)", directoryHint: .notDirectory)
	}

}
