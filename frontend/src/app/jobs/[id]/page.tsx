import Link from 'next/link';
import { notFound } from 'next/navigation';
import ContactButton from '@/components/ContactButton';
import RoleBasedJobActions from './RoleBasedJobActions';
import { fetchJob } from '@/lib/api/jobs';
import { formatBudget, formatDate } from '@/lib/format';

export const dynamic = 'force-dynamic';

export default async function JobDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  let job;
  try {
    job = await fetchJob(id);
  } catch {
    notFound();
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="bg-gradient-to-r from-green-700 via-green-600 to-green-500 py-8 md:py-12">
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

      <div className="mx-auto max-w-7xl px-4 py-8">
        <div className="grid grid-cols-1 gap-8 lg:grid-cols-3">
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

            <RoleBasedJobActions jobUuid={job.uuid} />
          </div>

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
