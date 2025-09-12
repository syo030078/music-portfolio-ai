#!/usr/bin/env python3
"""簡易テスト"""

print("=== 簡易テスト開始 ===")

# 1. インポートテスト
try:
    from music_analyzer import load_wav
    print("OK load_wav関数インポート成功")
except Exception as e:
    print(f"NG インポート失敗: {e}")

# 2. エラーハンドリングテスト
try:
    load_wav("存在しないファイル.wav")
    print("NG エラーが発生しませんでした")
except Exception:
    print("OK 適切にエラーが発生しました")

print("=== テスト完了 ===")
