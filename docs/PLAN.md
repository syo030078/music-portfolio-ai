# データベース設計方針書

## 概要

このドキュメントは、ER 図（[er-diagram.puml](./er-diagram.puml)）と現在のデータベーススキーマを分析し、段階的なテーブル拡張の設計方針をまとめたものです。
**補足**: 現行実装は PostgreSQL + UUID 拡張を採用しています。以下に MySQL 前提の記述がありますが、現時点では歴史的メモとして扱ってください。

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

## Phase 4 以降の実装計画

### Phase 4: 提案・契約システム（優先度：高）

**目的**: 音楽家が案件に提案し、契約・マイルストーン管理を行う基本機能

**実装方針**:

- PostgreSQL 移行完了済みのため、PostgreSQL の機能を活用可能
- UUID 主キーへの移行は Phase 4 完了後に別途実施（Phase 4.5）
- 現状は bigint (serial) 主キーで実装し、動作確認を優先

#### Task 4-1: proposals テーブル作成

**目的**: 音楽家が案件に提案を送信する機能

**テーブル設計**:

```ruby
create_table :proposals do |t|
  t.references :job, null: false, foreign_key: true, type: :bigint
  t.references :musician, null: false, foreign_key: { to_table: :users }, type: :bigint
  t.text :cover_message
  t.integer :quote_total_jpy, null: false
  t.integer :delivery_days, null: false
  t.string :status, null: false, default: 'submitted'
  t.timestamps
end

add_index :proposals, [:job_id, :musician_id], unique: true  # 1案件1音楽家1提案
add_index :proposals, :status
```

**モデル設計**:

```ruby
class Proposal < ApplicationRecord
  belongs_to :job
  belongs_to :musician, class_name: 'User', foreign_key: 'musician_id'
  has_one :contract, dependent: :destroy

  enum status: {
    submitted: 'submitted',      # 提出済み
    shortlisted: 'shortlisted',  # 候補リスト入り
    accepted: 'accepted',        # 受諾済み（契約作成）
    rejected: 'rejected',        # 却下
    withdrawn: 'withdrawn'       # 撤回
  }

  validates :cover_message, presence: true, length: { maximum: 2000 }
  validates :quote_total_jpy, presence: true, numericality: { greater_than: 0 }
  validates :delivery_days, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true
  validate :musician_cannot_be_job_owner
  validate :job_must_be_published

  scope :for_job, ->(job_id) { where(job_id: job_id) }
  scope :by_musician, ->(musician_id) { where(musician_id: musician_id) }

  private

  def musician_cannot_be_job_owner
    return unless musician_id && job
    errors.add(:musician_id, 'cannot propose to own job') if musician_id == job.client_id
  end

  def job_must_be_published
    return unless job
    errors.add(:job, 'must be published') unless job.published?
  end
end
```

**関連付け更新**:

- `Job` モデル: `has_many :proposals, dependent: :destroy`
- `User` モデル: `has_many :proposals, foreign_key: 'musician_id', dependent: :destroy`

#### Task 4-2: contracts テーブル作成

**目的**: 提案が受諾されたら契約を作成

**テーブル設計**:

```ruby
create_table :contracts do |t|
  t.references :proposal, null: false, foreign_key: true, type: :bigint, index: { unique: true }
  t.references :client, null: false, foreign_key: { to_table: :users }, type: :bigint
  t.references :musician, null: false, foreign_key: { to_table: :users }, type: :bigint
  t.integer :escrow_total_jpy, null: false
  t.string :status, null: false, default: 'active'
  t.timestamps
end

add_index :contracts, :status
add_index :contracts, [:client_id, :musician_id]
```

**モデル設計**:

```ruby
class Contract < ApplicationRecord
  belongs_to :proposal
  belongs_to :client, class_name: 'User', foreign_key: 'client_id'
  belongs_to :musician, class_name: 'User', foreign_key: 'musician_id'
  has_many :milestones, class_name: 'ContractMilestone', dependent: :destroy

  enum status: {
    active: 'active',           # アクティブ（作業開始前）
    in_progress: 'in_progress', # 進行中
    delivered: 'delivered',     # 納品済み
    completed: 'completed',     # 完了
    canceled: 'canceled'        # キャンセル
  }

  validates :escrow_total_jpy, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true
  validate :escrow_matches_milestone_total, if: -> { milestones.any? }

  after_create :update_proposal_and_job_status

  scope :for_client, ->(client_id) { where(client_id: client_id) }
  scope :for_musician, ->(musician_id) { where(musician_id: musician_id) }

  private

  def escrow_matches_milestone_total
    total = milestones.sum(:amount_jpy)
    errors.add(:escrow_total_jpy, "must equal milestone total (#{total})") if escrow_total_jpy != total
  end

  def update_proposal_and_job_status
    proposal.update!(status: 'accepted')
    proposal.job.update!(status: 'contracted')
  end
end
```

