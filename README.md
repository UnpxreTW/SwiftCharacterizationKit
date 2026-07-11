# SwiftCharacterizationKit

characterization test 的第一方底座：把「render → 序列化 → golden 比對」與 fixture 機制打包成一個 SPM package，test target 掛上即用、零 shipping 足跡。重構前先釘現行行為，重構時讓漂移自己現形。

核心取捨是**文字優先**：golden 一律是可讀文字（`.json`／`.text`／`.accessibilityTree`／`.viewHierarchy`），跨機穩定、PR diff 直接可讀；像素比對不在目前範圍。

> 本 baseline 僅含專案基礎檔；套件原始碼、CI 與安裝／使用文件將以切片 PR 依序進入（SnapshotCore → CharacterizationSupport → FixtureSupport）。

## License

Apache-2.0，見 `LICENSE` 與 `LICENSES/`（REUSE 佈局）。
