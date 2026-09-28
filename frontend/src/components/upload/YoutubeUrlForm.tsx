"use client";

type Props = {
  ytUrl: string;
  loading: boolean;
  onChange: (url: string) => void;
  onSubmit: () => void;
};

export default function YoutubeUrlForm({ ytUrl, loading, onChange, onSubmit }: Props) {
  return (
    <div className="rounded-lg border border-gray-200 bg-white p-8 shadow-sm">
      <h2 className="mb-6 text-2xl font-bold text-gray-900">
        YouTubeリンクから登録
      </h2>

      <div className="space-y-4">
        <div>
          <input
            type="url"
            value={ytUrl}
            onChange={(e) => onChange(e.target.value)}
            placeholder="https://www.youtube.com/watch?v=..."
            className="w-full rounded-lg border border-gray-300 px-4 py-3 text-gray-900 focus:border-purple-500 focus:outline-none focus:ring-2 focus:ring-purple-500"
          />
        </div>

        <button
          onClick={onSubmit}
          disabled={!ytUrl.trim() || loading}
          className="w-full rounded-lg bg-purple-600 px-6 py-3 font-semibold text-white transition-colors hover:bg-purple-700 disabled:bg-gray-400"
        >
          {loading ? "登録中..." : "YouTubeから登録"}
        </button>

        <p className="text-sm text-gray-500">
          YouTube動画のURLを入力してください
        </p>
      </div>
    </div>
  );
}
