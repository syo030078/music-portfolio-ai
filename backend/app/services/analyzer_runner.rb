# frozen_string_literal: true

require 'json'
require 'open3'

class AnalyzerRunner
  def self.call(audio_file_path)
    # Python解析スクリプトのパス
    analyzer_script = Rails.root.join('..', 'analyzer', 'music_analyzer.py')

    # 仮想環境のPython3パス（標準パス）
    python_path = Rails.root.join('..', '.venv', 'bin', 'python3')

    # Pythonやスクリプトの存在確認
    unless File.exist?(python_path)
      Rails.logger.error("Pythonパスが見つかりません: #{python_path}")
      return { error: "Python環境が見つかりません" }
    end

    unless File.exist?(analyzer_script)
      Rails.logger.error("解析スクリプトが見つかりません: #{analyzer_script}")
      return { error: "解析スクリプトが見つかりません" }
    end

    unless File.exist?(audio_file_path)
      Rails.logger.error("音声ファイルが見つかりません: #{audio_file_path}")
      return { error: "音声ファイルが見つかりません" }
    end

    begin
      # Open3.capture3でPython解析実行
      stdout, stderr, status = Open3.capture3(
        python_path.to_s, analyzer_script.to_s, "--file", audio_file_path,
        chdir: Rails.root.join('..').to_s
      )

      if status.success?
        # JSON解析結果をパース
        result = JSON.parse(stdout)
        result.merge({
          file_path: File.basename(audio_file_path),
          message: "Analysis completed",
          status: "success"
        })
      else
        Rails.logger.error("Python解析失敗 (exit code: #{status.exitstatus})")
        Rails.logger.error("stderr: #{stderr}")
        Rails.logger.error("stdout: #{stdout}")
        { error: "音楽解析に失敗しました。ファイル形式を確認してください。" }
      end

    rescue JSON::ParserError => e
      Rails.logger.error("JSON解析失敗: #{e.message}")
      Rails.logger.error("stdout: #{stdout}")
      { error: "解析結果の読み込みに失敗しました" }
    rescue => e
      Rails.logger.error("解析エラー: #{e.class} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      { error: "解析処理中にエラーが発生しました" }
    end
  end

  private

  def self.fallback_data(audio_file_path)
    {
      message: "load_wav",
      file_path: File.basename(audio_file_path),
      bpm: 120.0,
      key: "C",
      genre: "Pop",
      status: "fallback"
    }
  end
end
