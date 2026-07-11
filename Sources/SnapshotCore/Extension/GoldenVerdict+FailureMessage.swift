//
//  SnapshotCore
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

/// 失敗訊息在此統一組裝：雙框架薄殼共用同一份文案，
/// 訊息語彙（「recorded — re-run to verify」）是 record 紀律的一部分、不隨殼漂移。
extension GoldenVerdict {

	/// 失敗訊息中 diff 摘要的行數上限（全文另存 `.actual`／attachment，訊息只給前段）
	private static let diffSummaryLineLimit = 20

	/// 組裝框架失敗訊息；`pass` 回 `nil`
	public var failureMessage: String? {
		switch self {
		case .pass:
			return nil
		case let .recorded(outcome):
			let reasonDescription = switch outcome.reason {
			case .missingGolden: "No golden found"
			case .recordRequested: "Record mode on"
			}
			let goldenPath = outcome.goldenFileURL.path(percentEncoded: false)
			return "\(reasonDescription); recorded — re-run to verify. golden: \(goldenPath)"
		case let .mismatch(mismatch):
			let goldenFileName = mismatch.goldenFileURL.lastPathComponent
			let actualPath = mismatch.actualFileURL.path(percentEncoded: false)
			let diffLines = mismatch.diff.split(separator: "\n", omittingEmptySubsequences: false)
			var summaryLines = diffLines.prefix(Self.diffSummaryLineLimit).map(String.init)
			if diffLines.count > Self.diffSummaryLineLimit {
				summaryLines.append("… (+\(diffLines.count - Self.diffSummaryLineLimit) more diff lines)")
			}
			return "Golden mismatch (\(goldenFileName)); actual written to \(actualPath)\n"
				+ summaryLines.joined(separator: "\n")
		}
	}
}
