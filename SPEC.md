# BeFine Article Manager 仕様書

## 概要
- **URL**: https://befine.coremanagers.com/
- **構成**: 単一HTMLファイル（index.html, 4605行）+ Supabase（PostgreSQL + Auth）
- **認証**: Google OAuth（Supabase Auth経由）、**okisuzuki1122@gmail.com のみ許可**
- **デプロイ**: mainにpush → GitHub Actions → VPS自動反映
- **Supabase Project**: hwfbpissyywzqbdthpek
- **GitHub**: Okiichi1122/coremanagers-befine
- **ローカル**: ~/projects/befine-app/

---

## 画面構成（6タブ SPA）

### 1. 記事管理タブ
- KPIカード: 全記事数 / 公開中 / 執筆中 / 下書き数 / 今日更新数
- マスタ管理（折りたたみ）: 施術ジャンル / クライアント / 記事カテゴリ
- フィルター: 検索 / ステータス / ジャンル / リリース / 記事カテゴリ
- ページネーション: 1000件/ページ
- ヘッダークリックソート（ID/タイトル/ジャンル/カテゴリ/KW/ステータス/リリース/リリース日/No.1クライアント/合計金額）
- 記事一覧テーブル（横スクロール、ID+タイトル左固定、全フィールド表示、インラインセル編集）
- CSVエクスポート / 複数記事削除
- 新規記事モーダル / 編集モーダル / カテゴリピッカーモーダル

### 2. 発注管理タブ
- KPIカード: 今月の発注合計 / 先月の発注合計 / 未支払い額
- 発注フィルター: 月 / ライター / ステータス
- 新規発注モーダル（記事検索付き、検収者は部門連動、進捗は検収者名入り動的生成）
- 発注一覧テーブル
- ワーカー別月次発注額テーブル
- 月次CSVエクスポート

### 3. リライト管理タブ
- リライトステータスフィルター
- リライト中の記事一覧
- リライト工程の担当者 / 納期 / 進捗を表示

### 4. 工程別ビュータブ
- 工程フィルター（イントロ/画像/調査/紹介文/画像挿入）
- 進捗フィルター
- 該当工程の発注一覧

### 5. ライター管理タブ
- デフォルト「有効」フィルタ（契約終了者は非表示）
- ライター一覧テーブル（職種複数表示、検収者マーク、メール、Chatworkリンク、累計金額）
- フィルター: 職種 / ステータス(有効/契約終了) / 名前検索
- 複数職種チェックボックス / 検収者ON/OFF
- CSVインポート/エクスポート

### 6. 情報監査タブ
- `article_audits` の監査結果を一覧表示
- KPIカード: 全件 / 最高 / 高 / 未対応
- フィルター: 優先度 / ステータス / 種別 / 検索
- 詳細モーダル: 記事URL / 根拠URL / 記事内情報 / 最新情報 / 修正案 / 対応内容
- ステータス更新: 未対応 / 対応中 / 完了 / 無視
- 対応分類: 未判断 / 記事修正 / 指摘誤り / 対応不要 / 保留

---

## インラインセル編集

| フィールド | 編集方法 |
|---|---|
| 施術ジャンル | selectプルダウン（master_categories） |
| 記事カテゴリ | モーダルでチェックボックス複数選択（色バッジ、2つまで表示+N） |
| No.1クライアント | selectプルダウン（master_clients、色バッジ） |
| ステータス/リリース/季節訴求/アンケート | selectプルダウン |
| リリース日 | 日付ピッカー |
| テキスト系（KW/タイトル/URL/下書きURL/禁止KW等） | テキスト入力 |
| 工程 納品日 | datetime-local |
| 工程 担当者/納期/進捗 | 読み取り専用（発注管理から変更） |

---

## DBスキーマ

