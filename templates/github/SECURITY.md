# Security Policy

## Supported Versions

<!-- TODO: サポートバージョンを記載 -->

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |

## Reporting a Vulnerability

セキュリティ上の脆弱性を発見した場合は、**公開 Issue を作成しないでください**。

以下のいずれかの方法で報告してください:

1. **GitHub Security Advisories**: [Security タブ](../../security/advisories/new) から非公開で報告
2. **メール**: <!-- TODO: セキュリティ連絡先メールアドレス -->

### 報告に含めてほしい情報

- 脆弱性の概要
- 再現手順
- 影響範囲
- 可能であれば修正案

### 対応フロー

1. 報告受領の確認: **2営業日以内**
2. 初期調査と影響評価: **5営業日以内**
3. 修正リリース: 重大度に応じて対応

## Security Best Practices

このプロジェクトでは以下のセキュリティ対策を実施しています:

- Dependabot による依存関係の脆弱性検出
- GitHub Advanced Security (Code Scanning)
- シークレットスキャン (gitleaks)
- SAST (Static Application Security Testing)
