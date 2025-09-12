"use client";
import { useState } from "react";

const API = process.env.NEXT_PUBLIC_API_BASE_URL || "";

export default function Page() {
  const [audioFile, setAudioFile] = useState<File | null>(null);
  const [audioUrl, setAudioUrl] = useState<string>("");
  const [loading, setLoading] = useState(false);
  const [analysisResult, setAnalysisResult] = useState<any>(null);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setAudioFile(file);
      const url = URL.createObjectURL(file);
      setAudioUrl(url);
      // データは解析後まで保持する
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
      setAnalysisResult(data.data || null);
    } catch (error) {
      console.error("Analysis error:", error);
      setAnalysisResult({ error: "解析エラーが発生しました" });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ maxWidth: 600, margin: "50px auto", padding: 20 }}>
      <h1>音楽解析</h1>

      <div style={{ marginBottom: 20 }}>
        <input type="file" accept="audio/*" onChange={handleFileChange} />
      </div>

      {audioFile && (
        <div style={{ marginBottom: 20 }}>
          <h3>アップロードされた音声ファイル</h3>
          <div style={{ marginBottom: 15 }}>
            <strong>ファイル名:</strong> {audioFile.name}
          </div>
          <audio controls style={{ width: "100%", marginBottom: 15 }}>
            <source src={audioUrl} type={audioFile.type} />
            ブラウザがオーディオをサポートしていません
          </audio>
          <button
            onClick={analyzeAudio}
            disabled={loading}
            style={{
              padding: "10px 20px",
              backgroundColor: loading ? "#ccc" : "#007bff",
              color: "white",
              border: "none",
              borderRadius: "4px",
              cursor: loading ? "not-allowed" : "pointer",
            }}
          >
            {loading ? "解析中..." : "解析開始"}
          </button>
        </div>
      )}

      {analysisResult && (
        <div
          style={{
            marginTop: 20,
            padding: 15,
            backgroundColor: "#f5f5f5",
            borderRadius: "4px",
          }}
        >
          <h3>楽曲解析結果</h3>
          {analysisResult.error ? (
            <div style={{ color: "red", fontSize: "16px" }}>
              {analysisResult.error}
            </div>
          ) : (
            <div>
              <div style={{ marginBottom: 10 }}>
                <strong>BPM:</strong>{" "}
                <span style={{ fontSize: "18px", color: "#007bff" }}>
                  {analysisResult.bpm || "N/A"}
                </span>
              </div>
              <div style={{ marginBottom: 10 }}>
                <strong>キー:</strong>{" "}
                <span style={{ fontSize: "18px", color: "#28a745" }}>
                  {analysisResult.key || "N/A"}
                </span>
              </div>
              <div style={{ marginBottom: 10 }}>
                <strong>ジャンル:</strong>{" "}
                <span style={{ fontSize: "18px", color: "#dc3545" }}>
                  {analysisResult.genre || "N/A"}
                </span>
              </div>
              <div style={{ marginBottom: 10 }}>
                <strong>ファイル名:</strong>{" "}
                <span style={{ fontSize: "14px", color: "#666" }}>
                  {analysisResult.file_path || "N/A"}
                </span>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
