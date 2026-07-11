//
//  FixtureSupport
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

import Foundation

/// 一則 stub 回應：狀態碼、標頭與 body
///
/// 與 fixture 檔配套（``init(fixtureNamed:in:statusCode:headerFields:)``）——
/// 「打網路的 view model」以此釘住，測試不需要 staging 環境與帳號。
public struct StubbedResponse: Sendable {

	/// HTTP 狀態碼
	public let statusCode: Int

	/// 回應標頭（預設 JSON content type）
	public let headerFields: [String: String]

	/// 回應 body
	public let body: Data

	/// 直接以內容建立 stub 回應
	public init(
		statusCode: Int = 200,
		headerFields: [String: String] = ["Content-Type": "application/json"],
		body: Data = Data()
	) {
		self.statusCode = statusCode
		self.headerFields = headerFields
		self.body = body
	}

	/// 以 fixture 檔內容為 body 建立 stub 回應
	///
	/// - Throws: ``FixtureError`` fixture 載入失敗時。
	public init(
		fixtureNamed fixtureName: String,
		in bundle: Bundle? = nil,
		subdirectory: String? = nil,
		statusCode: Int = 200,
		headerFields: [String: String] = ["Content-Type": "application/json"]
	) throws {
		let body = try FixtureLoader.data(named: fixtureName, in: bundle, subdirectory: subdirectory)
		self.init(statusCode: statusCode, headerFields: headerFields, body: body)
	}
}
