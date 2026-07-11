//
//  SnapshotCore
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

/// 逐行 unified diff 產生器
///
/// golden 與 actual 都是文字（本 kit 的核心取捨），diff 用標準 unified 格式
/// （`@@ -a,b +c,d @@`＋前綴 ` `／`-`／`+`）——與 git diff 同語彙，PR review 直接可讀。
/// 實作走 LCS 動態規劃、O(行數²) 記憶體；golden 屬短文件（數十至數百行），此複雜度足夠。
public struct UnifiedDiffer: Sendable {

	// MARK: Public

	/// 每個 hunk 前後保留的未變更行數（與 git 預設一致取 3）
	public let contextLineCount: Int

	/// 比對兩份文字；完全一致回 `nil`、不一致回 unified diff 全文
	///
	/// 一致性以「原始字串完全相等」判定（先於逐行比較）——僅行尾換行差異
	/// 在逐行視角看不見，此時回固定標記文字而非 `nil`，避免 mismatch 卻無 diff 可報。
	public func diff(golden goldenText: String, actual actualText: String) -> String? {
		if goldenText == actualText {
			return nil
		}
		let goldenLines = lines(of: goldenText)
		let actualLines = lines(of: actualText)
		let edits = editScript(from: goldenLines, to: actualLines)
		let hunks = hunks(from: edits, contextLineCount: contextLineCount)
		var outputLines = ["--- golden", "+++ actual"]
		guard !hunks.isEmpty else {
			outputLines.append("(difference only in trailing newline)")
			return outputLines.joined(separator: "\n")
		}
		for hunk in hunks {
			outputLines.append("@@ -\(hunk.goldenStart),\(hunk.goldenCount) +\(hunk.actualStart),\(hunk.actualCount) @@")
			outputLines.append(contentsOf: hunk.renderedLines)
		}
		return outputLines.joined(separator: "\n")
	}

	/// 以指定 context 行數建立 differ
	public init(contextLineCount: Int = 3) {
		self.contextLineCount = contextLineCount
	}

	// MARK: Private

	// 以下 helper 不碰 `self`、邏輯上可以是 `static`——刻意留成 instance method：
	// 從 `static` 呼叫需要 `Self.foo(...)` 這種「型別名.成員」寫法，SwiftStyleKit
	// 的 propertyTypes（explicit 模式）在偵測不到真實回傳型別時會誤植成
	// `let x: Self = .foo(...)`、把非 Self 的回傳型別錯標成 Self 而編譯失敗；
	// 維持 instance method、呼叫端用隱式 self 不帶型別字首，即可繞過此已知誤判。

	/// 單行編輯操作（LCS 回推產物）
	private enum LineEdit {

		/// 兩側一致的行
		case equal(String)

		/// 僅存在 golden 側的行
		case delete(String)

		/// 僅存在 actual 側的行
		case insert(String)

		/// 是否為變更行（非 `equal`）
		var isChange: Bool {
			if case .equal = self { return false }
			return true
		}
	}

	/// 一個 unified hunk：起始行號、行數與已加前綴的內容行
	private struct Hunk {

		/// golden 側起始行號（1-based；hunk 內無 golden 行時為前一行行號）
		var goldenStart: Int

		/// golden 側行數（equal＋delete）
		var goldenCount: Int

		/// actual 側起始行號（1-based；hunk 內無 actual 行時為前一行行號）
		var actualStart: Int

		/// actual 側行數（equal＋insert）
		var actualCount: Int

		/// 已加 ` `／`-`／`+` 前綴的內容行
		var renderedLines: [String]
	}

	/// 把文字拆成行陣列
	///
	/// 尾端換行不產生空行元素（`"a\n"` 與 `"a"` 同為 `["a"]`）——尾換行差異
	/// 由 ``diff(golden:actual:)`` 的原始字串相等判定接手。
	private func lines(of text: String) -> [String] {
		guard !text.isEmpty else { return [] }
		var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
		if text.hasSuffix("\n") {
			lines.removeLast()
		}
		return lines
	}

	/// LCS 動態規劃＋回推，產出從 golden 到 actual 的逐行編輯腳本
	private func editScript(from goldenLines: [String], to actualLines: [String]) -> [LineEdit] {
		let goldenCount = goldenLines.count
		let actualCount = actualLines.count
		var table: Array = .init(repeating: Array(repeating: 0, count: actualCount + 1), count: goldenCount + 1)
		for goldenIndex in stride(from: goldenCount - 1, through: 0, by: -1) {
			for actualIndex in stride(from: actualCount - 1, through: 0, by: -1) {
				table[goldenIndex][actualIndex] = if goldenLines[goldenIndex] == actualLines[actualIndex] {
					table[goldenIndex + 1][actualIndex + 1] + 1
				} else {
					max(
						table[goldenIndex + 1][actualIndex],
						table[goldenIndex][actualIndex + 1]
					)
				}
			}
		}
		var edits: [LineEdit] = []
		var goldenIndex = 0
		var actualIndex = 0
		while goldenIndex < goldenCount, actualIndex < actualCount {
			if goldenLines[goldenIndex] == actualLines[actualIndex] {
				edits.append(.equal(goldenLines[goldenIndex]))
				goldenIndex += 1
				actualIndex += 1
			} else if table[goldenIndex + 1][actualIndex] >= table[goldenIndex][actualIndex + 1] {
				edits.append(.delete(goldenLines[goldenIndex]))
				goldenIndex += 1
			} else {
				edits.append(.insert(actualLines[actualIndex]))
				actualIndex += 1
			}
		}
		while goldenIndex < goldenCount {
			edits.append(.delete(goldenLines[goldenIndex]))
			goldenIndex += 1
		}
		while actualIndex < actualCount {
			edits.append(.insert(actualLines[actualIndex]))
			actualIndex += 1
		}
		return edits
	}

