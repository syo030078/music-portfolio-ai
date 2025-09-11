# frozen_string_literal: true

class AnalyzerRunner
  def self.call(audio_file_path)
    {
      message: "load_wav",
      file_path: audio_file_path,
      bpm: 120.0,
      key: "C",
      genre: "Pop",
      status: "success"
    }
  end
end
