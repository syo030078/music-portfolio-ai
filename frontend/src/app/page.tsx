"use client";

import MusicianCard from "@/components/MusicianCard";
import Link from "next/link";

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
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">
            音楽家を探す
          </h1>
          <p className="text-gray-600">
            プロの音楽家に楽曲制作を依頼できます
          </p>
        </div>

        {/* 音楽家カードグリッド */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {mockMusicians.map((musician) => (
            <MusicianCard key={musician.id} {...musician} />
          ))}
        </div>
      </main>
    </div>
  );
}
