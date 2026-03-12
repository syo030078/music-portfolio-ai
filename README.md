# Music Work

**音楽家と制作依頼者をつなぐマッチングプラットフォーム**

楽曲を登録してポートフォリオを公開。制作依頼を投稿して最適な音楽家とマッチング。提案・契約・メッセージングまでワンストップで実現します。

## こんな方におすすめ

- **音楽家**: もっと多くの人に作品を届けたい。制作の仕事を増やしたい。
- **制作依頼者**: イメージにぴったりの音楽家と出会いたい。スムーズに依頼したい。

## Music Work でできること

### 音楽家として

| できること | 詳細 |
| --- | --- |
| 楽曲を登録してポートフォリオを公開 | トラック情報を登録し、プロフェッショナルなプロフィールを作成 |
| 案件マーケットプレイスで仕事に出会える | 条件に合う制作依頼を検索・提案できる |
| ジャンル・楽器・スキルで専門性をアピール | 分類タグ付きポートフォリオで技術力を可視化 |

### 制作依頼者として

| できること | 詳細 |
| --- | --- |
| ジャンル・楽器・スキルで最適な音楽家を発見 | 豊富な分類タグによるマッチング |
| 案件を投稿して提案を受け取れる | 要件を設定して音楽家を募集 |
| マイルストーンベースで安心して契約 | エスクロー管理で双方を保護 |
| ビルトインメッセージングでスムーズにやりとり | 案件・契約に紐づいた会話（未読管理付き） |

## 今後の展望

- AI 楽曲解析（BPM・キー・ジャンル自動検出）によるマッチング精度の向上
- OpenAI 連携によるポートフォリオ自動生成
- エージェントの反応を見ながら段階的にブラッシュアップ予定

> **Note**: 上記はすべて構想段階です。現在の本番環境には AI 機能は含まれていません。

## 主な機能

- **認証・ロール管理**: デュアルロール（音楽家/依頼者）、JWT 認証、ロール別リダイレクト
- **楽曲登録・ポートフォリオ**: ファイルアップロード、YouTube URL 登録、プロフィール自動構成
- **案件マーケットプレイス**: 案件の投稿・検索・フィルタリング（予算・リモート・納期）
- **提案・契約管理**: 提案の作成・承認・却下、マイルストーンベースの契約
- **メッセージング**: 案件・契約に紐づく会話、未読カウント
- **制作依頼**: 音楽家への直接依頼、承認・却下・取り下げフロー

## 技術スタック

| カテゴリ | 技術 |
| --- | --- |
| **Frontend** | Next.js 15 (App Router), TypeScript, Tailwind CSS 4 |
| **Backend** | Rails 7 API mode, PostgreSQL 14+, Devise + JWT |
| **AI/ML** | Python 3.10+, librosa, ffmpeg（開発中） |
| **Testing** | RSpec, FactoryBot |
| **Deploy** | EC2, Docker Compose, nginx reverse proxy |

## セットアップ

### 前提条件

- Ruby 3.1.3（[.ruby-version](.ruby-version) 参照）
- Node.js 20 以降
- PostgreSQL 14 以降
- Python 3.10 以降（AI 機能開発時）
- ffmpeg（音源解析に必要）

### 1. リポジトリをクローン

```bash
git clone https://github.com/yourusername/music-portfolio-ai.git
cd music-portfolio-ai
```

### 2. Backend のセットアップ

```bash
cd backend
bundle install
bin/rails db:setup  # データベース作成・マイグレーション・シードデータ投入
bin/rails server    # http://localhost:3000 で起動
```

**環境変数の設定**:

- JWT 認証には `secret_key_base` を使用（自動生成）
- データベース接続情報は `config/database.yml` で設定可能

### 3. Frontend のセットアップ

```bash
cd frontend
npm install         # または pnpm install
npm run dev         # http://localhost:3001 で起動
```

**環境変数の設定**:

- `frontend/.env.local` を作成し、API 接続先を指定（任意）:
  ```
  NEXT_PUBLIC_API_BASE=http://localhost:3000
  ```

### 4. 音源解析 CLI のセットアップ（開発中）

```bash
cd analyzer
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
python music_analyzer.py --file path/to/audio.mp3
```

**ffmpeg のインストール**:

