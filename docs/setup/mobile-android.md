# モバイル (Android) セットアップガイド

## 現状サマリー

[docs/tool-catalog.md](../tool-catalog.md) セクション 4.1 および代表リポジトリの実態調査に基づく。

- [x] Kotlin 2.2.10 + Jetpack Compose (BOM 2026.01.01) 構成済み
- [x] Gradle 9.1.0 + AGP 9.0.0 + Version Catalog (`libs.versions.toml`) で依存一元管理
- [x] DevContainer 設定あり（ベースイメージ 1.0.13、Java 17 + Android SDK 35）
- [x] Unit テスト環境構築済み（JUnit 4 + Truth + MockK + Turbine、20+ ファイル）
- [x] Integration テスト構築済み（Espresso + Compose UI Test、10+ ファイル）
- [x] CI/CD ワークフロー（Lint → Unit Test → Build → Release → Firebase Distribution）
- [x] Android Lint 設定あり (`lint.xml`)
- [x] Hilt DI、Room (SQLCipher 暗号化)、Coroutines 導入済み
- [x] Firebase App Distribution による自動配布
- [x] Maestro による UI テスト環境あり (`.maestro/`)
- [ ] detekt（Kotlin 静的解析）未導入
- [ ] Kover（カバレッジ計測・閾値強制）未導入
- [ ] CLAUDE.md（未作成）
- [ ] commitlint / Git hooks（未設定）
- [ ] CodeQL / SAST（未追加）

**現在の品質ゲート達成率: 中程度（テスト・CI 基盤は充実、静的解析と閾値強制が不足）**

## セットアップ項目

### 優先度: 高

#### 1. detekt（Kotlin 静的解析）導入

**何を**: detekt を Gradle プラグインとして導入し、Kotlin コードの静的解析を CI に組み込む。

**なぜ**: Android Lint はリソース・マニフェスト中心の検査であり、Kotlin コードの複雑度・コード臭・命名規約等はカバーしない。ESLint 相当の品質保証に detekt が必要。

**現在の `build.gradle.kts`（ルート）に追加**:

```kotlin
plugins {
    // 既存の plugins に追加
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.android.library) apply false
    // ...
    id("io.gitlab.arturbosch.detekt") version "1.23.7" apply false
}
```

**`app/build.gradle.kts` に追加**:

```kotlin
plugins {
    id("io.gitlab.arturbosch.detekt")
}

detekt {
    buildUponDefaultConfig = true
    config.setFrom("$rootDir/config/detekt.yml")
}
```

**CI の既存 Lint ジョブに追加**:

```yaml
- name: Run detekt
  run: ./gradlew detekt
```

#### 2. Kover でカバレッジ計測・閾値強制

**何を**: JetBrains Kover を導入し、既存の豊富なテスト（Unit 20+, Integration 10+）のカバレッジを計測・70% 閾値を強制する。

**なぜ**: テスト環境は充実しているが、カバレッジの計測と閾値の強制が行われていない。TDD ベースラインの 70% を CI で担保する。

**`app/build.gradle.kts` に追加**:

```kotlin
plugins {
    id("org.jetbrains.kotlinx.kover") version "0.9.1"
}

kover {
    reports {
        verify {
            rule {
                minBound(70)
            }
        }
    }
}
```

**CI の既存 Unit Test ジョブに追加**:

```yaml
- name: Run tests with coverage
  run: ./gradlew koverVerify

- name: Generate coverage report
  run: ./gradlew koverHtmlReport
```

#### 3. CLAUDE.md 作成

**何を**: プロジェクト固有の開発コンテキストを CLAUDE.md に記載する。

**なぜ**: AI 支援開発の品質を一定に保つ。既存のアーキテクチャや技術スタックを明記する。

**含めるべき内容**:

- **技術スタック**: Kotlin / Jetpack Compose / DI フレームワーク / DB / Coroutines
- **アーキテクチャ**: レイヤー分離の方針（domain/data/presentation 等）
- **依存管理**: Version Catalog (`gradle/libs.versions.toml`) の運用方針
- **テスト戦略**: Unit テスト（JUnit + アサーション + モック）、Integration テストのフレームワーク
- **リリースフロー**: CI でのバージョン管理とデプロイ先
- **ビルド設定**: バージョン管理の仕組み

### 優先度: 中

#### 4. commitlint 相当の仕組み導入

**何を**: Conventional Commits を強制する Git hooks を導入する。

**なぜ**: CI の Release ジョブがコミットメッセージに基づくバージョンバンプを行っているため、不正なメッセージは自動リリースの障害になる。

**推奨**: lefthook（Go 製、JVM 非依存）

```yaml
# lefthook.yml
commit-msg:
  commands:
    commitlint:
      run: 'echo "{1}" | npx commitlint --edit'
```

#### 5. claude.yml ワークフロー追加

**何を**: `@claude` メンション対応の GitHub Actions ワークフローを追加する。

**なぜ**: Issue や PR で AI 支援を受けるための基盤。

**参考**: config リポジトリの `.github/workflows/claude.yml` をテンプレートとして使用。

#### 6. CodeQL / SAST 追加

**何を**: GitHub CodeQL（Java/Kotlin 対応）を CI に追加する。

**なぜ**: SAST は Static Quality Gates の必須要件。Room の SQL 操作や暗号化処理のセキュリティ検証に有効。

```yaml
- name: Initialize CodeQL
  uses: github/codeql-action/init@v3
  with:
    languages: java-kotlin

- name: Build
  run: ./gradlew assembleDebug

- name: Perform CodeQL Analysis
  uses: github/codeql-action/analyze@v3
```

### 優先度: 低

#### 7. ベースイメージ更新（1.0.13 → latest）

**何を**: DevContainer のベースイメージを最新版に更新する。

**なぜ**: AI CLI ツールやセキュリティパッチが大幅に遅れている（1.0.13 → 1.58.0+）。

**参考**: `/config-base-sync-update` コマンドで更新 + PR 作成が可能。

## DevContainer 最適化

- **ベースイメージ**: `ghcr.io/keito4/config-base:1.0.13` → `ghcr.io/keito4/config-base:latest`
- **既存 Features**: `java(17)` + Gradle — Android 固有のため維持
- **postCreateCommand**: `sdkmanager --install 'platforms;android-35' ...` — 維持
