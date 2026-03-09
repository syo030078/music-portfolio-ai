# frozen_string_literal: true

# =============================================================================
# Music Portfolio AI - Demo Seed Data
# =============================================================================
# 実用的なデモデータ。全画面を体験可能。
#
# ログイン情報:
#   音楽家: musician1@example.com ~ musician4@example.com (password123)
#   クライアント: client1@example.com ~ client3@example.com (password123)
# =============================================================================

puts "=== Seeding taxonomy master data ==="

genres = %w[Rock Pop Jazz Classical Electronic Hip\ Hop R&B Country Blues Metal Funk Latin Reggae Ambient Folk].map do |name|
  Genre.find_or_create_by!(name: name)
end

instruments = %w[Piano Guitar Bass Drums Violin Saxophone Vocals Synthesizer Trumpet Cello Flute Ukulele].map do |name|
  Instrument.find_or_create_by!(name: name)
end

skills = ['Composition', 'Arrangement', 'Mixing', 'Mastering', 'Recording', 'Production', 'Sound Design', 'Orchestration', 'Lyrics', 'Music Theory'].map do |name|
  Skill.find_or_create_by!(name: name)
end

genre_map = Genre.all.index_by(&:name)
instrument_map = Instrument.all.index_by(&:name)
skill_map = Skill.all.index_by(&:name)

# =============================================================================
# Users
# =============================================================================
puts "=== Seeding users ==="

musician1 = User.find_or_create_by!(email: 'musician1@example.com') do |u|
  u.password = 'password123'
  u.name = '田中一郎'
end
musician1.update!(
  name: '田中一郎',
  bio: "作曲家・ギタリスト。ゲーム音楽・映像音楽を中心に10年以上の制作実績があります。\n東京音楽大学卒業後、フリーランスとして活動中。RPG・アクション・シミュレーション等、幅広いジャンルのゲームBGMを手がけています。",
  is_musician: true,
  is_client: false
)

musician2 = User.find_or_create_by!(email: 'musician2@example.com') do |u|
  u.password = 'password123'
  u.name = '鈴木美咲'
end
musician2.update!(
  name: '鈴木美咲',
  bio: "Lo-Fi HipHop / Chillhop プロデューサー。Spotify・YouTube向けのリラックス系BGMを専門に制作しています。\n累計再生回数500万回超。カフェBGM・勉強用BGMなどのプレイリストに多数採用。",
  is_musician: true,
  is_client: false
)

musician3 = User.find_or_create_by!(email: 'musician3@example.com') do |u|
  u.password = 'password123'
  u.name = '高橋拓也'
end
musician3.update!(
  name: '高橋拓也',
  bio: "ジャズピアニスト・編曲家。CM・広告音楽、企業VP、ウェディング向けBGMの制作が得意です。\n国内外のジャズフェスティバルでの演奏経験あり。温かみのある上品なサウンドを提供します。",
  is_musician: true,
  is_client: false
)

musician4 = User.find_or_create_by!(email: 'musician4@example.com') do |u|
  u.password = 'password123'
  u.name = '中村さくら'
end
musician4.update!(
  name: '中村さくら',
  bio: "ボーカリスト・シンガーソングライター。ポップス・R&B・アニソン系の歌唱と作詞が専門です。\n仮歌・本歌録音、コーラスアレンジ、ナレーション収録にも対応しています。",
  is_musician: true,
  is_client: false
)

client1 = User.find_or_create_by!(email: 'client1@example.com') do |u|
  u.password = 'password123'
  u.name = '山田太郎'
end
client1.update!(
  name: '山田太郎',
  bio: 'ゲーム開発会社「PixelForge」のサウンドディレクター。インディーゲームのBGM・SE制作を外部に依頼しています。',
  is_musician: false,
  is_client: true
)

client2 = User.find_or_create_by!(email: 'client2@example.com') do |u|
  u.password = 'password123'
  u.name = '佐藤花子'
end
client2.update!(
  name: '佐藤花子',
  bio: 'YouTubeチャンネル「HanaTV」運営。登録者12万人。料理・旅行動画のBGMを定期的に募集しています。',
  is_musician: false,
  is_client: true
)

