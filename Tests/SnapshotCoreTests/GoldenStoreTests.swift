//
//  SnapshotCoreTests
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

import Foundation
import SnapshotCore
import Testing

private final class GoldenStoreTests {

	// MARK: Lifecycle

	/// 測試收尾清沙盒
	deinit {
		try? FileManager.default.removeItem(at: sandboxDirectoryURL)
	}

	// MARK: Private

	/// 每個測試實例獨立的沙盒目錄（充當「測試檔所在目錄」）
	private let sandboxDirectoryURL = FileManager.default
		.temporaryDirectory
		.appending(path: "GoldenStoreTests-\(UUID().uuidString)", directoryHint: .isDirectory)

	/// 在沙盒內組一個 golden 落點
	private func makeLocation() -> GoldenLocation {
		GoldenLocation(
			testFilePath: sandboxDirectoryURL.appending(path: "SyntheticTests.swift").path(percentEncoded: false),
			testName: "syntheticTest()",
			fileExtension: "txt"
		)
	}

	/// golden 檔不存在回 `nil`——「查無」是首次錄製的正常路徑、不當錯誤拋。
	@Test
	private func `returns nil when golden file is absent`() throws {
		let store: GoldenStore = .init()
		let location = makeLocation()
		#expect(try store.readGolden(at: location) == nil)
	}

	/// 寫入 golden 自動建 `__Golden__/<測試檔名>/` 中介目錄，內容原樣讀回。
	@Test
	private func `writes golden creating intermediate directory then reads it back`() throws {
		let store: GoldenStore = .init()
		let location = makeLocation()
		try store.writeGolden("expected\n", at: location)
		let directoryURL = location.goldenFileURL.deletingLastPathComponent()
		#expect(FileManager.default.fileExists(atPath: directoryURL.path(percentEncoded: false)))
		#expect(try store.readGolden(at: location) == "expected\n")
	}

	/// golden 內容非合法 UTF-8（如被二進位工具動過）一律 throws，不吞聲用替代字元混過去。
	@Test
	private func `throws when golden bytes are not valid utf8`() throws {
		let store: GoldenStore = .init()
		let location = makeLocation()
		try store.writeGolden("placeholder\n", at: location)
		let invalidBytes: Data = .init([0xFF, 0xFE, 0xFD])
		try invalidBytes.write(to: location.goldenFileURL, options: .atomic)
		#expect(throws: TextDecodingError.self) {
			try store.readGolden(at: location)
		}
	}

	/// `.actual` 檔寫在 golden 旁、內容原樣（mismatch 時供人工比對）。
	@Test
	private func `writes actual file alongside golden`() throws {
		let store: GoldenStore = .init()
		let location = makeLocation()
		try store.writeActual("observed\n", at: location)
		#expect(FileManager.default.fileExists(atPath: location.actualFileURL.path(percentEncoded: false)))
		let actualData = try Data(contentsOf: location.actualFileURL)
		let actualContent = try #require(String(bytes: actualData, encoding: .utf8))
		#expect(actualContent == "observed\n")
	}

	/// 移除 `.actual` 是 best effort：檔案不存在時安靜略過、不拋錯。
	@Test
	private func `remove actual is best effort when actual file is absent`() throws {
		let store: GoldenStore = .init()
		let location = makeLocation()
		store.removeActual(at: location)
		#expect(!FileManager.default.fileExists(atPath: location.actualFileURL.path(percentEncoded: false)))
	}
}
