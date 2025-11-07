# データベース設計方針書

## 概要

このドキュメントは、ER 図（[er-diagram.puml](./er-diagram.puml)）と現在のデータベーススキーマを分析し、段階的なテーブル拡張の設計方針をまとめたものです。

## 現状分析

### 既存スキーマ（MySQL 8.0）

| テーブル名    | 主な用途       | 主キー型 | 備考                     |
| ------------- | -------------- | -------- | ------------------------ |
| users         | ユーザー管理   | bigint   | Devise + OAuth 対応済み  |
| tracks        | 楽曲情報       | bigint   | YouTube URL、AI 解析結果 |
| jobs          | 制作依頼       | bigint   | commissions から改名済み |
| messages      | メッセージング | bigint   | job_id 依存              |
| jwt_denylists | JWT 管理       | bigint   | 認証トークン管理         |

### ER 図が示す理想形（PostgreSQL 前提）

- **ID 型**: UUID 主キー
- **PostgreSQL 固有型**: citext, timestamptz
- **enum 型**: ネイティブサポート
- **テーブル数**: 20 以上（完全実装時）

### 技術的ギャップ

| 項目        | ER 図      | 現状      | 対応方針                          |
| ----------- | ---------- | --------- | --------------------------------- |
| 主キー      | UUID       | bigint    | **bigint 継続**（移行コスト考慮） |
| DB          | PostgreSQL | MySQL 8.0 | **MySQL 継続**（Phase 3 まで）    |
| citext      | あり       | なし      | COLLATION 設定で代替              |
| timestamptz | あり       | datetime  | アプリ層で UTC 管理               |
| enum 型     | ネイティブ | なし      | string + Rails enum               |

## 設計判断の根拠

### なぜ MySQL 継続か？

1. **既存コードの安定性**: 既に MySQL 用マイグレーションが動作中
2. **学習コスト**: 新技術習得より実装完了を優先
3. **段階的移行**: Phase 3 完了後に PostgreSQL へ移行可能

### なぜ bigint 継続か？

1. **UUID のデメリット（MySQL）**:
   - インデックスパフォーマンスの低下
   - ストレージ使用量の増加（16 bytes vs 8 bytes）
2. **移行の複雑さ**: 既存テーブルとの関連で外部キー制約の再構築が必要
3. **PostgreSQL 移行時に検討**: DB 移行と同時に UUID 化する方が効率的

## 段階的実装計画

### Phase 1: ユーザープロファイル拡張（優先度：最高）

**目的**: 音楽家とクライアントの役割分離

#### Task 1-1: users テーブル拡張

```ruby
# マイグレーション: AddProfileFieldsToUsers
add_column :users, :display_name, :string
add_column :users, :timezone, :string, default: 'UTC'
add_column :users, :is_musician, :boolean, default: false
add_column :users, :is_client, :boolean, default: false
add_column :users, :deleted_at, :datetime

add_index :users, :deleted_at
```

**バリデーション**:

```ruby
# User model
validates :timezone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }, allow_nil: true
validates :display_name, length: { maximum: 50 }, allow_blank: true
```

**ER 図との差分**:

- `jti`カラムは見送り（jwt_denylists テーブルで管理継続）

#### Task 1-2: musician_profiles テーブル作成

```ruby
# マイグレーション: CreateMusicianProfiles
create_table :musician_profiles do |t|
  t.references :user, null: false, foreign_key: true, type: :bigint, index: { unique: true }
  t.text :headline
  t.text :bio
  t.integer :hourly_rate_jpy
  t.boolean :remote_ok, default: false
  t.boolean :onsite_ok, default: false
  t.string :portfolio_url
  t.decimal :avg_rating, precision: 2, scale: 1, default: 0.0
  t.integer :rating_count, default: 0
  t.timestamps
end
```

**モデル設計**:

