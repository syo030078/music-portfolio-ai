"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useState } from "react";

interface UserInfo {
  uuid: string;
  name: string;
  is_musician?: boolean;
  is_client?: boolean;
}

export default function Header() {
  const pathname = usePathname();
  const router = useRouter();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [user, setUser] = useState<UserInfo | null>(null);

  useEffect(() => {
    const stored = localStorage.getItem("user");
    const token = localStorage.getItem("jwt");
    if (stored && token) {
      try {
        setUser(JSON.parse(stored));
      } catch {
        setUser(null);
      }
    } else {
      setUser(null);
    }
  }, [pathname]);

  const handleLogout = async () => {
    const token = localStorage.getItem("jwt");
    const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "";

    try {
      await fetch(`${API_BASE_URL}/auth/sign_in`, {
        method: "DELETE",
        headers: {
          Authorization: token || "",
          Accept: "application/json",
        },
      });
    } catch {
      // ログアウトAPIが失敗してもローカルはクリアする
    }

    localStorage.removeItem("jwt");
    localStorage.removeItem("user");
    setUser(null);
    router.push("/");
  };

  const isActive = (path: string) => {
    return pathname === path;
  };

  const publicNavLinks = [
    { href: "/jobs", label: "案件を探す" },
    { href: "/", label: "音楽家を探す" },
  ];

  const authNavLinks = [
    { href: "/messages", label: "メッセージ" },
    { href: "/requests", label: "依頼管理" },
  ];

  const navLinks = user ? [...publicNavLinks, ...authNavLinks] : publicNavLinks;

  return (
    <header className="border-b border-gray-200 bg-white">
      <div className="mx-auto max-w-7xl px-4">
        <div className="flex h-16 items-center justify-between">
          <Link href="/" className="flex items-center space-x-2">
            <div className="text-2xl font-bold text-gray-900">
              Music<span className="text-green-600">Work</span>
            </div>
          </Link>

          <nav className="hidden md:flex items-center space-x-8">
            {navLinks.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                className={`text-sm font-medium transition-colors hover:text-green-600 ${
                  isActive(link.href) ? "text-green-600" : "text-gray-700"
                }`}
              >
                {link.label}
              </Link>
            ))}
          </nav>

          <div className="flex items-center space-x-4">
            {user ? (
              <>
                {user.is_musician && (
                  <Link
                    href="/upload"
                    className="hidden sm:inline-block rounded-md bg-green-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-green-700"
                  >
                    楽曲アップロード
                  </Link>
                )}
                <span className="hidden sm:inline-block text-sm text-gray-700">
                  {user.name}
                </span>
                <button
                  type="button"
                  onClick={handleLogout}
                  className="hidden sm:inline-block rounded-md border border-gray-300 px-3 py-1.5 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50"
                >
                  ログアウト
                </button>
              </>
            ) : (
              <>
                <Link
                  href="/login"
                  className="hidden sm:inline-block text-sm font-medium text-gray-700 transition-colors hover:text-green-600"
                >
                  ログイン
                </Link>
                <Link
                  href="/signup"
                  className="hidden sm:inline-block rounded-md bg-green-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-green-700"
                >
                  新規登録
                </Link>
              </>
            )}

            <button
              type="button"
              className="md:hidden p-2 text-gray-700 hover:text-green-600"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              aria-label="メニューを開く"
            >
              {mobileMenuOpen ? (
                <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              ) : (
                <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
                </svg>
              )}
            </button>
          </div>
        </div>
      </div>

      {mobileMenuOpen && (
        <div className="border-t border-gray-200 bg-white md:hidden">
          <nav className="mx-auto max-w-7xl px-4 py-4 space-y-3">
            {navLinks.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                onClick={() => setMobileMenuOpen(false)}
                className={`block text-sm font-medium transition-colors hover:text-green-600 ${
                  isActive(link.href) ? "text-green-600" : "text-gray-700"
                }`}
              >
                {link.label}
              </Link>
            ))}
            {user ? (
              <>
                {user.is_musician && (
                  <Link
                    href="/upload"
                    onClick={() => setMobileMenuOpen(false)}
                    className="block rounded-md bg-green-600 px-4 py-2 text-center text-sm font-medium text-white transition-colors hover:bg-green-700"
                  >
                    楽曲アップロード
                  </Link>
                )}
                <div className="pt-2 border-t border-gray-200">
                  <span className="block text-sm text-gray-700 mb-2">{user.name}</span>
                  <button
                    type="button"
                    onClick={() => {
                      setMobileMenuOpen(false);
                      handleLogout();
                    }}
                    className="block w-full rounded-md border border-gray-300 px-4 py-2 text-center text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50"
                  >
                    ログアウト
                  </button>
                </div>
              </>
            ) : (
              <div className="pt-2 border-t border-gray-200 space-y-2">
                <Link
                  href="/login"
                  onClick={() => setMobileMenuOpen(false)}
                  className="block rounded-md border border-gray-300 px-4 py-2 text-center text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50"
                >
                  ログイン
                </Link>
                <Link
                  href="/signup"
                  onClick={() => setMobileMenuOpen(false)}
                  className="block rounded-md bg-green-600 px-4 py-2 text-center text-sm font-medium text-white transition-colors hover:bg-green-700"
                >
                  新規登録
                </Link>
              </div>
            )}
          </nav>
        </div>
      )}
    </header>
  );
}
