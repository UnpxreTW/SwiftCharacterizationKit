//
//  SnapshotCore
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

import Foundation

/// record 模式的解析結果：這次比對要不要改寫 golden
///
/// 兩個開啟來源取聯集：呼叫點 `record: true`、或環境變數 `CHARACTERIZATION_RECORD=1`
/// （CI 永不設——CI 只驗不錄，新 golden 必經本機錄製＋PR 人審）。
public struct RecordMode: Sendable {

	/// 環境變數名；值為 `"1"` 時開啟 record 模式
	public static let environmentVariableName = "CHARACTERIZATION_RECORD"

	/// 是否開啟 record 模式
	public let isEnabled: Bool

	/// 由呼叫點旗標與環境變數解析
	///
	/// - Parameters:
	///   - callSiteRecord: 呼叫點的 `record:` 參數；單點重錄用、不必動環境。
	///   - environment: 供測試注入的環境字典；預設讀當前 process 環境。
	public init(callSiteRecord: Bool = false, environment: [String: String] = ProcessInfo.processInfo.environment) {
		self.isEnabled = callSiteRecord || environment[Self.environmentVariableName] == "1"
	}
}