client3 = User.find_or_create_by!(email: 'client3@example.com') do |u|
  u.password = 'password123'
  u.name = '伊藤健一'
end
client3.update!(
  name: '伊藤健一',
  bio: '広告代理店プロデューサー。テレビCM・Web広告向けの楽曲制作を担当。年間20本以上のプロジェクトを管理。',
  is_musician: false,
  is_client: true
)

# =============================================================================
# Musician Profiles
# =============================================================================
puts "=== Seeding musician profiles ==="

MusicianProfile.find_or_create_by!(user: musician1) do |p|
  p.headline = 'ゲーム音楽・映像音楽の作曲家'
  p.hourly_rate_jpy = 5000
  p.avg_rating = 4.8
  p.rating_count = 23
end

MusicianProfile.find_or_create_by!(user: musician2) do |p|
  p.headline = 'Lo-Fi / Chillhop プロデューサー'
  p.hourly_rate_jpy = 3500
  p.avg_rating = 4.6
  p.rating_count = 15
end

MusicianProfile.find_or_create_by!(user: musician3) do |p|
  p.headline = 'ジャズピアニスト・CM音楽クリエイター'
  p.hourly_rate_jpy = 6000
  p.avg_rating = 4.9
  p.rating_count = 31
end

MusicianProfile.find_or_create_by!(user: musician4) do |p|
  p.headline = 'ボーカリスト・シンガーソングライター'
  p.hourly_rate_jpy = 4000
  p.avg_rating = 4.7
  p.rating_count = 18
end

# =============================================================================
# Musician Taxonomy (genres, instruments, skills)
# =============================================================================
puts "=== Seeding musician taxonomy ==="

{
  musician1 => {
    genres: %w[Rock Electronic Classical],
    instruments: %w[Guitar Piano Synthesizer],
    skills: ['Composition', 'Arrangement', 'Sound Design', 'Orchestration']
  },
  musician2 => {
    genres: ['Hip Hop', 'R&B', 'Electronic', 'Ambient'],
    instruments: %w[Synthesizer Piano Drums],
    skills: %w[Production Mixing Mastering]
  },
  musician3 => {
    genres: %w[Jazz Classical Pop Latin],
    instruments: %w[Piano Saxophone Trumpet],
    skills: ['Composition', 'Arrangement', 'Music Theory', 'Recording']
  },
  musician4 => {
    genres: %w[Pop R&B Jazz],
    instruments: %w[Vocals Piano Guitar],
    skills: %w[Lyrics Composition Recording Arrangement]
  }
}.each do |user, taxonomies|
  taxonomies[:genres].each do |name|
    MusicianGenre.find_or_create_by!(user: user, genre: genre_map[name])
  end
  taxonomies[:instruments].each do |name|
    MusicianInstrument.find_or_create_by!(user: user, instrument: instrument_map[name])
  end
  taxonomies[:skills].each do |name|
    MusicianSkill.find_or_create_by!(user: user, skill: skill_map[name])
  end
end

# =============================================================================
# Tracks (YouTube URLs)
# =============================================================================
puts "=== Seeding tracks ==="

# musician1: ゲーム音楽系
Track.find_or_create_by!(user: musician1, title: 'Fantasy Quest - メインテーマ') do |t|
  t.yt_url = 'https://www.youtube.com/watch?v=kOTpICvOqSE'
  t.description = 'ファンタジーRPGのメインテーマ曲。壮大なオーケストラサウンド。'
  t.genre = 'Orchestral'
  t.bpm = 120
  t.key = 'D major'
end

Track.find_or_create_by!(user: musician1, title: 'Battle Arena - 戦闘BGM') do |t|
  t.yt_url = 'https://www.youtube.com/watch?v=GDflVhOpS4E'
  t.description = 'アクションゲーム向けの激しい戦闘BGM。エレキギターとシンセの融合。'
  t.genre = 'Rock'
  t.bpm = 160
  t.key = 'E minor'
end

Track.find_or_create_by!(user: musician1, title: '星降る夜 - フィールドBGM') do |t|
  t.yt_url = 'https://www.youtube.com/watch?v=lE6RYpe9IT0'
  t.description = '夜のフィールドをイメージした静かなBGM。ピアノとストリングス。'
  t.genre = 'Ambient'
  t.bpm = 80
  t.key = 'F major'
