require 'rails_helper'

RSpec.describe Message, type: :model do
  let(:user) { User.create!(email: 'user@example.com', password: 'password123') }
  let(:track) { Track.create!(title: 'Test Track', user: user, yt_url: 'https://youtube.com/watch?v=test') }
  let(:job) { Job.create!(client: user, track: track, title: 'Test Job', description: 'Test job', status: 'draft') }

  it 'creates a valid message' do
    message = Message.create!(
      job: job,
      sender: user,
      content: 'This is a test message'
    )

    expect(message.job).to eq(job)
    expect(message.sender).to eq(user)
    expect(message.content).to eq('This is a test message')
  end

  it 'requires content to be present' do
    message = Message.new(
      job: job,
      sender: user,
      content: ''
    )

    expect(message).not_to be_valid
    expect(message.errors[:content]).to include("can't be blank")
  end

  it 'requires content to be at least 1 character' do
    message = Message.new(
      job: job,
      sender: user,
      content: ''
    )

    expect(message).not_to be_valid
    expect(message.errors[:content]).to include("is too short (minimum is 1 character)")
  end

  it 'requires content to be at most 5000 characters' do
    long_content = 'a' * 5001
    message = Message.new(
      job: job,
      sender: user,
      content: long_content
    )

    expect(message).not_to be_valid
    expect(message.errors[:content]).to include("is too long (maximum is 5000 characters)")
  end

  it 'requires either job or thread to be present' do
    message = Message.new(
      sender: user,
      content: 'Test message'
    )

    expect(message).not_to be_valid
    expect(message.errors[:base]).to include("must have either thread or job")
  end

  it 'requires sender to be present' do
    message = Message.new(
      job: job,
      content: 'Test message'
    )

    expect(message).not_to be_valid
    expect(message.errors[:sender]).to include("must exist")
  end
end