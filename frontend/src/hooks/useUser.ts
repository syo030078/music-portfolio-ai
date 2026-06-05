import { useState, useEffect } from 'react';
import { getToken, getStoredUser } from '@/lib/auth';

interface UserInfo {
  readonly uuid: string;
  readonly name: string;
  readonly is_musician?: boolean;
  readonly is_client?: boolean;
}

interface UseUserResult {
  readonly user: UserInfo | null;
  readonly isLoggedIn: boolean;
  readonly isMusician: boolean;
  readonly isClient: boolean;
}

export function useUser(): UseUserResult {
  const [user, setUser] = useState<UserInfo | null>(null);

  useEffect(() => {
    const token = getToken();
    if (!token) return;
    setUser(getStoredUser<UserInfo>());
  }, []);

  return {
    user,
    isLoggedIn: user !== null,
    isMusician: user?.is_musician === true,
    isClient: user?.is_client === true,
  };
}
