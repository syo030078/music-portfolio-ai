"use client";

import Link from "next/link";
import { useState } from "react";
import { apiPost } from "@/lib/api/client";

type MatchResult = {
  readonly track_uuid: string;
  readonly title: string;
  readonly score: number;
  readonly reason: string;
  readonly bpm?: number;
  readonly key?: string;
  readonly genre?: string;
  readonly ai_text?: string;
  readonly musician: {
    readonly uuid: string;
    readonly name: string;
  };
};

export default function MatchingPage() {
  const [query, setQuery] = useState("");
  const [matches, setMatches] = useState<readonly MatchResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [searched, setSearched] = useState(false);

  const handleSearch = async () => {
    if (!query.trim()) return;

    setLoading(true);
    setError(null);
    setSearched(true);
    try {
      const data = await apiPost<{ matches: MatchResult[] }>(
        "/api/v1/matching",
        "",
        { query: query.trim() }
      );
      setMatches(data.matches);
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "マッチングに失敗しました"
      );
      setMatches([]);
    } finally {
      setLoading(false);
    }
  };

  const scoreColor = (score: number) => {
    if (score >= 80) return "bg-green-100 text-green-800";
    if (score >= 60) return "bg-yellow-100 text-yellow-800";
    return "bg-gray-100 text-gray-800";
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="bg-gradient-to-r from-green-600 to-green-700 py-12">
        <div className="mx-auto max-w-7xl px-4">
          <h1 className="text-2xl font-bold text-white mb-2 md:text-4xl">
            AIマッチング
          </h1>
          <p className="text-green-100 text-base md:text-lg">
            あなたのプロジェクトに最適な楽曲をAIが提案します
          </p>
        </div>
      </div>

      <main className="mx-auto max-w-7xl px-4 py-12">
        <div className="bg-white rounded-lg shadow-md p-8 mb-8">
          <h2 className="text-xl font-bold text-gray-900 mb-4">
            どんな音楽をお探しですか？
          </h2>
          <p className="text-sm text-gray-500 mb-4">
            自然な言葉で要望を入力してください（例：「明るいポップスで企業VP向け」「カフェで流れるような落ち着いたジャズ」）
          </p>
          <textarea
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="例：明るくてテンポの良いポップス。YouTubeの商品紹介動画のBGMに使いたい。"
            className="w-full rounded-lg border border-gray-300 px-4 py-3 text-sm focus:border-green-500 focus:ring-2 focus:ring-green-500 focus:outline-none"
            rows={3}
          />
          <button
            onClick={handleSearch}
            disabled={loading || !query.trim()}
            className="mt-4 w-full rounded-lg bg-green-600 px-6 py-3 text-sm font-semibold text-white transition-colors hover:bg-green-700 disabled:opacity-50"
          >
            {loading ? (
              <span className="inline-flex items-center gap-2">
                <svg
                  className="h-4 w-4 animate-spin"
                  fill="none"
                  viewBox="0 0 24 24"
                >
                  <circle
                    className="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    strokeWidth="4"
                  />
                  <path
                    className="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
                  />
                </svg>
                AIが分析中...
              </span>
            ) : (
              "AIで楽曲を探す"
            )}
          </button>
        </div>

        {error && (
          <div className="mb-8 rounded-lg bg-red-50 p-4 text-sm text-red-800">
            {error}
          </div>
        )}

        {searched && !loading && matches.length === 0 && !error && (
          <div className="mb-8 rounded-lg bg-gray-100 p-8 text-center text-gray-500">
            条件に合う楽曲が見つかりませんでした。別の表現で試してみてください。
          </div>
        )}

        {matches.length > 0 && (
          <div>
            <h2 className="text-xl font-bold text-gray-900 mb-6">
              おすすめ楽曲（{matches.length}件）
            </h2>
            <div className="space-y-4">
              {matches.map((match) => (
                <div
                  key={match.track_uuid}
                  className="rounded-lg border border-gray-200 bg-white p-6 transition-all hover:border-green-500 hover:shadow-lg"
                >
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        <h3 className="text-lg font-bold text-gray-900">
                          {match.title}
                        </h3>
                        <span
                          className={`rounded-full px-2.5 py-0.5 text-xs font-semibold ${scoreColor(match.score)}`}
                        >
                          {match.score}%
                        </span>
                      </div>
                      <p className="text-sm text-gray-600 mb-3">
                        {match.reason}
                      </p>
                      <div className="flex flex-wrap gap-3 text-xs text-gray-500">
                        {match.bpm && <span>BPM: {match.bpm}</span>}
                        {match.key && <span>Key: {match.key}</span>}
                        {match.genre && <span>{match.genre}</span>}
                        <span>by {match.musician.name}</span>
                      </div>
                      {match.ai_text && (
                        <div className="mt-3 rounded-lg bg-purple-50 p-2.5">
                          <p className="text-xs text-gray-600">
                            {match.ai_text}
                          </p>
                        </div>
                      )}
                    </div>
                    <Link
                      href={`/musicians/${match.musician.uuid}`}
                      className="shrink-0 rounded-md bg-green-50 px-3 py-1.5 text-xs font-medium text-green-700 transition-colors hover:bg-green-100"
                    >
                      詳細を見る
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
