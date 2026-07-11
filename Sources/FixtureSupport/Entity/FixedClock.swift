//
//  FixtureSupport
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

import Foundation

/// 固定時間源：決定性注入型別
///
/// 時間是 characterization 最常見的不穩定源。app 側先開注入 seam
/// （如 `var now: () -> Date`），測試端塞 `FixedClock(now:).callAsFunction`——
/// seam 屬各 app 的工作、kit 只提供型別。
public struct FixedClock: Sendable {

	/// 固定的「現在」
	public var now: Date

	/// 以 `() -> Date` seam 的函式形取值
	public func callAsFunction() -> Date {
		now
	}

	/// 前進固定時刻（模擬時間流逝的測試場景；仍是顯式、決定性的操作）
	public mutating func advance(by interval: TimeInterval) {
		now = now.addingTimeInterval(interval)
	}

	/// 以固定時刻建立時間源
	public init(now: Date) {
		self.now = now
	}
}