**関連付け更新**:

- `User` モデル:
  - `has_many :contracts_as_client, class_name: 'Contract', foreign_key: 'client_id', dependent: :destroy`
  - `has_many :contracts_as_musician, class_name: 'Contract', foreign_key: 'musician_id', dependent: :destroy`
- `Proposal` モデル: `has_one :contract, dependent: :destroy`

#### Task 4-3: contract_milestones テーブル作成

**目的**: 契約のマイルストーン管理

**テーブル設計**:

```ruby
create_table :contract_milestones do |t|
  t.references :contract, null: false, foreign_key: true, type: :bigint
  t.string :title, null: false
  t.integer :amount_jpy, null: false
  t.date :due_on
  t.string :status, null: false, default: 'open'
  t.timestamps
end

add_index :contract_milestones, :status
add_index :contract_milestones, [:contract_id, :status]
```

**モデル設計**:

```ruby
class ContractMilestone < ApplicationRecord
  belongs_to :contract

  enum status: {
    open: 'open',           # 未着手
    submitted: 'submitted', # 提出済み（音楽家が提出）
    approved: 'approved',   # 承認済み（クライアントが承認）
    rejected: 'rejected',   # 却下（クライアントが却下）
    paid: 'paid'           # 支払済み
  }

  validates :title, presence: true, length: { maximum: 255 }
  validates :amount_jpy, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true

  scope :for_contract, ->(contract_id) { where(contract_id: contract_id) }
  scope :pending, -> { where(status: ['open', 'submitted']) }
  scope :completed, -> { where(status: ['approved', 'paid']) }
end
```

**ビジネスロジック**:

- 契約作成時に escrow_total_jpy とマイルストーンの合計金額が一致することを検証
- マイルストーンが全て approved/paid になったら契約を completed にする（Phase 5 で実装）

#### ER 図との差分

- **主キー**: ER 図では UUID、実装では bigint (serial) を使用
  - UUID 移行は Phase 4.5 で実施予定
- **enum 型**: PostgreSQL の enum 型ではなく、Rails の string enum を使用
  - より柔軟で、マイグレーションが容易
- **proposal_id の uniqueness**: contracts テーブルの proposal_id に unique index を設定（1 提案 1 契約）

---

### Phase 4.5: UUID 主キー移行（優先度：中）

**目的**: セキュリティ向上と将来の分散システム対応

**実装方針**:

- Phase 4 完了後、動作確認が取れてから実施
- 段階的に移行（まず新規テーブルから、その後既存テーブル）

#### UUID 拡張の有効化

```ruby
class EnableUuidExtension < ActiveRecord::Migration[7.0]
  def change
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
  end
end
```

#### 新規テーブル（proposals, contracts, milestones）の UUID 化

```ruby
class MigrateProposalsToUuid < ActiveRecord::Migration[7.0]
  def change
    # 新しいUUIDカラムを追加
    add_column :proposals, :uuid, :uuid, default: 'gen_random_uuid()', null: false
    add_index :proposals, :uuid, unique: true

    # 古いIDを参照する外部キーを削除
    remove_foreign_key :contracts, :proposals

    # contractsテーブルにもUUIDカラム追加
    add_column :contracts, :uuid, :uuid, default: 'gen_random_uuid()', null: false
    add_column :contracts, :proposal_uuid, :uuid

    # データ移行
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE contracts
          SET proposal_uuid = proposals.uuid
          FROM proposals
          WHERE contracts.proposal_id = proposals.id
        SQL
      end
    end

    # 主キーの切り替え（要注意：ダウンタイムが発生）
    # 本番環境では別途慎重に実施
  end
end
```

#### 既存テーブル（users, jobs など）の UUID 化

**注意**: 既存データが多い場合、ダウンタイムが発生する可能性あり

- Blue-Green デプロイメントの検討
- または段階的移行（二重カラム方式）

