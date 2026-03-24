# マッチングロジック：課題整理と改善設計

## 1. 現状の課題

### 1.1 アルゴリズム的マッチングが未実装

現在のプラットフォームには **スコアリング/レコメンドの仕組みが一切存在しない**。

| 現状のフロー | 動作 | 問題点 |
|---|---|---|
| Job-Based | クライアントが案件公開 → ミュージシャンが一覧から手動で探して応募 | ミュージシャン側に適合案件の発見手段がない |
| Direct Request | クライアントがミュージシャンを直接指名 | クライアント側にミュージシャン発見の仕組みがない |

### 1.2 フロントエンドUIが未接続

- `/matching/page.tsx` に検索フォーム（ジャンル・予算・経験レベル）のUIは存在するが、APIと未接続
- 検索フィルタが機能しない状態

### 1.3 データは揃っている（活用されていない）

既存のデータモデルにはマッチングに必要な情報が十分に設計されている：

```
Job ──has_many──→ JobRequirement(kind: genre|instrument|skill, ref_id)
User ──has_many──→ MusicianGenre, MusicianInstrument, MusicianSkill
User ──has_one───→ MusicianProfile(hourly_rate_jpy, avg_rating, rating_count)
User ──has_many──→ Track(bpm, key, genre)
```

これらのリレーションを使えば、Job の要件とミュージシャンの属性を照合できる。

### 1.4 Track の genre が文字列フィールド

`tracks.genre` は自由入力の文字列であり、`genres` テーブルの正規化されたデータと連携していない。ジャンル一致判定の精度に影響する。

---

## 2. 改善設計

### 2.1 アーキテクチャ概要

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Frontend   │────→│  API Endpoint    │────→│  MatchingService │
│  /matching  │     │  GET /api/v1/    │     │  (Rails Service) │
│             │←────│  matches         │←────│                  │
└─────────────┘     └──────────────────┘     └────────┬────────┘
                                                      │
                                              ┌───────┴────────┐
                                              │  ScoreCalculator│
                                              │  (PORO)         │
                                              └────────────────┘
```

### 2.2 マッチングスコアの設計

#### スコアリング要素と重み

| 要素 | 重み | 説明 | 計算方法 |
|---|---|---|---|
| **ジャンル一致** | 0.30 | Job要件のジャンルとミュージシャンのジャンルの一致度 | `一致数 / 要件数` |
| **楽器一致** | 0.25 | Job要件の楽器とミュージシャンの楽器の一致度 | `一致数 / 要件数` |
| **スキル一致** | 0.20 | Job要件のスキルとミュージシャンのスキルの一致度 | `一致数 / 要件数` |
| **予算適合** | 0.15 | ミュージシャンの時給と案件予算の適合度 | 予算範囲内なら1.0、範囲外は距離に応じて減衰 |
| **評価スコア** | 0.10 | ミュージシャンの平均評価 | `avg_rating / 5.0` × 信頼度補正 |

#### 総合スコア計算式

```ruby
total_score = (genre_score  * 0.30) +
              (instrument_score * 0.25) +
              (skill_score * 0.20) +
              (budget_score * 0.15) +
              (rating_score * 0.10)
# total_score: 0.0 ~ 1.0
```

#### 各スコアの詳細

**ジャンル/楽器/スキル一致スコア:**
```ruby
# Jobの要件に対するミュージシャンの一致率
# 要件が0件の場合はスコア 1.0（制約なし = 全員マッチ）
def taxonomy_score(required_ids, musician_ids)
  return 1.0 if required_ids.empty?
  (required_ids & musician_ids).size.to_f / required_ids.size
end
```

**予算適合スコア:**
```ruby
def budget_score(musician_rate, budget_min, budget_max)
  return 1.0 if musician_rate.nil? # 未設定は除外しない
  return 1.0 if budget_min.nil? && budget_max.nil?

  if budget_min && budget_max
    if musician_rate.between?(budget_min, budget_max)
      1.0
    else
      distance = [budget_min - musician_rate, musician_rate - budget_max].max
      range = budget_max - budget_min
      [1.0 - (distance.to_f / [range, 1].max), 0.0].max
    end
  elsif budget_max
    musician_rate <= budget_max ? 1.0 : [1.0 - (musician_rate - budget_max).to_f / budget_max, 0.0].max
  else
    musician_rate >= budget_min ? 1.0 : [1.0 - (budget_min - musician_rate).to_f / budget_min, 0.0].max
  end
