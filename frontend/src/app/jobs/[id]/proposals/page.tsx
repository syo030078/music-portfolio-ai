'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import ProposalCard from '@/components/ProposalCard';

interface Proposal {
  uuid: string;
  quote_total_jpy: number;
  delivery_days: number;
  cover_message: string | null;
  status: string;
  created_at: string;
  musician: {
    uuid: string;
    name: string;
  };
}

export default function ProposalsPage({ params }: { params: { id: string } }) {
  const [proposals, setProposals] = useState<Proposal[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  useEffect(() => {
    const fetchProposals = async () => {
      setError(null);
      const token = localStorage.getItem('jwt');
      if (!token) {
        setError('ログインしてください');
        setLoading(false);
        return;
      }

      try {
        const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';
        const res = await fetch(`${apiUrl}/api/v1/jobs/${params.id}/proposals`, {
          headers: {
            'Content-Type': 'application/json',
            Authorization: token,
          },
          cache: 'no-store',
        });

        if (!res.ok) {
          const data = await res.json();
          throw new Error(data.error || '提案一覧の取得に失敗しました');
        }

        const data = await res.json();
        setProposals(data.proposals || []);
      } catch (err) {
        setError(err instanceof Error ? err.message : '不明なエラーが発生しました');
      } finally {
        setLoading(false);
      }
    };

    fetchProposals();
  }, [params.id]);

  const handleAccepted = (conversationUuid: string) => {
    router.push(`/messages/${conversationUuid}`);
  };

  const handleRejected = (proposalUuid: string) => {
    setProposals((prev) => prev.map((p) => (p.uuid === proposalUuid ? { ...p, status: 'rejected' } : p)));
  };

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
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-7xl px-4 py-8">
      <h1 className="text-2xl font-bold mb-8 md:text-3xl">提案一覧</h1>

      {proposals.length === 0 ? (
        <p className="text-gray-500">提案はまだありません</p>
      ) : (
        <div className="space-y-6">
          {proposals.map((proposal) => (
            <ProposalCard
              key={proposal.uuid}
              proposal={proposal}
              onAccepted={handleAccepted}
              onRejected={handleRejected}
            />
          ))}
        </div>
      )}
    </div>
  );
}
