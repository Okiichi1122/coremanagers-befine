BEGIN;

-- ============================================================
-- 1. アプリ利用者を管理する app_users テーブルを作成
-- ============================================================
CREATE TABLE app_users (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  email text NOT NULL UNIQUE,
  role text NOT NULL DEFAULT 'viewer' CHECK (role IN ('admin', 'viewer')),
  created_by text,
  created_at timestamptz DEFAULT now()
);

-- ============================================================
-- 2. app_users 管理用 RPC 関数
--    SECURITY DEFINER で RLS を回避し、現在ログイン中のメールから権限を確認する
-- ============================================================

-- 自分のアプリ権限を取得する。app_users に存在しない場合は null を返す。
CREATE OR REPLACE FUNCTION get_my_app_role_v2()
RETURNS text
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_role text;
BEGIN
  SELECT role
  INTO v_role
  FROM app_users
  WHERE email = (auth.jwt() ->> 'email')
  LIMIT 1;

  RETURN v_role;
END;
$$;

-- app_users の一覧を取得する。admin 以外は実行不可。
CREATE OR REPLACE FUNCTION list_app_users()
RETURNS SETOF app_users
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  IF get_my_app_role_v2() IS DISTINCT FROM 'admin' THEN
    RAISE EXCEPTION '権限がありません。app_users の一覧取得は admin のみ可能です。';
  END IF;

  RETURN QUERY
  SELECT *
  FROM app_users;
END;
$$;

-- app_users を追加または更新する。p_id がゼロ UUID の場合は追加、それ以外は更新する。
CREATE OR REPLACE FUNCTION upsert_app_user(
  p_id uuid,
  p_email text,
  p_role text,
  p_created_by text
)
RETURNS void
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  IF get_my_app_role_v2() IS DISTINCT FROM 'admin' THEN
    RAISE EXCEPTION '権限がありません。app_users の追加・更新は admin のみ可能です。';
  END IF;

  IF p_id = '00000000-0000-0000-0000-000000000000'::uuid THEN
    INSERT INTO app_users (email, role, created_by)
    VALUES (p_email, p_role, p_created_by);
  ELSE
    UPDATE app_users
    SET
      email = p_email,
      role = p_role,
      created_by = p_created_by
    WHERE id = p_id;
  END IF;
END;
$$;

-- app_users から利用者を削除する。admin 以外は実行不可。
CREATE OR REPLACE FUNCTION delete_app_user(p_id uuid)
RETURNS void
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  IF get_my_app_role_v2() IS DISTINCT FROM 'admin' THEN
    RAISE EXCEPTION '権限がありません。app_users の削除は admin のみ可能です。';
  END IF;

  DELETE FROM app_users
  WHERE id = p_id;
END;
$$;

-- ============================================================
-- 3. app_users の RLS を有効化し、admin のみ操作できるようにする
-- ============================================================
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "app_users_admin_select" ON app_users
  FOR SELECT
  USING (get_my_app_role_v2() = 'admin');

CREATE POLICY "app_users_admin_insert" ON app_users
  FOR INSERT
  WITH CHECK (get_my_app_role_v2() = 'admin');

CREATE POLICY "app_users_admin_update" ON app_users
  FOR UPDATE
  USING (get_my_app_role_v2() = 'admin')
  WITH CHECK (get_my_app_role_v2() = 'admin');

CREATE POLICY "app_users_admin_delete" ON app_users
  FOR DELETE
  USING (get_my_app_role_v2() = 'admin');

-- ============================================================
-- 4. 既存テーブルの RLS ポリシーを、固定メール判定から app_users 参照へ差し替え
-- ============================================================

-- articles
DROP POLICY IF EXISTS "auth_select" ON articles;
DROP POLICY IF EXISTS "auth_insert" ON articles;
DROP POLICY IF EXISTS "auth_update" ON articles;
DROP POLICY IF EXISTS "auth_delete" ON articles;
DROP POLICY IF EXISTS "auth_all" ON articles;

