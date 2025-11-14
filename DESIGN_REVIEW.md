# 設計レビュー依頼（15 分用）

## プロジェクト概要

音楽家向け仕事マッチングプラットフォーム
Rails API + Next.js、MVP 開発中

---

## データモデル全体像（13 テーブル）

```
Users (音楽家/依頼者)
├── MusicianProfile (音楽家プロフィール)
│   ├── MusicianGenres → Genres
│   ├── MusicianSkills → Skills
│   └── MusicianInstruments → Instruments
├── ClientProfile (依頼者プロフィール)
└── Tracks (音楽作品、YouTubeリンク)
    └── Jobs (制作依頼案件)
        ├── Messages (メッセージ)
        └── Threads (スレッド、Phase 5で追加)
            ├── ThreadParticipants
            └── Messages (thread対応済み)
```

### 認証・セキュリティ

- JwtDenylist (ログアウトトークン管理)

---

## 実装済みフェーズ

| Phase | 機能                 | テーブル追加                                      |
| ----- | -------------------- | ------------------------------------------------- |
| 1     | プロフィール拡張     | MusicianProfile, ClientProfile                    |
| 2     | タクソノミー         | Genres, Skills, Instruments + 中間テーブル 3 つ   |
| 3     | Jobs 拡張            | JobRequirements (未実装)                          |
| 4     | 提案・契約           | Proposals, Contracts, ContractMilestones (未確認) |
| 4.5   | UUID 全テーブル      | uuid 列 16 テーブル追加                           |
| 5     | メッセージ thread 化 | Threads, ThreadParticipants                       |

---

## 主要な設計判断

### 1. ユーザー二重ロール対応

- `users.is_musician` / `users.is_client` フラグ
- 両方 true で音楽家兼依頼者可能
- Profile テーブルを STI (Single Table Inheritance) せず分離

### 2. UUID 戦略

- INT 主キー維持 + uuid 列追加（gen_random_uuid()）
- `to_param`で UUID 返却（URL 公開用）
- 内部結合は INT、外部公開は UUID

### 3. MessageThread 命名

- Ruby ビルトイン`Thread`クラス衝突回避
- モデル名: `MessageThread` / テーブル名: `threads`
- `self.table_name = 'threads'`で実テーブル名維持

### 4. CHECK 制約（job_id XOR contract_id）

```sql
CHECK (
  (job_id IS NULL AND contract_id IS NOT NULL) OR
  (job_id IS NOT NULL AND contract_id IS NULL)
)
```

- Thread は必ず job か contract のどちらか一方に紐づく
- Rails 側でも validate 実装（二重保証）

### 5. 外部キー制約

- dependent: :destroy 多用（cascade 削除）
- 孤立レコード防止

---

## レビューしてほしい質問（3 つ）

### Q1. テーブル設計の致命的な問題はないか？

- N+1 発生しやすい構造
- スケール時にボトルネックになる箇所
- インデックス不足

### Q2. CHECK 制約 vs Application 層バリデーション

- `threads`テーブルの CHECK 制約は必要か？
- Rails validate だけで十分か？
- DB 制約と App 層の二重管理は過剰か？

### Q3. UUID 戦略の妥当性

- INT 主キー + uuid 列の二重管理は複雑すぎないか？
- UUID カラムにインデックス不要の判断は正しいか？
- `to_param`で UUID 返すのは Rails 慣例的に OK か？

---

## 現在の技術スタック

| 項目     | 技術                                         |
| -------- | -------------------------------------------- |
| Backend  | Rails 7.0 (API mode)                         |
| DB       | MySQL 8.0 → PostgreSQL 15 (Phase 4.5 で移行) |
| Frontend | Next.js 14, TypeScript                       |
| 認証     | Devise + JWT                                 |
| テスト   | RSpec (19 ファイル、1820 行)                 |
| CI       | GitHub Actions                               |

---

## 進めて良いか？修正すべきか？

**判断基準**:

- このまま実装継続して OK → 「進めて OK」
- 設計変更が必要 → 「修正すべき箇所を指摘」

**15 分で見てほしいのは方向性の確認です**