- macOS: `brew install ffmpeg`
- Ubuntu: `sudo apt install ffmpeg`
- Windows: [公式サイト](https://ffmpeg.org/download.html)からダウンロード

<details>
<summary>よくある質問</summary>

**Q: ポートが競合します**
A: Frontend を別ポートで起動: `PORT=3001 npm run dev`

**Q: PostgreSQL 接続エラーが出ます**
A: `backend/config/database.yml` で接続情報を確認してください。環境変数でも設定可能です。

**Q: ffmpeg が見つかりません**
A: ffmpeg が PATH に含まれているか確認: `ffmpeg -version`

**Q: テストが失敗します**
A: データベースをリセット: `cd backend && bin/rails db:test:prepare`

</details>

## API エンドポイント

### 認証

```
POST   /auth                 - ユーザー登録
POST   /auth/sign_in         - ログイン
DELETE /auth/sign_out        - ログアウト
```

### ユーザー・トラック

```
GET    /api/v1/user          - ユーザー情報取得
PATCH  /api/v1/user          - ユーザー情報更新
GET    /api/v1/tracks        - トラック一覧
POST   /api/v1/tracks        - トラック登録
GET    /api/v1/tracks/:id    - トラック詳細
PATCH  /api/v1/tracks/:id    - トラック更新
DELETE /api/v1/tracks/:id    - トラック削除
```

### 案件・提案

```
GET    /api/v1/jobs              - 案件一覧（フィルタリング対応）
GET    /api/v1/jobs/:uuid        - 案件詳細
POST   /api/v1/jobs/:uuid/proposals     - 提案作成
GET    /api/v1/jobs/:uuid/proposals     - 提案一覧
POST   /api/v1/proposals/:uuid/accept   - 提案承認
POST   /api/v1/proposals/:uuid/reject   - 提案却下
```

### 制作依頼

```
GET    /api/v1/production_requests              - 依頼一覧
POST   /api/v1/production_requests              - 依頼作成
GET    /api/v1/production_requests/:uuid        - 依頼詳細
POST   /api/v1/production_requests/:uuid/accept   - 依頼承認
POST   /api/v1/production_requests/:uuid/reject    - 依頼却下
POST   /api/v1/production_requests/:uuid/withdraw  - 依頼取り下げ
```

### メッセージング

```
GET    /api/v1/conversations              - 会話一覧
POST   /api/v1/conversations              - 会話作成
GET    /api/v1/conversations/:id          - 会話詳細
POST   /api/v1/conversations/:id/messages - メッセージ送信
```

## テストの実行

```bash
# Backend（RSpec）
cd backend
bundle exec rspec

# 特定のテストファイルのみ実行
bundle exec rspec spec/requests/api/v1/jobs_spec.rb

# Frontend（Lint）
cd frontend
npm run lint

# Analyzer
cd analyzer
python test_music_analyzer.py
```

## 開発状況

| フェーズ | 状態 | 説明 |
| --- | --- | --- |
| Phase 1-6 | 完了 | 基盤システム（Models, DB 設計, 認証） |
| Phase 7 | 完了 | Jobs / Proposals / Production Requests API |
| Phase 8 | 完了 | メッセージング（Conversations / Messages） |
| Frontend | 完了 | Next.js 画面実装（案件・メッセージ・マッチング・アップロード） |
| Deploy | 完了 | EC2 Docker Compose + nginx |
| AI 解析 | 開発中 | BPM・キー・ジャンル自動検出、OpenAI 連携 |

## リポジトリ構成

```
music-portfolio-ai/
├── frontend/          # Next.js 15 (App Router, TypeScript)
├── backend/           # Rails 7 API (PostgreSQL, Devise + JWT, RSpec)
├── analyzer/          # Python音源解析CLI（librosa, ffmpeg）開発中
├── docs/              # 設計資料・実装計画
└── README.md
```

## 開発への参加

### コミットメッセージ規約

```
feat:     新機能追加
fix:      バグ修正
docs:     ドキュメント更新
test:     テスト追加・修正
refactor: リファクタリング
style:    コードフォーマット
chore:    雑務（依存関係更新など）
```

TDD（テスト駆動開発）で Phase 単位に段階的に実装しています。

## ドキュメント

- **DB 設計**: [docs/implementation-plan/database.md](docs/implementation-plan/database.md)
- **ERD**: [docs/architecture/er-diagram.puml](docs/architecture/er-diagram.puml)

## ライセンス

このプロジェクトは現在ライセンス未設定です。商用利用を検討する場合は、適切なライセンスを追加予定です。

## 謝辞

このプロジェクトは以下のオープンソースプロジェクトに支えられています：

- [Rails](https://rubyonrails.org/) - Web アプリケーションフレームワーク
- [Next.js](https://nextjs.org/) - React フレームワーク
- [librosa](https://librosa.org/) - 音楽・音声解析ライブラリ
- [Devise](https://github.com/heartcombo/devise) - 認証システム

---
