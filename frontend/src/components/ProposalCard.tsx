'use client';

import { useState } from 'react';
import type { Proposal } from '@/types';
import { acceptProposal, rejectProposal } from '@/lib/api/proposals';
import ConfirmDialog from '@/components/ui/ConfirmDialog';
import { getToken } from '@/lib/auth';

interface ProposalCardProps {
  proposal: Proposal;
  onAccepted: (conversationUuid: string) => void;
  onRejected: (proposalUuid: string) => void;
}

const STATUS_LABELS: Record<Proposal['status'], { label: string; color: string }> = {
  submitted: { label: '審査中', color: 'bg-yellow-100 text-yellow-800' },
  shortlisted: { label: '候補', color: 'bg-blue-100 text-blue-800' },
  accepted: { label: '承諾済み', color: 'bg-green-100 text-green-800' },
  rejected: { label: '不採用', color: 'bg-red-100 text-red-800' },
  withdrawn: { label: '取り下げ', color: 'bg-gray-100 text-gray-800' },
};

export default function ProposalCard({ proposal, onAccepted, onRejected }: ProposalCardProps) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showRejectConfirm, setShowRejectConfirm] = useState(false);
  const isPending = proposal.status === 'submitted' || proposal.status === 'shortlisted';
  const statusInfo = STATUS_LABELS[proposal.status];

  const handleAction = async (action: 'accept' | 'reject') => {
    setLoading(true);
    setError(null);

    try {
      const token = getToken();
      if (!token) {
        throw new Error('ログインしてください');
      }

      if (action === 'accept') {
        const data = await acceptProposal(token, proposal.uuid);
        onAccepted(data.conversation_uuid);
      } else {
        await rejectProposal(token, proposal.uuid);
        onRejected(proposal.uuid);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : '不明なエラーが発生しました');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-white border border-gray-200 rounded-lg p-6 space-y-4">
      <div className="flex justify-between items-start">
        <div>
          <p className="text-lg font-semibold">{proposal.musician.name}</p>
          <p className="text-sm text-gray-500">
            応募日: {new Date(proposal.created_at).toLocaleDateString('ja-JP')}
          </p>
        </div>
        <span className={`text-xs font-semibold px-2 py-1 rounded-full ${statusInfo.color}`}>
          {statusInfo.label}
        </span>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <p className="text-sm text-gray-500">見積金額</p>
          <p className="font-semibold">¥{proposal.quote_total_jpy.toLocaleString()}</p>
        </div>
        <div>
          <p className="text-sm text-gray-500">納期</p>
          <p className="font-semibold">{proposal.delivery_days}日</p>
        </div>
      </div>

      {proposal.cover_message && (
        <div className="bg-gray-50 rounded-md p-3 text-sm text-gray-700 whitespace-pre-wrap">
          {proposal.cover_message}
        </div>
      )}

      {isPending && (
        <>
          <div className="flex gap-3">
            <button
              onClick={() => handleAction('accept')}
              disabled={loading}
              className="rounded-md bg-green-600 px-4 py-2 text-white font-semibold hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              承諾する
            </button>
            <button
              onClick={() => setShowRejectConfirm(true)}
              disabled={loading}
              className="rounded-md bg-gray-200 px-4 py-2 text-gray-800 font-semibold hover:bg-gray-300 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              拒否する
            </button>
          </div>
          <ConfirmDialog
            isOpen={showRejectConfirm}
            title="提案を拒否しますか？"
            message={`${proposal.musician.name} さんの提案を拒否します。この操作は取り消せません。`}
            confirmLabel="拒否する"
            variant="danger"
            isLoading={loading}
            onConfirm={() => {
              setShowRejectConfirm(false);
              handleAction('reject');
            }}
            onCancel={() => setShowRejectConfirm(false)}
          />
        </>
      )}

      {error && (
        <div className="rounded-lg bg-red-50 p-3 text-sm text-red-800">{error}</div>
      )}
    </div>
  );
}