end

# musician2: Lo-Fi HipHop系
Track.find_or_create_by!(user: musician2, title: 'Rainy Café - Lo-Fi Beat') do |t|
  t.yt_url = 'https://www.youtube.com/watch?v=jfKfPfyJRdk'
  t.description = '雨の日のカフェをイメージしたLo-Fiビート。勉強・作業用BGMに最適。'
  t.genre = 'Lo-Fi'
  t.bpm = 85
  t.key = 'C minor'
end

Track.find_or_create_by!(user: musician2, title: 'Sunset Drive - Chillhop') do |t|
  t.yt_url = 'https://www.youtube.com/watch?v=5qap5aO4i9A'
  t.description = '夕暮れのドライブをイメージしたChillhopトラック。'
  t.genre = 'Chillhop'
  t.bpm = 90
  t.key = 'G major'
end

# musician3: ジャズ系
Track.find_or_create_by!(user: musician3, title: 'Midnight Blue - ジャズバラード') do |t|
  t.yt_url = 'https://www.youtube.com/watch?v=vmDDOFXSgAs'
  t.description = 'しっとりとしたジャズバラード。企業VP・ウェディングBGMに。'
  t.genre = 'Jazz'
  t.bpm = 72
  t.key = 'Bb major'
end

Track.find_or_create_by!(user: musician3, title: 'Morning Coffee - ボサノヴァ') do |t|
  t.yt_url = 'https://www.youtube.com/watch?v=DIx3aMRDUL4'
  t.description = '朝のカフェタイムにぴったりのボサノヴァ。CM・店舗BGMに。'
  t.genre = 'Bossa Nova'
  t.bpm = 110
  t.key = 'A major'
end

# musician4: ボーカル系
Track.find_or_create_by!(user: musician4, title: '花が咲く頃 - ポップスデモ') do |t|
  t.yt_url = 'https://www.youtube.com/watch?v=CvFH_6DNRCY'
  t.description = '春をテーマにしたポップスの歌唱デモ。作詞作曲も担当。'
  t.genre = 'Pop'
  t.bpm = 128
  t.key = 'C major'
end

Track.find_or_create_by!(user: musician4, title: 'Moonlight - R&Bバラード') do |t|
  t.yt_url = 'https://www.youtube.com/watch?v=psuRGfAaju4'
  t.description = '切ないR&Bバラードの歌唱デモ。ウィスパーボイスが特徴。'
  t.genre = 'R&B'
  t.bpm = 68
  t.key = 'Eb major'
end

# =============================================================================
# Jobs (案件)
# =============================================================================
puts "=== Seeding jobs ==="

job1 = Job.find_or_create_by!(client: client1, title: 'インディーRPG「幻想紀行」BGM制作（全15曲）') do |j|
  j.description = <<~DESC.strip
    2Dピクセルアート RPG「幻想紀行」のBGMを制作していただける作曲家を募集します。

    ■ 必要な楽曲（全15曲）
    ・タイトル画面（1曲）
    ・フィールドBGM（4曲：草原/森/雪山/砂漠）
    ・街・村BGM（3曲）
    ・ダンジョンBGM（3曲）
    ・戦闘BGM（2曲：通常/ボス）
    ・イベントBGM（2曲：感動シーン/緊迫シーン）

    ■ 参考イメージ
    クロノトリガー、聖剣伝説のような温かみのあるファンタジーサウンド。
    各曲1〜3分程度。ループ対応必須。

    ■ 納品形式
    WAV (48kHz/24bit) + ループポイント指定書
  DESC
  j.budget_jpy = 150_000
  j.is_remote = true
  j.delivery_due_on = 90.days.from_now
  j.status = 'published'
  j.published_at = 5.days.ago
end

