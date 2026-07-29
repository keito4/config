#!/usr/bin/env bash
#
# skhd を安定した identity で自己署名できるようにする一度きりのセットアップ。
#
# Why this exists:
#   nix-darwin は skhd を /usr/local/bin/skhd に実体コピーして launchd から起動する。
#   このバイナリは ad-hoc (linker-signed) のため、macOS の TCC は cdhash で
#   アクセシビリティ許可を紐付ける。nixpkgs の skhd が更新されてコピーの中身が
#   変わると cdhash も変わり、許可が無効化される。
#
#   さらに厄介なことに、ad-hoc バイナリは同定が不安定なため、システム設定で
#   許可を付け直しても **launchd が直接起動したプロセスには適用されない**
#   (ターミナルから手動起動した場合だけ親プロセスの許可を継承して動く)。
#
#   固定の自己署名証明書で署名すると TCC は cdhash ではなく designated
#   requirement で紐付けるようになり、skhd を更新しても許可が保持される。
#
# Why this is not run automatically:
#   キーチェーンへの証明書取り込みと信頼設定は管理者認証を伴うため、
#   本人が対話的に実行する必要がある。
#
# Usage: sudo ./script/macos/setup-skhd-signing.sh
#
# 実行後は `darwin-rebuild switch` (make nix-switch) を一度流すと、activation が
# /usr/local/bin/skhd をこの identity で署名する。その後システム設定 >
# プライバシーとセキュリティ > アクセシビリティ で skhd を一度削除して追加し直すと、
# 以後は skhd を更新しても許可が維持される。

set -euo pipefail

IDENTITY="skhd-local-signing"
KEYCHAIN="/Library/Keychains/System.keychain"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

if [ "$(id -u)" -ne 0 ]; then
    echo "エラー: root で実行してください (sudo $0)" >&2
    exit 1
fi

if security find-identity -v -p codesigning "$KEYCHAIN" 2>/dev/null | grep -q "$IDENTITY"; then
    echo "identity '$IDENTITY' は既に存在します。何もしません。"
    exit 0
fi

echo "[1/4] 自己署名の code signing 証明書を作成します"
# extendedKeyUsage=codeSigning と basicConstraints を明示しないと codesign が受け付けない。
cat > "$WORKDIR/openssl.cnf" <<'CNF'
[req]
distinguished_name = dn
x509_extensions    = ext
prompt             = no

[dn]
CN = skhd-local-signing

[ext]
basicConstraints       = critical,CA:false
keyUsage               = critical,digitalSignature
extendedKeyUsage       = critical,codeSigning
CNF

openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -config "$WORKDIR/openssl.cnf" \
    -keyout "$WORKDIR/key.pem" -out "$WORKDIR/cert.pem" 2>/dev/null

openssl pkcs12 -export -inkey "$WORKDIR/key.pem" -in "$WORKDIR/cert.pem" \
    -out "$WORKDIR/bundle.p12" -passout pass: 2>/dev/null

echo "[2/4] System キーチェーンに取り込みます"
# root の activation から codesign が秘密鍵を使えるよう、System キーチェーンに入れる。
# -A は「どのアプリからも使用可」の意味で、これが無いと codesign 実行時に
# 対話プロンプトが出て activation が止まる。
security import "$WORKDIR/bundle.p12" -k "$KEYCHAIN" -P "" -A \
    -T /usr/bin/codesign -T /usr/bin/security >/dev/null

echo "[3/4] 証明書を code signing 用として信頼します"
security add-trusted-cert -d -r trustRoot -p codeSign -k "$KEYCHAIN" "$WORKDIR/cert.pem"

echo "[4/4] 確認"
if security find-identity -v -p codesigning "$KEYCHAIN" | grep -q "$IDENTITY"; then
    echo "  OK: identity '$IDENTITY' を作成しました"
else
    echo "  NG: identity が見つかりません" >&2
    exit 1
fi

cat <<MSG

次の手順:
  1. make nix-switch          (activation が skhd をこの identity で署名する)
  2. システム設定 > プライバシーとセキュリティ > アクセシビリティ で
     skhd を「−」で削除してから「＋」で /usr/local/bin/skhd を追加し直す
     (⌘⇧G でパスを直接指定できる)
  3. launchctl kickstart -k gui/\$(id -u)/org.nixos.skhd

以後 skhd が更新されても許可は保持される。
MSG