```ruby
class MusicianProfile < ApplicationRecord
  belongs_to :user

  validates :hourly_rate_jpy, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :avg_rating, numericality: { in: 0.0..5.0 }
  validates :rating_count, numericality: { greater_than_or_equal_to: 0 }
  validates :portfolio_url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true
  validates :headline, length: { maximum: 100 }, allow_blank: true
end
```

**ER 図との差分**:

- user_id を主キーではなく外部キーとして設計（Rails の慣習）
- timestamps を ER 図の timestamptz 相当として扱う

#### Task 1-3: client_profiles テーブル作成

```ruby
# マイグレーション: CreateClientProfiles
create_table :client_profiles do |t|
  t.references :user, null: false, foreign_key: true, type: :bigint, index: { unique: true }
  t.string :organization
  t.boolean :verified, default: false
  t.timestamps
end
```

**モデル設計**:

```ruby
class ClientProfile < ApplicationRecord
  belongs_to :user

  validates :organization, length: { maximum: 255 }
end
```

**実装手順（各タスク共通）**:

1. マイグレーションファイル作成
2. モデル作成/更新
3. テスト作成（model spec）
4. マイグレーション実行
5. テスト実行（全てグリーン確認）
6. コミット
7. PR 作成 & マージ

---

### Phase 2: タクソノミーシステム（優先度：最高）

**目的**: ジャンル・楽器・スキルの体系的管理

#### Task 2-1: マスターテーブル作成

```ruby
# マイグレーション: CreateTaxonomyTables
create_table :genres do |t|
  t.string :name, null: false
  t.timestamps
end
add_index :genres, :name, unique: true

create_table :instruments do |t|
  t.string :name, null: false
  t.timestamps
end
add_index :instruments, :name, unique: true

create_table :skills do |t|
  t.string :name, null: false
  t.timestamps
end
add_index :skills, :name, unique: true
```

**初期データ**:

```ruby
# db/seeds.rb
['Rock', 'Pop', 'Jazz', 'Classical', 'Electronic', 'Hip Hop', 'R&B', 'Country', 'Blues', 'Metal'].each do |name|
  Genre.find_or_create_by!(name: name)
end

['Piano', 'Guitar', 'Bass', 'Drums', 'Violin', 'Saxophone', 'Vocals', 'Synthesizer', 'Trumpet', 'Cello'].each do |name|
  Instrument.find_or_create_by!(name: name)
end

['Composition', 'Arrangement', 'Mixing', 'Mastering', 'Recording', 'Production', 'Sound Design', 'Orchestration'].each do |name|
  Skill.find_or_create_by!(name: name)
end
```

**ER 図との差分**:

- ER 図では serial（PostgreSQL）、MySQL では bigint auto_increment

#### Task 2-2: 中間テーブル作成（多対多関連）

```ruby
# マイグレーション: CreateMusicianTaxonomyJoinTables
create_table :musician_genres do |t|
  t.references :user, null: false, foreign_key: true, type: :bigint
  t.references :genre, null: false, foreign_key: true, type: :bigint
end
add_index :musician_genres, [:user_id, :genre_id], unique: true

create_table :musician_instruments do |t|
  t.references :user, null: false, foreign_key: true, type: :bigint
  t.references :instrument, null: false, foreign_key: true, type: :bigint
end
add_index :musician_instruments, [:user_id, :instrument_id], unique: true

create_table :musician_skills do |t|
  t.references :user, null: false, foreign_key: true, type: :bigint
  t.references :skill, null: false, foreign_key: true, type: :bigint
end
add_index :musician_skills, [:user_id, :skill_id], unique: true
```

**モデル関連付け**:

```ruby
# app/models/user.rb
has_many :musician_genres, dependent: :destroy
has_many :genres, through: :musician_genres

has_many :musician_instruments, dependent: :destroy
has_many :instruments, through: :musician_instruments

has_many :musician_skills, dependent: :destroy
has_many :skills, through: :musician_skills

# app/models/genre.rb (Instrument, Skillも同様)
has_many :musician_genres, dependent: :destroy
has_many :users, through: :musician_genres
```

