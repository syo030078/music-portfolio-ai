# frozen_string_literal: true

require 'json'
require 'open3'

class AnalyzerRunner
  def self.call(audio_file_path)
    # Python解析スクリプトのパス
    analyzer_script = Rails.root.join('..', 'analyzer', 'music_analyzer.py')

    # 仮想環境のPython3パス
    python_path = Rails.root.join('..', '.venv', 'bin', 'python3')

    begin
      # Open3.capture3でPython解析実行
      stdout, stderr, status = Open3.capture3(
        python_path.to_s, analyzer_script.to_s, "--file", audio_file_path,
        chdir: Rails.root.join('..').to_s,
        timeout: 30
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
        Rails.logger.error("Python解析失敗: #{stderr}")
        fallback_data(audio_file_path)
      end

    rescue JSON::ParserError => e
      Rails.logger.error("JSON解析失敗: #{e.message}")
      fallback_data(audio_file_path)
    rescue => e
      Rails.logger.error("解析エラー: #{e.message}")
      fallback_data(audio_file_path)
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