job2 = Job.find_or_create_by!(client: client2, title: 'YouTube料理チャンネル向けBGMセット（5曲）') do |j|
  j.description = <<~DESC.strip
    料理系YouTubeチャンネル「HanaTV」で使用するBGMセットを制作してください。

    ■ 楽曲リスト
    1. オープニングジングル（15秒）- 明るく元気な印象
    2. 調理中BGM（3分）- テンポの良いアコースティック系
    3. 盛り付け・完成BGM（2分）- 優雅でおしゃれな雰囲気
    4. トークBGM（3分）- 邪魔にならない控えめなBGM
    5. エンディング（30秒）- 余韻の残る温かい曲

    ■ 条件
    ・著作権は完全買取
    ・商用利用（YouTube収益化）
    ・リビジョン2回まで対応希望
  DESC
  j.budget_min_jpy = 30_000
  j.budget_max_jpy = 60_000
  j.is_remote = true
  j.delivery_due_on = 30.days.from_now
  j.status = 'published'
  j.published_at = 3.days.ago
end

job3 = Job.find_or_create_by!(client: client3, title: '健康食品CM用ジングル・BGM制作') do |j|
  j.description = <<~DESC.strip
    健康食品ブランド「NaturalLife」のテレビCM（15秒/30秒）用の音楽制作です。

    ■ 制作内容
    ・15秒版ジングル
    ・30秒版BGM
    ・各秒数に合わせたバリエーション

    ■ イメージ
    ターゲット：30〜50代女性
    キーワード：爽やか、自然、健康的、安心感
    楽器：アコースティックギター、ピアノ、軽いパーカッション
    ボーカルなし（インストのみ）

    ■ 納品形式
    WAV (48kHz/24bit)、CM尺に合わせたMIX
    放送用ラウドネス基準（-24 LKFS）準拠
  DESC
  j.budget_jpy = 80_000
  j.is_remote = true
  j.delivery_due_on = 21.days.from_now
  j.status = 'published'
  j.published_at = 2.days.ago
end

job4 = Job.find_or_create_by!(client: client2, title: 'Lo-Fi勉強用BGM 10曲セット') do |j|
  j.description = <<~DESC.strip
    新しいYouTubeチャンネル用のLo-Fi勉強用BGMを10曲制作してください。

    ■ コンセプト
    「深夜の図書館で聴くBGM」をテーマに、集中力を高めるLo-Fi HipHopトラック。
    各曲3〜5分。シームレスにループ可能な構成。

    ■ サウンド要素
    ・ビニールノイズ、環境音（雨音等）OK
    ・BPM 70-90程度
    ・過度なメロディは不要、テクスチャ重視

    ■ 納品
    WAV + MP3 (320kbps)
    曲ごとのクレジット表記あり
  DESC
  j.budget_jpy = 80_000
  j.is_remote = true
  j.delivery_due_on = 45.days.from_now
  j.status = 'published'
  j.published_at = 1.day.ago
end

job5 = Job.find_or_create_by!(client: client1, title: 'モバイルゲーム効果音・SE制作（50種）') do |j|
  j.description = <<~DESC.strip
    カジュアルパズルゲーム向けのSE（効果音）を50種制作してください。

    ■ カテゴリ
    ・UI音（タップ、スワイプ、決定、キャンセル等）：15種
    ・ゲームプレイ（パズル消去、コンボ、クリア等）：20種
    ・演出（レベルアップ、獲得、失敗等）：15種

    ■ イメージ
    ポップで軽快、子供から大人まで楽しめるカジュアルな音
    参考：ツムツム、パズドラ系のSE

    ■ 納品形式
    WAV (44.1kHz/16bit)、モノラル
    ファイル命名規則あり（別途共有）
  DESC
  j.budget_min_jpy = 50_000
  j.budget_max_jpy = 100_000
  j.is_remote = true
  j.delivery_due_on = 30.days.from_now
  j.status = 'published'
  j.published_at = 12.hours.ago
end

job6 = Job.find_or_create_by!(client: client3, title: 'ウェディング映像BGM制作（3曲）') do |j|
  j.description = <<~DESC.strip
    ブライダル映像制作会社向けの汎用BGMライブラリ用楽曲です。

    ■ 楽曲
    1. 入場シーン用（3分）- 華やかで期待感のある曲
    2. プロフィールムービー用（4分）- 温かく感動的な曲
    3. エンドロール用（3分）- 幸福感あふれるアップテンポな曲

    ■ 編成イメージ
    ピアノ主体 + ストリングス + 軽いリズムセクション
    ボーカルなし

    ■ ライセンス
    ブライダル映像での無制限使用権（再販不可）
  DESC
  j.budget_jpy = 120_000
  j.is_remote = true
  j.delivery_due_on = 60.days.from_now
  j.status = 'published'
  j.published_at = 6.hours.ago
