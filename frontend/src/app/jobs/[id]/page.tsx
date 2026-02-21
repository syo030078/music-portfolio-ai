import Link from 'next/link';
import { notFound } from 'next/navigation';
import ContactButton from '@/components/ContactButton';
import ProposalForm from '@/components/ProposalForm';

interface Job {
  uuid: string;
  title: string;
  description: string;
  budget_jpy: number | null;
  budget_min_jpy: number | null;
  budget_max_jpy: number | null;
  is_remote: boolean;
  delivery_due_on: string | null;
  published_at: string;
  created_at: string;
  client: {
    uuid: string;
    name: string;
    bio: string | null;
  };
}

async function getJob(id: string): Promise<Job | null> {
  const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';
  const res = await fetch(`${apiUrl}/api/v1/jobs/${id}`, {
    cache: 'no-store',
  });

  if (!res.ok) {
    return null;
  }

  const data = await res.json();
  return data.job;
}

function formatBudget(job: Job): string {
  if (job.budget_jpy) {
    return `¥${job.budget_jpy.toLocaleString()}`;
  }
  if (job.budget_min_jpy && job.budget_max_jpy) {
    return `¥${job.budget_min_jpy.toLocaleString()} - ¥${job.budget_max_jpy.toLocaleString()}`;
  }
  return '要相談';
}

function formatDate(dateString: string | null): string {
  if (!dateString) return '-';
  const date = new Date(dateString);
  return date.toLocaleDateString('ja-JP');
}

export default async function JobDetailPage({
  params,
}: {
  params: { id: string };
}) {
  const job = await getJob(params.id);

  if (!job) {
    notFound();
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* ヒーローセクション */}
      <div className="bg-gradient-to-r from-green-600 to-green-700 py-8 md:py-12">
        <div className="mx-auto max-w-7xl px-4">
          <Link
            href="/jobs"
            className="mb-4 inline-flex items-center text-green-100 hover:text-white"
          >
            ← 案件一覧に戻る
          </Link>
          <h1 className="text-2xl font-bold text-white md:text-4xl">
            {job.title}
          </h1>
        </div>
      </div>

      {/* メインコンテンツ */}
      <div className="mx-auto max-w-7xl px-4 py-8">
        <div className="grid grid-cols-1 gap-8 lg:grid-cols-3">
          {/* 左カラム: 案件詳細 */}
          <div className="lg:col-span-2 space-y-6">
            <div className="rounded-lg border border-gray-200 bg-white p-6 md:p-8">
              <h2 className="text-lg font-semibold mb-3">案件詳細</h2>
              <p className="text-gray-700 whitespace-pre-wrap">
                {job.description}
              </p>
            </div>

            <div className="rounded-lg border border-gray-200 bg-white p-6 md:p-8">
              <h2 className="text-lg font-semibold mb-4">条件</h2>
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div className="rounded-lg bg-gray-50 p-4">
                  <p className="text-sm text-gray-500">予算</p>
                  <p className="text-lg font-semibold text-green-600">
                    {formatBudget(job)}
                  </p>
                </div>
                <div className="rounded-lg bg-gray-50 p-4">
                  <p className="text-sm text-gray-500">リモート</p>
                  <p
                    className={`text-lg font-semibold ${
                      job.is_remote ? 'text-blue-600' : 'text-gray-500'
                    }`}
                  >
                    {job.is_remote ? '可' : '不可'}
                  </p>
                </div>
                <div className="rounded-lg bg-gray-50 p-4">
                  <p className="text-sm text-gray-500">納期</p>
                  <p className="text-lg font-semibold text-gray-900">
                    {formatDate(job.delivery_due_on)}
                  </p>
                </div>
                <div className="rounded-lg bg-gray-50 p-4">
                  <p className="text-sm text-gray-500">公開日</p>
                  <p className="text-lg font-semibold text-gray-900">
                    {formatDate(job.published_at)}
                  </p>
                </div>
              </div>
            </div>

            <ProposalForm jobUuid={job.uuid} />

            <div className="text-center">
              <Link
                href={`/jobs/${job.uuid}/proposals`}
                className="text-sm text-green-600 hover:underline"
              >
                提案一覧を見る（クライアント向け）
              </Link>
            </div>
          </div>

          {/* 右カラム: 依頼者情報 + アクション */}
          <div className="space-y-6">
            <div className="rounded-lg border border-gray-200 bg-white p-6">
              <h2 className="text-lg font-semibold mb-3">依頼者情報</h2>
              <div className="flex items-center gap-3 mb-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-green-100 text-sm font-bold text-green-700">
                  {job.client.name.charAt(0)}
                </div>
                <p className="font-medium text-lg">{job.client.name}</p>
              </div>
              {job.client.bio && (
                <p className="text-sm text-gray-600">{job.client.bio}</p>
              )}
            </div>

            <div className="rounded-lg border border-gray-200 bg-white p-6">
              <ContactButton jobUuid={job.uuid} clientUuid={job.client.uuid} />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
