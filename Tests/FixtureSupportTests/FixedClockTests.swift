//
//  FixtureSupportTests
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

import FixtureSupport
import Foundation
import Testing

private final class FixedClockTests {

	/// 固定時刻恆定回傳、函式形與屬性一致。
	@Test
	private func `returns the fixed instant`() {
		let fixedInstant: Date = .init(timeIntervalSince1970: 1000)
		let clock: FixedClock = .init(now: fixedInstant)
		#expect(clock() == fixedInstant)
		#expect(clock.now == fixedInstant)
	}

	/// `advance` 顯式前進、仍是決定性操作。
	@Test
	private func `advance shifts now deterministically`() {
		var clock: FixedClock = .init(now: Date(timeIntervalSince1970: 0))
		clock.advance(by: 60)
		#expect(clock() == Date(timeIntervalSince1970: 60))
	}
}
