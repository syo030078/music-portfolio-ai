"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

export default function Header() {
  const pathname = usePathname();

  const isActive = (path: string) => {
    return pathname === path;
  };

  return (
    <header className="border-b border-gray-200 bg-white">
      <div className="mx-auto max-w-7xl px-4">
        <div className="flex h-16 items-center justify-between">
          {/* ロゴ */}
          <Link href="/" className="flex items-center space-x-2">
            <div className="text-2xl font-bold text-gray-900">
              Music<span className="text-green-600">Work</span>
            </div>
          </Link>

          {/* ナビゲーション */}
          <nav className="hidden md:flex items-center space-x-8">
            <Link
              href="/jobs"
              className={`text-sm font-medium transition-colors hover:text-green-600 ${
                isActive("/jobs") ? "text-green-600" : "text-gray-700"
              }`}
            >
              案件を探す
            </Link>
            <Link
              href="/"
              className={`text-sm font-medium transition-colors hover:text-green-600 ${
                isActive("/") ? "text-green-600" : "text-gray-700"
              }`}
            >
              音楽家を探す
            </Link>
          </nav>

          {/* アクションボタン */}
          <div className="flex items-center space-x-4">
            <Link
              href="/upload"
              className="rounded-md bg-green-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-green-700"
            >
              楽曲アップロード
            </Link>
          </div>
        </div>
      </div>
    </header>
  );
}
