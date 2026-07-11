//
//  SnapshotCore
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

/// golden 比對核心引擎：序列化 → 讀 golden → 裁定
///
/// 不依賴任何測試框架——`expectGolden`（Swift Testing）與 `assertGolden`（XCTest）
/// 是它的雙薄殼，未來的 golden audit CLI 也直接建在這層之上。
public struct GoldenChecker {

	/// golden 檔讀寫層
	public let store: GoldenStore

	/// diff 產生器
	public let differ: UnifiedDiffer

	/// 執行一次 golden 比對
	///
	/// 裁定規則：
	/// 1. record 模式開啟 → 改寫 golden、回 ``GoldenVerdict/recorded(_:)``（寫入後仍 fail、強制 re-run 驗證）。
	/// 2. golden 不存在 → 首次錄製、同樣回 `recorded`（golden 永遠不會默默轉綠）。
	/// 3. 存在且一致 → ``GoldenVerdict/pass``、順手清掉殘留 `.actual`。
	/// 4. 不一致 → 寫 `.actual`、回 ``GoldenVerdict/mismatch(_:)`` 附 unified diff。
	public func check<Subject>(
		subject: Subject,
		strategy: GoldenStrategy<Subject>,
		at location: GoldenLocation,
		recordMode: RecordMode = RecordMode()
	) throws -> GoldenVerdict {
		let actualText = try strategy.serialize(subject)
		if recordMode.isEnabled {
			try store.writeGolden(actualText, at: location)
			store.removeActual(at: location)
			return .recorded(GoldenRecordOutcome(reason: .recordRequested, goldenFileURL: location.goldenFileURL))
		}
		guard let goldenText = try store.readGolden(at: location) else {
			try store.writeGolden(actualText, at: location)
			return .recorded(GoldenRecordOutcome(reason: .missingGolden, goldenFileURL: location.goldenFileURL))
		}
		if let diffText = differ.diff(golden: goldenText, actual: actualText) {
			try store.writeActual(actualText, at: location)
			return .mismatch(GoldenMismatch(
				diff: diffText,
				goldenFileURL: location.goldenFileURL,
				actualFileURL: location.actualFileURL
			))
		}
		store.removeActual(at: location)
		return .pass
	}

	/// 以讀寫層與 differ 建立引擎（預設值即標準行為，注入點供測試用）
	public init(store: GoldenStore = GoldenStore(), differ: UnifiedDiffer = UnifiedDiffer()) {
		self.store = store
		self.differ = differ
	}
}
