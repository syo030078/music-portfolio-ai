import { useState, useEffect } from 'react';

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
    const stored = localStorage.getItem('user');
    const token = localStorage.getItem('jwt');
    if (stored && token) {
      try {
        setUser(JSON.parse(stored));
      } catch {
        setUser(null);
      }
    }
  }, []);

  return {
    user,
    isLoggedIn: user !== null,
    isMusician: user?.is_musician === true,
    isClient: user?.is_client === true,
  };
}