### articles テーブル（記事ID = CSVタスクID）
| カラム | 型 | 説明 |
|---|---|---|
| id | bigint | PK（CSVのタスクIDと一致） |
| title | text | 記事タイトル |
| url | text | 記事URL |
| draft_url | text | 下書きURL |
| keyword | text | 対策キーワード |
| genre | text | 施術ジャンル（単一） |
| category | text | 記事カテゴリ（カンマ区切り複数可） |
| status | text | 公開中/執筆中/下書き/公開停止中/作成中止 |
| no1_client | text | No.1クライアント名 |
| release_date | date | リリース日 |
| release_status | text | 記事完了待ち/リリース可能/リリース済/リライト中/保留 |
| skip_workflows | text | 不要工程（カンマ区切り） |
| seasonal_appeal | text | 季節訴求: あり/なし |
| banned_keywords | text | 禁止キーワード |
| survey_status | text | アンケート準備: 未完了/完了/不要 |
| survey_url | text | アンケートURL |
| figma_url | text | FIGMA URL |
| image_folder_url | text | 画像フォルダURL |
| urgent_notice | text | 緊急伝達事項 |
| regulation | text | レギュレーション |
| pre_report_url | text | 事前報告シートURL |
| notes | text | メモ/備考 |
| meta_description | text | メタディスクリプション |
| movie | text | 動画解説 |
| blog_parts | text | ブログパーツ |
| picture_request | text | 画像発注可否 |
| designer_release | text | 画像進捗（リリース） |
| old_draft_url | text | 旧下書きURL |
| rewrite_status | text | リライトステータス |
| rewrite_deadline | timestamptz | リライト納期 |
| rewrite_review | text | リライト検収状況 |

### orders テーブル
| カラム | 型 | 説明 |
|---|---|---|
| id | uuid | PK |
| article_id | bigint | FK → articles.id |
| worker_id | uuid | FK → workers.id（検収タスクの場合は検収者） |
| department | text | 部門コード |
| order_type | text | 発注種類（イントロ執筆/画像デザイン/医院情報収集/医院紹介文/リライト/その他） |
| task_category | text | タスク種別: 作成依頼 / 検収（排他） |
| parent_order_id | uuid | FK → orders.id（検収タスクが対象とする作成依頼。リライト検収時に使用） |
| amount | integer | 金額（円） |
| ordered_at | timestamptz | 発注日 |
| deadline | timestamptz | 納期 |
| delivered_at | date | 納品日 |
| paid_at | date | 支払日 |
| status | text | 発注済み/納品済み/支払済み |
| progress | text | 依頼中/完成（検収依頼中）/修正依頼中/〇〇検収完了 |
| notes | text | メモ/備考 |

### workers テーブル
| カラム | 型 | 説明 |
|---|---|---|
| id | uuid | PK |
| name | text | ワーカー名 |
| role | text | 職種（カンマ区切り複数可） |
| is_reviewer | boolean | 検収者 |
| active | boolean | 有効/契約終了 |
| chatwork_link | text | Chatworkリンク |
| notes | text | メモ/備考 |

### マスタテーブル
- **master_categories**: 施術ジャンル
- **master_article_categories**: 記事カテゴリ（色バッジ付き）
- **master_clients**: No.1クライアント（色バッジ付き）

### 情報監査テーブル
- **clinic_snapshots**: 公式サイトから取得したクリニック別・カテゴリ別のスナップショット
- **clinic_changes**: 前回スナップショットとの差分
- **article_audits**: 記事内情報と公式情報の不一致・修正案・対応ステータス・対応結果・ナレッジ用テキスト

---

## ワーカーロール

| role値 | 表示名 |
|---|---|
| intro_writer | イントロライター |
| designer | 画像デザイナー |
| researcher | 医院情報収集 |
| clinic_writer | 医院紹介文 |
| image_inserter | 画像挿入者 |
| manager | マネージャー（全部門の検収者に自動表示） |
| reviewer | 検収者 |

- 複数職種可（カンマ区切り）
- 契約終了者: active=false、発注フォーム/検収者select/進捗selectに出ない
- 検収者: `is_reviewer=true` + roleの部門一致で該当部門に表示

---

## リリースステータス自動計算

| 条件 | ステータス |
|---|---|
| 手動セット（保留/リリース済/リライト中） | 維持 |
| skip_workflows除く全発注が納品済み/支払済み | リリース可能 |
| 未完了発注あり | 記事完了待ち |

## 進捗選択肢（部門別動的生成）
- 固定: 依頼中 / 完成（検収依頼中）/ 修正依頼中
- 部門固有: 画像URL発行待ち（designer）
- 動的: `[検収者名]検収完了`（部門のis_reviewer=trueワーカー）

---

## データ規模
- 記事: 未確認（Supabase本番データ未取得）
- 発注: 未確認（Supabase本番データ未取得）
- ワーカー: 未確認（Supabase本番データ未取得）

## 日時フォーマット
- 納期/納品日: `YYYY/MM/DD HH:mm`

## デプロイ
- **GitHub**: Okiichi1122/coremanagers-befine
- **自動デプロイ**: mainにpush → GitHub Actions → VPS
- **VPS**: 148.230.102.162 → `/var/www/befine/index.html`
- **deploy.yml**: `burnett01/rsync-deployments@7.0.1` で `/var/www/befine/` に rsync 配置（`--delete --exclude='.git' --exclude='.github'`）