**実装手順**:

1. UUID 拡張の有効化
2. 新規テーブルの UUID 化とテスト
3. 既存テーブルの UUID 化計画策定
4. 段階的移行とテスト

---

### Phase 5: メッセージング拡張（優先度：中〜低）

**目的**: 現在の job ベースのメッセージングを conversation ベースに拡張

**現状の問題**:

- messages テーブルが job_id に直接紐づいている
- 契約後のコミュニケーション（契約に関する議論）が job に紐づいてしまう
- 複数の参加者（クライアント、音楽家、プロジェクトマネージャーなど）の管理が困難

**目指す設計**:

- conversation ベースのメッセージング
- job や contract に紐づく conversation
- conversation_participants で参加者管理と既読管理

#### Task 5-1: conversations テーブル作成

```ruby
create_table :conversations, id: :uuid do |t|
  t.references :job, foreign_key: true, type: :bigint, null: true
  t.references :contract, foreign_key: true, type: :bigint, null: true
  t.timestamps
end

# CHECK制約: job_idとcontract_idのいずれか一方のみ必須（XOR）
add_check_constraint :conversations,
  "(job_id IS NOT NULL AND contract_id IS NULL) OR (job_id IS NULL AND contract_id IS NOT NULL)",
  name: 'conversations_job_or_contract'
```

#### Task 5-2: conversation_participants テーブル作成

```ruby
create_table :conversation_participants, id: :uuid do |t|
  t.references :conversation, null: false, foreign_key: true, type: :uuid
  t.references :user, null: false, foreign_key: true, type: :bigint
  t.datetime :last_read_at
  t.timestamps
end

add_index :conversation_participants, [:conversation_id, :user_id],
  unique: true, name: 'index_conversation_participants_on_conversation_and_user'
```

#### Task 5-3: messages テーブルの移行

**完全移行**:

1. 既存の job_id 参照を削除
2. conversation_id カラムを追加（UUID 型）
3. カラム名を ER 図に合わせて変更（content → body, user_id → sender_id）
4. attachment_url カラムを追加

```ruby
class UpdateMessagesToUseConversations < ActiveRecord::Migration[7.0]
  def change
    # 既存のjob_id参照を削除
    remove_reference :messages, :job, foreign_key: true, index: true

    # conversation_id追加（uuid型）
    add_reference :messages, :conversation, null: true, foreign_key: true, type: :uuid
    add_index :messages, [:conversation_id, :created_at]

    # カラム名変更（ER図に合わせる）
    rename_column :messages, :content, :body
    rename_column :messages, :user_id, :sender_id

    # Phase 6用のattachment_url追加
    add_column :messages, :attachment_url, :text

    # conversation_idをNOT NULLに変更
    change_column_null :messages, :conversation_id, false
  end
end
```

#### モデル設計

```ruby
class Conversation < ApplicationRecord
  belongs_to :job, optional: true
  belongs_to :contract, optional: true

  has_many :conversation_participants, dependent: :destroy
  has_many :participants, through: :conversation_participants, source: :user
  has_many :messages, dependent: :destroy

  validates :job_id, presence: true, if: -> { contract_id.blank? }
  validates :contract_id, presence: true, if: -> { job_id.blank? }
  validate :only_one_parent

  # 参加者チェック
  def participant?(user)
    participants.exists?(id: user.id)
  end

  # 未読メッセージ数取得
  def unread_count_for(user)
    participant = conversation_participants.find_by(user: user)
    return 0 unless participant

    messages.where('created_at > ?', participant.last_read_at || Time.at(0)).count
  end

  private

  def only_one_parent
    if job_id.present? && contract_id.present?
      errors.add(:base, 'Cannot belong to both job and contract')
    end
  end
end

class ConversationParticipant < ApplicationRecord
  belongs_to :conversation
  belongs_to :user

  validates :user_id, uniqueness: { scope: :conversation_id }

  # 既読マーク
  def mark_as_read!
    update(last_read_at: Time.current)
  end
end

class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, class_name: 'User'

  validates :body, presence: true, length: { minimum: 1, maximum: 1000 }

  # 送信後に送信者を既読にする
  after_create :mark_sender_as_read

  private

  def mark_sender_as_read
    participant = conversation.conversation_participants.find_by(user: sender)
    participant&.mark_as_read!
  end
end
```

---

### Phase 6: レビュー・決済システム（優先度：中〜低）

