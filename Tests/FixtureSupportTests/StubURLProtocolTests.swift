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

/// `.serialized`：stub 登記表是 process 級共享狀態，各測試的註冊與清空不可交錯。
@Suite(.serialized)
private final class StubURLProtocolTests {

	/// 測試收尾清空登記表，stub 不洩漏到下一個測試
	deinit {
		StubURLProtocol.removeAllStubs()
	}

	/// 已註冊 URL 回 stub 的狀態碼、標頭與 body。
	@Test
	private func `returns stubbed response for registered url`() async throws {
		let url = try #require(URL(string: "https://stub.invalid/quotes"))
		StubURLProtocol.setStub(StubbedResponse(body: Data("{\"ok\":true}".utf8)), for: url)
		let session: URLSession = .init(configuration: StubURLProtocol.sessionConfiguration)
		let (body, response) = try await session.data(from: url)
		let httpResponse = try #require(response as? HTTPURLResponse)
		#expect(httpResponse.statusCode == 200)
		#expect(httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json")
		let responseBody = try #require(String(bytes: body, encoding: .utf8))
		#expect(responseBody == "{\"ok\":true}")
	}

	/// 自訂狀態碼與標頭原樣回傳。
	@Test
	private func `honors custom status code and headers`() async throws {
		let url = try #require(URL(string: "https://stub.invalid/not-found"))
		StubURLProtocol.setStub(
			StubbedResponse(statusCode: 404, headerFields: ["X-Reason": "gone"], body: Data()),
			for: url
		)
		let session: URLSession = .init(configuration: StubURLProtocol.sessionConfiguration)
		let (_, response) = try await session.data(from: url)
		let httpResponse = try #require(response as? HTTPURLResponse)
		#expect(httpResponse.statusCode == 404)
		#expect(httpResponse.value(forHTTPHeaderField: "X-Reason") == "gone")
	}

	/// 未註冊 URL 大聲失敗、不放行真網路。
	@Test
	private func `fails loudly for unregistered url`() async throws {
		let url = try #require(URL(string: "https://stub.invalid/not-registered"))
		let session: URLSession = .init(configuration: StubURLProtocol.sessionConfiguration)
		await #expect(throws: (any Error).self) {
			_ = try await session.data(from: url)
		}
	}

	/// fixture 檔直接當 stub body（fixture 回應的標準組合）。
	@Test
	private func `builds stub body from fixture file`() async throws {
		let url = try #require(URL(string: "https://stub.invalid/users/1"))
		let stubbedResponse = try StubbedResponse(fixtureNamed: "sample-user.json", in: .module, subdirectory: "Fixtures")
		StubURLProtocol.setStub(stubbedResponse, for: url)
		let session: URLSession = .init(configuration: StubURLProtocol.sessionConfiguration)
		let (body, _) = try await session.data(from: url)
		let expectedBody = try FixtureLoader.data(named: "sample-user.json", in: .module, subdirectory: "Fixtures")
		#expect(body == expectedBody)
	}
}
