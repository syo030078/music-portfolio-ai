'use client';

import { useEffect, useState } from 'react';
import MusicianCard from '@/components/MusicianCard';
import type { MusicianSummary } from '@/types';
import { fetchMusicians } from '@/lib/api/musicians';

export default function HomePage() {
  const [musicians, setMusicians] = useState<MusicianSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const load = async () => {
      try {
        const data = await fetchMusicians();
        setMusicians(data);
      } catch (err) {
        setError(err instanceof Error ? err.message : '音楽家の取得に失敗しました');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  return (
    <div className="min-h-screen bg-gray-50">
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

      <main className="mx-auto max-w-7xl px-4 py-12">
        <div className="mb-8">
          <h2 className="mb-2 text-2xl font-bold text-gray-900">
            おすすめの音楽家
          </h2>
          {!loading && !error && (
            <p className="text-gray-600">
              {musicians.length}人の音楽家が登録しています
            </p>
          )}
        </div>

        {loading && (
          <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
            {[1, 2, 3].map((i) => (
              <div key={i} className="h-80 animate-pulse rounded-lg bg-gray-200" />
            ))}
          </div>
        )}

        {error && (
          <div className="rounded-lg bg-red-50 p-4 text-red-800">{error}</div>
        )}

        {!loading && !error && musicians.length === 0 && (
          <div className="text-center py-12">
            <p className="text-gray-500">登録されている音楽家はまだいません</p>
          </div>
        )}

        {!loading && !error && musicians.length > 0 && (
          <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
            {musicians.map((musician) => (
              <MusicianCard
                key={musician.uuid}
                uuid={musician.uuid}
                name={musician.name}
                bio={musician.bio}
                genres={musician.genres}
                trackCount={musician.trackCount}
              />
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
