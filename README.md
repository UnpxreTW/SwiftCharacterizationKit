# SwiftCharacterizationKit

characterization test 的第一方底座：把「render → 序列化 → golden 比對」與 fixture 機制打包成一個 SPM package，test target 掛上即用、零 shipping 足跡。重構前先釘現行行為，重構時讓漂移自己現形。

核心取捨是**文字優先**：golden 一律是可讀文字（`.json`／`.text`／`.accessibilityTree`／`.viewHierarchy`），跨機穩定、PR diff 直接可讀；像素比對不在目前範圍。

## 安裝

```swift
.package(url: "https://github.com/UnpxreTW/SwiftCharacterizationKit.git", from: "0.0.1")
```

三個 library product 只掛在 test target 上——這就是「零 shipping 足跡」的字面意思：

```swift
.testTarget(
	name: "MyAppTests",
	dependencies: [
		.product(name: "CharacterizationSupport", package: "SwiftCharacterizationKit"),
		.product(name: "FixtureSupport", package: "SwiftCharacterizationKit"),
	],
	resources: [.copy("Fixtures")]
)
```

`CharacterizationSupport` 轉出 `SnapshotCore`（`GoldenStrategy` 等型別），測試檔只需 `import CharacterizationSupport`；只要序列化層、不要測試框架薄殼時才單獨掛 `SnapshotCore`。

環境下限：swift-tools-version 6.2、iOS 26／macOS 26。畫面層策略（`.accessibilityTree`／`.viewHierarchy`）依賴 UIKit、只在 iOS 生效，macOS 側用邏輯層策略（`.json`／`.text`）。

## 最小使用範例

Swift Testing：

```swift
import CharacterizationSupport
import Testing

struct HomeSummary: Encodable {

	let title: String

	let badgeCount: Int
}

@Test func homeSummaryStaysStable() throws {
	let summary: HomeSummary = .init(title: "首頁", badgeCount: 3)
	try expectGolden(of: summary, as: .json)
}
```

`.json` 要求主體是 `Encodable`，輸出格式釘死在排序鍵、固定縮排與結尾換行，golden 不會因字典迭代序而漂移；`.text` 要求 `CustomStringConvertible`，把 `description` 原樣入檔、不做任何正規化（含尾換行）——整理輸出是受測程式的職責，不是比對層的。既有 XCTest target 改用同引擎的 `assertGolden(of:as:)`，不必為了掛安全網先遷移測試框架。

golden 落在測試檔旁：`__Golden__/<測試檔名>/<測試名>.<區分名>.<副檔名>`，**與測試檔一起進 git**——golden 即規格、diff 即 review 面。首次執行會寫出 golden 並**仍然失敗**（訊息 `recorded — re-run to verify`），再跑一次才轉綠；重錄單一 golden 在呼叫點加 `record: true`，整批重錄用環境變數 `CHARACTERIZATION_RECORD=1`（CI 永不設——CI 只驗不錄，新 golden 必經本機錄製與人審）。比對不一致時，本次實際輸出寫成同目錄的 `.actual` 檔，下游把它排除在版控外：

```gitignore
**/__Golden__/**/*.actual.*
```

畫面層（iOS）：`try expectGolden(of: view, as: .accessibilityTree)` 釘 SwiftUI 的無障礙樹，`.viewHierarchy` 釘 UIKit 的視圖階層；畫布尺寸由 `DevicePreset` 固定、不隨測試機螢幕漂移，例 `.accessibilityTree(preset: .iPadPortrait)`。

`.accessibilityTree` 需要 **hosted test target**（app 專案的 unit test target 天生如此）：無 host app 的 SwiftPM 測試 process 列舉不到 SwiftUI 的無障礙元素，會錄出空 golden。UIKit 的 `.viewHierarchy` 走視圖階層、不經無障礙元素列舉。

fixture 與決定性注入（`FixtureSupport`）：

```swift
import FixtureSupport

// test target 的 resources: [.copy("Fixtures")] 對應 subdirectory
let user: SampleUser = try FixtureLoader.load("sample-user.json", in: .module, subdirectory: "Fixtures")

// 網路層改打 stub，不需要 staging 環境與帳號
let url: URL = .init(string: "https://example.com/user")!
let stub: StubbedResponse = try .init(fixtureNamed: "sample-user.json", in: .module, subdirectory: "Fixtures")
StubURLProtocol.setStub(stub, for: url)
let session: URLSession = .init(configuration: StubURLProtocol.sessionConfiguration)
```

時間與識別碼同樣可釘：`FixedClock(now:)` 提供固定的 `Date`、`FixedUUID()` 依序產生可讀的 `UUID`，兩者都以 `callAsFunction` 直接塞進 app 側的注入 seam。每個測試收尾呼叫 `StubURLProtocol.removeAllStubs()` 清乾淨。

## 開發

```sh
swift build
SWIFTSTYLELINT_STRICT=1 swift test
```

風格規則由 SwiftStyleKit 的 `SwiftStyleLint` build tool plugin 在每次 build 時套用，`SWIFTSTYLELINT_STRICT=1` 把違規升為錯誤（CI 的 test job 即以此執行）。

iOS 側另跑模擬器 leg；scheme 名由套件自動生成、隨 Xcode 版本而異，以 `xcodebuild -list` 查得：

```sh
xcodebuild test -scheme "<套件 scheme>" -destination 'platform=iOS Simulator,name=iPhone 17' -skipPackagePluginValidation
```

`-skipPackagePluginValidation` 是必要的：套件相依的 build tool plugin 在無 UI 環境會卡在互動核准步驟。CI（`.github/workflows/`）釘 Xcode 26.3、跑 build 與 test 兩個 workflow 的 macOS 與 iOS Simulator legs，另有 REUSE 授權合規檢查。

## License

Apache-2.0，見 `LICENSE` 與 `LICENSES/`（REUSE 佈局）。