**目的**: 契約完了後のレビュー機能と決済・エスクロー管理

#### Task 6-1: reviews テーブル作成

**目的**: 契約完了後に相互レビュー

```ruby
create_table :reviews do |t|
  t.references :contract, null: false, foreign_key: true, index: false
  t.references :reviewer, null: false, foreign_key: { to_table: :users }, index: false
  t.references :reviewee, null: false, foreign_key: { to_table: :users }, index: false
  t.integer :rating, null: false
  t.text :comment
  t.uuid :uuid, null: false, default: -> { "gen_random_uuid()" }
  t.timestamps
end

add_index :reviews, :uuid, unique: true
add_index :reviews, :rating
add_index :reviews, :reviewer_id
add_index :reviews, :reviewee_id
add_index :reviews, :contract_id, unique: true
add_check_constraint :reviews, 'rating >= 1 AND rating <= 5', name: 'reviews_rating_range'
```

**モデル設計**:

```ruby
class Review < ApplicationRecord
  belongs_to :contract
  belongs_to :reviewer, class_name: 'User'
  belongs_to :reviewee, class_name: 'User'

  validates :rating, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :contract_id, uniqueness: true
  validates :comment, length: { maximum: 1000 }, allow_blank: true
  validates :reviewer_id, presence: true
  validates :reviewee_id, presence: true

  scope :for_contract, ->(contract_id) { where(contract_id: contract_id) }
  scope :for_user, ->(user_id) { where('reviewer_id = ? OR reviewee_id = ?', user_id, user_id) }

  def to_param
    uuid
  end

  def self.find_by_uuid(uuid)
    find_by(uuid: uuid)
  end
end
```

#### Task 6-2: transactions テーブル作成

**目的**: 決済・エスクロー管理（Stripe など外部決済サービスとの連携）

```ruby
create_table :transactions do |t|
  t.references :contract, null: false, foreign_key: true, index: false
  t.references :milestone, null: true, foreign_key: { to_table: :contract_milestones, on_delete: :nullify }, index: false
  t.integer :amount_jpy, null: false
  t.string :kind, null: false
  t.string :status, null: false, default: 'authorized'
  t.string :provider
  t.string :provider_ref
  t.uuid :uuid, null: false, default: -> { "gen_random_uuid()" }
  t.timestamps
end

add_index :transactions, :uuid, unique: true
add_index :transactions, :contract_id
add_index :transactions, :milestone_id
add_index :transactions, :kind
add_index :transactions, :status
add_check_constraint :transactions, 'amount_jpy > 0', name: 'transactions_amount_positive'
```

**モデル設計**:

```ruby
class Transaction < ApplicationRecord
  belongs_to :contract
  belongs_to :milestone, class_name: 'ContractMilestone', optional: true

  enum kind: {
    escrow_deposit: 'escrow_deposit',
    milestone_payout: 'milestone_payout',
    refund: 'refund',
    platform_fee: 'platform_fee'
  }

  enum status: {
    authorized: 'authorized',
    captured: 'captured',
    paid_out: 'paid_out',
    failed: 'failed',
    refunded: 'refunded'
  }

  validates :amount_jpy, presence: true, numericality: { greater_than: 0 }
  validates :kind, presence: true
  validates :status, presence: true

  scope :for_contract, ->(contract_id) { where(contract_id: contract_id) }
  scope :for_milestone, ->(milestone_id) { where(milestone_id: milestone_id) }

  def to_param
    uuid
  end

  def self.find_by_uuid(uuid)
    find_by(uuid: uuid)
  end
end
```

**Stripe 連携例**:

```ruby
class TransactionService
  def self.create_escrow_deposit(contract, payment_method)
    # Stripe で PaymentIntent を作成
    intent = Stripe::PaymentIntent.create({
      amount: contract.escrow_total_jpy,
      currency: 'jpy',
      payment_method: payment_method,
      confirm: true,
      capture_method: 'manual' # エスクロー用に手動キャプチャ
    })

    # Transaction レコードを作成
    Transaction.create!(
      contract: contract,
      kind: 'escrow_deposit',
      status: 'authorized',
      amount_jpy: contract.escrow_total_jpy,
      provider: 'stripe',
      provider_ref: intent.id
    )
  end

  def self.payout_milestone(milestone)
    # マイルストーン承認後、音楽家に支払い
    contract = milestone.contract

    # Stripe Transfer で音楽家の Stripe Connect アカウントに送金
    transfer = Stripe::Transfer.create({
      amount: milestone.amount_jpy,
      currency: 'jpy',
      destination: contract.musician.stripe_account_id
    })

    Transaction.create!(
      contract: contract,
      milestone: milestone,
      kind: 'milestone_payout',
      status: 'paid_out',
      amount_jpy: milestone.amount_jpy,
      provider: 'stripe',
      provider_ref: transfer.id
    )
  end
end
```

