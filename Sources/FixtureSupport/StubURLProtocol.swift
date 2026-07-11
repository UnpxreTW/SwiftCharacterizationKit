//
//  FixtureSupport
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

import Foundation
import Synchronization

/// `URLProtocol` 攔截層：把 URLSession 請求導向已註冊的 fixture 回應
///
/// 使用方式：以 ``sessionConfiguration`` 建 `URLSession`（或把它注入受測物的
/// session 建構 seam），再以 ``setStub(_:for:)`` 逐 URL 註冊回應。
/// 該 configuration 下所有請求都被攔截：未註冊的 URL 直接回錯誤、不放行真網路——
/// 見 ``StubURLProtocolError``。URL 比對採 `absoluteString` 完全一致。
public final class StubURLProtocol: URLProtocol {

	/// 產生掛好本攔截層的 ephemeral session configuration
	public static var sessionConfiguration: URLSessionConfiguration {
		let configuration: URLSessionConfiguration = .ephemeral
		configuration.protocolClasses = [StubURLProtocol.self]
		return configuration
	}

	/// 註冊（或覆蓋）某 URL 的 stub 回應
	public static func setStub(_ response: StubbedResponse, for url: URL) {
		stubRegistry.withLock { $0[url.absoluteString] = response }
	}

	/// 清空登記表——測試收尾必呼叫，避免 stub 洩漏到下一個測試
	public static func removeAllStubs() {
		stubRegistry.withLock { $0.removeAll() }
	}

	// MARK: URLProtocol

	/// 攔截所有請求（本協定只該掛在 ``sessionConfiguration``、不做全域註冊）
	override public static func canInit(with request: URLRequest) -> Bool {
		true
	}

	/// 不改寫請求
	override public static func canonicalRequest(for request: URLRequest) -> URLRequest {
		request
	}

	/// 查登記表回應；未註冊即回 ``StubURLProtocolError/noStubRegistered(_:)``
	override public func startLoading() {
		guard let requestURL = request.url else {
			client?.urlProtocol(self, didFailWithError: StubURLProtocolError.missingRequestURL)
			return
		}
		let stub = Self.stubRegistry.withLock { $0[requestURL.absoluteString] }
		guard let stub else {
			client?.urlProtocol(self, didFailWithError: StubURLProtocolError.noStubRegistered(requestURL))
			return
		}
		// 宣告與 unwrap 合成一句 guard——`HTTPURLResponse.init(url:statusCode:httpVersion:headerFields:)`
		// 是 failable，拆成獨立 `let httpResponse = HTTPURLResponse(...)` 會被 SwiftStyleKit 的
		// propertyTypes（explicit 模式）誤標成非 Optional 的 `: HTTPURLResponse = .init(...)`、編譯失敗。
		guard
			let httpResponse = HTTPURLResponse(
				url: requestURL,
				statusCode: stub.statusCode,
				httpVersion: "HTTP/1.1",
				headerFields: stub.headerFields
			)
		else {
			client?.urlProtocol(self, didFailWithError: StubURLProtocolError.missingRequestURL)
			return
		}
		client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
		client?.urlProtocol(self, didLoad: stub.body)
		client?.urlProtocolDidFinishLoading(self)
	}

	/// 無進行中資源可停（回應是同步組出來的）
	override public func stopLoading() {}

	/// 已註冊 stub 的登記表（跨執行緒安全；URLSession 從內部 queue 呼叫本協定）
	private static let stubRegistry: Mutex<[String: StubbedResponse]> = .init([:])
}
