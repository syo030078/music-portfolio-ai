require 'rails_helper'

RSpec.describe TrackAudioAnalysisService do
  let(:user) { User.create!(email: 'musician@example.com', password: 'password123', name: 'Musician') }
  let(:audio_file) { fixture_file_upload('test.wav', 'audio/wav') }

  describe '.call' do
    context 'when analysis succeeds' do
      before do
        allow(AnalyzerRunner).to receive(:call).and_return({
          bpm: 120,
          key: "C",
          genre: "Pop",
          file_path: "test.wav",
          status: "success"
        })
      end

      it 'creates a track owned by the user and returns success' do
        result = described_class.call(user: user, audio_file: audio_file, title: 'My Track')

        expect(result.success?).to be true
        expect(result.message).to eq("楽曲を登録しました")
        expect(result.data[:bpm]).to eq(120)
        expect(result.data[:key]).to eq("C")
        expect(result.data[:genre]).to eq("Pop")
        expect(result.data[:uuid]).to be_present

        created_track = Track.last
        expect(created_track.user_id).to eq(user.id)
        expect(created_track.title).to eq('My Track')
      end

      it 'uses the filename (without extension) as the default title when title is blank' do
        result = described_class.call(user: user, audio_file: audio_file, title: nil)

        expect(result.success?).to be true
        expect(Track.last.title).to eq('test')
      end

      it 'deletes the temporary uploaded file afterward' do
        described_class.call(user: user, audio_file: audio_file, title: 'My Track')

        temp_path = Rails.root.join('tmp', 'uploads', audio_file.original_filename)
        expect(File.exist?(temp_path)).to be false
      end

      it 'passes the written temp file path to AnalyzerRunner' do
        described_class.call(user: user, audio_file: audio_file, title: 'My Track')

        expect(AnalyzerRunner).to have_received(:call).with(a_string_ending_with('test.wav'))
      end
    end

    context 'when AnalyzerRunner returns a string-keyed result (raw JSON.parse shape)' do
      before do
        allow(AnalyzerRunner).to receive(:call).and_return({
          "bpm" => 98,
          "key" => "Am",
          "genre" => "Lo-fi",
          "status" => "success"
        })
      end

      it 'still reads bpm/key/genre via the defensive string-key fallback' do
        result = described_class.call(user: user, audio_file: audio_file, title: 'My Track')

        expect(result.success?).to be true
        expect(result.data[:bpm]).to eq(98)
        expect(result.data[:key]).to eq("Am")
        expect(result.data[:genre]).to eq("Lo-fi")
      end
    end

    context 'when analysis fails' do
      before do
        allow(AnalyzerRunner).to receive(:call).and_return({
          error: "音楽解析に失敗しました。ファイル形式を確認してください。"
        })
      end

      it 'returns a failure result without creating a track' do
        result = nil

        expect {
          result = described_class.call(user: user, audio_file: audio_file, title: 'My Track')
        }.not_to change(Track, :count)

        expect(result.success?).to be false
        expect(result.status).to eq(:unprocessable_entity)
        expect(result.error).to eq("音楽解析に失敗しました。ファイル形式を確認してください。")
      end

      it 'deletes the temporary uploaded file' do
        described_class.call(user: user, audio_file: audio_file, title: 'My Track')

        temp_path = Rails.root.join('tmp', 'uploads', audio_file.original_filename)
        expect(File.exist?(temp_path)).to be false
      end
    end

    context 'when the track fails to save' do
      before do
        allow(AnalyzerRunner).to receive(:call).and_return({ bpm: 120, key: "C", genre: "Pop", status: "success" })
      end

      it 'returns a failure result with the validation error' do
        long_title = 'a' * 121

        result = described_class.call(user: user, audio_file: audio_file, title: long_title)

        expect(result.success?).to be false
        expect(result.status).to eq(:unprocessable_entity)
        expect(result.error).to be_present
      end

      it 'deletes the temporary uploaded file' do
        long_title = 'a' * 121

        described_class.call(user: user, audio_file: audio_file, title: long_title)

        temp_path = Rails.root.join('tmp', 'uploads', audio_file.original_filename)
        expect(File.exist?(temp_path)).to be false
      end
    end

    context 'when AnalyzerRunner raises an unexpected error' do
      before do
        allow(AnalyzerRunner).to receive(:call).and_raise(StandardError.new('boom'))
      end

      it 'returns an internal_server_error failure and still cleans up the temp file' do
        result = described_class.call(user: user, audio_file: audio_file, title: 'My Track')

        expect(result.success?).to be false
        expect(result.status).to eq(:internal_server_error)
        expect(result.error).to eq("解析エラーが発生しました")

        temp_path = Rails.root.join('tmp', 'uploads', audio_file.original_filename)
        expect(File.exist?(temp_path)).to be false
      end
    end
  end
end
