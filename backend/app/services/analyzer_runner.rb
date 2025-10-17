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
      # Open3.popen3でPython解析実行（60秒タイムアウト）
      stdout_str = nil
      stderr_str = nil
      exit_status = nil

      Open3.popen3(python_path.to_s, analyzer_script.to_s, "--file", audio_file_path, chdir: Rails.root.join('..').to_s) do |stdin, stdout, stderr, wait_thr|
        stdin.close

        # タイムアウト付きで待機
        begin
          Timeout.timeout(60) do
            stdout_str = stdout.read
            stderr_str = stderr.read
            exit_status = wait_thr.value
          end
        rescue Timeout::Error
          # タイムアウト時はプロセスをkill
          Process.kill('KILL', wait_thr.pid) rescue nil
          Rails.logger.error("Python解析タイムアウト (60秒)")
          return { error: "解析がタイムアウトしました。ファイルサイズが大きすぎる可能性があります。" }
        end
      end

      if exit_status.success?
        # JSON解析結果をパース
        result = JSON.parse(stdout_str)
        result.merge({
          file_path: File.basename(audio_file_path),
          message: "Analysis completed",
          status: "success"
        })
      else
        Rails.logger.error("Python解析失敗 (exit code: #{exit_status.exitstatus})")
        Rails.logger.error("stderr: #{stderr_str}")
        Rails.logger.error("stdout: #{stdout_str}")
        { error: "音楽解析に失敗しました。ファイル形式を確認してください。" }
      end

    rescue JSON::ParserError => e
      Rails.logger.error("JSON解析失敗: #{e.message}")
      Rails.logger.error("stdout: #{stdout_str}")
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
