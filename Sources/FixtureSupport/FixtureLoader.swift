//
//  FixtureSupport
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

import Foundation

/// 目前 process 已載入的所有 bundle（`Bundle.allBundles` 的直接轉發）
///
/// 檔案層級 free function：``FixtureLoader/discoveredBundles()`` 內部若寫成
/// `let seedBundles = Bundle.allBundles` 這種「型別名.成員」寫法，SwiftStyleKit
/// 的 propertyTypes（explicit 模式）會誤把回傳型別標成單數 `Bundle`（實為 `[Bundle]`）
/// 而編譯失敗；此處以無型別字首的 free function 回傳、呼叫端不觸發誤判。
private func allLoadedBundles() -> [Bundle] {
	Bundle.allBundles
}

// MARK: - FixtureLoader

/// fixture 檔載入器：從 test bundle resources 取回測試資料
///
/// fixture 是 characterization 決定性的另一半——真實資料去識別化後入檔，
/// 測試不再依賴帳號、網路與時間。副檔名省略時預設 `json`。
public enum FixtureLoader {

	// MARK: Public

	/// 載入 fixture 原始 `Data`
	///
	/// - Parameters:
	///   - fixtureName: 檔名（如 `home-default.json`）；無副檔名時視為 `json`。
	///   - bundle: fixture 所在 bundle；SwiftPM test target 傳 `.module`。`nil` 時
	///     掃描所有已載入 bundle 及其巢狀 resource bundle（`Bundle.module` 的實體形）——
	///     方便但較慢，位置明確時建議顯式傳入。
	///   - subdirectory: bundle 內子目錄（SwiftPM `.copy("Fixtures")` 資源對應 `"Fixtures"`）。
	/// - Throws: ``FixtureError/notFound(fixtureName:searchedBundles:)`` 找不到時；訊息帶已搜尋範圍。
	public static func data(
		named fixtureName: String, in bundle: Bundle? = nil, subdirectory: String? = nil
	) throws -> Data {
		let (resourceName, resourceExtension) = split(fixtureName: fixtureName)
		let candidateBundles: [Bundle] = if let bundle { [bundle] } else { discoveredBundles() }
		for candidateBundle in candidateBundles {
			let resourceURL = candidateBundle.url(
				forResource: resourceName,
				withExtension: resourceExtension,
				subdirectory: subdirectory
			)
			if let resourceURL {
				return try Data(contentsOf: resourceURL)
			}
		}
		throw FixtureError.notFound(
			fixtureName: fixtureName,
			searchedBundles: candidateBundles.map(\.bundleURL.lastPathComponent)
		)
	}

	/// 載入 fixture 並以 `JSONDecoder` 解碼成指定型別
	///
	/// 呼叫形：`let model: HomeModel = try FixtureLoader.load("home-default.json")`。
	public static func load<Fixture: Decodable>(
		_ fixtureName: String,
		as fixtureType: Fixture.Type = Fixture.self,
		in bundle: Bundle? = nil,
		subdirectory: String? = nil,
		decoder: JSONDecoder = JSONDecoder()
	) throws -> Fixture {
		let fixtureData = try data(named: fixtureName, in: bundle, subdirectory: subdirectory)
		return try decoder.decode(fixtureType, from: fixtureData)
	}

	/// 載入 fixture 為 UTF-8 字串（文字 golden 的種子、非 JSON 的文字資產）
	public static func string(
		named fixtureName: String, in bundle: Bundle? = nil, subdirectory: String? = nil
	) throws -> String {
		let fixtureData = try data(named: fixtureName, in: bundle, subdirectory: subdirectory)
		guard let text = String(bytes: fixtureData, encoding: .utf8) else {
			throw FixtureError.invalidEncoding(fixtureName: fixtureName)
		}
		return text
	}

	// MARK: Private

	/// `Bundle(for:)` 錨點：本 class 隨 FixtureSupport 靜態連結進測試 bundle，
	/// 以它定位「程式碼實際所在」的 bundle——`swift test` 的 runner process 裡
	/// `Bundle.allBundles` 看不到測試 bundle，此錨點是唯一可靠入口。
	private final class BundleFinder {}

	/// 拆檔名與副檔名；無副檔名時預設 `json`
	private static func split(fixtureName: String) -> (name: String, fileExtension: String) {
		let fixtureURL: URL = .init(filePath: fixtureName)
		let fileExtension = fixtureURL.pathExtension
		guard !fileExtension.isEmpty else { return (fixtureName, "json") }
		return (fixtureURL.deletingPathExtension().lastPathComponent, fileExtension)
	}

	/// 蒐集搜尋範圍：已載入 bundle、程式碼所在 bundle、main bundle，
	/// 加上各自內部（`resourceURL`）與同層目錄的 `.bundle`（SwiftPM resource bundle 實體形——
	/// Xcode 佈局放 bundle 內、`swift test` 佈局放建置產物目錄與測試 bundle 同層）
	private static func discoveredBundles() -> [Bundle] {
		var seedBundles: [Bundle] = allLoadedBundles()
		seedBundles.append(Bundle(for: BundleFinder.self))
		seedBundles.append(Bundle.main)
		var bundles: [Bundle] = []
		var visitedBundleURLs: Set<URL> = []
		for bundle in seedBundles where visitedBundleURLs.insert(bundle.bundleURL).inserted {
			bundles.append(bundle)
		}
		var searchDirectoryURLs: [URL] = []
		for bundle in bundles {
			if let resourceURL = bundle.resourceURL {
				searchDirectoryURLs.append(resourceURL)
			}
			searchDirectoryURLs.append(bundle.bundleURL.deletingLastPathComponent())
		}
		for directoryURL in searchDirectoryURLs {
			guard
				let contents = try? FileManager.default.contentsOfDirectory(
					at: directoryURL,
					includingPropertiesForKeys: nil
				)
			else { continue }
			for entry in contents where entry.pathExtension == "bundle" {
				guard visitedBundleURLs.insert(entry).inserted else { continue }
				if let nestedBundle = Bundle(url: entry) {
					bundles.append(nestedBundle)
				}
			}
		}
		return bundles
	}
}
