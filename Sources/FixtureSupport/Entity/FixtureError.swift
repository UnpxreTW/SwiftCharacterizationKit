//
//  FixtureSupport
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

/// fixture 載入失敗的錯誤
///
/// 測試資產缺失是需要人處理的狀況（fixture 沒進 resources、檔名打錯）——
/// 訊息必須自帶足夠診斷資訊，別讓人重跑加 print。
public enum FixtureError: Error, CustomStringConvertible {

	/// 找不到 fixture；附已搜尋的 bundle 清單供診斷
	case notFound(fixtureName: String, searchedBundles: [String])

	/// fixture 內容不是合法 UTF-8（``FixtureLoader/string(named:in:subdirectory:)`` 專用）
	case invalidEncoding(fixtureName: String)

	/// 人讀診斷訊息
	public var description: String {
		switch self {
		case let .notFound(fixtureName, searchedBundles):
			"fixture \"\(fixtureName)\" not found; searched bundles: \(searchedBundles.joined(separator: ", ")). "
				+ "Check the resource is declared in Package.swift (e.g. .copy(\"Fixtures\")) and the name matches."
		case let .invalidEncoding(fixtureName):
			"fixture \"\(fixtureName)\" is not valid UTF-8 text."
		}
	}
}
