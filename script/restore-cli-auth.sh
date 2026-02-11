#!/usr/bin/env bash
# ============================================================================
# CLI Authentication Restore Script
# Codespaces Secretsから認証情報を復元
# ============================================================================

set -euo pipefail

echo "[INFO] CLI認証情報の復元を開始します..."

# Codex認証情報の復元
if [[ -n "${CODEX_AUTH_JSON:-}" ]]; then
    echo "[INFO] Codex認証情報を復元中..."
    mkdir -p ~/.codex
    echo "$CODEX_AUTH_JSON" | base64 -d > ~/.codex/auth.json
    chmod 600 ~/.codex/auth.json
    echo "[SUCCESS] Codex認証情報を復元しました"
else
    echo "[INFO] CODEX_AUTH_JSON が設定されていません。スキップします。"
fi

# Gemini認証情報の復元
if [[ -n "${GEMINI_OAUTH_CREDS:-}" ]]; then
    echo "[INFO] Gemini OAuth認証情報を復元中..."
    mkdir -p ~/.gemini
    echo "$GEMINI_OAUTH_CREDS" | base64 -d > ~/.gemini/oauth_creds.json
    chmod 600 ~/.gemini/oauth_creds.json
    echo "[SUCCESS] Gemini OAuth認証情報を復元しました"
else
    echo "[INFO] GEMINI_OAUTH_CREDS が設定されていません。スキップします。"
fi

if [[ -n "${GEMINI_GOOGLE_ACCOUNTS:-}" ]]; then
    echo "[INFO] Gemini Googleアカウント情報を復元中..."
    mkdir -p ~/.gemini
    echo "$GEMINI_GOOGLE_ACCOUNTS" | base64 -d > ~/.gemini/google_accounts.json
    chmod 644 ~/.gemini/google_accounts.json
    echo "[SUCCESS] Gemini Googleアカウント情報を復元しました"
else
    echo "[INFO] GEMINI_GOOGLE_ACCOUNTS が設定されていません。スキップします。"
fi

echo "[SUCCESS] CLI認証情報の復元が完了しました"