**ER 図との差分**:

- ER 図では複合主キー、Rails では自動 ID+複合ユニークインデックス

---

### Phase 3: jobs テーブル拡張（優先度：高）

**目的**: 案件管理システムの完成

#### Task 3-1: jobs テーブル拡張

```ruby
# マイグレーション: ExpandJobsTable
add_column :jobs, :title, :string
add_column :jobs, :budget_min_jpy, :integer
add_column :jobs, :budget_max_jpy, :integer
add_column :jobs, :delivery_due_on, :date
add_column :jobs, :is_remote, :boolean, default: true
add_column :jobs, :location_note, :text
add_column :jobs, :published_at, :datetime

# track_id を optional に変更
change_column_null :jobs, :track_id, true

# budget → budget_jpy へリネーム
rename_column :jobs, :budget, :budget_jpy

# user_id → client_id へリネーム（ER図に合わせる）
rename_column :jobs, :user_id, :client_id

# statusにデフォルト値設定
change_column_default :jobs, :status, from: nil, to: 'draft'

# インデックス追加
add_index :jobs, :status
add_index :jobs, :published_at
```

**モデル更新**:

```ruby
class Job < ApplicationRecord
  belongs_to :client, class_name: 'User', foreign_key: 'client_id'
  belongs_to :track, optional: true

  enum status: {
    draft: 'draft',
    published: 'published',
    in_review: 'in_review',
    contracted: 'contracted',
    completed: 'completed',
    closed: 'closed'
  }

  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true
  validates :budget_min_jpy, numericality: { greater_than: 0 }, allow_nil: true
  validates :budget_max_jpy, numericality: { greater_than: 0 }, allow_nil: true
  validate :budget_max_greater_than_min

  scope :published, -> { where(status: 'published').where.not(published_at: nil) }

  private

  def budget_max_greater_than_min
    return unless budget_min_jpy && budget_max_jpy
    errors.add(:budget_max_jpy, 'must be greater than or equal to minimum') if budget_max_jpy < budget_min_jpy
  end
end
```

**既存データの移行**:

```ruby
# マイグレーション内で既存レコードを更新
reversible do |dir|
  dir.up do
    Job.where(title: nil).update_all(title: 'Untitled Job')
  end
end
```

**ER 図との差分**:

- client カラム名を client_id に変更（Rails 慣習）

#### Task 3-2: job_requirements テーブル作成

```ruby
# マイグレーション: CreateJobRequirements
create_table :job_requirements do |t|
  t.references :job, null: false, foreign_key: true, type: :bigint
  t.string :kind, null: false
  t.bigint :ref_id, null: false
  t.timestamps
end

add_index :job_requirements, [:job_id, :kind, :ref_id], unique: true, name: 'index_job_requirements_unique'
```

**モデル設計**:

```ruby
class JobRequirement < ApplicationRecord
  belongs_to :job

  enum kind: {
    genre: 'genre',
    instrument: 'instrument',
    skill: 'skill'
  }

  validates :kind, presence: true
  validates :ref_id, presence: true
  validate :ref_id_exists

  # ヘルパーメソッド
  def reference_object
    case kind
    when 'genre'
      Genre.find_by(id: ref_id)
    when 'instrument'
      Instrument.find_by(id: ref_id)
    when 'skill'
      Skill.find_by(id: ref_id)
    end
  end

  def reference_name
    reference_object&.name
  end

  private

  def ref_id_exists
    return if reference_object.present?
    errors.add(:ref_id, "#{kind} with id #{ref_id} does not exist")
  end
end

# app/models/job.rb に追加
has_many :job_requirements, dependent: :destroy
```

**ER 図との差分**:

- ER 図では`ref_id`に対する外部キー制約なし（ポリモーフィック的な設計のため）
- バリデーションで整合性を保証

---

## 将来の拡張計画（Phase 4 以降）

### Phase 4: 提案・契約システム（優先度：中）

