//
//  FixtureSupport
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

import Foundation

/// stub 攔截層的錯誤
///
/// 未註冊的請求是大聲失敗、不是默默放行——characterization 測試裡
/// 任何真的打出去的網路請求都是決定性漏洞。
public enum StubURLProtocolError: Error, CustomStringConvertible {

	/// 請求缺 URL（理論上不會發生、保底）
	case missingRequestURL

	/// 該 URL 沒有註冊 stub
	case noStubRegistered(URL)

	/// 人讀診斷訊息
	public var description: String {
		switch self {
		case .missingRequestURL:
			"request has no URL"
		case let .noStubRegistered(url):
			"no stub registered for \(url.absoluteString); register one with StubURLProtocol.setStub(_:for:)"
		}
	}
}
