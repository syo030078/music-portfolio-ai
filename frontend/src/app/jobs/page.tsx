import Link from 'next/link';

interface Job {
  uuid: string;
  title: string;
  description: string;
  budget_jpy: number | null;
  budget_min_jpy: number | null;
  budget_max_jpy: number | null;
  is_remote: boolean;
  published_at: string;
  client: {
    id: number;
    name: string;
  };
}

async function getJobs(): Promise<Job[]> {
  const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';
  const res = await fetch(`${apiUrl}/api/v1/jobs`, {
    cache: 'no-store',
  });

  if (!res.ok) {
    throw new Error('Failed to fetch jobs');
  }

  const data = await res.json();
  return data.jobs;
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

export default async function JobsPage() {
  const jobs = await getJobs();

  return (
    <div className="min-h-screen bg-gray-50">
      {/* ヒーローセクション */}
      <div className="bg-gradient-to-r from-green-600 to-green-700 py-12">
        <div className="mx-auto max-w-7xl px-4">
          <h1 className="text-4xl font-bold text-white mb-4">
            音楽制作の案件を探す
          </h1>
          <p className="text-green-100 text-lg">
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
          <div className="rounded-lg bg-white p-12 text-center shadow-sm">
            <p className="text-gray-500">現在公開中の案件はありません。</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
            {jobs.map((job) => (
              <Link
                key={job.uuid}
                href={`/jobs/${job.uuid}`}
                className="group block"
              >
                <div className="rounded-lg border border-gray-200 bg-white p-6 transition-all hover:border-green-500 hover:shadow-lg">
                  <h2 className="mb-3 text-xl font-bold text-gray-900 group-hover:text-green-600">
                    {job.title}
                  </h2>

                  <p className="mb-4 line-clamp-2 text-sm text-gray-600">
                    {job.description}
                  </p>

                  <div className="mb-4 space-y-2">
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-gray-500">予算</span>
                      <span className="font-bold text-green-600">
                        {formatBudget(job)}
                      </span>
                    </div>

                    {job.is_remote && (
                      <div className="inline-flex items-center rounded-full bg-blue-50 px-3 py-1 text-xs font-medium text-blue-700">
                        リモートOK
                      </div>
                    )}
                  </div>

                  <div className="flex items-center border-t pt-4">
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
