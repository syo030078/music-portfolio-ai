import Link from 'next/link';
import EmptyState from '@/components/EmptyState';
import { fetchJobs } from '@/lib/api/jobs';
import { formatBudget } from '@/lib/format';

export const dynamic = 'force-dynamic';

export default async function JobsPage() {
  let jobs;
  try {
    jobs = await fetchJobs();
  } catch {
    return (
      <div className="min-h-screen bg-gray-50">
        <div className="bg-gradient-to-r from-green-700 via-green-600 to-green-500 py-12">
          <div className="mx-auto max-w-7xl px-4">
            <h1 className="text-2xl font-bold text-white mb-4 md:text-4xl">
              音楽制作の案件を探す
            </h1>
          </div>
        </div>
        <div className="mx-auto max-w-7xl px-4 py-8">
          <div className="rounded-lg bg-red-50 border border-red-200 p-6 text-center">
            <p className="text-red-800 mb-4">案件の取得に失敗しました</p>
            <Link
              href="/jobs"
              className="inline-block rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-semibold text-gray-700 transition-colors hover:bg-gray-50"
            >
              再試行
            </Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* ヒーローセクション */}
      <div className="bg-gradient-to-r from-green-700 via-green-600 to-green-500 py-12">
        <div className="mx-auto max-w-7xl px-4">
          <h1 className="text-2xl font-bold text-white mb-4 md:text-4xl">
            音楽制作の案件を探す
          </h1>
          <p className="text-green-100 text-base md:text-lg">
            あなたのスキルを活かせる案件が見つかります
          </p>
        </div>
      </div>

      {/* メインコンテンツ */}
      <div className="mx-auto max-w-7xl px-4 py-8">
        <div className="mb-6 flex items-center justify-between">
          <p className="text-gray-600">
            {jobs.length > 0 ? `${jobs.length}件の案件` : '案件はありません'}
          </p>
        </div>

        {jobs.length === 0 ? (
          <EmptyState
            icon="📋"
            title="現在公開中の案件はありません"
            description="新しい案件が投稿されるまでお待ちください"
          />
        ) : (
          <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
            {jobs.map((job) => (
              <Link
                key={job.uuid}
                href={`/jobs/${job.uuid}`}
                className="group block h-full"
              >
                <div className="flex h-full flex-col rounded-lg border border-gray-200 bg-white p-6 transition-shadow hover:shadow-lg">
                  <h2 className="mb-3 text-xl font-bold text-gray-900 group-hover:text-green-600 transition-colors line-clamp-2">
                    {job.title}
                  </h2>

                  <p className="mb-4 line-clamp-2 text-sm text-gray-600 flex-grow">
                    {job.description}
                  </p>

                  <div className="mb-4 space-y-2">
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-gray-500">予算</span>
                      <span className="font-bold text-green-600">
                        {formatBudget(job)}
                      </span>
                    </div>

                    <div className="h-6">
                      {job.is_remote && (
                        <span className="inline-flex items-center rounded-full bg-blue-50 px-3 py-1 text-xs font-medium text-blue-700">
                          リモートOK
                        </span>
                      )}
                    </div>
                  </div>

                  <div className="flex items-center border-t pt-4 mt-auto">
                    <div className="flex h-8 w-8 items-center justify-center rounded-full bg-gray-200 text-sm font-medium text-gray-600">
                      {job.client.name.charAt(0)}
                    </div>
                    <span className="ml-2 text-sm text-gray-700">
                      {job.client.name}
                    </span>
                  </div>
                </div>
              </Link>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
