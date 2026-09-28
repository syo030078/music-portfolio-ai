"use client";
import Link from "next/link";
import { useState } from "react";
import AuthGuard from "@/components/AuthGuard";
import AudioDropZone from "@/components/upload/AudioDropZone";
import YoutubeUrlForm from "@/components/upload/YoutubeUrlForm";
import AnalysisResultCard, { type AnalysisResult } from "@/components/upload/AnalysisResultCard";
import { useUser } from "@/hooks/useUser";
import { getToken } from "@/lib/auth";
import { registerYoutube, uploadAudio, type TrackUploadResult } from "@/lib/api/tracks";

const errorMessage = (e: unknown) =>
  e instanceof Error ? e.message : "サーバーとの通信に失敗しました";

export default function UploadPage() {
  const { user } = useUser();
  const [audioFile, setAudioFile] = useState<File | null>(null);
  const [audioUrl, setAudioUrl] = useState<string>("");
  const [loading, setLoading] = useState(false);
  const [analysisResult, setAnalysisResult] = useState<AnalysisResult | null>(null);
  const [ytUrl, setYtUrl] = useState("");
  const [uploadSuccess, setUploadSuccess] = useState(false);

  const clearAudio = () => {
    if (audioUrl) {
      URL.revokeObjectURL(audioUrl);
    }
    setAudioFile(null);
    setAudioUrl("");
  };

  const selectFile = (file: File) => {
    clearAudio();
    setAudioFile(file);
    setAudioUrl(URL.createObjectURL(file));
    setAnalysisResult(null);
    setUploadSuccess(false);
  };

  // 送信処理の共通部分（loading 制御・成功/失敗時の状態更新）
  const submit = async (send: (token: string) => Promise<TrackUploadResult>, onSuccess: () => void) => {
    setLoading(true);
    setUploadSuccess(false);
    try {
      const result = await send(getToken() || "");
      setAnalysisResult(result);
      setUploadSuccess(true);
      onSuccess();
    } catch (e) {
      setAnalysisResult({ error: errorMessage(e) });
    } finally {
      setLoading(false);
    }
  };

  const analyzeAudio = () => {
    if (!audioFile) return;
    submit((token) => uploadAudio(token, audioFile), clearAudio);
  };

  const submitYoutube = () => {
    if (!ytUrl.trim()) return;
    submit((token) => registerYoutube(token, ytUrl), () => setYtUrl(""));
  };

  return (
    <AuthGuard>
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
          <AudioDropZone
            audioFile={audioFile}
            audioUrl={audioUrl}
            loading={loading}
            onSelect={selectFile}
            onSubmit={analyzeAudio}
          />
          <YoutubeUrlForm
            ytUrl={ytUrl}
            loading={loading}
            onChange={setYtUrl}
            onSubmit={submitYoutube}
          />
        </div>

        {/* 成功メッセージ */}
        {uploadSuccess && !analysisResult?.error && (
          <div className="mt-8 rounded-lg bg-green-50 p-6">
            <p className="font-medium text-green-800 mb-4">
              楽曲を登録しました
            </p>
            <div className="flex flex-wrap gap-3">
              {user && (
                <Link
                  href={`/users/${user.uuid}`}
                  className="inline-block rounded bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700 transition-colors"
                >
                  マイページを見る
                </Link>
              )}
              <button
                onClick={() => {
                  setUploadSuccess(false);
                  setAnalysisResult(null);
                }}
                className="inline-block rounded bg-purple-600 px-4 py-2 text-sm font-medium text-white hover:bg-purple-700 transition-colors"
              >
                続けてアップロード
              </button>
            </div>
          </div>
        )}

        {analysisResult && <AnalysisResultCard result={analysisResult} />}
      </div>
    </div>
    </AuthGuard>
  );
}
