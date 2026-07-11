//
//  SnapshotCore
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

import Foundation

/// golden 檔的讀寫層
///
/// 只管檔案系統存取、不管比對邏輯——路徑推導在 ``GoldenLocation``、
/// 裁定在 ``GoldenChecker``，三者拆開讓未來工具（golden audit CLI）能單獨重用。
public struct GoldenStore: Sendable {

	/// 讀取 golden 內容；檔案不存在回 `nil`
	///
	/// 「查無」是首次錄製的正常路徑、不當錯誤拋；讀取失敗（權限、IO 錯誤）與內容
	/// 不是合法 UTF-8 都視為異常、一律 throws——golden 必須是可讀文字，壞編碼不該
	/// 被悄悄吞成亂碼。
	public func readGolden(at location: GoldenLocation) throws -> String? {
		guard FileManager.default.fileExists(atPath: location.goldenFileURL.path(percentEncoded: false)) else {
			return nil
		}
		let goldenData = try Data(contentsOf: location.goldenFileURL)
		guard let golden = String(bytes: goldenData, encoding: .utf8) else {
			throw TextDecodingError.invalidUTF8(context: location.goldenFileURL.path(percentEncoded: false))
		}
		return golden
	}

	/// 寫入 golden（自動建立 `__Golden__/<測試檔名>/` 中介目錄、原子寫入）
	public func writeGolden(_ content: String, at location: GoldenLocation) throws {
		try writeFile(content, to: location.goldenFileURL)
	}

	/// 寫出 `.actual` 檔（mismatch 時的本次輸出，供人工比對；應進 gitignore）
	public func writeActual(_ content: String, at location: GoldenLocation) throws {
		try writeFile(content, to: location.actualFileURL)
	}

	/// 移除殘留的 `.actual` 檔（best effort、不拋錯）
	///
	/// 比對轉綠後舊 `.actual` 是誤導性殘骸——pass 時順手清掉，失敗不影響裁定。
	public func removeActual(at location: GoldenLocation) {
		try? FileManager.default.removeItem(at: location.actualFileURL)
	}

	/// 建立讀寫層（無狀態、直接操作預設 `FileManager`）
	public init() {}

	/// 建目錄＋原子寫入的共用底層
	private func writeFile(_ content: String, to fileURL: URL) throws {
		let directoryURL = fileURL.deletingLastPathComponent()
		try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
		try Data(content.utf8).write(to: fileURL, options: .atomic)
	}
}
