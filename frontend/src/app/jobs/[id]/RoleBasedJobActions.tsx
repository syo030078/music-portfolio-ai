'use client';

import Link from 'next/link';
import ProposalForm from '@/components/ProposalForm';
import { useUser } from '@/hooks/useUser';

interface RoleBasedJobActionsProps {
  readonly jobUuid: string;
}

export default function RoleBasedJobActions({ jobUuid }: RoleBasedJobActionsProps) {
  const { isMusician, isClient } = useUser();

  if (isMusician) {
    return <ProposalForm jobUuid={jobUuid} />;
  }

  if (isClient) {
    return (
      <div className="rounded-lg border border-gray-200 bg-white p-6 text-center">
        <h2 className="text-lg font-semibold mb-3">提案を確認</h2>
        <p className="text-sm text-gray-500 mb-4">
          この案件に届いた提案を確認できます
        </p>
        <Link
          href={`/jobs/${jobUuid}/proposals`}
          className="inline-block rounded-lg bg-green-600 px-6 py-2 font-semibold text-white transition-colors hover:bg-green-700"
        >
          提案一覧を見る
        </Link>
      </div>
    );
  }

  return null;
}
