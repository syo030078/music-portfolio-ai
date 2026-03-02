'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';
import DirectRequestForm from '@/components/DirectRequestForm';
import type { MusicianSummary } from '@/types';
import { fetchMusicianByUuid } from '@/lib/api/musicians';

export default function MusicianDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const [musician, setMusician] = useState<MusicianSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [resolvedId, setResolvedId] = useState<string | null>(null);

  useEffect(() => {
    const resolveParams = async () => {
      const { id } = await params;
      setResolvedId(id);
    };
    resolveParams();
  }, [params]);

  useEffect(() => {
    if (!resolvedId) return;

    const load = async () => {
      try {
        const data = await fetchMusicianByUuid(resolvedId);
        setMusician(data);
      } catch (err) {
        setError(err instanceof Error ? err.message : '音楽家の取得に失敗しました');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, [resolvedId]);

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50">
        <div className="bg-gradient-to-r from-green-600 to-green-700 py-16">
          <div className="mx-auto max-w-7xl px-4">
            <div className="h-10 w-48 animate-pulse rounded bg-green-400" />
          </div>
        </div>
        <div className="mx-auto max-w-7xl px-4 py-12">
          <div className="h-64 animate-pulse rounded-lg bg-gray-200" />
        </div>
      </div>
    );
  }

  if (error || !musician) {
    return (
      <div className="min-h-screen bg-gray-50">
        <div className="mx-auto max-w-7xl px-4 py-8">
          <div className="rounded-lg bg-red-50 p-4 text-red-800">
            {error || '音楽家が見つかりません'}
          </div>
          <Link href="/" className="mt-4 inline-block text-green-600 hover:underline">
            ← 音楽家一覧に戻る
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="bg-gradient-to-r from-green-600 to-green-700 py-16">
        <div className="mx-auto max-w-7xl px-4">
          <Link
            href="/"
            className="mb-6 inline-flex items-center text-green-100 hover:text-white"
          >
            ← 音楽家一覧に戻る
          </Link>
          <h1 className="mb-4 text-3xl font-bold text-white md:text-5xl">
            {musician.name}
          </h1>
          {musician.bio && (
            <p className="mb-4 text-lg text-green-100 md:text-xl">{musician.bio}</p>
          )}
          {musician.genres.length > 0 && (
            <div className="flex flex-wrap gap-2">
              {musician.genres.map((g) => (
                <span
                  key={g}
                  className="rounded-full bg-white/20 px-3 py-1 text-sm text-white"
                >
                  {g}
                </span>
              ))}
            </div>
          )}
        </div>
      </div>

      <main className="mx-auto max-w-7xl px-4 py-12">
        <div className="grid grid-cols-1 gap-8 lg:grid-cols-3">
          <div className="lg:col-span-2 space-y-6">
            <div>
              <h2 className="mb-6 text-2xl font-bold text-gray-900">
                登録楽曲（{musician.trackCount}曲）
              </h2>
              {musician.tracks.length === 0 ? (
                <p className="text-gray-500">楽曲はまだ登録されていません</p>
              ) : (
                <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
                  {musician.tracks.map((track) => (
                    <div
                      key={track.uuid}
                      className="overflow-hidden rounded-lg border border-gray-200 bg-white transition-all hover:border-green-500 hover:shadow-lg"
                    >
                      <div className="p-6">
                        <h3 className="mb-4 text-xl font-bold text-gray-900">
                          {track.title}
                        </h3>
                        <div className="space-y-2 text-sm">
                          {track.bpm && (
                            <div className="flex justify-between border-b pb-2">
                              <span className="text-gray-600">BPM</span>
                              <span className="font-medium text-gray-900">{track.bpm}</span>
                            </div>
                          )}
                          {track.key && (
                            <div className="flex justify-between border-b pb-2">
                              <span className="text-gray-600">キー</span>
                              <span className="font-medium text-gray-900">{track.key}</span>
                            </div>
                          )}
                          {track.genre && (
                            <div className="flex justify-between">
                              <span className="text-gray-600">ジャンル</span>
                              <span className="font-medium text-gray-900">{track.genre}</span>
                            </div>
                          )}
                        </div>
                        {track.yt_url && (
                          <a
                            href={track.yt_url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="mt-4 inline-block text-sm text-green-600 hover:underline"
                          >
                            YouTube で聴く →
                          </a>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          <div className="space-y-6">
            <DirectRequestForm
              musicianUuid={musician.uuid}
              musicianName={musician.name}
            />
          </div>
        </div>
      </main>
    </div>
  );
}
