/**
 * User型定義
 */
export type User = {
  uuid: string;
  email: string;
  name: string;
  bio?: string;
};

/**
 * Track型定義
 */
export type Track = {
  uuid: string;
  title: string;
  description?: string;
  yt_url: string;
  bpm?: number;
  key?: string;
  genre?: string;
  ai_text?: string;
  created_at: string;
  updated_at?: string;
  user: User;
};

/**
 * Job型定義
 */
export type Job = {
  uuid: string;
  title: string;
  description: string;
  budget_jpy?: number;
  budget_min_jpy?: number;
  budget_max_jpy?: number;
  is_remote?: boolean;
  delivery_due_on?: string;
  published_at?: string;
  created_at?: string;
  client: {
    uuid: string;
    name: string;
    bio?: string;
  };
};

/**
 * Message型定義
 */
export type Message = {
  uuid: string;
  sender_uuid: string;
  sender_name: string;
  content: string;
  created_at: string;
};

/**
 * Conversation型定義
 */
export type Conversation = {
  uuid: string;
  job_uuid?: string;
  contract_uuid?: string;
  created_at: string;
  updated_at?: string;
  participants: {
    uuid: string;
    name: string;
    bio?: string;
  }[];
  messages?: Message[];
  last_message?: {
    uuid: string;
    content: string;
    sender_uuid: string;
    created_at: string;
  };
  unread_count?: number;
};

/**
 * Tracks一覧取得APIのレスポンス型
 */
export type TracksListResponse = {
  tracks: Track[];
  pagination: {
    current_page: number;
    total_pages: number;
    total_count: number;
    per_page: number;
  };
};

/**
 * Track詳細取得APIのレスポンス型
 */
export type TrackDetailResponse = {
  track: Track;
};

/**
 * Jobs一覧取得APIのレスポンス型
 */
export type JobsListResponse = {
  jobs: Job[];
};

/**
 * Job詳細取得APIのレスポンス型
 */
export type JobDetailResponse = {
  job: Job;
};

/**
 * Conversations一覧取得APIのレスポンス型
 */
export type ConversationsListResponse = {
  conversations: Conversation[];
};

/**
 * Conversation詳細取得APIのレスポンス型
 */
export type ConversationDetailResponse = {
  conversation: Conversation;
};

/**
 * 音楽家サマリー型（Tracks APIから導出）
 */
export type MusicianSummary = {
  uuid: string;
  name: string;
  bio: string | null;
  trackCount: number;
  genres: string[];
  tracks: Track[];
};

/**
 * 制作依頼型
 */
export type DirectRequest = {
  uuid: string;
  title: string;
  description: string;
  budget_jpy: number;
  delivery_days: number;
  status: 'pending' | 'accepted' | 'rejected';
  created_at: string;
  musician: {
    uuid: string;
    name: string;
  };
  client: {
    uuid: string;
    name: string;
  };
};

/**
 * 制作依頼作成ペイロード型
 */
export type DirectRequestCreatePayload = {
  musician_uuid: string;
  title: string;
  description: string;
  budget_jpy: number;
  delivery_days: number;
};

/**
 * DirectRequests一覧取得APIのレスポンス型
 */
export type DirectRequestsListResponse = {
  production_requests: DirectRequest[];
};

/**
 * DirectRequest詳細APIのレスポンス型
 */
export type DirectRequestDetailResponse = {
  production_request: DirectRequest;
  conversation_uuid?: string;
};

/**
 * APIエラーレスポンス型
 */
export type ApiErrorResponse = {
  error: string;
};
