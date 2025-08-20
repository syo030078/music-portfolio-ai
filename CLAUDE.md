# 🎯 1️⃣ MVPフェーズ：要件定義（ユーザー側のみ）

## 1. サービス概要（MVP）
音楽家が自作曲（YouTubeリンク）を登録し、AI（librosa, GPT-4）で楽曲解析（BPM、キー、ジャンル）と紹介文生成を行い、自動でポートフォリオを作成。
SNSシェア機能や制作依頼機能を備え、音楽家の作品発表と収益化をサポートする。

---

## 2. ユーザーストーリー（MVP）

| ID  | ストーリー |
|-----|-------------|
| US1 | ユーザーはアカウント登録（メール or GitHub OAuth）し、ログインできる。 |
| US2 | 自作曲のYouTubeリンクを登録し、AIでBPM・キー・ジャンルを解析できる。 |
| US3 | AIによる楽曲紹介文（PR文）とSNS投稿文を生成できる。 |
| US4 | 自分のポートフォリオページで楽曲を一覧表示できる。 |
| US5 | 制作依頼（依頼者→音楽家）を作成・受け取れる（簡易チャット機能含む）。 |
| US6 | 楽曲やポートフォリオをSNSでシェアできる。 |

---

## 3. 機能要件（MVP）

### A. ユーザー管理
- メール認証 or GitHub OAuth  
- ログイン・ログアウト  
- ユーザー情報（名前、自己紹介）  

### B. 楽曲管理
- YouTubeリンク登録  
- Python（yt-dlp）で音源DL  
- librosaでBPM・キー・ジャンル解析  
- GPT-4で楽曲紹介文生成  
- 楽曲詳細画面（解析結果、AI生成テキスト）  
- ポートフォリオ（曲一覧）  
- SNSシェア（X API、Instagram URLコピー）  

### C. 制作依頼
- 依頼フォーム（依頼内容、予算、納期）  
- 依頼ステータス（pending, accepted, done）  
- 依頼詳細（簡易チャット）  

---

## 4. データモデル（MVP）

- **users**（id, email, password_digest, provider, uid, name, bio）  
- **tracks**（id, user_id, title, description, yt_url, bpm, key, genre, ai_text）  
- **commissions**（id, user_id, track_id, description, budget, status）  
- **messages**（id, commission_id, sender_id, content）  

---

## 5. 技術要件（MVP）

| 項目 | 技術 |
|------|------|
| フロント | Next.js, React, TypeScript |
| バックエンド | Rails（APIモード） |
| AI解析 | Python（yt-dlp, librosa） |
| AIテキスト生成 | GPT-4（OpenAI API） |
| インフラ | AWS EC2（docker-compose）、Terraform |
| CI/CD | GitHub Actions（テスト・ビルド・デプロイ） |
| ストレージ | ローカル or EC2（解析後削除） |
| SNS連携 | X API、Instagram URLコピー |

---

## 6. ビジネス要件（MVP）

- 制作依頼手数料：依頼成立時に10%手数料課金  

---

# 🚀 2️⃣ 最終フェーズ：要件定義（完成版）

## 1. サービス概要（最終版）
MVP機能に加え、管理画面、BGM販売、ニュース機能、詳細なAI分析、SNS自動投稿、広告収益、サブスク機能を含む、音楽家のブランド力向上と収益化を総合的に支援するプラットフォーム。

---

## 2. ユーザーストーリー（最終版）

| ID  | ストーリー |
|-----|-------------|
| US1〜US6 | （MVP機能そのまま） |
| US7 | 管理者は全ユーザー・楽曲・依頼を管理できる（管理画面） |
| US8 | 音楽家は自作曲をBGMとしてライセンス販売できる（マーケット機能） |
| US9 | AI自動生成ニュースでジャンル別トレンドを把握し、制作のヒントを得る。 |
| US10 | 企業はBGM検索や音楽家マッチングAPIを利用できる（B2B展開）。 |
| US11 | プレミアムユーザーはSNS自動投稿、収益分析、AI詳細解析機能を利用できる。 |

---

## 3. 機能要件（最終版）

### A. 管理画面
- rails_admin / ActiveAdmin導入  
- ユーザー管理（BAN、編集）  
- 楽曲管理（削除・通報対応）  
- 依頼管理（荒らし・迷惑対策）  

### B. BGM販売
- 楽曲の価格設定  
- 購入決済（Stripe）  
- 購入者管理、納品管理  

### C. AIニュース機能
- RSSフィードクローラー（外部ニュース取得）  
- GPT-4で要約・タグ付け  
- ニュース一覧・詳細・お気に入り  

### D. SNS自動投稿
- X APIで定期投稿  
- Instagram API（またはSNS URL共有）  

### E. 企業向けAPI
- 楽曲検索API  
- 制作依頼マッチングAPI  

### F. プレミアムプラン
- 月額課金（AI詳細解析、SNS自動投稿、優先マッチング）  

---

## 4. データモデル（最終版）

MVPモデルに加え：
- **roles**（管理者ロール管理）  
- **bgm_sales**（販売情報）  
- **news**（ニュース記事）  
- **user_subscriptions**（サブスクプラン管理）  
- **tags**（ジャンル・ムード）  
- **favorites**（お気に入り）  
- **likes**（いいね）  

---

## 5. 技術要件（最終版）

| 項目 | 技術 |
|------|------|
| 管理画面 | rails_admin / ActiveAdmin |
| 決済 | Stripe |
| サブスク | Stripe + Webhook |
| AIニュース | Python（RSS, GPT-4） |
| SNS自動投稿 | X API、Instagram API |
| B2B API | Rails API with Token認証 |
| ストレージ | S3（音源保管）、CloudFront（配信） |

---

## 6. ビジネス要件（最終版）

- 制作依頼手数料：10%課金  
- BGM販売：売上の20%課金  
- サブスク：月額980円〜  
- 広告：ニュースページ広告（Google AdSense想定）  
- 企業向けAPI：月額課金 or 案件単位課金  

---

# ✅ 結論
- まずは「ユーザー側のみのMVP」を完成させて実証  
- その後、管理画面・BGM販売・ニュース機能・サブスクなどを段階的に拡張  
- データモデルやロール設計は将来を見据えて拡張性を持たせておく  
