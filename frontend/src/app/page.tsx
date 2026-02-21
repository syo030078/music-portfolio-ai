"use client";

import MusicianCard from "@/components/MusicianCard";

// モックデータ（後でAPI接続）
const mockMusicians = [
  {
    id: 1,
    name: "田中 太郎",
    bio: "ロック・ポップス専門の作曲家。10年以上の制作実績があります。",
    genre: "Rock, Pop",
    trackCount: 15,
  },
  {
    id: 2,
    name: "佐藤 花子",
    bio: "エレクトロニック・アンビエント音楽を得意としています。",
    genre: "Electronic, Ambient",
    trackCount: 23,
  },
  {
    id: 3,
    name: "鈴木 一郎",
    bio: "ジャズ・フュージョンを中心に活動。企業CM音楽多数。",
    genre: "Jazz, Fusion",
    trackCount: 31,
  },
  {
    id: 4,
    name: "高橋 美咲",
    bio: "アコースティック・フォーク音楽が専門です。",
    genre: "Acoustic, Folk",
    trackCount: 12,
  },
  {
    id: 5,
    name: "伊藤 健太",
    bio: "Hip-Hop・R&Bトラック制作。ビートメイカーとして活動中。",
    genre: "Hip-Hop, R&B",
    trackCount: 27,
  },
  {
    id: 6,
    name: "渡辺 さくら",
    bio: "クラシック・オーケストラ編曲を得意としています。",
    genre: "Classical, Orchestral",
    trackCount: 8,
  },
];

export default function HomePage() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* ヒーローセクション */}
      <div className="bg-gradient-to-r from-purple-600 to-blue-600 py-16">
        <div className="mx-auto max-w-7xl px-4">
          <h1 className="mb-4 text-3xl font-bold text-white md:text-5xl">
            プロの音楽家を見つけよう
          </h1>
          <p className="text-lg text-purple-100 md:text-xl">
            あなたのプロジェクトにぴったりの音楽家がここにいます
          </p>
        </div>
      </div>

      {/* メインコンテンツ */}
      <main className="mx-auto max-w-7xl px-4 py-12">
        <div className="mb-8">
          <h2 className="mb-2 text-2xl font-bold text-gray-900">
            おすすめの音楽家
          </h2>
          <p className="text-gray-600">
            {mockMusicians.length}人の音楽家が登録しています
          </p>
        </div>

        {/* 音楽家カードグリッド */}
        <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
          {mockMusicians.map((musician) => (
            <MusicianCard key={musician.id} {...musician} />
          ))}
        </div>
      </main>
    </div>
  );
}
