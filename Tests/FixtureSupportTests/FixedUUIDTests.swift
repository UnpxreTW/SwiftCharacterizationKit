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

private final class FixedUUIDTests {

	/// 由 0 起算遞增、可讀可預期。
	@Test
	private func `generates incrementing uuids from zero`() {
		let makeUUID: FixedUUID = .init()
		#expect(makeUUID().uuidString == "00000000-0000-0000-0000-000000000000")
		#expect(makeUUID().uuidString == "00000000-0000-0000-0000-000000000001")
		#expect(makeUUID.next().uuidString == "00000000-0000-0000-0000-000000000002")
	}

	/// 各實例獨立計數、互不影響。
	@Test
	private func `instances count independently`() {
		let firstGenerator: FixedUUID = .init()
		let secondGenerator: FixedUUID = .init()
		_ = firstGenerator()
		#expect(secondGenerator().uuidString == "00000000-0000-0000-0000-000000000000")
	}
}
