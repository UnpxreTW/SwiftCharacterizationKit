//
//  SnapshotCore
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

/// 一次 golden 比對的裁定
///
/// 核心引擎（``GoldenChecker``）不依賴任何測試框架、只回裁定；
/// 由 Swift Testing／XCTest 薄殼各自把非 `pass` 的裁定轉成框架的失敗回報。
public enum GoldenVerdict: Equatable, Sendable {

	/// 與 golden 一致
	case pass

	/// 已寫入（或改寫）golden——寫入後仍視為失敗，強制乾淨 re-run 才能轉綠
	case recorded(GoldenRecordOutcome)

	/// 與 golden 不一致；附 diff 與 `.actual` 落點
	case mismatch(GoldenMismatch)
}
