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

puts "Seed data created successfully!"
