/**
 * Integration Test Example
 *
 * 統合テストは、複数のコンポーネントやサービスが
 * 正しく連携して動作することを確認するテストです。
 *
 * tests/integration/user-flow.test.ts として配置してください。
 */

import { createClient } from '@supabase/supabase-js';

// テスト用のSupabaseクライアント
const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || 'http://localhost:54321',
  process.env.SUPABASE_SERVICE_ROLE_KEY || 'test-service-role-key',
);

describe('User Flow Integration', () => {
  // テストデータのクリーンアップ
  const testUserEmail = `test-${Date.now()}@example.com`;
  let testUserId: string;

  beforeAll(async () => {
    // テスト用ユーザーの作成
    const { data, error } = await supabase.auth.admin.createUser({
      email: testUserEmail,
      password: 'TestPassword123!',
      email_confirm: true,
    });

    if (error) throw error;
    testUserId = data.user.id;
  });

  afterAll(async () => {
    // テストユーザーの削除
    if (testUserId) {
      await supabase.auth.admin.deleteUser(testUserId);
    }
  });

  describe('ユーザー登録フロー', () => {
    it('ユーザーがデータベースに正しく保存される', async () => {
      const { data, error } = await supabase.from('users').select('*').eq('id', testUserId).single();

      expect(error).toBeNull();
      expect(data).toBeDefined();
      expect(data.email).toBe(testUserEmail);
    });

    it('ユーザープロファイルが初期化される', async () => {
      const { data, error } = await supabase.from('profiles').select('*').eq('user_id', testUserId).single();

      expect(error).toBeNull();
      expect(data).toBeDefined();
    });
  });

  describe('データ整合性', () => {
    it('外部キー制約が正しく機能する', async () => {
      // 存在しないユーザーIDでの挿入を試みる
      const { error } = await supabase.from('profiles').insert({
        user_id: '00000000-0000-0000-0000-000000000000',
        display_name: 'Test',
      });

      expect(error).toBeDefined();
      expect(error?.code).toBe('23503'); // Foreign key violation
    });

    it('重複メールアドレスは拒否される', async () => {
      const { error } = await supabase.auth.admin.createUser({
        email: testUserEmail, // 既存のメールアドレス
        password: 'AnotherPassword123!',
      });

      expect(error).toBeDefined();
    });
  });

  describe('カスケード削除', () => {
    it('ユーザー削除時に関連データも削除される', async () => {
      // テスト用の一時ユーザーを作成
      const tempEmail = `temp-${Date.now()}@example.com`;
      const { data: tempUser } = await supabase.auth.admin.createUser({
        email: tempEmail,
        password: 'TempPassword123!',
        email_confirm: true,
      });

      const tempUserId = tempUser.user?.id;

      // 関連データを作成
      await supabase.from('profiles').insert({
        user_id: tempUserId,
        display_name: 'Temp User',
      });

      // ユーザーを削除
      await supabase.auth.admin.deleteUser(tempUserId!);

      // プロファイルも削除されていることを確認
      const { data: profile } = await supabase.from('profiles').select('*').eq('user_id', tempUserId).single();

      expect(profile).toBeNull();
    });
  });
});
