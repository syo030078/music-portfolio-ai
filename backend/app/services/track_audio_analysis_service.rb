class TrackAudioAnalysisService
  Result = Struct.new(:success?, :message, :data, :error, :status, keyword_init: true)

  def self.call(user:, audio_file:, title:)
    new(user, audio_file, title).call
  end

  def initialize(user, audio_file, title)
    @user = user
    @audio_file = audio_file
    @title = title
    @temp_path = Rails.root.join('tmp', 'uploads', audio_file.original_filename)
  end

  def call
    write_temp_file
    result = AnalyzerRunner.call(temp_path.to_s)

    # AnalyzerRunnerのエラー時ハッシュは常に{error: ...}のみを持つ前提で文字列だけ渡している
    return failure(result[:error], :unprocessable_entity) if result[:error]

    track = build_track(result)

    if track.save
      track.reload
      success(track)
    else
      failure(track.errors.full_messages.join(", "), :unprocessable_entity)
    end
  rescue => e
    Rails.logger.error("解析処理エラー: #{e.message}")
    failure("解析エラーが発生しました", :internal_server_error)
  ensure
    File.delete(temp_path) if File.exist?(temp_path)
  end

  private

  attr_reader :user, :audio_file, :title, :temp_path

  def write_temp_file
    FileUtils.mkdir_p(File.dirname(temp_path))
    File.write(temp_path, audio_file.read, mode: 'wb')
  end

  def build_track(result)
    # AnalyzerRunnerはJSON.parse(文字列キー)+ merge(シンボルキー)混在のハッシュを返すため両方参照する
    Track.new(
      user_id: user.id,
      title: title || File.basename(audio_file.original_filename, '.*'),
      bpm: result[:bpm] || result["bpm"],
      key: result[:key] || result["key"],
      genre: result[:genre] || result["genre"]
    )
  end

  def success(track)
    Result.new(
      success?: true,
      message: "楽曲を登録しました",
      data: { uuid: track.uuid, bpm: track.bpm, key: track.key, genre: track.genre },
      status: :created
    )
  end

  def failure(message, status)
    Result.new(success?: false, error: message, status: status)
  end
end