- proposals テーブル（音楽家が案件に提案）
- contracts テーブル（提案が受諾されたら契約）
- contract_milestones テーブル（マイルストーン管理）

**実装時の注意**:

- この段階で UUID 主キー導入を検討
- PostgreSQL 移行も検討（UUID, enum 型のネイティブサポート）

### Phase 5: メッセージング拡張（優先度：低）

- threads テーブル（スレッド管理）
- thread_participants テーブル（参加者管理）
- messages テーブルの移行（job_id → thread_id）

### Phase 6: レビュー・決済システム（優先度：中〜低）

- reviews テーブル（評価システム）
- transactions テーブル（決済・エスクロー）

---

## PostgreSQL 移行計画（オプション）

### 移行タイミング

**推奨**: Phase 3 完了後、Phase 4 開始前

### 移行理由

1. **UUID 主キー**: セキュリティ向上、分散システム対応
2. **enum 型**: データ整合性の向上
3. **citext 型**: 大文字小文字を区別しないメールアドレス検索
4. **timestamptz**: タイムゾーン情報の正確な管理

### 移行手順

```bash
# 1. Gemfileの変更
bundle remove mysql2
bundle add pg

# 2. database.ymlの変更
# development:
#   adapter: postgresql
#   encoding: unicode
#   pool: 5

# 3. データダンプ
mysqldump -u root music_portfolio_ai_development > dump.sql

# 4. PostgreSQLへインポート（スキーマ変換含む）
# 5. マイグレーションの調整
# 6. テスト実行
```

---

## テスト戦略

### Phase 1〜3 で実装するテスト

1. **Model specs**:

   - バリデーションテスト
   - 関連付けテスト
   - スコープテスト

2. **Request specs（Phase 3 以降）**:

   - API エンドポイントのテスト
   - 認証・認可のテスト

3. **Factory 定義**:
   - FactoryBot でテストデータ生成

### テストカバレッジ目標

- Model: 90%以上
- Controller/Request: 80%以上

---

## 開発フロー（CLAUDE.md 準拠）

### 基本原則

**「未知の作業を複数同時にやらないこと」**

### 各タスクの実装手順

1. マイグレーションファイル作成
2. モデル作成/更新
3. テスト作成
4. マイグレーション実行
5. テスト実行（全てグリーン確認）
6. コミット
7. PR 作成
8. CI 実行
9. マージ

### 1 タスク = 1PR

- Phase 1-1 → PR#1
- Phase 1-2 → PR#2
- Phase 1-3 → PR#3
- ...

---

## まとめ

### ER 図との整合性

| 項目         | ER 図      | 実装                                           | 理由       |
| ------------ | ---------- | ---------------------------------------------- | ---------- |
| 主キー型     | UUID       | bigint（Phase 1-3）→ UUID（Phase 4 以降）      | 段階的移行 |
| DB           | PostgreSQL | MySQL（Phase 1-3）→ PostgreSQL（Phase 4 以降） | リスク分散 |
| enum 型      | ネイティブ | Rails enum                                     | MySQL 制約 |
| テーブル構造 | ER 図通り  | ER 図通り                                      | 設計踏襲   |

### 実装優先度

1. **Phase 1（最高）**: ユーザープロファイル → 設計力アピール
2. **Phase 2（最高）**: タクソノミー → 多対多関連アピール
3. **Phase 3（高）**: jobs 拡張 → 実務的な機能
4. **PostgreSQL 移行（中）**: Phase 3 完了後に検討
5. **Phase 4 以降（中〜低）**: 時間に応じて実装

### 所要時間見積もり

- Phase 1: 2-3 時間
- Phase 2: 2-3 時間
- Phase 3: 2-3 時間
- **合計**: 6-9 時間（最小 MVP）

---

## 実装進捗

### ✅ Phase 1: ユーザープロファイル拡張（完了）

**ブランチ**: `feature/user-profiles`
**実装日**: 2025-11-06