end
```

**評価スコア（信頼度補正付き）:**
```ruby
# rating_countが少ない場合はスコアを保守的にする
def rating_score(avg_rating, rating_count)
  confidence = [rating_count / 5.0, 1.0].min  # 5件でフル信頼
  raw = avg_rating / 5.0
  # ベイズ平均的アプローチ: 少ないレビューは平均(0.6)に近づける
  (raw * confidence) + (0.6 * (1.0 - confidence))
end
```

### 2.3 APIエンドポイント設計

#### A) Job に対するミュージシャン推薦（クライアント向け）

```
GET /api/v1/jobs/:job_uuid/matched_musicians
```

**レスポンス:**
```json
{
  "data": [
    {
      "musician_uuid": "...",
      "name": "...",
      "headline": "...",
      "score": 0.85,
      "score_breakdown": {
        "genre": 0.30,
        "instrument": 0.25,
        "skill": 0.20,
        "budget": 0.15,
        "rating": 0.10
      },
      "matched_genres": ["Rock", "Jazz"],
      "matched_instruments": ["Guitar"],
      "avg_rating": 4.5,
      "rating_count": 12,
      "hourly_rate_jpy": 5000
    }
  ],
  "meta": { "total": 42, "page": 1, "per_page": 20 }
}
```

#### B) ミュージシャンに対するJob推薦（ミュージシャン向け）

```
GET /api/v1/matched_jobs
```

ミュージシャンのプロフィール（genres, instruments, skills, hourly_rate）を元に、公開中のJobを適合度順で返す。

### 2.4 実装ファイル構成

```
backend/
  app/
    services/
      matching/
        score_calculator.rb    # スコア計算ロジック（PORO）
        musician_matcher.rb    # Job→ミュージシャン推薦
        job_matcher.rb         # ミュージシャン→Job推薦
    controllers/
      api/v1/
        matched_musicians_controller.rb
        matched_jobs_controller.rb
  spec/
    services/
      matching/
        score_calculator_spec.rb
        musician_matcher_spec.rb
        job_matcher_spec.rb
    requests/
      api/v1/
        matched_musicians_spec.rb
        matched_jobs_spec.rb
```

### 2.5 パフォーマンス考慮

**Phase 1（現段階）:**
- SQLでの事前フィルタリング（要件が1つも一致しないミュージシャンを除外）
- Rubyでスコア計算
- ミュージシャン数が数千人規模であれば十分な性能

```ruby
# 事前フィルタ例: 要件ジャンルの少なくとも1つを持つミュージシャンに絞る
scope :with_any_genre, ->(genre_ids) {
  where(id: MusicianGenre.where(genre_id: genre_ids).select(:user_id))
}
```

**Phase 2（将来）:**
- PostgreSQL の `pg_trgm` や全文検索でテキストマッチ
- スコアキャッシュ（ミュージシャンのプロフィール更新時に再計算）
- Track の音声特徴量を活用した類似度マッチング

### 2.6 tracks.genre の正規化（オプション）

`tracks.genre` を `genres` テーブルと連携させるために：

1. `tracks` に `genre_id` カラムを追加（nullable）
2. 既存の文字列 `genre` を `genres` テーブルとマッピング
3. Track のジャンルもマッチング要素として活用可能に

これは Phase 2 で対応し、Phase 1 では `musician_genres` のみを使用する。

---

## 3. 実装優先順位

| Phase | 内容 | 目的 |
|---|---|---|
| **Phase 1** | `ScoreCalculator` + `MusicianMatcher` + API + テスト | MVP: Jobに対するミュージシャン推薦 |
| **Phase 2** | `JobMatcher` + フロントエンド接続 | ミュージシャン向けJob推薦 + UI完成 |
| **Phase 3** | Track音声特徴量活用 + スコアキャッシュ | 精度向上 + パフォーマンス最適化 |
