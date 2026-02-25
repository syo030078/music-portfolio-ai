'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import DirectRequestCard from '@/components/DirectRequestCard';
import type { DirectRequest } from '@/types';
import { fetchDirectRequests } from '@/lib/api/directRequests';

export default function RequestsPage() {
  const router = useRouter();
  const [requests, setRequests] = useState<DirectRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [currentUserUuid, setCurrentUserUuid] = useState<string | null>(null);

  useEffect(() => {
    const token = localStorage.getItem('jwt');
    const userStr = localStorage.getItem('user');

    if (!token || !userStr) {
      setError('ログインしてください');
      setLoading(false);
      return;
    }

    try {
      const user = JSON.parse(userStr);
      setCurrentUserUuid(user.uuid);
    } catch {
      setError('ユーザー情報の取得に失敗しました');
      setLoading(false);
      return;
    }

    const load = async () => {
      try {
        const data = await fetchDirectRequests(token);
        setRequests(data);
      } catch (err) {
        setError(err instanceof Error ? err.message : '依頼一覧の取得に失敗しました');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  const handleAccepted = (requestUuid: string, conversationUuid: string) => {
    setRequests((prev) =>
      prev.map((r) =>
        r.uuid === requestUuid ? { ...r, status: 'accepted' as const } : r
      )
    );
    router.push(`/messages/${conversationUuid}`);
  };

  const handleRejected = (uuid: string) => {
    setRequests((prev) =>
      prev.map((r) =>
        r.uuid === uuid ? { ...r, status: 'rejected' as const } : r
      )
    );
  };

  const sentRequests = requests.filter(
    (r) => r.client.uuid === currentUserUuid
  );
  const receivedRequests = requests.filter(
    (r) => r.musician.uuid === currentUserUuid
  );

  if (loading) {
    return (
      <div className="mx-auto max-w-7xl px-4 py-8">
        <p className="text-gray-500">読み込み中...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="mx-auto max-w-7xl px-4 py-8">
        <div className="rounded-lg bg-red-50 p-4 text-red-800">{error}</div>
        {error.includes('ログイン') && (
          <Link href="/login" className="mt-2 inline-block text-purple-600 underline hover:text-purple-800">
            ログインページへ
          </Link>
        )}
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="bg-gradient-to-r from-purple-600 to-blue-600 py-8 md:py-12">
        <div className="mx-auto max-w-7xl px-4">
          <h1 className="text-2xl font-bold text-white md:text-4xl">
            依頼管理
          </h1>
          <p className="mt-2 text-purple-100">
            送信した依頼と受け取った依頼を管理します
          </p>
        </div>
      </div>

      <main className="mx-auto max-w-7xl px-4 py-8 space-y-10">
        <section>
          <h2 className="text-xl font-bold text-gray-900 mb-4">
            受け取った依頼（{receivedRequests.length}件）
          </h2>
          {receivedRequests.length === 0 ? (
            <p className="text-gray-500 py-4">受け取った依頼はまだありません</p>
          ) : (
            <div className="space-y-4">
              {receivedRequests.map((req) => (
                <DirectRequestCard
                  key={req.uuid}
                  request={req}
                  isReceived={true}
                  onAccepted={handleAccepted}
                  onRejected={handleRejected}
                />
              ))}
            </div>
          )}
        </section>

        <section>
          <h2 className="text-xl font-bold text-gray-900 mb-4">
            送信した依頼（{sentRequests.length}件）
          </h2>
          {sentRequests.length === 0 ? (
            <div className="text-center py-8">
              <p className="text-gray-500 mb-4">送信した依頼はまだありません</p>
              <Link
                href="/"
                className="inline-block rounded-lg bg-purple-600 px-6 py-2 text-white hover:bg-purple-700 transition-colors"
              >
                音楽家を探す
              </Link>
            </div>
          ) : (
            <div className="space-y-4">
              {sentRequests.map((req) => (
                <DirectRequestCard
                  key={req.uuid}
                  request={req}
                  isReceived={false}
                  onAccepted={handleAccepted}
                  onRejected={handleRejected}
                />
              ))}
            </div>
          )}
        </section>
      </main>
    </div>
  );
}