#### ✅ Task 1-1: users テーブル拡張（完了）

- **コミット**: `7e26bd6` - feat(users): add display_name, timezone, role flags to users table
- **マイグレーション**: `20251106030011_add_profile_fields_to_users.rb`
- **実装内容**:
  - display_name, timezone, is_musician, is_client, deleted_at カラム追加
  - deleted_at インデックス追加
  - バリデーション実装（timezone, display_name）
  - スコープ実装（active, musicians, clients）
  - ソフトデリート機能実装
- **テスト**: 21 examples, 0 failures

#### ✅ Task 1-2: musician_profiles テーブル作成（完了）

- **コミット**: `d3d15cd` - feat(musician_profiles): create musician_profiles table
- **マイグレーション**: `20251106030207_create_musician_profiles.rb`
- **実装内容**:
  - musician_profiles テーブル作成
  - user_id に unique インデックス
  - デフォルト値設定（remote_ok=false, onsite_ok=false, avg_rating=0.0, rating_count=0）
  - バリデーション実装（hourly_rate_jpy, avg_rating, rating_count, portfolio_url, headline）
  - User モデルに has_one :musician_profile 関連追加
- **テスト**: 23 examples, 0 failures

#### ✅ Task 1-3: client_profiles テーブル作成（完了）

- **コミット**: `26f74bd` - feat(client_profiles): create client_profiles table
- **マイグレーション**: `20251106030620_create_client_profiles.rb`
- **実装内容**:
  - client_profiles テーブル作成
  - user_id に unique インデックス
  - デフォルト値設定（verified=false）
  - バリデーション実装（organization）
  - User モデルに has_one :client_profile 関連追加
- **テスト**: 6 examples, 0 failures

### ✅ Phase 2: タクソノミーシステム（完了）

**ブランチ**: `feature/taxonomy-system`
**実装日**: 2025-11-07

#### ✅ Task 2-1: マスターテーブル作成（完了）

- **コミット**: `31815f9` - feat(taxonomy): create taxonomy master tables (genres, instruments, skills)
- **マイグレーション**: `20251107102634_create_taxonomy_tables.rb`
- **実装内容**:
  - genres テーブル作成（name カラムに unique インデックス）
  - instruments テーブル作成（name カラムに unique インデックス）
  - skills テーブル作成（name カラムに unique インデックス）
  - 各モデルに uniqueness バリデーション実装
  - has_many 関連付け実装
- **テスト**: 15 examples, 0 failures

#### ✅ Task 2-2: 中間テーブル作成（完了）

- **コミット**: `9e48a54` - feat(taxonomy): create join tables for musician taxonomies
- **マイグレーション**: `20251107102954_create_musician_taxonomy_join_tables.rb`
- **実装内容**:
  - musician_genres テーブル作成（user_id, genre_id に複合 unique インデックス）
  - musician_instruments テーブル作成（user_id, instrument_id に複合 unique インデックス）
  - musician_skills テーブル作成（user_id, skill_id に複合 unique インデックス）
  - 各中間モデルに uniqueness バリデーション実装
  - User モデルに through 関連付け追加（genres, instruments, skills）
- **テスト**: 109 examples, 0 failures

#### ✅ シードデータ追加（完了）

- **コミット**: `4c18d47` - feat(taxonomy): add seed data for genres, instruments, and skills
- **実装内容**:
  - 10ジャンル登録（Rock, Pop, Jazz, Classical, Electronic, Hip Hop, R&B, Country, Blues, Metal）
  - 10楽器登録（Piano, Guitar, Bass, Drums, Violin, Saxophone, Vocals, Synthesizer, Trumpet, Cello）
  - 8スキル登録（Composition, Arrangement, Mixing, Mastering, Recording, Production, Sound Design, Orchestration）
  - テストを既存シードデータと共存するように更新
- **テスト**: 109 examples, 0 failures

### ✅ Phase 3: jobs テーブル拡張（完了）

