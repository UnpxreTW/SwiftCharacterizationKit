//
//  SnapshotCoreTests
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

import SnapshotCore
import Testing

private final class UnifiedDifferTests {

	/// 完全一致回 `nil`（含空字串對空字串）。
	@Test
	private func `returns nil for identical text`() {
		let differ: UnifiedDiffer = .init()
		#expect(differ.diff(golden: "a\nb\n", actual: "a\nb\n") == nil)
		#expect(differ.diff(golden: "", actual: "") == nil)
	}

	/// 單行變更：hunk 帶前後 context、`-`／`+` 前綴正確。
	@Test
	private func `emits unified hunk for single changed line`() {
		let diff = UnifiedDiffer().diff(golden: "a\nb\nc\n", actual: "a\nB\nc\n")
		let expected = """
			--- golden
			+++ actual
			@@ -1,3 +1,3 @@
			 a
			-b
			+B
			 c
			"""
		#expect(diff == expected)
	}

	/// 相距超過 2×context 的變更拆成兩個 hunk、行號各自正確。
	@Test
	private func `separates distant changes into multiple hunks`() {
		let goldenText = (1 ... 7).map { "l\($0)" }.joined(separator: "\n") + "\n"
		let actualLines = (1 ... 7).map { lineNumber in
			lineNumber == 2 || lineNumber == 6 ? "X\(lineNumber)" : "l\(lineNumber)"
		}
		let actualText = actualLines.joined(separator: "\n") + "\n"
		let diff = UnifiedDiffer(contextLineCount: 1).diff(golden: goldenText, actual: actualText)
		let expected = """
			--- golden
			+++ actual
			@@ -1,3 +1,3 @@
			 l1
			-l2
			+X2
			 l3
			@@ -5,3 +5,3 @@
			 l5
			-l6
			+X6
			 l7
			"""
		#expect(diff == expected)
	}

	/// 尾端純插入：golden 側行數照舊、actual 側多一行。
	@Test
	private func `renders pure insertion at end`() {
		let diff = UnifiedDiffer().diff(golden: "a\n", actual: "a\nb\n")
		let expected = """
			--- golden
			+++ actual
			@@ -1,1 +1,2 @@
			 a
			+b
			"""
		#expect(diff == expected)
	}

	/// 空 golden 對上有內容的 actual：hunk 以 `-0,0` 表達空側。
	@Test
	private func `renders insertion into empty golden`() {
		let diff = UnifiedDiffer().diff(golden: "", actual: "x\n")
		let expected = """
			--- golden
			+++ actual
			@@ -0,0 +1,1 @@
			+x
			"""
		#expect(diff == expected)
	}

	/// 僅尾換行差異：逐行視角看不見、回固定標記而非 `nil`。
	@Test
	private func `flags trailing newline only difference`() {
		let diff = UnifiedDiffer().diff(golden: "a\n", actual: "a")
		let expected = """
			--- golden
			+++ actual
			(difference only in trailing newline)
			"""
		#expect(diff == expected)
	}
}
