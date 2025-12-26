"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";

type AnalysisResult = {
  bpm?: number | null;
  key?: string | null;
  genre?: string | null;
  file_path?: string | null;
  error?: string;
};

const API = process.env.NEXT_PUBLIC_API_BASE_URL || "";

export default function UploadPage() {
  const router = useRouter();
  const [audioFile, setAudioFile] = useState<File | null>(null);
  const [audioUrl, setAudioUrl] = useState<string>("");
  const [loading, setLoading] = useState(false);
  const [analysisResult, setAnalysisResult] = useState<AnalysisResult | null>(
    null
  );
  const [isDragOver, setIsDragOver] = useState(false);
  const [ytUrl, setYtUrl] = useState("");

  const processFile = (file: File) => {
    if (audioUrl) {
      URL.revokeObjectURL(audioUrl);
    }
    setAudioFile(file);
    const url = URL.createObjectURL(file);
    setAudioUrl(url);
    setAnalysisResult(null);
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      processFile(file);
    }
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(true);
  };

  const handleDragLeave = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(false);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(false);
    const files = e.dataTransfer.files;
    if (files.length > 0) {
      const file = files[0];
      if (file.type.startsWith("audio/")) {
        processFile(file);
      }
    }
  };

  const analyzeAudio = async () => {
    if (!audioFile) return;

    setLoading(true);
    try {
      const formData = new FormData();
      formData.append("audio_file", audioFile);

      const res = await fetch(`${API}/api/v1/tracks`, {
        method: "POST",
        body: formData,
      });

      const data = await res.json();
      const resultData = data.data || null;
      setAnalysisResult(resultData);
    } catch (error) {
      console.error("解析エラー:", error);
      setAnalysisResult({ error: "サーバーとの通信に失敗しました" });
    } finally {
      setLoading(false);
    }
  };

  const registerYoutube = async () => {
    if (!ytUrl) return;

    try {
      const res = await fetch(`${API}/api/v1/tracks`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ yt_url: ytUrl, title: "YouTube Video" }),
      });

      if (res.ok) {
        setYtUrl("");
        alert("YouTube動画を登録しました！");
      } else {
        alert("登録に失敗しました");
      }
    } catch {
      alert("登録エラーが発生しました");
    }
  };

  const handleLogout = () => {
    localStorage.clear();
    router.push("/login");
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="mx-auto max-w-4xl px-4 py-12">
        {/* ヘッダー */}
        <div className="mb-8">
          <h1 className="mb-2 text-3xl font-bold text-gray-900">
            楽曲をアップロード
          </h1>
          <p className="text-gray-600">
            音楽ファイルまたはYouTube URLを登録してください
          </p>
        </div>

        {/* YouTube登録セクション */}
        <div className="mb-8 rounded-lg border-2 border-dashed border-red-300 bg-white p-6">
          <h2 className="mb-4 text-xl font-bold text-gray-900">
            YouTube URLから登録
          </h2>
          <div className="flex gap-3">
            <input
              value={ytUrl}
              onChange={(e) => setYtUrl(e.target.value)}
              placeholder="https://www.youtube.com/watch?v=..."
              className="flex-1 rounded-lg border border-gray-300 px-4 py-2 focus:border-red-500 focus:outline-none focus:ring-2 focus:ring-red-200"
            />
            <button
              onClick={registerYoutube}
              disabled={!ytUrl}
              className="rounded-lg bg-red-600 px-6 py-2 font-medium text-white transition-colors hover:bg-red-700 disabled:bg-gray-300"
            >
              登録
            </button>
          </div>
        </div>

        {/* ファイルアップロードセクション */}
        <div className="rounded-lg bg-white p-6 shadow-sm">
          <h2 className="mb-4 text-xl font-bold text-gray-900">
            音楽ファイルから登録
          </h2>

          {/* ドラッグ&ドロップエリア */}
          <div
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            onDrop={handleDrop}
            className={`relative mb-6 flex cursor-pointer flex-col items-center justify-center rounded-lg border-2 border-dashed p-12 transition-colors ${
              isDragOver
                ? "border-blue-500 bg-blue-50"
                : "border-gray-300 bg-gray-50"
            }`}
          >
            <input
              type="file"
              accept="audio/*"
              onChange={handleFileChange}
              className="absolute inset-0 cursor-pointer opacity-0"
            />
            <div className="pointer-events-none text-center">
              <div className="mb-4 text-6xl">🎵</div>
              <div className="mb-2 text-lg font-semibold text-gray-700">
                ここに音楽ファイルをドロップ
              </div>
              <div className="text-sm text-gray-500">
                またはクリックしてファイルを選択
              </div>
            </div>
          </div>

          {/* ファイルプレビュー */}
          {audioFile && (
            <div className="space-y-4">
              <div className="rounded-lg border border-gray-200 bg-gray-50 p-4">
                <div className="mb-2 text-sm font-medium text-gray-700">
                  ファイル名: {audioFile.name}
                </div>
                <audio controls className="w-full">
                  <source src={audioUrl} type={audioFile.type} />
                  ブラウザがオーディオをサポートしていません
                </audio>
              </div>

              <button
                onClick={analyzeAudio}
                disabled={loading}
                className="w-full rounded-lg bg-blue-600 px-6 py-3 font-semibold text-white transition-colors hover:bg-blue-700 disabled:bg-gray-400"
              >
                {loading ? "解析中..." : "BPM・キーを解析"}
              </button>
            </div>
          )}

          {/* 解析結果 */}
          {analysisResult && (
            <div className="mt-6 rounded-lg border border-gray-200 bg-gray-50 p-6">
              <h3 className="mb-4 text-lg font-bold text-gray-900">
                解析結果
              </h3>

              {analysisResult.error ? (
                <div className="text-red-600">{analysisResult.error}</div>
              ) : (
                <div className="space-y-3">
                  <div className="flex items-center justify-between rounded-lg bg-white p-4">
                    <span className="font-medium text-gray-700">BPM</span>
                    <span className="text-xl font-bold text-blue-600">
                      {analysisResult.bpm || "N/A"}
                    </span>
                  </div>
                  <div className="flex items-center justify-between rounded-lg bg-white p-4">
                    <span className="font-medium text-gray-700">キー</span>
                    <span className="text-xl font-bold text-green-600">
                      {analysisResult.key || "N/A"}
                    </span>
                  </div>
                  <div className="flex items-center justify-between rounded-lg bg-white p-4">
                    <span className="font-medium text-gray-700">ジャンル</span>
                    <span className="text-xl font-bold text-purple-600">
                      {analysisResult.genre || "N/A"}
                    </span>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>

        {/* ログアウトボタン */}
        <div className="mt-8">
          <button
            onClick={handleLogout}
            className="text-sm text-gray-600 hover:text-gray-900"
          >
            ログアウト
          </button>
        </div>
      </div>
    </div>
  );
}
