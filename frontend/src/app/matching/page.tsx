"use client";

import Link from "next/link";

export default function MatchingPage() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* ヘッダー */}
      <header className="bg-white border-b border-gray-200">
        <nav className="max-w-7xl mx-auto px-4 py-4 flex items-center justify-between">
          <Link href="/" className="text-2xl font-bold text-gray-900">
            Music Portfolio
          </Link>
          <div className="flex gap-4">
            <Link
              href="/"
              className="text-gray-600 hover:text-gray-900 px-4 py-2"
            >
              音楽家向け
            </Link>
            <Link
              href="/matching"
              className="text-blue-600 font-semibold px-4 py-2"
            >
              企業向け
            </Link>
          </div>
        </nav>
      </header>

      {/* メインコンテンツ */}
      <main className="max-w-7xl mx-auto px-4 py-12">
        <div className="mb-12 text-center">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            音楽家マッチング支援
          </h1>
          <p className="text-xl text-gray-600">
            あなたのプロジェクトに最適な音楽家を見つけます
          </p>
        </div>

        {/* 検索セクション */}
        <div className="bg-white rounded-lg shadow-md p-8 mb-8">
          <h2 className="text-2xl font-bold text-gray-900 mb-6">
            音楽家を検索
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                ジャンル
              </label>
              <select className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                <option value="">すべて</option>
                <option value="rock">Rock</option>
                <option value="pop">Pop</option>
                <option value="electronic">Electronic</option>
                <option value="jazz">Jazz</option>
                <option value="classical">Classical</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                予算
              </label>
              <select className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                <option value="">指定なし</option>
                <option value="low">〜5万円</option>
                <option value="medium">5万円〜20万円</option>
                <option value="high">20万円〜</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                実績
              </label>
              <select className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                <option value="">指定なし</option>
                <option value="beginner">〜10曲</option>
                <option value="intermediate">10〜30曲</option>
                <option value="expert">30曲〜</option>
              </select>
            </div>
          </div>
          <button className="mt-6 w-full bg-blue-500 hover:bg-blue-600 text-white font-semibold py-3 rounded-lg transition-colors duration-200">
            検索する
          </button>
        </div>
      </main>
    </div>
  );
}
