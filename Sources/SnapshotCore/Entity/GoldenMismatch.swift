//
//  SnapshotCore
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

import Foundation

/// golden 不一致的細節：diff 全文與兩側檔案落點
///
/// `.actual` 已寫至 ``actualFileURL``——重構抓到漂移時，人工比對兩份檔案
/// 或直接看 ``diff`` 判斷是回歸還是刻意變更（後者 re-record）。
public struct GoldenMismatch: Equatable, Sendable {

	/// unified diff 全文（golden 為舊、actual 為新）
	public let diff: String

	/// golden 檔路徑
	public let goldenFileURL: URL

	/// 本次序列化輸出寫出的 `.actual` 檔路徑
	public let actualFileURL: URL

	/// 以 diff 與兩側落點建立不一致細節
	public init(diff: String, goldenFileURL: URL, actualFileURL: URL) {
		self.diff = diff
		self.goldenFileURL = goldenFileURL
		self.actualFileURL = actualFileURL
	}
}