---

### Phase 7: API エンドポイント実装（優先度：高）

**目的**: フロントエンドとの連携のための RESTful API

**実装方針**:

- UUID 識別: 全てのリソースを UUID で識別（`:uuid` パラメータ使用）
- 認証・認可: Devise + JWT、各アクションで所有者確認
- ページネーション: デフォルト 10 件、最大 50 件（TracksController パターン踏襲）
- 段階的実装: 1API 完了ごとにコミット・PR・マージ

**詳細計画**: [cheerful-snuggling-beacon.md](.claude/plans/cheerful-snuggling-beacon.md)

#### Phase 7.1: Jobs API（6 エンドポイント）

**エンドポイント**:

- `GET /api/v1/jobs` - 案件一覧（公開中、認証不要）
- `GET /api/v1/jobs/:uuid` - 案件詳細（認証不要）
- `POST /api/v1/jobs` - 案件作成（要認証）
- `PATCH /api/v1/jobs/:uuid` - 案件更新（要認証・要所有者）
- `DELETE /api/v1/jobs/:uuid` - 案件削除（要認証・要所有者）
- `POST /api/v1/jobs/:uuid/publish` - 案件公開（要認証・要所有者）

**実装タスク**: JobsController 作成、Routes 追加、RSpec 作成（30+テスト）

#### Phase 7.2: Proposals API（7 エンドポイント）

**エンドポイント**:

- `GET /api/v1/jobs/:job_uuid/proposals` - 提案一覧
- `GET /api/v1/proposals/:uuid` - 提案詳細
- `POST /api/v1/jobs/:job_uuid/proposals` - 提案作成
- `PATCH /api/v1/proposals/:uuid` - 提案更新
- `DELETE /api/v1/proposals/:uuid` - 提案撤回
- `POST /api/v1/proposals/:uuid/accept` - 提案受諾（契約作成）
- `POST /api/v1/proposals/:uuid/reject` - 提案却下

**実装タスク**: ProposalsController 作成、Routes 追加、RSpec 作成（35+テスト）

#### Phase 7.3: Contracts API（3 エンドポイント、MVP 簡易版）

**エンドポイント**:

- `GET /api/v1/contracts` - 契約一覧（自分が関わる契約のみ）
- `GET /api/v1/contracts/:uuid` - 契約詳細
- `PATCH /api/v1/contracts/:uuid` - 契約ステータス更新

**実装タスク**: ContractsController 作成、Routes 追加、RSpec 作成（20+テスト）

#### Phase 7.4: Milestones API（4 エンドポイント、MVP 簡易版）

**エンドポイント**:

- `GET /api/v1/contracts/:contract_uuid/milestones` - マイルストーン一覧
- `GET /api/v1/milestones/:id` - マイルストーン詳細（注: UUID 未対応のため ID 使用）
- `PATCH /api/v1/milestones/:id` - ステータス更新
- `POST /api/v1/milestones/:id/complete` - 完了マーク

**実装タスク**: ContractMilestonesController 作成、Routes 追加、RSpec 作成（25+テスト）

#### Phase 7.5: Conversations & Messages API（4 エンドポイント）

**エンドポイント**:

- `GET /api/v1/conversations` - 会話一覧
- `GET /api/v1/conversations/:uuid/messages` - メッセージ一覧
- `POST /api/v1/conversations/:uuid/messages` - メッセージ送信
- `POST /api/v1/conversations/:uuid/mark_as_read` - 既読マーク

**実装タスク**: ConversationsController + MessagesController 作成、Routes 追加、RSpec 作成（30+テスト）

#### Phase 7.6: Reviews & Transactions API（4 エンドポイント）

**エンドポイント**:

**Reviews**:

- `GET /api/v1/contracts/:contract_uuid/review` - レビュー取得
- `POST /api/v1/contracts/:contract_uuid/review` - レビュー作成

