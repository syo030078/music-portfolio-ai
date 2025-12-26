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
    <div className="min-h-screen bg-white">
      {/* ヒーローセクション */}
      <div className="bg-gradient-to-r from-purple-600 to-blue-600 py-16">
        <div className="mx-auto max-w-7xl px-4">
          <Link
            href="/"
            className="mb-6 inline-flex items-center text-purple-100 hover:text-white"
          >
            ← 音楽家一覧に戻る
          </Link>
          <h1 className="mb-4 text-5xl font-bold text-white">
            {mockMusician.name}
          </h1>
          <p className="mb-4 text-xl text-purple-100">{mockMusician.bio}</p>
          <div className="flex gap-4 text-purple-100">
            <span>得意ジャンル: {mockMusician.genre}</span>
          </div>
        </div>
      </div>

      {/* メインコンテンツ */}
      <main className="mx-auto max-w-7xl px-4 py-12">
        {/* 楽曲一覧セクション */}
        <div>
          <h2 className="mb-8 text-3xl font-bold text-gray-900">登録楽曲</h2>
          <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
            {mockTracks.map((track) => (
              <div
                key={track.id}
                className="overflow-hidden rounded-lg border border-gray-200 bg-white transition-all hover:border-purple-500 hover:shadow-xl"
              >
                <div className="p-6">
                  <h3 className="mb-4 text-xl font-bold text-gray-900">
                    {track.title}
                  </h3>
                  <div className="mb-6 space-y-2 text-sm">
                    <div className="flex justify-between border-b pb-2">
                      <span className="text-gray-600">BPM</span>
                      <span className="font-medium text-gray-900">
                        {track.bpm}
                      </span>
                    </div>
                    <div className="flex justify-between border-b pb-2">
                      <span className="text-gray-600">キー</span>
                      <span className="font-medium text-gray-900">
                        {track.key}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600">ジャンル</span>
                      <span className="font-medium text-gray-900">
                        {track.genre}
                      </span>
                    </div>
                  </div>
                  <button className="w-full rounded-lg bg-purple-600 px-4 py-3 font-semibold text-white transition-colors hover:bg-purple-700">
                    依頼する
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      </main>
    </div>
  );
}
