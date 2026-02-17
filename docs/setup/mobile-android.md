# モバイル (Android) セットアップガイド

## detekt（Kotlin 静的解析）

```kotlin
// build.gradle.kts (ルート)
plugins {
    id("io.gitlab.arturbosch.detekt") version "1.23.7" apply false
}

// app/build.gradle.kts
plugins {
    id("io.gitlab.arturbosch.detekt")
}

detekt {
    buildUponDefaultConfig = true
    config.setFrom("$rootDir/config/detekt.yml")
}
```

```yaml
# CI
- name: Run detekt
  run: ./gradlew detekt
```

## Kover（カバレッジ 70%）

```kotlin
// app/build.gradle.kts
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

```yaml
# CI
- name: Run tests with coverage
  run: ./gradlew koverVerify
- name: Generate coverage report
  run: ./gradlew koverHtmlReport
```

## CLAUDE.md

**含めるべき内容**:

- **技術スタック**: Kotlin / Jetpack Compose / DI フレームワーク / DB / Coroutines
- **アーキテクチャ**: レイヤー分離の方針（domain/data/presentation 等）
- **依存管理**: Version Catalog (`gradle/libs.versions.toml`) の運用方針
- **テスト戦略**: Unit テスト（JUnit + アサーション + モック）、Integration テストのフレームワーク
- **リリースフロー**: CI でのバージョン管理とデプロイ先
- **ビルド設定**: バージョン管理の仕組み

## commitlint（lefthook）

Android プロジェクトは JVM 非依存の lefthook を推奨。

```yaml
# lefthook.yml
commit-msg:
  commands:
    commitlint:
      run: 'echo "{1}" | npx commitlint --edit'
```

## Claude Code ワークフロー

config リポジトリの `.github/workflows/claude.yml` をテンプレートとして追加。

## CodeQL

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

## DevContainer

- **ベースイメージ**: `ghcr.io/keito4/config-base:latest`
- **Features**: `java(17)` + Gradle — Android 固有のため維持
- **postCreateCommand**: `sdkmanager --install 'platforms;android-35' ...`
