"use client";
import { useState } from "react";

type AnalysisResult = {
  bpm?: number | null;
  key?: string | null;
  genre?: string | null;
  error?: string;
};

const API = process.env.NEXT_PUBLIC_API_BASE_URL || "";

export default function UploadPage() {
  const [audioFile, setAudioFile] = useState<File | null>(null);
  const [audioUrl, setAudioUrl] = useState<string>("");
  const [loading, setLoading] = useState(false);
  const [analysisResult, setAnalysisResult] = useState<AnalysisResult | null>(null);
  const [isDragOver, setIsDragOver] = useState(false);
  const [ytUrl, setYtUrl] = useState("");
  const [uploadSuccess, setUploadSuccess] = useState(false);

  const processFile = (file: File) => {
    if (audioUrl) {
      URL.revokeObjectURL(audioUrl);
    }
    setAudioFile(file);
    const url = URL.createObjectURL(file);
    setAudioUrl(url);
    setAnalysisResult(null);
    setUploadSuccess(false);
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
    setUploadSuccess(false);

    try {
      const formData = new FormData();
      formData.append("audio_file", audioFile);

      const res = await fetch(`${API}/api/v1/tracks`, {
        method: "POST",
        body: formData,
      });

      const data = await res.json();

      if (res.ok) {
        const resultData = data.data || {};
        setAnalysisResult(resultData);
        setUploadSuccess(true);
        setAudioFile(null);
        if (audioUrl) {
          URL.revokeObjectURL(audioUrl);
          setAudioUrl("");
        }
      } else {
        setAnalysisResult({ error: data.error || "解析に失敗しました" });
      }
    } catch (error) {
      console.error("解析エラー:", error);
      setAnalysisResult({ error: "サーバーとの通信に失敗しました" });
    } finally {
      setLoading(false);
    }
  };

  const registerYoutube = async () => {
    if (!ytUrl.trim()) return;

    setLoading(true);
    setUploadSuccess(false);

    try {
      const res = await fetch(`${API}/api/v1/tracks`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ yt_url: ytUrl, title: "YouTube Video" }),
      });

      const data = await res.json();

      if (res.ok) {
        setAnalysisResult(data.data || {});
        setUploadSuccess(true);
        setYtUrl("");
      } else {
        setAnalysisResult({ error: data.error || "登録に失敗しました" });
      }
    } catch (error) {
      console.error("登録エラー:", error);
      setAnalysisResult({ error: "サーバーとの通信に失敗しました" });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-white">
      {/* ヒーローセクション */}
      <div className="bg-gradient-to-r from-purple-600 to-blue-600 py-16">
        <div className="mx-auto max-w-7xl px-4">
          <h1 className="mb-4 text-3xl font-bold text-white md:text-5xl">
            楽曲をアップロード
          </h1>
          <p className="text-lg text-purple-100 md:text-xl">
            音声ファイルまたはYouTubeリンクから楽曲を登録できます
          </p>
        </div>
      </div>

      {/* メインコンテンツ */}
      <div className="mx-auto max-w-7xl px-4 py-12">
        <div className="grid grid-cols-1 gap-8 lg:grid-cols-2">
          {/* 音声ファイルアップロード */}
          <div className="rounded-lg border border-gray-200 bg-white p-8 shadow-sm">
            <h2 className="mb-6 text-2xl font-bold text-gray-900">
              音声ファイルをアップロード
            </h2>

            {/* ドラッグ&ドロップエリア */}
            <div
              onDragOver={handleDragOver}
              onDragLeave={handleDragLeave}
              onDrop={handleDrop}
              className={`relative mb-6 flex cursor-pointer flex-col items-center justify-center rounded-lg border-2 border-dashed p-12 transition-all ${
                isDragOver
                  ? "border-purple-500 bg-purple-50"
                  : "border-gray-300 bg-gray-50 hover:bg-gray-100"
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
                  ファイルをドラッグ または クリックして選択
                </div>
                <div className="text-sm text-gray-500">
                  MP3, WAV, FLAC などの音声ファイル
                </div>
              </div>
            </div>

            {/* ファイルプレビュー */}
            {audioFile && (
              <div className="space-y-4">
                <div className="rounded-lg border border-gray-200 bg-gray-50 p-4">
                  <div className="mb-3 text-sm font-medium text-gray-700">
                    {audioFile.name}
                  </div>
                  <audio controls className="w-full">
                    <source src={audioUrl} type={audioFile.type} />
                  </audio>
                </div>

                <button
                  onClick={analyzeAudio}
                  disabled={loading}
                  className="w-full rounded-lg bg-purple-600 px-6 py-3 font-semibold text-white transition-colors hover:bg-purple-700 disabled:bg-gray-400"
                >
                  {loading ? "解析中..." : "解析してアップロード"}
                </button>
              </div>
            )}
          </div>

          {/* YouTube登録 */}
          <div className="rounded-lg border border-gray-200 bg-white p-8 shadow-sm">
            <h2 className="mb-6 text-2xl font-bold text-gray-900">
              YouTubeリンクから登録
            </h2>

            <div className="space-y-4">
              <div>
                <input
                  type="url"
                  value={ytUrl}
                  onChange={(e) => setYtUrl(e.target.value)}
                  placeholder="https://www.youtube.com/watch?v=..."
                  className="w-full rounded-lg border border-gray-300 px-4 py-3 text-gray-900 focus:border-purple-500 focus:outline-none focus:ring-2 focus:ring-purple-500"
                />
              </div>

              <button
                onClick={registerYoutube}
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
        </div>

        {/* 成功メッセージ */}
        {uploadSuccess && !analysisResult?.error && (
          <div className="mt-8 rounded-lg bg-green-50 p-4">
            <p className="font-medium text-green-800">
              ✓ 楽曲を登録しました
            </p>
          </div>
        )}

        {/* 解析結果 */}
        {analysisResult && (
          <div className="mt-8 rounded-lg border border-gray-200 bg-white p-8 shadow-sm">
            <h2 className="mb-6 text-2xl font-bold text-gray-900">
              解析結果
            </h2>

            {analysisResult.error ? (
              <div className="rounded-lg bg-red-50 p-4">
                <p className="text-red-800">{analysisResult.error}</p>
              </div>
            ) : (
              <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
                <div className="rounded-lg bg-purple-50 p-6 text-center">
                  <div className="text-sm font-medium text-purple-600">BPM</div>
                  <div className="mt-2 text-3xl font-bold text-purple-900">
                    {analysisResult.bpm || "N/A"}
                  </div>
                </div>
                <div className="rounded-lg bg-blue-50 p-6 text-center">
                  <div className="text-sm font-medium text-blue-600">キー</div>
                  <div className="mt-2 text-3xl font-bold text-blue-900">
                    {analysisResult.key || "N/A"}
                  </div>
                </div>
                <div className="rounded-lg bg-indigo-50 p-6 text-center">
                  <div className="text-sm font-medium text-indigo-600">ジャンル</div>
                  <div className="mt-2 text-3xl font-bold text-indigo-900">
                    {analysisResult.genre || "N/A"}
                  </div>
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
