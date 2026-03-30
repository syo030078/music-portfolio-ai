#!/usr/bin/env python3
import argparse, json, os, tempfile
import numpy as np
import librosa
from pydub import AudioSegment


def load_wav(path):
    # 音声ファイルの読み込み（MP3→WAV自動変換対応）
    converted_path = None
    try:
        # WAV以外の場合は一時WAVファイルに変換
        if not path.lower().endswith('.wav'):
            temp_wav = tempfile.NamedTemporaryFile(suffix='.wav', delete=False)
            converted_path = temp_wav.name
            temp_wav.close()

            # pydub + ffmpegで変換
            audio = AudioSegment.from_file(path)
            audio.export(converted_path, format="wav")
            actual_path = converted_path
        else:
            actual_path = path

        # librosaで読み込み（22050Hzに統一し処理速度を優先）
        y, sr = librosa.load(actual_path, sr=22050, mono=True)
        return y, sr

    finally:
        # 一時ファイル削除
        if converted_path and os.path.exists(converted_path):
            os.unlink(converted_path)


def estimate_bpm(y, sr):
    # テンポとビートフレームを推定（beat_framesも返す）
    tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr)
    if tempo is not None:
        # numpy配列の場合は最初の要素を取得
        if hasattr(tempo, 'item'):
            tempo = tempo.item()
        return int(round(float(tempo))), beat_frames
    return 0, beat_frames


def estimate_key(y, sr):
    chroma = librosa.feature.chroma_cqt(y=y, sr=sr)
    pitch_class = int(chroma.mean(axis=1).argmax())
    keys = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    return keys[pitch_class]


def compute_rms(y):
    # RMSを一度だけ計算して再利用するためのヘルパー
    return librosa.feature.rms(y=y)[0]


def estimate_energy_level(rms):
    # RMSエネルギーからエネルギーレベルを推定
    rms_mean = float(np.mean(rms))

    if rms_mean > 0.08:
        level = "high"
    elif rms_mean > 0.03:
        level = "medium"
    else:
        level = "low"

    return {"level": level, "rms_mean": round(rms_mean, 4)}


def estimate_tempo_stability(beat_frames, sr):
    # ビートフレーム間隔の変動係数でテンポ安定性を推定
    if beat_frames is None or len(beat_frames) < 3:
        return {"stability": "unknown", "cv": None}

    beat_times = librosa.frames_to_time(beat_frames, sr=sr)
    intervals = np.diff(beat_times)

    if len(intervals) == 0 or np.mean(intervals) == 0:
        return {"stability": "unknown", "cv": None}

    cv = float(np.std(intervals) / np.mean(intervals))

    if cv < 0.05:
        stability = "stable"
    elif cv < 0.15:
        stability = "moderate"
    else:
        stability = "variable"

    return {"stability": stability, "cv": round(cv, 4)}


def estimate_sections(y, sr, rms):
    # 自己相似行列ベースのセクション分割（事前計算済みRMSを再利用）
    try:
        mfcc = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=13)
        n_segments = min(8, max(2, int(len(y) / sr / 30)))
        bound_frames = librosa.segment.agglomerative(mfcc, n_segments)
        bound_times = librosa.frames_to_time(bound_frames, sr=sr)
        duration = len(y) / sr

        all_times = sorted(set([0.0] + list(bound_times) + [duration]))

        rms_times = librosa.frames_to_time(np.arange(len(rms)), sr=sr)
        overall_rms_mean = float(np.mean(rms))

        sections = []
        total = len(all_times) - 1
        for i in range(total):
            start_t, end_t = all_times[i], all_times[i + 1]
            mask = (rms_times >= start_t) & (rms_times < end_t)
            section_rms = (
                float(np.mean(rms[mask])) if np.any(mask) else overall_rms_mean
            )

            is_high = section_rms > overall_rms_mean * 1.2
            is_low = section_rms < overall_rms_mean * 0.7

            if i == 0 and is_low:
                label = "intro"
            elif i == total - 1 and is_low:
                label = "outro"
            elif is_high:
                label = "chorus"
            else:
                label = "verse"

            sections.append({
                "start_sec": round(start_t, 1),
                "end_sec": round(end_t, 1),
                "label": label,
            })

        return sections
    except Exception:
        return []


def estimate_spectral_brightness(y, sr):
    # スペクトルロールオフで音色の明るさを推定
    rolloff = librosa.feature.spectral_rolloff(y=y, sr=sr, roll_percent=0.85)[0]
    rolloff_mean = float(np.mean(rolloff))

    if rolloff_mean > 6000:
        brightness = "bright"
    elif rolloff_mean > 3000:
        brightness = "warm"
    else:
        brightness = "dark"

    return {"brightness": brightness, "rolloff_mean": round(rolloff_mean, 1)}


def main():
    ap = argparse.ArgumentParser(description="Analyze local audio file (BPM/Key)")
    ap.add_argument("--file", required=True, help="path to audio file")
    args = ap.parse_args()

    try:
        # load_wavが自動でMP3→WAV変換を処理
        y, sr = load_wav(args.file)
        tempo, beat_frames = estimate_bpm(y, sr)
        key = estimate_key(y, sr)

        # 拡張分析（RMSは一度だけ計算して再利用）
        rms = compute_rms(y)
        energy = estimate_energy_level(rms)
        tempo_stab = estimate_tempo_stability(beat_frames, sr)
        sections = estimate_sections(y, sr, rms)
        spectral = estimate_spectral_brightness(y, sr)
        duration_sec = round(len(y) / sr, 1)

        # 結果出力
        result = {
            "bpm": tempo,
            "key": key or "C",
            "genre": "Unknown",
            "analysis_data": {
                "energy_level": energy["level"],
                "energy_rms_mean": energy["rms_mean"],
                "tempo_stability": tempo_stab["stability"],
                "tempo_stability_cv": tempo_stab["cv"],
                "duration_sec": duration_sec,
                "spectral_brightness": spectral["brightness"],
                "spectral_rolloff_mean": spectral["rolloff_mean"],
                "sections": sections,
                "section_count": len(sections),
                "has_distinct_sections": len(sections) >= 3,
            },
        }
        print(json.dumps(result))

    except Exception:
        # エラー時はフォールバックデータ
        result = {
            "bpm": 120,
            "key": "C",
            "genre": "Unknown",
            "analysis_data": {},
        }
        print(json.dumps(result))


if __name__ == "__main__":
    main()
