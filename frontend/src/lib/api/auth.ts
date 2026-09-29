import { apiDelete, apiPostPublic } from './client';

export type AuthUser = {
  uuid: string;
  email: string;
  name: string;
  is_musician: boolean;
  is_client: boolean;
};

export type AuthSession = {
  token: string;
  user: AuthUser;
};

export type SignUpParams = {
  email: string;
  password: string;
  name: string;
  is_musician: boolean;
  is_client: boolean;
};

type AuthResponse = {
  token: string | null;
  user: AuthUser;
};

// sign_in / sign_up はどちらも本文に "Bearer ..." 形式の token を含めて返す
function toSession(res: AuthResponse): AuthSession {
  if (!res.token) {
    throw new Error('認証トークンの取得に失敗しました');
  }
  return { token: res.token, user: res.user };
}

export async function signIn(email: string, password: string): Promise<AuthSession> {
  const res = await apiPostPublic<AuthResponse>('/auth/sign_in', { user: { email, password } });
  return toSession(res);
}

export async function signUp(params: SignUpParams): Promise<AuthSession> {
  const res = await apiPostPublic<AuthResponse>('/auth/', { user: params });
  return toSession(res);
}

// JWT を denylist に登録して失効させる（devise.rb の revocation_requests は /auth/sign_out のみ）
export async function signOut(token: string): Promise<void> {
  await apiDelete('/auth/sign_out', token);
}
