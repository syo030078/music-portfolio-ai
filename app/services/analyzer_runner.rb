# app/services/analyzer_runner.rb
require 'json'
require 'open3'

class AnalyzerRunner
  # YouTube URL を受け取り、{ "bpm"=>..., "key"=>..., "genre"=>..., "ai_text"=>... } を返す
  def self.call(url)
    # 仮想環境の python を明示（必要に応じて調整）
    py = Rails.root.join(".venv/bin/python").to_s
    script = Rails.root.join("analyzer/analyze.py").to_s

    cmd = [py, script, "--url", url]

    stdout, stderr, status = Open3.capture3(*cmd, chdir: Rails.root.to_s)

    unless status.success?
      Rails.logger.error("[AnalyzerRunner] exit=#{status.exitstatus} stderr=#{stderr}")
      raise "Analyzer failed: #{stderr}"
    end

    # analyzer/analyze.py は JSON を標準出力に出す想定
    JSON.parse(stdout) # => Ruby の Hash を返す
  rescue => e
    Rails.logger.error("[AnalyzerRunner] Error: #{e.class}: #{e.message}")
    raise
  end
end
