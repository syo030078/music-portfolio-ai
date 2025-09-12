#!/usr/bin/env python3
"""
音楽解析スクリプト
音声ファイルからBPM、キー、ジャンルを解析してJSON形式で出力する
"""

import argparse
import json
import librosa


def load_audio_file(file_path):
    """
    音声ファイルを読み込む
    
    Args:
        file_path (str): 音声ファイルのパス
        
    Returns:
        tuple: (音声データ, サンプリングレート)
    """
    audio_data, sample_rate = librosa.load(file_path, sr=None, mono=True)
    return audio_data, sample_rate


def analyze_tempo(audio_data, sample_rate):
    """
    音声データからテンポ（BPM）を推定する
    
    Args:
        audio_data: 音声データ
        sample_rate: サンプリングレート
        
    Returns:
        float: 推定されたテンポ（BPM）
    """
    tempo, _ = librosa.beat.beat_track(y=audio_data, sr=sample_rate)
    return float(tempo) if tempo is not None else 0.0


def analyze_key(audio_data, sample_rate):
    """
    音声データからキー（調）を推定する
    
    Args:
        audio_data: 音声データ
        sample_rate: サンプリングレート
        
    Returns:
        str: 推定されたキー
    """
    # クロマ特徴量を計算
    chroma = librosa.feature.chroma_cqt(y=audio_data, sr=sample_rate)
    
    # 最も強いピッチクラスを特定
    pitch_class = int(chroma.mean(axis=1).argmax())
    
    # 音名リスト（C=0, C#=1, ..., B=11）
    key_names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    
    return key_names[pitch_class]


def analyze_genre():
    """
    ジャンル推定（MVP版では固定値を返す）
    
    Returns:
        str: ジャンル名
    """
    # TODO: 将来的にはより高度な機械学習モデルを使用
    return "Unknown"


def create_analysis_result(tempo, key, genre):
    """
    解析結果をJSON形式の辞書として作成する
    
    Args:
        tempo (float): BPM
        key (str): キー
        genre (str): ジャンル
        
    Returns:
        dict: 解析結果
    """
    return {
        "bpm": tempo,
        "key": key or "C",  # キーが取得できない場合のデフォルト値
        "genre": genre
    }


def main():
    """メイン処理"""
    # コマンドライン引数の設定
    parser = argparse.ArgumentParser(
        description="音楽ファイルを解析してBPM、キー、ジャンルを抽出します"
    )
    parser.add_argument(
        "--file", 
        required=True, 
        help="解析する音声ファイルのパス"
    )
    args = parser.parse_args()

    try:
        # 音声ファイル読み込み
        audio_data, sample_rate = load_audio_file(args.file)
        
        # 各種解析実行
        tempo = analyze_tempo(audio_data, sample_rate)
        key = analyze_key(audio_data, sample_rate)
        genre = analyze_genre()
        
        # 結果をJSON形式で出力
        result = create_analysis_result(tempo, key, genre)
        print(json.dumps(result))
        
    except Exception:
        # エラー時はデフォルト値を返す
        error_result = create_analysis_result(120.0, "C", "Unknown")
        print(json.dumps(error_result))


if __name__ == "__main__":
    main()
