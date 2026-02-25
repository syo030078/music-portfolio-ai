const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

async function parseResponse<T>(res: Response): Promise<T> {
  const text = await res.text();
  try {
    return JSON.parse(text) as T;
  } catch {
    if (text) {
      throw new Error(text);
    }
    throw new Error(`リクエストに失敗しました (${res.status})`);
  }
}

export async function apiGet<T>(path: string, token?: string): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };
  if (token) {
    headers.Authorization = token;
  }

  const res = await fetch(`${API_URL}${path}`, {
    cache: 'no-store',
    headers,
  });

  if (res.status === 401) {
    throw new Error('ログインセッションが切れました。再度ログインしてください');
  }

  const data = await parseResponse<T & { error?: string; errors?: string[] }>(res);

  if (!res.ok) {
    const message = data.error || data.errors?.join(', ') || `リクエストに失敗しました (${res.status})`;
    throw new Error(message);
  }

  return data;
}

export async function apiPost<T>(path: string, token: string, body?: unknown): Promise<T> {
  const res = await fetch(`${API_URL}${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: token,
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  if (res.status === 401) {
    throw new Error('ログインセッションが切れました。再度ログインしてください');
  }

  const data = await parseResponse<T & { error?: string; errors?: string[] }>(res);

  if (!res.ok) {
    const message = data.error || data.errors?.join(', ') || `リクエストに失敗しました (${res.status})`;
    throw new Error(message);
  }

  return data;
}
