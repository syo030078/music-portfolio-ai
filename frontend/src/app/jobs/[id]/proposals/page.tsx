'use client';

import Link from 'next/link';
import { use, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import AuthGuard from '@/components/AuthGuard';
import ProposalCard from '@/components/ProposalCard';
import type { Proposal } from '@/types';
import { fetchProposals } from '@/lib/api/proposals';
import { fetchJob } from '@/lib/api/jobs';
import { getToken } from '@/lib/auth';

interface JobSummary {
  uuid: string;
  title: string;
}

export default function ProposalsPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const [proposals, setProposals] = useState<Proposal[]>([]);
  const [job, setJob] = useState<JobSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  useEffect(() => {
    const fetchData = async () => {
      setError(null);
      const token = getToken();
      if (!token) return;

      try {
        const [proposalsResult, jobResult] = await Promise.allSettled([
          fetchProposals(token, id),
          fetchJob(id),
        ]);

        if (proposalsResult.status === 'rejected') {
          throw proposalsResult.reason;
        }
        setProposals(proposalsResult.value);

        if (jobResult.status === 'fulfilled') {
          setJob({ uuid: jobResult.value.uuid, title: jobResult.value.title });
        }
      } catch (err) {
        setError(err instanceof Error ? err.message : '不明なエラーが発生しました');
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [id]);

  const handleAccepted = (conversationUuid: string) => {
    router.push(`/messages/${conversationUuid}`);
  };

  const handleRejected = (proposalUuid: string) => {
    setProposals((prev) => prev.map((p) => (p.uuid === proposalUuid ? { ...p, status: 'rejected' } : p)));
  };

  return (
    <AuthGuard>
      <div className="min-h-screen bg-gray-50">
        <div className="bg-gradient-to-r from-green-600 to-green-700 py-8 md:py-12">
          <div className="mx-auto max-w-7xl px-4">
            <Link
              href={`/jobs/${id}`}
              className="mb-4 inline-flex items-center text-green-100 hover:text-white"
            >
              ← 案件詳細に戻る
            </Link>
            <h1 className="text-2xl font-bold text-white md:text-4xl">
              提案一覧
            </h1>
            {job && (
              <p className="mt-2 text-green-100">{job.title}</p>
            )}
          </div>
        </div>

        <div className="mx-auto max-w-7xl px-4 py-8">
          {loading ? (
            <p className="text-gray-500">読み込み中...</p>
          ) : error ? (
            <div className="rounded-lg bg-red-50 p-4 text-red-800">{error}</div>
          ) : proposals.length === 0 ? (
            <div className="rounded-lg bg-white p-12 text-center shadow-sm">
              <p className="text-gray-500">提案はまだありません</p>
            </div>
          ) : (
            <div className="space-y-6">
              <p className="text-gray-600">{proposals.length}件の提案</p>
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
      </div>
    </AuthGuard>
  );
}
