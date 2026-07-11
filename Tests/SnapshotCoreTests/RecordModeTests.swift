//
//  SnapshotCoreTests
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

import SnapshotCore
import Testing

private final class RecordModeTests {

	/// 環境變數值 `"1"` 開啟 record 模式。
	@Test
	private func `environment value one enables record mode`() {
		#expect(RecordMode(environment: ["CHARACTERIZATION_RECORD": "1"]).isEnabled)
	}

	/// 缺席或其他值（含 `"true"`）不開啟——值刻意收窄成 `"1"`、避免 CI 誤觸。
	@Test
	private func `absent or other values keep record mode disabled`() {
		#expect(!RecordMode(environment: [:]).isEnabled)
		#expect(!RecordMode(environment: ["CHARACTERIZATION_RECORD": "0"]).isEnabled)
		#expect(!RecordMode(environment: ["CHARACTERIZATION_RECORD": "true"]).isEnabled)
	}

	/// 呼叫點 `record: true` 不受環境影響、一律開啟。
	@Test
	private func `call site record wins regardless of environment`() {
		#expect(RecordMode(callSiteRecord: true, environment: [:]).isEnabled)
	}
}
