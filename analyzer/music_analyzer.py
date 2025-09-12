#!/usr/bin/env python3
import argparse, json, os, tempfile
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

        # librosaで読み込み
        y, sr = librosa.load(actual_path, sr=None, mono=True)
        return y, sr

    finally:
        # 一時ファイル削除
        if converted_path and os.path.exists(converted_path):
            os.unlink(converted_path)

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

    try:
        # load_wavが自動でMP3→WAV変換を処理
        y, sr = load_wav(args.file)
        tempo = estimate_bpm(y, sr)
        key = estimate_key(y, sr)

        # 結果出力
        result = {
            "bpm": tempo,
            "key": key or "C",
            "genre": "Unknown"
        }
        print(json.dumps(result))

    except Exception as e:
        # エラー時はフォールバックデータ
        result = {
            "bpm": 120,
            "key": "C",
            "genre": "Unknown"
        }
        print(json.dumps(result))


if __name__ == "__main__":
    main()
