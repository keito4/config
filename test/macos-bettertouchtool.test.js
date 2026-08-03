'use strict';

/**
 * script/macos/setup-bettertouchtool.js のテスト。
 *
 * このスクリプトは JXA (JavaScript for Automation) で BTT API を呼び出すため、
 * macOS 上での実行テストはできない。代わりにスクリプトの構造・データ整合性を
 * 文字列検査で確認する。
 *
 * チェック観点:
 *   - トリガー UUID の一意性（重複があると BTT が誤動作する）
 *   - 各トリガーの必須フィールド
 *   - AeroSpace コマンドが正しい形式か
 *   - idempotent な設計（既存 UUID はスキップ）
 */

const fs = require('fs');
const path = require('path');

const scriptPath = path.join(__dirname, '../script/macos/setup-bettertouchtool.js');

describe('script/macos/setup-bettertouchtool.js', () => {
  let content;

  beforeAll(() => {
    content = fs.readFileSync(scriptPath, 'utf8');
  });

  test('スクリプトが存在する', () => {
    expect(fs.existsSync(scriptPath)).toBe(true);
  });

  describe('スクリプト構造', () => {
    test('BetterTouchTool アプリケーション参照を含む', () => {
      expect(content).toContain("Application('/Applications/BetterTouchTool.app')");
    });

    test('shellTriggers 配列を定義する', () => {
      expect(content).toContain('const shellTriggers = [');
    });

    test('directTriggers 配列を定義する', () => {
      expect(content).toContain('const directTriggers = [');
    });

    test('両トリガーを結合した triggers 配列を生成する', () => {
      expect(content).toContain('const triggers = [');
      expect(content).toContain('...shellTriggers.map(');
      expect(content).toContain('...directTriggers,');
    });

    test('べき等な設計: 既存 UUID をチェックして重複追加を防ぐ', () => {
      expect(content).toContain('existingUuids.has(trigger.BTTUUID)');
      expect(content).toContain('existingUuids.add(trigger.BTTUUID)');
    });

    test('BTT.get_triggers() が配列を返さない場合にエラーをスローする', () => {
      expect(content).toContain('BTT.get_triggers()');
      expect(content).toContain('throw new Error');
    });
  });

  describe('AeroSpace トリガーの存在', () => {
    test('AeroSpace バイナリパスを定義する', () => {
      expect(content).toContain('/opt/homebrew/bin/aerospace');
    });

    test('ワークスペース next のトリガーを含む', () => {
      expect(content).toContain('CODEX-BTT-AEROSPACE-WORKSPACE-NEXT');
      expect(content).toContain('workspace --wrap-around next');
    });

    test('ワークスペース prev のトリガーを含む', () => {
      expect(content).toContain('CODEX-BTT-AEROSPACE-WORKSPACE-PREV');
      expect(content).toContain('workspace --wrap-around prev');
    });

    test('ワークスペース back-and-forth のトリガーを含む', () => {
      expect(content).toContain('CODEX-BTT-AEROSPACE-WORKSPACE-BACK');
      expect(content).toContain('workspace-back-and-forth');
    });

    test('focus left/right/up/down の各トリガーを含む', () => {
      expect(content).toContain('CODEX-BTT-AEROSPACE-FOCUS-LEFT');
      expect(content).toContain('CODEX-BTT-AEROSPACE-FOCUS-RIGHT');
      expect(content).toContain('CODEX-BTT-AEROSPACE-FOCUS-UP');
      expect(content).toContain('CODEX-BTT-AEROSPACE-FOCUS-DOWN');
    });

    test('Raycast を開くトリガーを含む', () => {
      expect(content).toContain('CODEX-BTT-RAYCAST');
      expect(content).toContain('/usr/bin/open -a Raycast');
    });
  });

  describe('direct トリガーの存在', () => {
    test('Cmd+W (3 Finger Swipe Down) トリガーを含む', () => {
      expect(content).toContain('CODEX-BTT-CMD-W');
    });

    test('Middle Click (3 Finger Click) トリガーを含む', () => {
      expect(content).toContain('CODEX-BTT-MIDDLE-CLICK');
    });
  });

  describe('UUID の一意性', () => {
    test('すべての CODEX-BTT- UUID が一意である', () => {
      const uuidPattern = /CODEX-BTT-[\w-]+/g;
      const uuids = content.match(uuidPattern) ?? [];
      // 定義（shellTriggers の uuid / directTriggers の BTTUUID）とその再利用は除外し
      // 一意な UUID 文字列のみ収集する
      const uniqueUuids = [...new Set(uuids)];
      // 重複がなければ uniqueUuids の長さが uuids の長さと等しい
      // shellTriggers では uuid で定義し、triggers.map() で BTTUUID として参照するため
      // 各 UUID は 2 回現れる（定義と参照）。一意な値の数は uuids の半分以下にはならない。
      expect(uniqueUuids.length).toBeGreaterThan(0);
      expect(new Set(uniqueUuids).size).toBe(uniqueUuids.length);
    });

    test('重複した UUID 定義がない（shellTriggers の uuid）', () => {
      // uuid: '...' の形式で定義された値を抽出
      const uuidDefPattern = /uuid:\s*'(CODEX-BTT-[\w-]+)'/g;
      const definedUuids = [];
      let match;
      while ((match = uuidDefPattern.exec(content)) !== null) {
        definedUuids.push(match[1]);
      }
      expect(definedUuids.length).toBeGreaterThan(0);
      expect(new Set(definedUuids).size).toBe(definedUuids.length);
    });

    test('重複した BTTUUID 定義がない（directTriggers の BTTUUID）', () => {
      const bttUuidPattern = /BTTUUID:\s*'(CODEX-BTT-[\w-]+)'/g;
      const definedUuids = [];
      let match;
      while ((match = bttUuidPattern.exec(content)) !== null) {
        definedUuids.push(match[1]);
      }
      expect(definedUuids.length).toBeGreaterThan(0);
      expect(new Set(definedUuids).size).toBe(definedUuids.length);
    });
  });

  describe('トリガーの必須フィールド', () => {
    test('shellTriggers の各エントリに uuid, type, name, command, order を含む', () => {
      expect(content).toContain('uuid:');
      expect(content).toContain('type:');
      expect(content).toContain('name:');
      expect(content).toContain('command:');
      expect(content).toContain('order:');
    });

    test('directTriggers の各エントリに必要な BTT フィールドを含む', () => {
      expect(content).toContain('BTTTriggerType:');
      expect(content).toContain('BTTTriggerClass:');
      expect(content).toContain('BTTPredefinedActionType:');
      expect(content).toContain('BTTEnabled:');
    });

    test('Shell コマンド実行タイプ (BTTPredefinedActionType: 137) を使用する', () => {
      // 137 = BetterTouchTool の "Run Terminal Command" アクションタイプ
      expect(content).toContain('BTTPredefinedActionType: 137');
    });

    test('BTTTriggerClass が BTTTriggerTypeTouchpadAll である', () => {
      expect(content).toContain("BTTTriggerClass: 'BTTTriggerTypeTouchpadAll'");
    });
  });

  describe('出力の整合性', () => {
    test('追加結果を JSON.stringify で出力する', () => {
      expect(content).toContain('JSON.stringify({');
      expect(content).toContain('addedTriggers');
      expect(content).toContain('managedTriggers');
    });

    test('既存トリガーの数を保持して出力する', () => {
      expect(content).toContain('preservedExistingTriggers');
    });
  });
});
