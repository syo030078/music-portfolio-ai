#!/usr/bin/env python3
import argparse, json
import librosa

def load_wav(path):
    # 音声ファイルの読み込み
    y, sr = librosa.load(path, sr=None, mono=True)
    return y, sr

def estimate_bpm(y, sr):
    # テンポとビートを推定
    tempo, _ = librosa.beat.beat_track(y=y, sr=sr)
    if tempo is not None:
        # numpy配列の場合は最初の要素を取得
        if hasattr(tempo, 'item'):
            tempo = tempo.item()
        return int(round(float(tempo)))
    return 0

def estimate_key(y, sr):
    chroma = librosa.feature.chroma_cqt(y=y, sr=sr)
    pitch_class = int(chroma.mean(axis=1).argmax())
    keys = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
    return keys[pitch_class]

def main():
    ap = argparse.ArgumentParser(description="Analyze local audio file (BPM/Key)")
    ap.add_argument("--file", required=True, help="path to audio file ")
    args = ap.parse_args()

    y, sr = load_wav(args.file)
    tempo = estimate_bpm(y, sr)
    key = estimate_key(y, sr)

    # 簡易ジャンル（MVPは固定/空でOK）
    result = {
        "bpm": tempo,
        "key": key or "C",
        "genre": "Unknown"
    }
    print(json.dumps(result))


if __name__ == "__main__":
    main()
