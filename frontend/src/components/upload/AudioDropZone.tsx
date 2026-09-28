"use client";
import { useState } from "react";

type Props = {
  audioFile: File | null;
  audioUrl: string;
  loading: boolean;
  onSelect: (file: File) => void;
  onSubmit: () => void;
};

export default function AudioDropZone({ audioFile, audioUrl, loading, onSelect, onSubmit }: Props) {
  const [isDragOver, setIsDragOver] = useState(false);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      onSelect(file);
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
    const file = e.dataTransfer.files[0];
    if (file && file.type.startsWith("audio/")) {
      onSelect(file);
    }
  };

  return (
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
            onClick={onSubmit}
            disabled={loading}
            className="w-full rounded-lg bg-purple-600 px-6 py-3 font-semibold text-white transition-colors hover:bg-purple-700 disabled:bg-gray-400"
          >
            {loading ? "解析中..." : "解析してアップロード"}
          </button>
        </div>
      )}
    </div>
  );
}
