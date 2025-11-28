# Music Portfolio AI

**音楽家と制作依頼者を AI でつなぐマッチングプラットフォーム**

音楽家が楽曲をアップロードすると、AI が自動で BPM・キー・ジャンルを解析。プロフェッショナルなポートフォリオを生成し、制作依頼者とのマッチングを実現します。

## このプロジェクトが行うこと

- **楽曲の自動解析**: Python（librosa）で BPM/キー/ジャンルを AI 推定
- **ポートフォリオ自動生成**: 解析データから魅力的な音楽家プロフィールを作成
- **案件マッチング**: 制作依頼の投稿・提案・契約管理をワンストップで実現
- **メッセージング**: 依頼者と音楽家のリアルタイムコミュニケーション
- **レビューシステム**: 信頼性の高い取引をサポート

## このプロジェクトが有益な理由

従来、音楽家が制作依頼を受けるには、ポートフォリオサイトの構築や営業活動に多くの時間を費やす必要がありました。このプラットフォームは：

- 楽曲をアップロードするだけで、AI が自動的にポートフォリオを生成
- 依頼者は楽曲データ（BPM・キー・ジャンル）で適切な音楽家を検索可能
- 案件投稿から契約、支払いまでをシステム内で完結

音楽家はクリエイティブな活動に集中でき、依頼者は効率的に最適な音楽家を見つけられます。

## 技術スタック

| カテゴリ     | 技術                                                |
| ------------ | --------------------------------------------------- |
| **Frontend** | Next.js 15 (App Router), TypeScript, Tailwind CSS 4 |
| **Backend**  | Rails 7 API mode, PostgreSQL 14+, Devise + JWT      |
| **AI/ML**    | Python 3.10+, librosa, ffmpeg, OpenAI API           |
| **Testing**  | RSpec, FactoryBot                                   |
| **Tools**    | Docker (optional), Git, Bundler, npm                |

## このプロジェクトの使い始め方

### 前提条件

以下のツールがインストールされている必要があります：

- Ruby 3.1.3（[.ruby-version](.ruby-version)参照）
- Node.js 20 以降
- PostgreSQL 14 以降
- Python 3.10 以降
- ffmpeg（音源解析に必要）

### インストール手順

#### 1. リポジトリをクローン

```bash
git clone https://github.com/yourusername/music-portfolio-ai.git
cd music-portfolio-ai
```

#### 2. Backend のセットアップ

```bash
cd backend
bundle install
bin/rails db:setup  # データベース作成・マイグレーション・シードデータ投入
bin/rails server    # http://localhost:3000 で起動
```

**環境変数の設定**:

- JWT 認証には`secret_key_base`を使用（自動生成）
- データベース接続情報は`config/database.yml`で設定可能

#### 3. Frontend のセットアップ

```bash
cd frontend
npm install         # または pnpm install
npm run dev         # http://localhost:3001 で起動
```

**環境変数の設定**:

- `frontend/.env.local`を作成し、API 接続先を指定（任意）:
  ```
  NEXT_PUBLIC_API_BASE=http://localhost:3000
  ```

#### 4. 音源解析 CLI のセットアップ

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

## API エンドポイント

### 認証（Devise + JWT）

```
POST   /auth                 - ユーザー登録
POST   /auth/sign_in         - ログイン
DELETE /auth/sign_out        - ログアウト
```

### 案件管理

```
GET    /api/v1/jobs          - 案件一覧（ページネーション・フィルタリング対応）
POST   /api/v1/jobs          - 案件作成
GET    /api/v1/jobs/:uuid    - 案件詳細
PATCH  /api/v1/jobs/:uuid    - 案件更新
DELETE /api/v1/jobs/:uuid    - 案件削除
POST   /api/v1/jobs/:uuid/publish - 案件公開
```

### 提案・契約（予定）

Phase 7.2-7.6 で以下の API を実装予定です：

- Proposals API（7 エンドポイント）
- Contracts API（3 エンドポイント）
- Milestones API（4 エンドポイント）
- Conversations & Messages API（4 エンドポイント）
- Reviews & Transactions API（4 エンドポイント）

完全な API 仕様は[docs/PLAN.md](docs/PLAN.md)を参照してください。

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

| フェーズ      | 状態 | 説明                             |
| ------------- | ---- | -------------------------------- |
| Phase 1-6     | 完了 | 基盤システム（Models, DB 設計）  |
| Phase 7.1     | 完了 | Jobs API（28 tests passing）     |
| Phase 7.2-7.6 | 予定 | Proposals/Contracts/Messages API |
| Frontend 統合 | 予定 | Next.js 画面実装                 |

詳細な実装計画は[docs/PLAN.md](docs/PLAN.md)を参照してください。

## リポジトリ構成

```
music-portfolio-ai/
├── frontend/          # Next.js 15 (App Router, TypeScript)
├── backend/           # Rails 7 API (PostgreSQL, Devise + JWT, RSpec)
├── analyzer/          # Python音源解析CLI（librosa, ffmpeg）
├── docs/              # 設計資料
│   ├── PLAN.md       # DB設計・実装計画
│   └── CLAUDE.md     # 要件定義
└── README.md          # このファイル
```

## このプロジェクトに関するヘルプをどこで得るか

### ドキュメント

- **要件定義**: [CLAUDE.md](CLAUDE.md) - プロジェクトの要件と MVP 仕様
- **DB 設計**: [docs/PLAN.md](docs/PLAN.md) - データベース設計と実装計画
- **ERD**: [docs/er-diagram.puml](docs/er-diagram.puml) - エンティティ関係図

### よくある質問

**Q: ポートが競合します**
A: Frontend を別ポートで起動: `PORT=3001 npm run dev`

**Q: PostgreSQL 接続エラーが出ます**
A: `backend/config/database.yml`で接続情報を確認してください。環境変数でも設定可能です。

**Q: ffmpeg が見つかりません**
A: ffmpeg が PATH に含まれているか確認: `ffmpeg -version`

**Q: テストが失敗します**
A: データベースをリセット: `cd backend && bin/rails db:test:prepare`

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

### 開発方針

- **未知の作業を複数同時にやらない**: 各 Phase を順番に完了
- **テスト駆動**: Model specs → Request specs の順で実装
- **段階的リリース**: Phase 完了ごとに PR 作成・CI 実行・マージ

詳細は[CLAUDE.md](CLAUDE.md)の開発フローを参照してください。

## ライセンス

このプロジェクトは現在ライセンス未設定です。商用利用を検討する場合は、適切なライセンスを追加予定です。

## 謝辞

このプロジェクトは以下のオープンソースプロジェクトに支えられています：

- [Rails](https://rubyonrails.org/) - Web アプリケーションフレームワーク
- [Next.js](https://nextjs.org/) - React フレームワーク
- [librosa](https://librosa.org/) - 音楽・音声解析ライブラリ
- [Devise](https://github.com/heartcombo/devise) - 認証システム

---
