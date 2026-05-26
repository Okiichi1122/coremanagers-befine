-- BeFine Article Manager: 初期セットアップ SQL
-- Supabase SQL Editor で実行する

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
-- マスタテーブル
-- ============================================================

CREATE TABLE master_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE master_article_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  color text NOT NULL DEFAULT '#6b7280',
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE master_clients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  color text NOT NULL DEFAULT '#6b7280',
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- articles テーブル
-- ============================================================

CREATE TABLE articles (
  id bigint PRIMARY KEY,
  title text,
  url text,
  draft_url text,
  keyword text,
  genre text,
  category text,
  status text DEFAULT '執筆中',
  no1_client text,
  release_date date,
  release_status text DEFAULT '記事完了待ち',
  skip_workflows text,
  seasonal_appeal text,
  banned_keywords text,
  survey_status text DEFAULT '未完了',
  survey_url text,
  figma_url text,
  image_folder_url text,
  urgent_notice text,
  regulation text,
  pre_report_url text,
  notes text,
  meta_description text,
  movie text,
  blog_parts text,
  picture_request text,
  designer_release text,
  old_draft_url text,
  rewrite_status text,
  rewrite_deadline timestamptz,
  rewrite_review text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- workers テーブル
-- ============================================================

CREATE TABLE workers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  role text,
  is_reviewer boolean NOT NULL DEFAULT false,
  active boolean NOT NULL DEFAULT true,
  chatwork_link text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- orders テーブル
-- ============================================================

CREATE TABLE orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id bigint REFERENCES articles(id),
  worker_id uuid REFERENCES workers(id),
  department text,
  order_type text,
  task_category text NOT NULL DEFAULT '作成依頼'
    CHECK (task_category IN ('作成依頼', '検収')),
  parent_order_id uuid REFERENCES orders(id),
  amount integer DEFAULT 0,
  ordered_at timestamptz DEFAULT now(),
  deadline timestamptz,
  delivered_at date,
  paid_at date,
  status text DEFAULT '発注済み',
  progress text DEFAULT '依頼中',
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- 情報監査テーブル
-- ============================================================

CREATE TABLE clinic_snapshots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_name text NOT NULL,
  category text NOT NULL,
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  source_url text,
  snapshot_date date NOT NULL DEFAULT current_date,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE clinic_changes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_name text NOT NULL,
  category text NOT NULL,
  change_type text NOT NULL CHECK (change_type IN ('added', 'removed', 'modified')),
  old_value text,
  new_value text,
  importance text NOT NULL DEFAULT '中' CHECK (importance IN ('最高', '高', '中', '低')),
  detected_at date NOT NULL DEFAULT current_date,
  acknowledged boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE article_audits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  article_url text,
  article_title text,
  clinic_name text,
  issue_type text NOT NULL,
  priority text NOT NULL DEFAULT '中' CHECK (priority IN ('最高', '高', '中', '低')),
  description text,
  current_in_article text,
  actual_info text,
  source_url text,
  suggested_fix text,
  resolution_type text NOT NULL DEFAULT '未判断'
    CHECK (resolution_type IN ('未判断', '記事修正', '指摘誤り', '対応不要', '保留')),
  resolution_plan text,
  resolution_result text,
  resolution_memo text,
  resolved_at timestamptz,
  resolved_by_email text,
  knowledge_text text,
  knowledge_embedding real[],
  knowledge_embedding_model text,
  status text NOT NULL DEFAULT '未対応' CHECK (status IN ('未対応', '対応中', '完了', '無視')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- インデックス
-- ============================================================

CREATE INDEX clinic_snapshots_lookup_idx
  ON clinic_snapshots (clinic_name, category, snapshot_date DESC);

CREATE INDEX clinic_changes_open_idx
  ON clinic_changes (acknowledged, importance, detected_at DESC);

CREATE INDEX article_audits_status_priority_idx
  ON article_audits (status, priority, created_at DESC);

CREATE INDEX article_audits_resolution_idx
  ON article_audits (resolution_type, status, updated_at DESC);

-- ============================================================
-- RLS（Row Level Security）
-- ============================================================

ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE workers ENABLE ROW LEVEL SECURITY;
ALTER TABLE master_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE master_article_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE master_clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinic_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinic_changes ENABLE ROW LEVEL SECURITY;
ALTER TABLE article_audits ENABLE ROW LEVEL SECURITY;

-- 許可メールアドレス（必要に応じて追加）
-- okisuzuki1122@gmail.com のみ許可

CREATE POLICY "auth_select" ON articles FOR SELECT
  USING ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');
CREATE POLICY "auth_insert" ON articles FOR INSERT
  WITH CHECK ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');
CREATE POLICY "auth_update" ON articles FOR UPDATE
  USING ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com')
  WITH CHECK ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');
CREATE POLICY "auth_delete" ON articles FOR DELETE
  USING ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');

CREATE POLICY "auth_select" ON orders FOR SELECT
  USING ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');
CREATE POLICY "auth_insert" ON orders FOR INSERT
  WITH CHECK ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');
CREATE POLICY "auth_update" ON orders FOR UPDATE
  USING ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com')
  WITH CHECK ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');
CREATE POLICY "auth_delete" ON orders FOR DELETE
  USING ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');

CREATE POLICY "auth_select" ON workers FOR SELECT
  USING ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');
CREATE POLICY "auth_insert" ON workers FOR INSERT
  WITH CHECK ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');
CREATE POLICY "auth_update" ON workers FOR UPDATE
  USING ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com')
  WITH CHECK ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');
CREATE POLICY "auth_delete" ON workers FOR DELETE
  USING ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');

CREATE POLICY "auth_select" ON master_categories FOR SELECT
  USING ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');
CREATE POLICY "auth_all" ON master_categories FOR ALL
  USING ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com')
  WITH CHECK ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');

CREATE POLICY "auth_select" ON master_article_categories FOR SELECT
  USING ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');
CREATE POLICY "auth_all" ON master_article_categories FOR ALL
  USING ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com')
  WITH CHECK ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');

CREATE POLICY "auth_select" ON master_clients FOR SELECT
  USING ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');
CREATE POLICY "auth_all" ON master_clients FOR ALL
  USING ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com')
  WITH CHECK ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');

CREATE POLICY "auth_select" ON clinic_snapshots FOR SELECT
  USING ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');

CREATE POLICY "auth_select" ON clinic_changes FOR SELECT
  USING ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');

CREATE POLICY "auth_select" ON article_audits FOR SELECT
  USING ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');
CREATE POLICY "auth_update" ON article_audits FOR UPDATE
  USING ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com')
  WITH CHECK ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');

COMMIT;
