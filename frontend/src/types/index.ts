/**
 * User型定義
 */
export type User = {
  id: number;
  email: string;
  name: string;
  bio?: string;
};

/**
 * Track型定義
 */
export type Track = {
  id: number;
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
 * APIエラーレスポンス型
 */
export type ApiErrorResponse = {
  error: string;
};
