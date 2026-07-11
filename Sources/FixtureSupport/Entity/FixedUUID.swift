//
//  FixtureSupport
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

import Foundation
import Synchronization

/// 決定性 UUID 產生器：注入型別
///
/// 依序產生 `00000000-0000-0000-0000-000000000000`、`…0001`、`…0002`——
/// golden 裡的 UUID 因此可讀、可預期。app 側 seam（如 `var makeUUID: () -> UUID`）
/// 屬各 app 的工作，測試端塞 `FixedUUID().callAsFunction`。
/// class 而非 struct：產生器需跨閉包共享同一個遞增狀態。
public final class FixedUUID: Sendable {

	/// 以 `() -> UUID` seam 的函式形取值
	public func callAsFunction() -> UUID {
		next()
	}

	/// 取下一個 UUID（後 12 位十六進位遞增、其餘位固定為 0）
	public func next() -> UUID {
		let value = nextValue.withLock { currentValue in
			let issued = currentValue
			currentValue += 1
			return issued
		}
		let suffix: String = .init(format: "%012llX", value & 0xFFF_FFFF_FFFF)
		guard let uuid = UUID(uuidString: "00000000-0000-0000-0000-\(suffix)") else {
			preconditionFailure("deterministic UUID string construction can never fail")
		}
		return uuid
	}

	/// 從 0 起算建立產生器
	public init() {}

	/// 下一個序號（跨執行緒安全；受測物可能在任意 isolation 呼叫 seam）
	private let nextValue: Mutex<UInt64> = .init(0)
}
