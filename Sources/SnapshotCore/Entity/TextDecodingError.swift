//
//  SnapshotCore
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

/// bytes → 文字失敗的錯誤：golden 內容不是合法 UTF-8
///
/// 一律拒收、不吞聲用 replacement character 混過去——非法位元組多半代表檔案被
/// 二進位工具動過或編碼設定出錯，這類問題該在當下爆出來、不該被悄悄顯示成亂碼。
public enum TextDecodingError: Error, CustomStringConvertible {

	/// bytes 不是合法 UTF-8；`context` 是人讀的來源描述（如檔案路徑）
	case invalidUTF8(context: String)

	/// 人讀診斷訊息
	public var description: String {
		switch self {
		case let .invalidUTF8(context):
			"bytes are not valid UTF-8: \(context)"
		}
	}
}
