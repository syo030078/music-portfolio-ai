"use client";
import { useState, useEffect } from "react";

const API = process.env.NEXT_PUBLIC_API_BASE_URL || "";

export default function Page() {
  const [audioFile, setAudioFile] = useState<File | null>(null);
  const [audioUrl, setAudioUrl] = useState<string>("");
  const [loading, setLoading] = useState(false);
  const [analysisResult, setAnalysisResult] = useState<any>(null);
  const [isDragOver, setIsDragOver] = useState(false);
  const [progressStep, setProgressStep] = useState("");
  const [copyStatus, setCopyStatus] = useState("");
  const [uploadHistory, setUploadHistory] = useState<any[]>([]);
  const [showHistory, setShowHistory] = useState(false);
  const [ytUrl, setYtUrl] = useState("");

  useEffect(() => {
    const savedHistory = localStorage.getItem("musicAnalysisHistory");
    if (savedHistory) {
      setUploadHistory(JSON.parse(savedHistory));
    }
  }, []);

  const saveToHistory = (result: any, fileName: string) => {
    if (!result || result.error) return;

    const historyItem = {
      id: Date.now(),
      fileName,
      bpm: result.bpm,
      key: result.key,
      genre: result.genre,
      timestamp: new Date().toISOString(),
      displayDate: new Date().toLocaleString("ja-JP"),
    };

    const newHistory = [historyItem, ...uploadHistory].slice(0, 10); // Keep only last 10
    setUploadHistory(newHistory);
    localStorage.setItem("musicAnalysisHistory", JSON.stringify(newHistory));
  };

  const processFile = (file: File) => {
    // 前のBlobURLをクリーンアップ
    if (audioUrl) {
      URL.revokeObjectURL(audioUrl);
    }

    setAudioFile(file);
    const url = URL.createObjectURL(file);
    setAudioUrl(url);
    // 前の解析結果をクリア
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
    setProgressStep("ファイルをサーバーに送信中...");
    try {
      const formData = new FormData();
      formData.append("audio_file", audioFile);

      setProgressStep("音楽を解析中...");
      const res = await fetch(`${API}/api/v1/tracks`, {
        method: "POST",
        body: formData,
      });

      setProgressStep("結果を処理中...");
      const data = await res.json();
      setAnalysisResult(data.data || null);
      if (data.data && !data.data.error && audioFile) {
        saveToHistory(data.data, audioFile.name);
      }
      setProgressStep("解析完了！");
    } catch (error) {
      console.error("Analysis error:", error);
      setAnalysisResult({ error: "解析エラーが発生しました" });
      setProgressStep("");
    } finally {
      setLoading(false);
      setTimeout(() => setProgressStep(""), 1000);
    }
  };

  const copyToClipboard = async (text: string, type: string) => {
    try {
      await navigator.clipboard.writeText(text);
      setCopyStatus(`${type}をコピーしました！`);
      setTimeout(() => setCopyStatus(""), 2000);
    } catch (error) {
      setCopyStatus("コピーに失敗しました");
      setTimeout(() => setCopyStatus(""), 2000);
    }
  };

  const exportData = () => {
    if (!analysisResult) return;

    const exportText = `楽曲解析結果
ファイル名: ${analysisResult.file_path || "N/A"}
BPM: ${analysisResult.bpm || "N/A"}
キー: ${analysisResult.key || "N/A"}
ジャンル: ${analysisResult.genre || "N/A"}
解析日時: ${new Date().toLocaleString("ja-JP")}`;

    const blob = new Blob([exportText], { type: "text/plain" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `music_analysis_${Date.now()}.txt`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const registerYoutube = async () => {
    if (!ytUrl) return;

    try {
      const res = await fetch(`${API}/api/v1/tracks`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ yt_url: ytUrl, title: "YouTube Video" }),
      });

      const data = await res.json();
      if (res.ok) {
        setYtUrl("");
        alert("YouTube動画を登録しました！");
      } else {
        alert("登録に失敗しました");
      }
    } catch (error) {
      console.error("YouTube登録エラー:", error);
      alert("登録エラーが発生しました");
    }
  };

  return (
    <div style={{ maxWidth: 600, margin: "50px auto", padding: 20 }}>
      <div style={{ textAlign: "center", marginBottom: 40 }}>
        <h1 style={{ fontSize: "24px", marginBottom: "8px", color: "#333" }}>
          音楽ポートフォリオ
        </h1>
        <p style={{ color: "#666", fontSize: "14px", margin: 0 }}>
          あなたの音楽作品を管理・共有するプラットフォーム
        </p>
      </div>

      <div
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        onDrop={handleDrop}
        style={{
          border: isDragOver ? "2px dashed #0056b3" : "2px dashed #007bff",
          borderRadius: "8px",
          padding: "40px 20px",
          textAlign: "center",
          backgroundColor: isDragOver ? "#e3f2fd" : "#f8f9fa",
          marginBottom: 20,
          position: "relative",
          transition: "all 0.2s ease",
        }}
      >
        <input
          type="file"
          accept="audio/*"
          onChange={handleFileChange}
          style={{
            position: "absolute",
            top: 0,
            left: 0,
            width: "100%",
            height: "100%",
            opacity: 0,
            cursor: "pointer",
          }}
        />
        <div style={{ pointerEvents: "none" }}>
          <div style={{ fontSize: "48px", marginBottom: "16px" }}>🎵</div>
          <div
            style={{
              fontSize: "18px",
              fontWeight: "bold",
              marginBottom: "8px",
            }}
          >
            ここに音楽ファイルを入れてください
          </div>
          <div style={{ fontSize: "14px", color: "#666" }}>
            または クリックして選択もできます
          </div>
        </div>
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
              padding: "12px 24px",
              backgroundColor: loading ? "#28a745" : "#007bff",
              color: "white",
              border: "none",
              borderRadius: "6px",
              cursor: loading ? "not-allowed" : "pointer",
              fontSize: "16px",
              fontWeight: "bold",
              width: "200px",
              position: "relative",
            }}
          >
            {loading ? (
              <>
                <span style={{ marginRight: "8px" }}>⏳</span>
                {progressStep || "解析中..."}
              </>
            ) : (
              "BPM・キーを解析"
            )}
          </button>
          {progressStep && !loading && (
            <div
              style={{
                color: "#28a745",
                fontSize: "14px",
                marginTop: "8px",
                fontWeight: "bold",
              }}
            >
              ✅ {progressStep}
            </div>
          )}
        </div>
      )}

      {analysisResult && (
        <div
          style={{
            marginTop: 20,
            padding: 20,
            backgroundColor: "#f8f9fa",
            borderRadius: "8px",
            border: "1px solid #e9ecef",
          }}
        >
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              marginBottom: "16px",
            }}
          >
            <h3 style={{ margin: 0, color: "#333" }}>楽曲解析結果</h3>
            {!analysisResult.error && (
              <button
                onClick={exportData}
                style={{
                  padding: "8px 16px",
                  backgroundColor: "#28a745",
                  color: "white",
                  border: "none",
                  borderRadius: "4px",
                  cursor: "pointer",
                  fontSize: "12px",
                }}
              >
                📄 エクスポート
              </button>
            )}
          </div>

          {copyStatus && (
            <div
              style={{
                color: "#28a745",
                fontSize: "12px",
                marginBottom: "12px",
                fontWeight: "bold",
              }}
            >
              ✅ {copyStatus}
            </div>
          )}

          {analysisResult.error ? (
            <div style={{ color: "red", fontSize: "16px" }}>
              {analysisResult.error}
            </div>
          ) : (
            <div>
              <div
                style={{
                  marginBottom: 16,
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                }}
              >
                <div>
                  <strong>BPM:</strong>{" "}
                  <span
                    style={{
                      fontSize: "20px",
                      color: "#007bff",
                      fontWeight: "bold",
                    }}
                  >
                    {analysisResult.bpm || "N/A"}
                  </span>
                </div>
                <button
                  onClick={() =>
                    copyToClipboard(
                      analysisResult.bpm?.toString() || "N/A",
                      "BPM"
                    )
                  }
                  style={{
                    padding: "4px 8px",
                    backgroundColor: "#007bff",
                    color: "white",
                    border: "none",
                    borderRadius: "3px",
                    cursor: "pointer",
                    fontSize: "11px",
                  }}
                >
                  📋 コピー
                </button>
              </div>
              <div
                style={{
                  marginBottom: 16,
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                }}
              >
                <div>
                  <strong>キー:</strong>{" "}
                  <span
                    style={{
                      fontSize: "20px",
                      color: "#28a745",
                      fontWeight: "bold",
                    }}
                  >
                    {analysisResult.key || "N/A"}
                  </span>
                </div>
                <button
                  onClick={() =>
                    copyToClipboard(analysisResult.key || "N/A", "キー")
                  }
                  style={{
                    padding: "4px 8px",
                    backgroundColor: "#28a745",
                    color: "white",
                    border: "none",
                    borderRadius: "3px",
                    cursor: "pointer",
                    fontSize: "11px",
                  }}
                >
                  📋 コピー
                </button>
              </div>
              <div
                style={{
                  marginBottom: 16,
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                }}
              >
                <div>
                  <strong>ジャンル:</strong>{" "}
                  <span
                    style={{
                      fontSize: "18px",
                      color: "#dc3545",
                      fontWeight: "bold",
                    }}
                  >
                    {analysisResult.genre || "N/A"}
                  </span>
                </div>
                <button
                  onClick={() =>
                    copyToClipboard(analysisResult.genre || "N/A", "ジャンル")
                  }
                  style={{
                    padding: "4px 8px",
                    backgroundColor: "#dc3545",
                    color: "white",
                    border: "none",
                    borderRadius: "3px",
                    cursor: "pointer",
                    fontSize: "11px",
                  }}
                >
                  📋 コピー
                </button>
              </div>
              <div
                style={{ marginBottom: 16, fontSize: "12px", color: "#666" }}
              >
                <strong>ファイル名:</strong> {analysisResult.file_path || "N/A"}
              </div>
              <div
                style={{
                  marginTop: 16,
                  paddingTop: 16,
                  borderTop: "1px solid #e9ecef",
                  display: "flex",
                  gap: "8px",
                }}
              >
                <button
                  onClick={() =>
                    copyToClipboard(
                      `BPM: ${analysisResult.bpm || "N/A"}, キー: ${
                        analysisResult.key || "N/A"
                      }, ジャンル: ${analysisResult.genre || "N/A"}`,
                      "全データ"
                    )
                  }
                  style={{
                    flex: 1,
                    padding: "8px 12px",
                    backgroundColor: "#6c757d",
                    color: "white",
                    border: "none",
                    borderRadius: "4px",
                    cursor: "pointer",
                    fontSize: "12px",
                  }}
                >
                  📋 全てコピー
                </button>
              </div>
            </div>
          )}
        </div>
      )}

      {uploadHistory.length > 0 && (
        <div
          style={{
            marginTop: 40,
            borderTop: "1px solid #e9ecef",
            paddingTop: 20,
          }}
        >
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              marginBottom: 16,
            }}
          >
            <h4 style={{ margin: 0, color: "#666" }}>これまでに解析した曲</h4>
            <button
              onClick={() => setShowHistory(!showHistory)}
              style={{
                padding: "4px 12px",
                backgroundColor: "#6c757d",
                color: "white",
                border: "none",
                borderRadius: "4px",
                cursor: "pointer",
                fontSize: "12px",
              }}
            >
              {showHistory ? "非表示" : `履歴を表示 (${uploadHistory.length})`}
            </button>
          </div>

          {showHistory && (
            <div
              style={{
                maxHeight: "200px",
                overflowY: "auto",
                backgroundColor: "#f8f9fa",
                borderRadius: "6px",
                padding: "12px",
              }}
            >
              {uploadHistory.map((item) => (
                <div
                  key={item.id}
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                    padding: "8px 12px",
                    marginBottom: "8px",
                    backgroundColor: "white",
                    borderRadius: "4px",
                    border: "1px solid #e9ecef",
                  }}
                >
                  <div style={{ flex: 1 }}>
                    <div
                      style={{
                        fontSize: "12px",
                        fontWeight: "bold",
                        marginBottom: "2px",
                      }}
                    >
                      {item.fileName}
                    </div>
                    <div style={{ fontSize: "11px", color: "#666" }}>
                      BPM: {item.bpm} | キー: {item.key} | ジャンル:{" "}
                      {item.genre}
                    </div>
                    <div style={{ fontSize: "10px", color: "#999" }}>
                      {item.displayDate}
                    </div>
                  </div>
                  <button
                    onClick={() =>
                      copyToClipboard(
                        `BPM: ${item.bpm}, キー: ${item.key}, ジャンル: ${item.genre}`,
                        "履歴データ"
                      )
                    }
                    style={{
                      padding: "4px 8px",
                      backgroundColor: "#6c757d",
                      color: "white",
                      border: "none",
                      borderRadius: "3px",
                      cursor: "pointer",
                      fontSize: "10px",
                    }}
                  >
                    📋
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* YouTube登録フォーム */}
      <div
        style={{
          marginBottom: 40,
          padding: 20,
          border: "2px dashed #dc3545",
          borderRadius: "8px",
        }}
      >
        <h3></h3>
        <input
          value={ytUrl}
          onChange={(e) => setYtUrl(e.target.value)}
          placeholder="Youtube"
          style={{
            width: "100%",
            padding: "12px",
            marginBottom: "12px",
            border: "1px solid #ddd",
            borderRadius: "6px",
          }}
        />
        <button
          onClick={registerYoutube}
          style={{
            padding: "12px 24px",
            backgroundColor: "#dc3545",
            color: "white",
            border: "none",
            borderRadius: "6px",
          }}
        >
          📺 登録
        </button>
      </div>
    </div>
  );
}