end

# =============================================================================
# Proposals (提案)
# =============================================================================
puts "=== Seeding proposals ==="

# job1 (RPG BGM) に musician1 が応募
proposal1 = Proposal.find_or_create_by!(job: job1, musician: musician1) do |p|
  p.quote_total_jpy = 140_000
  p.delivery_days = 75
  p.cover_message = <<~MSG.strip
    はじめまして、田中一郎と申します。

    ゲーム音楽の作曲を10年以上続けており、RPG・アクション・シミュレーション等のBGMを多数手がけてきました。
    クロノトリガーや聖剣伝説のような温かみのあるサウンドは私の得意分野です。

    ポートフォリオの「Fantasy Quest - メインテーマ」「星降る夜 - フィールドBGM」が参考になるかと思います。

    15曲すべてループ対応で制作可能です。まずは2〜3曲のサンプルを制作し、方向性を確認させていただければ幸いです。

    よろしくお願いいたします。
  MSG
  p.status = 'submitted'
end

# job1 に musician3 も応募
Proposal.find_or_create_by!(job: job1, musician: musician3) do |p|
  p.quote_total_jpy = 180_000
  p.delivery_days = 60
  p.cover_message = <<~MSG.strip
    高橋拓也と申します。

    オーケストラアレンジを得意としており、ファンタジーRPGのBGMは私の専門領域です。
    ピアノ・ストリングスを中心とした上品で壮大なサウンドを提供できます。

    納期は60日で対応可能です。迅速かつ丁寧に制作いたします。
  MSG
  p.status = 'submitted'
end

# job2 (YouTube BGM) に musician2 が応募 → 承諾済み
Proposal.find_or_create_by!(job: job2, musician: musician2) do |p|
  p.quote_total_jpy = 45_000
  p.delivery_days = 21
  p.cover_message = <<~MSG.strip
    鈴木美咲です。YouTube BGMの制作経験が豊富です。

    料理チャンネルに合う温かいアコースティック系のサウンドも得意です。
    Lo-Fiだけでなく、ジャンルを問わず幅広く対応できます。

    過去にも複数のYouTuberさんのBGM制作を担当しました。
    リビジョンも2回まで快く対応いたします。
  MSG
  p.status = 'accepted'
end

# job3 (CM ジングル) に musician3 が応募
Proposal.find_or_create_by!(job: job3, musician: musician3) do |p|
  p.quote_total_jpy = 75_000
  p.delivery_days = 14
  p.cover_message = <<~MSG.strip
    高橋です。CM音楽の制作経験が20件以上あります。

    アコースティックギターとピアノを組み合わせた爽やかなサウンドは得意分野です。
    放送用ラウドネス基準にも対応可能です。

    「Morning Coffee」のような温かみのあるサウンドをベースに、
    CMの尺に合わせた構成を提案させていただきます。
  MSG
  p.status = 'shortlisted'
end

# job4 (Lo-Fi BGM) に musician2 が応募
Proposal.find_or_create_by!(job: job4, musician: musician2) do |p|
  p.quote_total_jpy = 70_000
  p.delivery_days = 30
  p.cover_message = <<~MSG.strip
    Lo-Fi HipHopは私の専門です！

    「Rainy Café」「Sunset Drive」のようなトラックを、
    ご要望に合わせて10曲制作いたします。

    ビニールノイズや環境音のミックスバランスも
    お好みに合わせて調整可能です。
  MSG
  p.status = 'submitted'
end

# job6 (ウェディング) に musician3 が応募、musician4 も応募
Proposal.find_or_create_by!(job: job6, musician: musician3) do |p|
  p.quote_total_jpy = 110_000
  p.delivery_days = 45
  p.cover_message = <<~MSG.strip
    ブライダル映像用BGMの制作実績が多数あります。
    ピアノとストリングスを中心とした感動的なサウンドをお届けします。

    「Midnight Blue」のような美しい旋律を活かした楽曲を制作いたします。
  MSG
  p.status = 'submitted'
