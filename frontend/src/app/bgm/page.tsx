"use client";

import { useState } from "react";
import { useBgmPlayer } from "@/hooks/useBgmPlayer";
import { composeSong, MOOD_IDS, MOODS, SECTION_LABELS, type MoodId, type Song } from "@/lib/bgm/compose";
import { randomSeed } from "@/lib/bgm/random";
import { renderSong } from "@/lib/bgm/render";
import { NOTE_NAMES } from "@/lib/bgm/theory";
import { audioBufferToWav } from "@/lib/bgm/wav";

const LENGTH_OPTIONS = [1, 2, 3, 5] as const;

const SECTION_COLORS = {
  intro: "bg-green-200",
  A: "bg-green-400",
  B: "bg-green-600",
  outro: "bg-green-300",
} as const;

const formatTime = (seconds: number) => {
  const s = Math.floor(seconds);
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
};

export default function BgmPage() {
  const player = useBgmPlayer();
  const [mood, setMood] = useState<MoodId>("lofi");
  const [bpm, setBpm] = useState(MOODS.lofi.bpm.default);
  const [key, setKey] = useState<number | null>(null);
  const [minutes, setMinutes] = useState<number>(2);
  const [seed, setSeed] = useState(1017);
  const [song, setSong] = useState<Song | null>(null);
  const [buffer, setBuffer] = useState<AudioBuffer | null>(null);
  const [rendering, setRendering] = useState(false);
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState<string | null>(null);

  const preset = MOODS[mood];

  const selectMood = (id: MoodId) => {
    setMood(id);
    setBpm(MOODS[id].bpm.default);
  };

  const generate = async (nextSeed = seed) => {
    player.ensureContext();
    setRendering(true);
    setProgress(0);
    setError(null);
    try {
      const composed = composeSong({ mood, bpm, key, minutes, seed: nextSeed });
      const rendered = await renderSong(composed, setProgress);
      player.load(rendered);
      player.play();
      setSong(composed);
      setBuffer(rendered);
    } catch (e) {
      setError(e instanceof Error ? e.message : "BGMの生成に失敗しました");
    } finally {
      setRendering(false);
    }
  };

  const generateWithNewSeed = () => {
    const next = randomSeed();
    setSeed(next);
    void generate(next);
  };

  const download = () => {
    if (!buffer || !song) return;
    const url = URL.createObjectURL(audioBufferToWav(buffer));
    const link = document.createElement("a");
    link.href = url;
    link.download = `${song.title.replace(/\s+/g, "_")}_${song.settings.seed}.wav`;
    link.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="bg-gradient-to-r from-green-600 to-green-700 py-12">
        <div className="mx-auto max-w-7xl px-4">
          <h1 className="text-2xl font-bold text-white mb-2 md:text-4xl">作業BGMジェネレーター</h1>
          <p className="text-green-100 text-base md:text-lg">
            コード進行もメロディも音色も、その場でアルゴリズムが作る完全オリジナルのBGM
          </p>
        </div>
      </div>

      <main className="mx-auto max-w-5xl px-4 py-12 space-y-8">
        <section className="bg-white rounded-lg shadow-md p-6 md:p-8">
          <h2 className="text-xl font-bold text-gray-900 mb-4">雰囲気を選ぶ</h2>
          <div className="grid gap-3 sm:grid-cols-2">
            {MOOD_IDS.map((id) => (
              <button
                key={id}
                type="button"
                onClick={() => selectMood(id)}
                aria-pressed={mood === id}
                className={`rounded-lg border-2 p-4 text-left transition-colors ${
                  mood === id ? "border-green-600 bg-green-50" : "border-gray-200 hover:border-green-400"
                }`}
              >
                <div className="font-semibold text-gray-900">{MOODS[id].label}</div>
                <div className="mt-1 text-sm text-gray-600">{MOODS[id].description}</div>
              </button>
            ))}
          </div>

          <div className="mt-8 grid gap-6 md:grid-cols-2">
            <label className="block">
              <span className="flex justify-between text-sm font-medium text-gray-700">
                テンポ <span className="text-gray-900">{bpm} BPM</span>
              </span>
              <input
                type="range"
                min={preset.bpm.min}
                max={preset.bpm.max}
                value={bpm}
                onChange={(e) => setBpm(Number(e.target.value))}
                className="mt-3 w-full accent-green-600"
              />
            </label>

            <label className="block">
              <span className="text-sm font-medium text-gray-700">キー</span>
              <select
                value={key ?? ""}
                onChange={(e) => setKey(e.target.value === "" ? null : Number(e.target.value))}
                className="mt-2 w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-green-500 focus:ring-2 focus:ring-green-500 focus:outline-none"
              >
                <option value="">おまかせ</option>
                {NOTE_NAMES.map((name, i) => (
                  <option key={name} value={i}>
                    {name}
                  </option>
                ))}
              </select>
            </label>

            <div>
              <span className="text-sm font-medium text-gray-700">長さ（ループ1周）</span>
              <div className="mt-2 flex gap-2">
                {LENGTH_OPTIONS.map((m) => (
                  <button
                    key={m}
                    type="button"
                    onClick={() => setMinutes(m)}
                    aria-pressed={minutes === m}
                    className={`flex-1 rounded-md border px-3 py-2 text-sm font-medium transition-colors ${
                      minutes === m
                        ? "border-green-600 bg-green-600 text-white"
                        : "border-gray-300 text-gray-700 hover:bg-gray-50"
                    }`}
                  >
                    約{m}分
                  </button>
                ))}
              </div>
            </div>

            <label className="block">
              <span className="text-sm font-medium text-gray-700">シード値（同じ値なら同じ曲になる）</span>
              <input
                type="number"
                min={0}
                value={seed}
                onChange={(e) => setSeed(Math.max(0, Math.floor(Number(e.target.value) || 0)))}
                className="mt-2 w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-green-500 focus:ring-2 focus:ring-green-500 focus:outline-none"
              />
            </label>
          </div>

          <div className="mt-8 flex flex-col gap-3 sm:flex-row">
            <button
              type="button"
              onClick={() => void generate()}
              disabled={rendering}
              className="flex-1 rounded-lg bg-green-600 px-6 py-3 text-sm font-semibold text-white transition-colors hover:bg-green-700 disabled:opacity-50"
            >
              {rendering ? `作曲・合成中... ${Math.round(progress * 100)}%` : "この設定でBGMを生成"}
            </button>
            <button
              type="button"
              onClick={generateWithNewSeed}
              disabled={rendering}
              className="flex-1 rounded-lg border border-green-600 px-6 py-3 text-sm font-semibold text-green-700 transition-colors hover:bg-green-50 disabled:opacity-50"
            >
              別の曲を作る（シード値をランダムに）
            </button>
          </div>
        </section>

        {error && <div className="rounded-lg bg-red-50 p-4 text-sm text-red-800">{error}</div>}

        {song && buffer && (
          <section className="bg-white rounded-lg shadow-md p-6 md:p-8">
            <div className="flex flex-wrap items-start justify-between gap-4">
              <div>
                <h2 className="text-2xl font-bold text-gray-900">{song.title}</h2>
                <div className="mt-2 flex flex-wrap gap-3 text-xs text-gray-500">
                  <span>{song.preset.label}</span>
                  <span>{song.keyLabel}</span>
                  <span>BPM: {song.settings.bpm}</span>
                  <span>{song.bars}小節 / {formatTime(song.duration)}</span>
                  <span>シード値: {song.settings.seed}</span>
                </div>
              </div>
              <button
                type="button"
                onClick={download}
                className="rounded-md bg-green-50 px-4 py-2 text-sm font-medium text-green-700 transition-colors hover:bg-green-100"
              >
                WAVでダウンロード
              </button>
            </div>

            <div className="mt-6 flex items-center gap-4">
              <button
                type="button"
                onClick={player.isPlaying ? player.pause : player.play}
                aria-label={player.isPlaying ? "一時停止" : "再生"}
                className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-green-600 text-white transition-colors hover:bg-green-700"
              >
                {player.isPlaying ? (
                  <svg className="h-5 w-5" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M6 5h4v14H6zM14 5h4v14h-4z" />
                  </svg>
                ) : (
                  <svg className="h-5 w-5" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M8 5v14l11-7z" />
                  </svg>
                )}
              </button>
              <div className="flex-1">
                <div className="flex h-2 overflow-hidden rounded-full">
                  {song.sections.map((section) => (
                    <div
                      key={section.startBar}
                      className={`${SECTION_COLORS[section.kind]} border-r border-white last:border-r-0`}
                      style={{ width: `${(section.bars / song.bars) * 100}%` }}
                      title={SECTION_LABELS[section.kind]}
                    />
                  ))}
                </div>
                <input
                  type="range"
                  min={0}
                  max={buffer.duration}
                  step={0.1}
                  value={player.position}
                  onChange={(e) => player.seek(Number(e.target.value))}
                  aria-label="再生位置"
                  className="mt-1 w-full accent-green-600"
                />
                <div className="flex justify-between text-xs text-gray-500">
                  <span>{formatTime(player.position)}</span>
                  <span className="hidden sm:inline">終わりまで来たら先頭に戻って流れ続けます</span>
                  <span>{formatTime(buffer.duration)}</span>
                </div>
              </div>
            </div>

            <label className="mt-4 flex items-center gap-3 text-sm text-gray-700">
              音量
              <input
                type="range"
                min={0}
                max={1}
                step={0.01}
                value={player.volume}
                onChange={(e) => player.setVolume(Number(e.target.value))}
                className="w-40 accent-green-600"
              />
            </label>

            <div className="mt-6 grid gap-4 sm:grid-cols-2">
              {(["A", "B"] as const).map((part) => (
                <div key={part} className="rounded-lg bg-gray-50 p-4">
                  <div className="text-xs font-medium text-gray-500">コード進行 {SECTION_LABELS[part]}</div>
                  <div className="mt-2 flex flex-wrap gap-2">
                    {song.progressions[part].map((chord, i) => (
                      <span key={i} className="rounded bg-white px-2.5 py-1 font-mono text-sm text-gray-900 shadow-sm">
                        {chord}
                      </span>
                    ))}
                  </div>
                </div>
              ))}
            </div>

            <div className="mt-4 flex flex-wrap gap-2 text-xs text-gray-600">
              {song.sections.map((section) => (
                <span key={section.startBar} className="rounded-full bg-gray-100 px-2.5 py-1">
                  {section.startBar + 1}〜{section.startBar + section.bars}小節: {SECTION_LABELS[section.kind]}
                </span>
              ))}
            </div>
          </section>
        )}

        <section className="rounded-lg border border-gray-200 bg-white p-6 text-sm text-gray-600">
          <h2 className="font-semibold text-gray-900 mb-2">オリジナルである理由</h2>
          <ul className="list-disc space-y-1 pl-5">
            <li>既存の楽曲・サンプル音源・外部の生成AIは使っていません。音色はすべてブラウザ内の発振器とノイズから合成しています。</li>
            <li>コード進行・メロディ・ベース・ドラムのパターンは、シード値をもとにその場で作曲しています。</li>
            <li>同じ設定とシード値なら同じ曲を再現できます。気に入った曲はシード値を控えておくか、WAVで保存してください。</li>
          </ul>
        </section>
      </main>
    </div>
  );
}
