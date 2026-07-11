//
//  SnapshotCore
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

/// golden 序列化策略：把受測主體轉成可入檔、可逐行 diff 的穩定文字
///
/// 文字優先是本 kit 的核心取捨——跨機 golden 漂移幾乎全是像素層問題，
/// 把序列化定在文字層讓 golden 可直接進 PR diff 人審。內建策略見
/// `Extension/GoldenStrategy+*.swift`（`.json`／`.text`／`.accessibilityTree`／`.viewHierarchy`）。
public struct GoldenStrategy<Subject> {

	/// golden 檔副檔名（不含點）
	///
	/// 同時決定 mismatch 時 `.actual` 檔的字尾；允許帶點的複合副檔名（如 `a11y.txt`），
	/// 讓策略種類從檔名就能辨識。
	public let fileExtension: String

	/// 序列化閉包
	///
	/// 輸出必須決定性（同一主體必得同一文字），否則 golden 比對淪為 flaky——
	/// 排序、時間、亂數都要在這層（或 fixture 層）釘死。
	public let serialize: (Subject) throws -> String

	/// 以副檔名與序列化規則建立自訂策略
	///
	/// 內建策略不敷使用時（自訂文字格式、額外遮罩不穩定欄位）走此入口。
	public init(fileExtension: String, serialize: @escaping (Subject) throws -> String) {
		self.fileExtension = fileExtension
		self.serialize = serialize
	}
}
