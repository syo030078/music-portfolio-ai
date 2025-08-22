# frozen_string_literal: true
require "open3"
require "timeout"

class AnalyzerRunner
  TIMEOUT_SEC = 120

  def self.call(youtube_url)
    script = Rails.root.join("analyzer", "analyze.py").to_s
    cmd = ["python3", script, "--url", youtube_url]

    stdout = nil
    status = nil
    begin
      Timeout.timeout(TIMEOUT_SEC) do
        stdout, stderr, status = Open3.capture3(*cmd)
        raise(StandardError, stderr.presence || "analyzer failed") unless status.success?
      end
    rescue Timeout::Error
      raise(StandardError, "analyzer timeout")
    end

    JSON.parse(stdout)
  end
end

