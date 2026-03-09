export default function JobsLoading() {
  return (
    <div className="min-h-screen bg-gray-50">
      <div className="bg-gradient-to-r from-green-700 via-green-600 to-green-500 py-12">
        <div className="mx-auto max-w-7xl px-4">
          <div className="h-8 w-64 animate-pulse rounded bg-green-500" />
          <div className="mt-4 h-5 w-96 animate-pulse rounded bg-green-500/50" />
        </div>
      </div>
      <div className="mx-auto max-w-7xl px-4 py-8">
        <div className="mb-6 h-5 w-32 animate-pulse rounded bg-gray-200" />
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
          {[1, 2, 3].map((i) => (
            <div
              key={i}
              className="rounded-lg border border-gray-200 bg-white p-6"
            >
              <div className="mb-3 h-6 w-3/4 animate-pulse rounded bg-gray-200" />
              <div className="mb-4 space-y-2">
                <div className="h-4 w-full animate-pulse rounded bg-gray-100" />
                <div className="h-4 w-2/3 animate-pulse rounded bg-gray-100" />
              </div>
              <div className="flex items-center border-t pt-4">
                <div className="h-8 w-8 animate-pulse rounded-full bg-gray-200" />
                <div className="ml-2 h-4 w-20 animate-pulse rounded bg-gray-200" />
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