**ブランチ**: `feature/jobs-expansion`
**PR**: (作成予定)

#### ✅ Task 3-1: jobs テーブル拡張（完了）

- **コミット**: `339ccf3` - feat(jobs): Task 3-1 - expand jobs table and update model (Phase 3)
- **マイグレーション**: `20251107113000_expand_jobs_table.rb`
- **実装内容**:
  - 新規カラム追加:
    - `title`: string（案件タイトル、必須、最大255文字）
    - `budget_min_jpy`: integer（予算下限、正の整数、nullable）
    - `budget_max_jpy`: integer（予算上限、正の整数、nullable、下限以上であること）
    - `delivery_due_on`: date（納期）
    - `is_remote`: boolean（リモート可否、デフォルト true）
    - `location_note`: text（場所に関するメモ）
    - `published_at`: datetime（公開日時、index 追加）
  - カラム名変更:
    - `user_id` → `client_id`（依頼者を明示）
    - `budget` → `budget_jpy`（通貨を明示）
  - track_id を optional に変更
  - status に index 追加、デフォルト値 'draft' 設定
  - Job モデル更新:
    - enum status に 6 つのステータス追加（draft, published, in_review, contracted, completed, closed）
    - belongs_to :client 関連付け（User モデルへの参照）
    - belongs_to :track, optional: true
    - has_many :messages, dependent: :destroy
    - has_many :job_requirements, dependent: :destroy
    - バリデーション追加（title, description, budget 各種、budget_max >= budget_min）
    - scope :published 追加
  - User モデル更新:
    - has_many :jobs, foreign_key: 'client_id' に変更
  - 既存データ移行: title が nil のレコードに 'Untitled Job' を設定
- **テスト**: job_spec.rb 更新（21 examples for Job model validations, enums, associations, scopes, defaults）

#### ✅ Task 3-2: job_requirements テーブル作成（完了）

- **コミット**: `c87144e` - feat(jobs): Task 3-2 - add job_requirements table and model (Phase 3)
- **マイグレーション**: `20251107113100_create_job_requirements.rb`
- **実装内容**:
  - job_requirements テーブル作成:
    - `job_id`: bigint（外部キー、NOT NULL）
    - `kind`: string（'genre', 'instrument', 'skill' のいずれか、NOT NULL）
    - `ref_id`: bigint（参照先 ID、NOT NULL）
    - 複合 unique インデックス: (job_id, kind, ref_id)
  - JobRequirement モデル実装:
    - belongs_to :job
    - enum kind（genre, instrument, skill）
    - バリデーション（kind, ref_id の存在、ref_id の参照先存在チェック）
    - ヘルパーメソッド: reference_object, reference_name
  - Job モデルに has_many :job_requirements 追加
- **テスト**: job_requirement_spec.rb 作成（20+ examples covering associations, validations, enums, helper methods, uniqueness）

---

### ✅ PostgreSQL 移行（完了）

**ブランチ**: `feature/postgresql-migration`
**PR**: (作成予定)
**実施日**: 2025-11-07

#### 移行内容

- **Gemfile**: mysql2 gem を pg gem に置換
- **database.yml**: PostgreSQL adapter に変更（ポート 3306 → 5432）
- **GitHub Actions**: MySQL サービスを PostgreSQL に変更（postgres:15 イメージ使用）

#### 移行の利点

1. **データ整合性の向上**: PostgreSQL のより厳格な型システム
2. **将来の拡張性**: UUID 主キー、enum 型、citext 型などのサポート
3. **本番環境での一般的な選択**: スケーラビリティと信頼性
4. **既存マイグレーションの互換性**: 全マイグレーションがデータベース非依存で記述されているため、再実行のみで移行完了

#### 注意事項

- 既存のマイグレーションファイルは変更不要（Rails の抽象化により互換性あり）
- データベース作成と既存マイグレーションの再実行のみで移行完了
- 開発環境・CI環境ともに PostgreSQL 15 を使用

---

最終更新: 2025-11-07