CREATE POLICY "app_users_select" ON articles
  FOR SELECT
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_insert" ON articles
  FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_update" ON articles
  FOR UPDATE
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')))
  WITH CHECK (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_delete" ON articles
  FOR DELETE
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

-- orders
DROP POLICY IF EXISTS "auth_select" ON orders;
DROP POLICY IF EXISTS "auth_insert" ON orders;
DROP POLICY IF EXISTS "auth_update" ON orders;
DROP POLICY IF EXISTS "auth_delete" ON orders;
DROP POLICY IF EXISTS "auth_all" ON orders;

CREATE POLICY "app_users_select" ON orders
  FOR SELECT
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_insert" ON orders
  FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_update" ON orders
  FOR UPDATE
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')))
  WITH CHECK (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_delete" ON orders
  FOR DELETE
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

-- workers
DROP POLICY IF EXISTS "auth_select" ON workers;
DROP POLICY IF EXISTS "auth_insert" ON workers;
DROP POLICY IF EXISTS "auth_update" ON workers;
DROP POLICY IF EXISTS "auth_delete" ON workers;
DROP POLICY IF EXISTS "auth_all" ON workers;

CREATE POLICY "app_users_select" ON workers
  FOR SELECT
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_insert" ON workers
  FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_update" ON workers
  FOR UPDATE
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')))
  WITH CHECK (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_delete" ON workers
  FOR DELETE
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

-- master_categories
DROP POLICY IF EXISTS "auth_select" ON master_categories;
DROP POLICY IF EXISTS "auth_insert" ON master_categories;
DROP POLICY IF EXISTS "auth_update" ON master_categories;
DROP POLICY IF EXISTS "auth_delete" ON master_categories;
DROP POLICY IF EXISTS "auth_all" ON master_categories;

CREATE POLICY "app_users_select" ON master_categories
  FOR SELECT
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_insert" ON master_categories
  FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_update" ON master_categories
  FOR UPDATE
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')))
  WITH CHECK (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_delete" ON master_categories
  FOR DELETE
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

-- master_article_categories
DROP POLICY IF EXISTS "auth_select" ON master_article_categories;
DROP POLICY IF EXISTS "auth_insert" ON master_article_categories;
DROP POLICY IF EXISTS "auth_update" ON master_article_categories;
DROP POLICY IF EXISTS "auth_delete" ON master_article_categories;
DROP POLICY IF EXISTS "auth_all" ON master_article_categories;

CREATE POLICY "app_users_select" ON master_article_categories
  FOR SELECT
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_insert" ON master_article_categories
  FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_update" ON master_article_categories
  FOR UPDATE
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')))
  WITH CHECK (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_delete" ON master_article_categories
  FOR DELETE
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

-- master_clients
DROP POLICY IF EXISTS "auth_select" ON master_clients;
DROP POLICY IF EXISTS "auth_insert" ON master_clients;
DROP POLICY IF EXISTS "auth_update" ON master_clients;
DROP POLICY IF EXISTS "auth_delete" ON master_clients;
DROP POLICY IF EXISTS "auth_all" ON master_clients;

CREATE POLICY "app_users_select" ON master_clients
  FOR SELECT
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_insert" ON master_clients
  FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_update" ON master_clients
  FOR UPDATE
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')))
  WITH CHECK (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_delete" ON master_clients
  FOR DELETE
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

-- master_directories
DROP POLICY IF EXISTS "auth_select" ON master_directories;
DROP POLICY IF EXISTS "auth_insert" ON master_directories;
DROP POLICY IF EXISTS "auth_update" ON master_directories;
DROP POLICY IF EXISTS "auth_delete" ON master_directories;
DROP POLICY IF EXISTS "auth_all" ON master_directories;

CREATE POLICY "app_users_select" ON master_directories
  FOR SELECT
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_insert" ON master_directories
  FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_update" ON master_directories
  FOR UPDATE
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')))
  WITH CHECK (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_delete" ON master_directories
  FOR DELETE
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

-- clinic_snapshots
DROP POLICY IF EXISTS "auth_select" ON clinic_snapshots;
DROP POLICY IF EXISTS "auth_insert" ON clinic_snapshots;
DROP POLICY IF EXISTS "auth_update" ON clinic_snapshots;
DROP POLICY IF EXISTS "auth_delete" ON clinic_snapshots;
DROP POLICY IF EXISTS "auth_all" ON clinic_snapshots;

CREATE POLICY "app_users_select" ON clinic_snapshots
  FOR SELECT
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_insert" ON clinic_snapshots
  FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_update" ON clinic_snapshots
  FOR UPDATE
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')))
  WITH CHECK (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_delete" ON clinic_snapshots
  FOR DELETE
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

-- clinic_changes
DROP POLICY IF EXISTS "auth_select" ON clinic_changes;
DROP POLICY IF EXISTS "auth_insert" ON clinic_changes;
DROP POLICY IF EXISTS "auth_update" ON clinic_changes;
DROP POLICY IF EXISTS "auth_delete" ON clinic_changes;
DROP POLICY IF EXISTS "auth_all" ON clinic_changes;

CREATE POLICY "app_users_select" ON clinic_changes
  FOR SELECT
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_insert" ON clinic_changes
  FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_update" ON clinic_changes
  FOR UPDATE
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')))
  WITH CHECK (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_delete" ON clinic_changes
  FOR DELETE
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

-- article_audits
DROP POLICY IF EXISTS "auth_select" ON article_audits;
DROP POLICY IF EXISTS "auth_insert" ON article_audits;
DROP POLICY IF EXISTS "auth_update" ON article_audits;
DROP POLICY IF EXISTS "auth_delete" ON article_audits;
DROP POLICY IF EXISTS "auth_all" ON article_audits;

CREATE POLICY "app_users_select" ON article_audits
  FOR SELECT
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_insert" ON article_audits
  FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_update" ON article_audits
  FOR UPDATE
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')))
  WITH CHECK (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

CREATE POLICY "app_users_delete" ON article_audits
  FOR DELETE
  USING (EXISTS (SELECT 1 FROM app_users WHERE email = (auth.jwt() ->> 'email')));

-- ============================================================
-- 5. 初期 admin ユーザーを登録
-- ============================================================
INSERT INTO app_users (email, role, created_by) VALUES
  ('okisuzuki1122@gmail.com', 'admin', 'system'),
  ('kzt.set01@gmail.com', 'admin', 'system');

COMMIT;