end

Proposal.find_or_create_by!(job: job6, musician: musician4) do |p|
  p.quote_total_jpy = 100_000
  p.delivery_days = 40
  p.cover_message = <<~MSG.strip
    中村さくらです。インスト楽曲の制作も対応しています。
    ピアノ演奏と歌唱の両方ができるため、
    将来的にボーカル入りバージョンの制作も可能です。
  MSG
  p.status = 'submitted'
end

# =============================================================================
# Production Requests (直接依頼)
# =============================================================================
puts "=== Seeding production requests ==="

ProductionRequest.find_or_create_by!(
  client: client3,
  musician: musician3,
  title: '企業VP用BGM制作（高橋様専用）'
) do |pr|
  pr.description = <<~DESC.strip
    弊社クライアントの企業VP（5分）用BGMの制作をお願いしたく、ご連絡しました。

    ■ 内容
    IT企業の会社紹介映像用BGM（1曲・5分）
    テーマ：革新的、信頼感、未来志向
    ピアノ＋エレクトロニカ系のハイブリッドなサウンド

    ■ 納期
    2週間以内

    過去にお仕事させていただいた際のクオリティが素晴らしかったので、
    ぜひ再度ご依頼させていただきたいです。
  DESC
  pr.budget_jpy = 60_000
  pr.delivery_days = 14
  pr.status = 'pending'
end

ProductionRequest.find_or_create_by!(
  client: client1,
  musician: musician2,
  title: 'ゲームメニュー画面用Lo-Fi BGM'
) do |pr|
  pr.description = <<~DESC.strip
    開発中のカジュアルゲームのメニュー画面用BGMを制作してください。

    ・Lo-Fi系のリラックスしたBGM（2分・ループ対応）
    ・ゲームの世界観：夜のネオン街
    ・参考：「Rainy Café」のようなトーンで少しサイバーパンク感

    ポートフォリオを拝見し、ぜひお願いしたいと思いました。
  DESC
  pr.budget_jpy = 15_000
  pr.delivery_days = 7
  pr.status = 'accepted'
end

ProductionRequest.find_or_create_by!(
  client: client2,
  musician: musician4,
  title: 'YouTube用オリジナルテーマソング歌唱'
) do |pr|
  pr.description = <<~DESC.strip
    チャンネルのオリジナルテーマソングの歌唱をお願いしたいです。

    ・楽曲は既に完成済み（別途共有）
    ・明るくポップな女性ボーカル
    ・レコーディング＋簡単なミックスまで対応希望
    ・仮歌1テイク＋本番2テイク希望

    サンプル音源を聴いて、声質がチャンネルにぴったりだと感じました。
  DESC
  pr.budget_jpy = 25_000
  pr.delivery_days = 10
  pr.status = 'pending'
end

# =============================================================================
# Conversations & Messages
# =============================================================================
puts "=== Seeding conversations and messages ==="

# Conversation 1: job1 に関する会話 (client1 ↔ musician1)
conv1 = Conversation.find_or_create_by!(job: job1)
ConversationParticipant.find_or_create_by!(conversation: conv1, user: client1) do |cp|
  cp.last_read_at = 1.hour.ago
end
ConversationParticipant.find_or_create_by!(conversation: conv1, user: musician1) do |cp|
  cp.last_read_at = 30.minutes.ago
end

