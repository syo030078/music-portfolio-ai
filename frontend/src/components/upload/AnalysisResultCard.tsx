export type AnalysisResult = {
  bpm?: number | null;
  key?: string | null;
  genre?: string | null;
  error?: string;
};

const RESULT_ITEMS = [
  { label: "BPM", field: "bpm", color: "purple" },
  { label: "キー", field: "key", color: "blue" },
  { label: "ジャンル", field: "genre", color: "indigo" },
] as const;

// Tailwind は動的クラス名を検出できないため、色ごとのクラスを静的に列挙する
const COLOR_CLASSES = {
  purple: { box: "bg-purple-50", label: "text-purple-600", value: "text-purple-900" },
  blue: { box: "bg-blue-50", label: "text-blue-600", value: "text-blue-900" },
  indigo: { box: "bg-indigo-50", label: "text-indigo-600", value: "text-indigo-900" },
} as const;

export default function AnalysisResultCard({ result }: { result: AnalysisResult }) {
  return (
    <div className="mt-8 rounded-lg border border-gray-200 bg-white p-8 shadow-sm">
      <h2 className="mb-6 text-2xl font-bold text-gray-900">
        解析結果
      </h2>

      {result.error ? (
        <div className="rounded-lg bg-red-50 p-4">
          <p className="text-red-800">{result.error}</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
          {RESULT_ITEMS.map(({ label, field, color }) => (
            <div key={field} className={`rounded-lg ${COLOR_CLASSES[color].box} p-6 text-center`}>
              <div className={`text-sm font-medium ${COLOR_CLASSES[color].label}`}>{label}</div>
              <div className={`mt-2 text-3xl font-bold ${COLOR_CLASSES[color].value}`}>
                {result[field] || "N/A"}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
