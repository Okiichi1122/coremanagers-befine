-- redirect_urls テーブル: clinic-detail?param=KEY → リダイレクト先URL の対応表
-- Supabase SQL Editor で実行する

BEGIN;

CREATE TABLE redirect_urls (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text NOT NULL,
  url text,
  category text NOT NULL,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (key)
);

CREATE INDEX redirect_urls_category_idx ON redirect_urls (category);

ALTER TABLE redirect_urls ENABLE ROW LEVEL SECURITY;

CREATE POLICY "auth_select" ON redirect_urls FOR SELECT
  USING ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');
CREATE POLICY "auth_insert" ON redirect_urls FOR INSERT
  WITH CHECK ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');
CREATE POLICY "auth_update" ON redirect_urls FOR UPDATE
  USING ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com')
  WITH CHECK ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');
CREATE POLICY "auth_delete" ON redirect_urls FOR DELETE
  USING ((auth.jwt() ->> 'email') = 'okisuzuki1122@gmail.com');

COMMIT;