**Transactions**:

- `GET /api/v1/contracts/:contract_uuid/transactions` - トランザクション一覧
- `GET /api/v1/transactions/:uuid` - トランザクション詳細

**実装タスク**: ReviewsController + TransactionsController 作成、Routes 追加、RSpec 作成（25+テスト）

---

## まとめ

### 優先順位

1. **Phase 4**: 提案・契約システム（最優先）
2. **Phase 7**: API エンドポイント実装（Phase 4 と並行可能）
3. **Phase 4.5**: UUID 主キー移行（Phase 4 完了後）
4. **Phase 5**: メッセージング拡張
5. **Phase 6**: レビュー・決済システム

### 開発方針

- **未知の作業を複数同時にやらない**: 各 Phase を順番に完了させる
- **テスト駆動**: Model specs → Request specs の順で実装
- **段階的リリース**: Phase ごとに PR を作成し、CI を通してマージ
- **ドキュメント更新**: 各 Phase 完了時に PLAN.md を更新

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
  - 10 ジャンル登録（Rock, Pop, Jazz, Classical, Electronic, Hip Hop, R&B, Country, Blues, Metal）
  - 10 楽器登録（Piano, Guitar, Bass, Drums, Violin, Saxophone, Vocals, Synthesizer, Trumpet, Cello）
  - 8 スキル登録（Composition, Arrangement, Mixing, Mastering, Recording, Production, Sound Design, Orchestration）
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
    - `title`: string（案件タイトル、必須、最大 255 文字）
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
- 開発環境・CI 環境ともに PostgreSQL 15 を使用

---

### ✅ Phase 4: 提案・契約システム（完了）

- **ブランチ**: ローカル作業
- **実施日**: 2025-11-10
- **内容**:
  - proposals/contracts/contract_milestones を追加し、Job/Proposal/Contract の関連を整備
  - Contract に status(enum)・スコープ・バリデーションを実装、マイルストーン管理を追加
  - モデルスペックでバリデーション・enum・スコープ・依存削除を確認

---

### ✅ Phase 4.5: UUID サポート拡張（完了）

- **ブランチ**: ローカル作業
- **実施日**: 2025-11-10
- **内容**:
  - pgcrypto 有効化、全テーブルに uuid カラムと unique index を付与
  - User/Job/Proposal/Contract 等に to_param/find_by_uuid を実装し、外部公開 ID を uuid 化
  - uuid_support_spec で生成・公開 ID を検証

---

### ✅ Phase 5: メッセージング拡張（完了）

- **ブランチ**: `feature/conversations-system`
- **PR**: #56
- **実施日**: 2025-11-27
- **内容**:
  - conversations: job/contract と XOR 制約、UUID 主キー
  - conversation_participants: 参加者管理と既読管理（last_read_at）、UUID 主キー
  - messages: conversation ベースに完全移行、カラム名変更（content → body, user_id → sender_id）、attachment_url 追加
  - モデル: Conversation/ConversationParticipant を新設、Message を ER 図準拠に改修
  - 未読管理機能: unread_count_for(user)、mark_as_read!、自動既読マーク
- **テスト**: 全 295 テスト成功
  - conversation_spec.rb (149 examples)
  - conversation_participant_spec.rb (59 examples)
  - message_spec.rb (102 examples - リファクタリング)
  - messaging_system_spec.rb (統合テスト)
  - schema_end_to_end_spec.rb (E2E テスト)

---

### ✅ Phase 6: レビュー・決済システム（完了）

- **ブランチ**: `feature/phase6-reviews-transactions`
- **PR**: #57
- **実施日**: 2025-11-27
- **内容**:
  - reviews: contract 単位で 1 件、reviewer/reviewee の FK、rating (1-5) CHECK、uuid 付与
  - transactions: contract 必須・milestone 任意、kind/status は enum 文字列、amount_jpy > 0 の CHECK、uuid 付与
  - モデル: Review/Transaction を追加し、Contract に has_one :review / has_many :transactions、User に given/received_reviews を関連付け
  - データベース制約テストの修正（messaging_system_spec.rb）
- **テスト**: 全 295 テスト成功
  - review_spec.rb (63 examples)
  - transaction_spec.rb (82 examples)
  - reviews_transactions_spec.rb (統合テスト)
  - schema_end_to_end_spec.rb (E2E テスト)

---

最終更新: 2025-11-27