[
  { sender: client1, content: 'はじめまして。「幻想紀行」BGM制作の件でご連絡しました。ポートフォリオの「Fantasy Quest」がまさにイメージ通りでした！', created_at: 3.days.ago },
  { sender: musician1, content: "はじめまして、田中です。ありがとうございます！\n\n「幻想紀行」のコンセプトアートや世界観資料などありましたら共有いただけますか？楽曲の方向性を具体的に詰められればと思います。", created_at: 3.days.ago + 2.hours },
  { sender: client1, content: "資料を準備中です。来週月曜までにお送りしますね。\n\nちなみに、フィールドBGM4曲は地域ごとに異なる雰囲気を想定しています。草原は牧歌的、森は神秘的、雪山は静寂感、砂漠はエスニック寄りで考えています。", created_at: 2.days.ago },
  { sender: musician1, content: "承知しました。各地域のイメージがしっかりされていて助かります。\n\nまずはフィールドBGMの草原をサンプルとして制作し、方向性を確認させてください。1週間程度で初稿をお出しできます。", created_at: 2.days.ago + 4.hours },
  { sender: client1, content: 'ぜひお願いします！楽しみにしています。', created_at: 2.days.ago + 5.hours },
].each do |msg|
  Message.find_or_create_by!(conversation: conv1, sender: msg[:sender], content: msg[:content]) do |m|
    m.created_at = msg[:created_at]
  end
end

# Conversation 2: job2 承諾後の会話 (client2 ↔ musician2)
conv2 = Conversation.find_or_create_by!(job: job2)
ConversationParticipant.find_or_create_by!(conversation: conv2, user: client2) do |cp|
  cp.last_read_at = 2.hours.ago
end
ConversationParticipant.find_or_create_by!(conversation: conv2, user: musician2) do |cp|
  cp.last_read_at = 3.hours.ago
end

[
  { sender: client2, content: "応募ありがとうございます！提案内容がとても良かったので、ぜひお願いしたいです。\n\n早速ですが、チャンネルの雰囲気を掴んでいただくために、最新動画をいくつか見ていただけますか？", created_at: 1.day.ago },
  { sender: musician2, content: "ありがとうございます！チャンネル拝見しました。\n\n明るくて温かい雰囲気が素敵ですね。アコースティックギター＋ウクレレをメインにした軽快なサウンドが合いそうだと感じました。\n\nまずはオープニングジングルから着手してよろしいでしょうか？", created_at: 1.day.ago + 3.hours },
  { sender: client2, content: "はい、お願いします！ジングルが一番使用頻度が高いので、こだわりたいところです。\n\n「パパパパーン♪ HanaTV!」みたいなキャッチーな感じが理想です（笑）", created_at: 1.day.ago + 5.hours },
  { sender: musician2, content: '了解です！キャッチーなジングル、腕の見せどころですね。3日程度で初稿をお送りします。', created_at: 1.day.ago + 6.hours },
].each do |msg|
  Message.find_or_create_by!(conversation: conv2, sender: msg[:sender], content: msg[:content]) do |m|
    m.created_at = msg[:created_at]
  end
end

# Conversation 3: job3 に関する会話 (client3 ↔ musician3)
conv3 = Conversation.find_or_create_by!(job: job3)
ConversationParticipant.find_or_create_by!(conversation: conv3, user: client3) do |cp|
  cp.last_read_at = 5.hours.ago
end
ConversationParticipant.find_or_create_by!(conversation: conv3, user: musician3) do |cp|
  cp.last_read_at = 4.hours.ago
end

[
  { sender: client3, content: "高橋様、ご応募ありがとうございます。候補として検討させていただいております。\n\nいくつか追加でお伺いしたいのですが、CM放送用のラウドネス基準対応の経験はございますか？", created_at: 1.day.ago },
  { sender: musician3, content: "伊藤様、ご連絡ありがとうございます。\n\nはい、テレビCM向けの楽曲制作は20件以上の実績があり、-24 LKFS準拠のマスタリングにも対応しております。\n\nラウドネスメーターを使用した正確な管理が可能です。", created_at: 1.day.ago + 1.hour },
  { sender: client3, content: '心強いです。クライアントとの最終確認後、正式にご依頼させていただく予定です。来週中にはご連絡いたします。', created_at: 20.hours.ago },
].each do |msg|
  Message.find_or_create_by!(conversation: conv3, sender: msg[:sender], content: msg[:content]) do |m|
    m.created_at = msg[:created_at]
  end
end

puts "=== Seed data created successfully! ==="
puts ""
puts "Login credentials:"
puts "  Musicians: musician1@example.com ~ musician4@example.com"
puts "  Clients:   client1@example.com ~ client3@example.com"
puts "  Password:  password123"
