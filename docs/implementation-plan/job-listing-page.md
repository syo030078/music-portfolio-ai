# 案件一覧画面・チャット画面の実装とリレーション検証

## 目的

1. **案件一覧画面の実装**: 公開済み案件を表示し、Job → Client リレーションを検証
2. **チャット画面の実装**: メッセージ送受信機能を実装し、Conversation → Participants → Messages リレーションを検証

---

## 実装する機能

### 1. 案件一覧画面

#### 目的
- 公開済み案件の一覧表示
- **Job → Client リレーションの検証**

#### 実装内容

**バックエンドAPI**:
- `GET /api/v1/jobs` - 案件一覧（公開済みのみ）
- `GET /api/v1/jobs/:uuid` - 案件詳細

**フロントエンド**:
- 案件一覧画面 (`/jobs`)
  - カード形式で表示
  - タイトル、説明、予算、リモート可否、依頼者名
  - 詳細ボタン
- 案件詳細画面 (`/jobs/[id]`)
  - 動的ルート（UUID）
  - 全案件情報表示
  - 404ハンドリング

#### 検証項目
- ✅ `job.client.name` で依頼者名を取得できる
- ✅ `.includes(:client)` でN+1問題を防止できる
- ✅ UUID を使った安全なルーティング

#### 実装時間
**2時間**

---

### 2. チャット画面

#### 目的
- メッセージ送受信機能の実装
- **Conversation → ConversationParticipants → Messages リレーションの検証**

#### 実装内容

**バックエンドAPI**:
- `GET /api/v1/conversations` - 会話一覧
- `GET /api/v1/conversations/:id` - 会話詳細（メッセージ含む）
- `POST /api/v1/conversations` - 会話作成
- `POST /api/v1/conversations/:id/messages` - メッセージ送信

**フロントエンド**:
- メッセージ一覧画面 (`/messages`)
  - 参加中の会話一覧
  - 最終メッセージプレビュー
- **チャット画面** (`/messages/[id]`)
  - メッセージ履歴表示
  - **メッセージ送信フォーム** ← 重要
  - 自動スクロール
  - 自分/相手のメッセージ色分け
  - Ctrl+Enter で送信

#### 技術実装
- **Server Component**: データ取得（メッセージ履歴）
- **Client Component**: メッセージ送信フォーム（ChatBox）
- Server/Client Components の適切な分離

#### 検証項目
- ✅ `conversation.participants` で参加者一覧を取得できる
- ✅ `conversation.messages` でメッセージ履歴を取得できる
- ✅ `message.sender` で送信者情報を取得できる
- ✅ `conversation.participant?(user)` で権限チェックができる
- ✅ XOR制約（job_id OR contract_id）が動作する
- ✅ Cascade削除（Job削除時にConversation削除）が動作する

#### 実装時間
**3時間**
- API実装: 1時間
- メッセージ一覧画面: 30分
- チャット画面（Server Component部分）: 30分
- ChatBox Component（Client Component）: 45分
- 動作確認: 15分

---

## 技術スタック

### バックエンド
- Rails 7 API
- PostgreSQL
- Devise認証

### フロントエンド
- Next.js 15 (App Router)
- React 19
- TypeScript
- Tailwind CSS
- **Server Components** + **Client Components**

### 技術的特徴
- Server Components でデータ取得（useEffect不使用）
- UUID公開ID
- N+1問題防止 (`.includes`)
- 認証・権限チェック
- 楽観的UI更新（メッセージ送信後）

---

## 実装ファイル

### バックエンド
**新規作成**:
- `backend/app/controllers/api/v1/jobs_controller.rb`
- `backend/app/controllers/api/v1/conversations_controller.rb`
- `backend/app/controllers/api/v1/messages_controller.rb`

**編集**:
- `backend/config/routes.rb`
- `backend/db/seeds.rb` (テストデータ)

### フロントエンド
**新規作成**:
- `frontend/src/app/jobs/page.tsx` - 案件一覧
- `frontend/src/app/jobs/[id]/page.tsx` - 案件詳細
- `frontend/src/app/messages/page.tsx` - メッセージ一覧
- `frontend/src/app/messages/[id]/page.tsx` - チャット画面（Server Component）
- `frontend/src/app/messages/[id]/ChatBox.tsx` - メッセージ送信フォーム（Client Component）

---

## リレーション検証計画

### Job → Client
```ruby
# backend/app/controllers/api/v1/jobs_controller.rb
jobs = Job.published.includes(:client)  # N+1防止

job_json(job)
  client: { name: job.client.name }  # リレーション動作確認
```

### Conversation → Participants → Messages
```ruby
# backend/app/controllers/api/v1/conversations_controller.rb
conversation = current_user.conversations
  .includes(:participants, :messages)  # N+1防止

# 参加者チェック
conversation.participant?(current_user)

# メッセージ取得
conversation.messages.includes(:sender).order(:created_at)
```

### 検証方法
1. **ブラウザ確認**: 画面で情報が正しく表示されることを確認
2. **Railsログ確認**: N+1クエリが発生していないことを確認
3. **コンソール確認**: リレーションメソッドの動作を確認

---

## 開発フロー（CLAUDE.md準拠）

1. **実装**: 案件一覧 → 案件詳細 → メッセージ一覧 → チャット画面
2. **検証**: ブラウザで動作確認、リレーション動作確認
3. **コミット**: 機能ごとまたは全体で1コミット
4. **PR作成**: GitHub上でプルリクエスト
5. **CI実行**: テスト実行（自動テストは後続で追加）
6. **マージ**: レビュー後にマージ

---

## 成功基準

### 案件一覧画面
- ✅ 公開済み案件が一覧表示される
- ✅ 依頼者名（job.client.name）が表示される
- ✅ 詳細ボタンで詳細画面に遷移できる
- ✅ N+1クエリが発生しない

### チャット画面
- ✅ メッセージ履歴が時系列で表示される
- ✅ メッセージ送信フォームが表示される
- ✅ メッセージを送信できる
- ✅ 送信後、画面に即座に反映される
- ✅ 自分と相手のメッセージが区別される
- ✅ 自動スクロールが動作する
- ✅ Ctrl+Enter で送信できる
- ✅ 参加者のみアクセスできる（権限チェック）

### リレーション検証
- ✅ Job → Client リレーションが動作する
- ✅ Conversation → Participants → Messages リレーションが動作する
- ✅ N+1問題が発生しない
- ✅ XOR制約が動作する
- ✅ Cascade削除が動作する

---

## 次のステップ

1. **計画確認**: この計画でOKか確認
2. **実装開始**: 案件一覧画面から実装
3. **ブラウザ検証**: 各画面の動作確認
4. **リレーション検証**: Railsログでクエリ確認
5. **コミット・PR**: 完了後にコミット・PR作成

---

## 備考

- **認証について**: 現在は環境変数で簡易認証、本番では Cookie/localStorage
- **リアルタイム更新**: 現在は楽観的更新のみ、後続でポーリングまたはWebSocket
- **テスト**: MVPフェーズではブラウザ検証のみ、後続で自動テスト追加
- **ブランチ戦略**: routes.rb/seeds.rb が跨るため1つのPR、次回以降は機能ごとにブランチ分割
