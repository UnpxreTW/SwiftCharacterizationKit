//
//  SnapshotCore
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

import Foundation

/// golden 寫入事件的內容：為何寫、寫到哪
///
/// 「寫入後仍 fail」是 record 紀律的核心——golden 永遠不會在同一次執行內默默轉綠，
/// 此型別讓失敗訊息能說清楚寫入原因與落點。
public struct GoldenRecordOutcome: Equatable, Sendable {

	/// 寫入原因
	public enum Reason: Equatable, Sendable {

		/// golden 不存在（首次錄製）
		case missingGolden

		/// 呼叫點或環境變數要求重錄
		case recordRequested
	}

	/// 寫入原因
	public let reason: Reason

	/// 寫入的 golden 檔路徑
	public let goldenFileURL: URL

	/// 以原因與落點建立寫入事件
	public init(reason: Reason, goldenFileURL: URL) {
		self.reason = reason
		self.goldenFileURL = goldenFileURL
	}
}
