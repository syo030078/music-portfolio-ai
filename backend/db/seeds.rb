# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Taxonomy master data
puts "Seeding genres..."
['Rock', 'Pop', 'Jazz', 'Classical', 'Electronic', 'Hip Hop', 'R&B', 'Country', 'Blues', 'Metal'].each do |name|
  Genre.find_or_create_by!(name: name)
end

puts "Seeding instruments..."
['Piano', 'Guitar', 'Bass', 'Drums', 'Violin', 'Saxophone', 'Vocals', 'Synthesizer', 'Trumpet', 'Cello'].each do |name|
  Instrument.find_or_create_by!(name: name)
end

puts "Seeding skills..."
['Composition', 'Arrangement', 'Mixing', 'Mastering', 'Recording', 'Production', 'Sound Design', 'Orchestration'].each do |name|
  Skill.find_or_create_by!(name: name)
end

# Test users
puts "Seeding test users..."
client1 = User.find_or_create_by!(email: 'client1@example.com') do |u|
  u.password = 'password123'
  u.name = '山田太郎'
  u.bio = '音楽プロデューサーです。様々なプロジェクトで楽曲制作を依頼しています。'
end

client2 = User.find_or_create_by!(email: 'client2@example.com') do |u|
  u.password = 'password123'
  u.name = '佐藤花子'
  u.bio = 'YouTubeクリエイター。動画のBGM制作を依頼しています。'
end

# Test jobs
puts "Seeding test jobs..."
Job.find_or_create_by!(
  client: client1,
  title: 'ゲーム用BGM制作依頼'
) do |job|
  job.description = 'RPGゲームのフィールドBGMを制作していただける方を募集しています。ファンタジー系の明るく冒険心をかき立てるような曲を希望します。'
  job.budget_jpy = 50000
  job.is_remote = true
  job.status = 'published'
  job.published_at = 3.days.ago
end

Job.find_or_create_by!(
  client: client1,
  title: 'CM用ジングル制作'
) do |job|
  job.description = '15秒のCM用ジングルを制作してください。商品は健康食品で、爽やかで元気なイメージの曲を希望します。'
  job.budget_min_jpy = 30000
  job.budget_max_jpy = 80000
  job.is_remote = true
  job.delivery_due_on = 30.days.from_now
  job.status = 'published'
  job.published_at = 2.days.ago
end

Job.find_or_create_by!(
  client: client2,
  title: 'YouTube動画BGM制作（10曲セット）'
) do |job|
  job.description = 'YouTube動画用のBGMを10曲制作していただける方を募集します。ジャンルはLo-Fi HipHop系を希望。各曲3分程度。'
  job.budget_jpy = 100000
  job.is_remote = true
  job.delivery_due_on = 60.days.from_now
  job.status = 'published'
  job.published_at = 1.day.ago
end

puts "Seed data created successfully!"
