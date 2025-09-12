#!/usr/bin/env python3
import os

# 1. インポートテスト
try:
    from music_analyzer import load_wav, estimate_bpm, estimate_key
    print("OK load_wav関数インポート成功")
    print("OK estimate_bpm関数インポート成功")
    print("OK estimate_key関数インポート成功")
except Exception as e:
    print(f"NG インポート失敗: {e}")

# 2. エラーハンドリングテスト
try:
    load_wav("存在しないファイル.wav")
    print("NG エラーが発生しませんでした")
except Exception:
    print("OK 適切にエラーが発生しました")

# 3. 実際の音声ファイルテスト
print("\n--- 音声ファイル解析テスト ---")
try:
    if os.path.exists("test_audio.wav"):
        print("test_audio.wavファイルが見つかりました")

        # 音声ファイル読み込みテスト
        y, sr = load_wav("test_audio.wav")
        print(f"OK 音声読み込み成功: 長さ={len(y)}, サンプルレート={sr}")

        # BPM推定テスト
        tempo = estimate_bpm(y, sr)
        print(f"BPM推定結果: {tempo}")

        # キー推定テスト
        key = estimate_key(y, sr)
        print(f"キー推定結果: {key}")

    else:
        print("test_audio.wavファイルが見つかりません")

except Exception as e:
    print(f"NG 音声解析エラー: {e}")

print("\n=== テスト完了 ===")
