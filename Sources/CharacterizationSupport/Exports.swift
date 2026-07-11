//
//  CharacterizationSupport
//
//  Copyright © 2026 Unpxre (GitHub: UnpxreTW)
//  Licensed under the Apache License 2.0. See LICENSE for details.
//
//  SPDX-License-Identifier: Apache-2.0

// !!!: `@_exported` 屬底線 attribute、非正式支援 API——刻意採用：
// 呼叫 `expectGolden(as: .json)` 必然觸及 SnapshotCore 的 `GoldenStrategy` 型別，
// 若不轉出，下游每個測試檔都得多寫一行 `import SnapshotCore`。
// 若未來 Swift 提供正式的 re-export 機制，改用之。
@_exported import SnapshotCore
