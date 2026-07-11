//
//  SnapshotCore
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

/// `.text` 策略：報表、格式器輸出等「本身就是文字」的主體
extension GoldenStrategy where Subject: CustomStringConvertible {

	/// `String`／`CustomStringConvertible` 原文入檔、不加工
	///
	/// 不做任何正規化（含尾換行）——characterization 釘的是輸出原樣，
	/// 「整理輸出」是受測程式的職責、不是比對層的。
	public static var text: GoldenStrategy<Subject> {
		GoldenStrategy(fileExtension: "txt") { subject in
			subject.description
		}
	}
}
