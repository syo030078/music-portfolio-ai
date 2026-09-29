import { handleSessionExpired } from '../auth';

// SSR (Server Component) では相対パスが使えないため、サーバー内部URLを使用
// ブラウザ (Client Component) では空文字 → 相対パス → nginx/rewrites がプロキシ
const API_URL =
  typeof window === 'undefined'
    ? (process.env.API_INTERNAL_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000')
    : (process.env.NEXT_PUBLIC_API_URL || '');

// JSON 以外（nginx の 413/502/504 HTML ページなど）は本文を画面に出さず、ステータスから文言を決める
async function parseResponse<T>(res: Response): Promise<T> {
  const text = await res.text();
  try {
    return JSON.parse(text) as T;
  } catch {
    if (res.status === 413) {
      throw new Error('ファイルサイズが大きすぎます');
    }
    throw new Error(`リクエストに失敗しました (${res.status})`);
  }
}

type RequestOptions = {
  // ログイン前のリクエスト（sign_in 等）では 401 = 認証失敗なので、セッション切れ扱いにしない
  handleUnauthorized?: boolean;
};

// 全リクエスト共通: 401 → セッション切れ処理、エラー時はサーバーの error / errors を例外メッセージにする
async function request<T>(
  path: string,
  init: RequestInit,
  { handleUnauthorized = true }: RequestOptions = {},
): Promise<T> {
  const res = await fetch(`${API_URL}${path}`, init).catch(() => {
    throw new Error('ネットワークエラーが発生しました');
  });

  if (res.status === 401 && handleUnauthorized) {
    handleSessionExpired();
    throw new Error('ログインセッションが切れました。再度ログインしてください');
  }

  if (res.status === 204) {
    return undefined as T;
  }

  const data = await parseResponse<T & { error?: string; errors?: string[] }>(res);

  if (!res.ok) {
    const message = data.error || data.errors?.join(', ') || `リクエストに失敗しました (${res.status})`;
    throw new Error(message);
  }

  return data;
}

export async function apiGet<T>(path: string, token?: string): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };
  if (token) {
    headers.Authorization = token;
  }

  return request<T>(path, { cache: 'no-store', headers });
}

export async function apiPost<T>(path: string, token: string, body?: unknown): Promise<T> {
  return request<T>(path, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: token,
    },
    body: body ? JSON.stringify(body) : undefined,
  });
}

// 未ログイン状態で送るリクエスト用（sign_in / sign_up）
export async function apiPostPublic<T>(path: string, body: unknown): Promise<T> {
  return request<T>(
    path,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify(body),
    },
    { handleUnauthorized: false },
  );
}

export async function apiDelete<T = void>(path: string, token: string): Promise<T> {
  return request<T>(path, {
    method: 'DELETE',
    headers: { Authorization: token, Accept: 'application/json' },
  });
}

// multipart/form-data 送信用。Content-Type はブラウザが boundary 付きで設定するため指定しない
export async function apiPostForm<T>(path: string, token: string, formData: FormData): Promise<T> {
  return request<T>(path, {
    method: 'POST',
    headers: { Authorization: token },
    body: formData,
  });
}
