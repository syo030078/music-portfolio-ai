#!/usr/bin/env python3
"""
music_analyzer.pyの基本的なテスト
"""

def test_load_wav_function_exists():
    """load_wav関数が存在することを確認"""
    try:
        from music_analyzer import load_wav
        print("✅ load_wav関数のインポートに成功")
        return True
    except ImportError as e:
        print(f"❌ load_wav関数のインポートに失敗: {e}")
        return False

def test_basic_imports():
    """基本的なライブラリのインポートテスト"""
    try:
        import json
        print("✅ json インポート成功")
    except ImportError:
        print("❌ json インポート失敗")

    try:
        import argparse
        print("✅ argparse インポート成功")
    except ImportError:
        print("❌ argparse インポート失敗")

    try:
        import librosa
        print("✅ librosa インポート成功")
    except ImportError:
        print("❌ librosa インポート失敗")

    try:
        import numpy
        print("✅ numpy インポート成功")
    except ImportError:
        print("❌ numpy インポート失敗")

def run_tests():
    """全テストを実行"""
    print("=== 基本テスト開始 ===")
    print()

    print("1. ライブラリインポートテスト:")
    test_basic_imports()
    print()

    print("2. 関数存在テスト:")
    test_load_wav_function_exists()
    print()

    print("=== テスト完了 ===")

if __name__ == "__main__":
    run_tests()
