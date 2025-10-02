"use client";

import Link from "next/link";

// モックデータ
const mockMusician = {
  id: 1,
  name: "田中 太郎",
  bio: "ロック・ポップス専門の作曲家。10年以上の制作実績があります。企業CM、ゲーム音楽、YouTubeコンテンツなど幅広く対応可能です。",
  genre: "Rock, Pop",
  email: "tanaka@example.com",
};

const mockTracks = [
  {
    id: 1,
    title: "Summer Breeze",
    bpm: 128,
    key: "C Major",
    genre: "Pop",
  },
  {
    id: 2,
    title: "Night Drive",
    bpm: 95,
    key: "A Minor",
    genre: "Rock",
  },
  {
    id: 3,
    title: "City Lights",
    bpm: 110,
    key: "G Major",
    genre: "Electronic Pop",
  },
];

export default function MusicianDetailPage() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* ヘッダー */}
      <header className="bg-white border-b border-gray-200">
        <nav className="max-w-7xl mx-auto px-4 py-4 flex items-center justify-between">
          <Link href="/" className="text-2xl font-bold text-gray-900">
            Music Portfolio
          </Link>
          <Link
            href="/upload"
            className="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded-lg transition-colors duration-200"
          >
            楽曲アップロード
          </Link>
        </nav>
      </header>

      {/* メインコンテンツ */}
      <main className="max-w-7xl mx-auto px-4 py-12">
        <Link
          href="/"
          className="inline-flex items-center text-blue-500 hover:text-blue-600 mb-6"
        >
          ← 音楽家一覧に戻る
        </Link>

        {/* プロフィールセクション */}
        <div className="bg-white rounded-2xl p-8 mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-4">
            {mockMusician.name}
          </h1>
          <p className="text-gray-600 mb-4">{mockMusician.bio}</p>
          <div className="flex gap-4 text-sm text-gray-500">
            <span>得意ジャンル: {mockMusician.genre}</span>
          </div>
        </div>

        {/* 楽曲一覧セクション */}
        <div>
          <h2 className="text-2xl font-bold text-gray-900 mb-6">登録楽曲</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {mockTracks.map((track) => (
              <div
                key={track.id}
                className="bg-white rounded-2xl p-6 hover:shadow-lg transition-shadow duration-200"
              >
                <h3 className="text-xl font-bold text-gray-900 mb-3">
                  {track.title}
                </h3>
                <div className="space-y-2 text-sm text-gray-600 mb-4">
                  <div className="flex justify-between">
                    <span>BPM:</span>
                    <span className="font-medium">{track.bpm}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>キー:</span>
                    <span className="font-medium">{track.key}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>ジャンル:</span>
                    <span className="font-medium">{track.genre}</span>
                  </div>
                </div>
                <button className="w-full bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded-lg transition-colors duration-200">
                  依頼する
                </button>
              </div>
            ))}
          </div>
        </div>
      </main>
    </div>
  );
}