	/// 把編輯腳本切成帶 context 的 hunk 群
	///
	/// 相鄰變更間距 ≤ 2×context 時併入同一 hunk（與 git 行為一致），
	/// 避免碎 hunk 干擾閱讀。
	private func hunks(from edits: [LineEdit], contextLineCount: Int) -> [Hunk] {
		let changedIndices = edits.indices.filter { edits[$0].isChange }
		guard !changedIndices.isEmpty else { return [] }
		let ranges = mergedRanges(around: changedIndices, contextLineCount: contextLineCount, editCount: edits.count)
		let offsets = lineOffsets(for: edits)
		return ranges.map { range in
			hunk(for: range, edits: edits, goldenLineBefore: offsets.golden, actualLineBefore: offsets.actual)
		}
	}

	/// 把變更行位置各自加上 context、相鄰／重疊者併成同一段 range
	///
	/// 「相鄰間距 ≤ 2×context 併入同一 hunk」在此體現：下一段起點落在
	/// 前一段終點 +1 以內即合併，避免碎 hunk。
	private func mergedRanges(
		around changedIndices: [Int], contextLineCount: Int, editCount: Int
	) -> [ClosedRange<Int>] {
		var ranges: [ClosedRange<Int>] = []
		for changedIndex in changedIndices {
			let lowerBound = max(changedIndex - contextLineCount, 0)
			let upperBound = min(changedIndex + contextLineCount, editCount - 1)
			if let lastRange = ranges.last, lowerBound <= lastRange.upperBound + 1 {
				ranges[ranges.count - 1] = lastRange.lowerBound ... max(lastRange.upperBound, upperBound)
			} else {
				ranges.append(lowerBound ... upperBound)
			}
		}
		return ranges
	}

	/// 預先算出每個編輯位置「之前」的兩側行號（1-based 起點）
	///
	/// `.insert` 不消耗 golden 行、`.delete` 不消耗 actual 行——兩側各自累加、
	/// 供 hunk 起始行號與空側慣例（見 ``hunk(for:edits:goldenLineBefore:actualLineBefore:)``）取用。
	private func lineOffsets(for edits: [LineEdit]) -> (golden: [Int], actual: [Int]) {
		var goldenLineBefore: Array = .init(repeating: 1, count: edits.count + 1)
		var actualLineBefore: Array = .init(repeating: 1, count: edits.count + 1)
		for (editIndex, edit) in edits.enumerated() {
			switch edit {
			case .equal:
				goldenLineBefore[editIndex + 1] = goldenLineBefore[editIndex] + 1
				actualLineBefore[editIndex + 1] = actualLineBefore[editIndex] + 1
			case .delete:
				goldenLineBefore[editIndex + 1] = goldenLineBefore[editIndex] + 1
				actualLineBefore[editIndex + 1] = actualLineBefore[editIndex]
			case .insert:
				goldenLineBefore[editIndex + 1] = goldenLineBefore[editIndex]
				actualLineBefore[editIndex + 1] = actualLineBefore[editIndex] + 1
			}
		}
		return (goldenLineBefore, actualLineBefore)
	}

	/// 組出單一 range 對應的 ``Hunk``：加前綴的內容行＋兩側起始行號／行數
	///
	/// 空側的 unified 慣例：count 0 時 start 標示在前一行。
	private func hunk(
		for range: ClosedRange<Int>,
		edits: [LineEdit],
		goldenLineBefore: [Int],
		actualLineBefore: [Int]
	) -> Hunk {
		var goldenCount = 0
		var actualCount = 0
		var renderedLines: [String] = []
		for editIndex in range {
			switch edits[editIndex] {
			case let .equal(line):
				goldenCount += 1
				actualCount += 1
				renderedLines.append(" \(line)")
			case let .delete(line):
				goldenCount += 1
				renderedLines.append("-\(line)")
			case let .insert(line):
				actualCount += 1
				renderedLines.append("+\(line)")
			}
		}
		let goldenStart = goldenCount == 0 ? goldenLineBefore[range.lowerBound] - 1 : goldenLineBefore[range.lowerBound]
		let actualStart = actualCount == 0 ? actualLineBefore[range.lowerBound] - 1 : actualLineBefore[range.lowerBound]
		return Hunk(
			goldenStart: goldenStart,
			goldenCount: goldenCount,
			actualStart: actualStart,
			actualCount: actualCount,
			renderedLines: renderedLines
		)
	}
}
