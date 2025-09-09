require 'rails_helper'

RSpec.describe Message, type: :model do
  let(:user) { User.create!(email: 'user@example.com', password: 'password123') }
  let(:track) { Track.create!(title: 'Test Track', user: user, yt_url: 'https://youtube.com/watch?v=test') }
  let(:commission) { Commission.create!(user: user, track: track, description: 'Test commission', budget: 5000, status: 'pending') }

  it 'creates a valid message' do
    message = Message.create!(
      commission: commission,
      user: user,
      content: 'This is a test message'
    )

    expect(message.commission).to eq(commission)
    expect(message.user).to eq(user)
    expect(message.content).to eq('This is a test message')
  end

  it 'requires content to be present' do
    message = Message.new(
      commission: commission,
      user: user,
      content: ''
    )

    expect(message).not_to be_valid
    expect(message.errors[:content]).to include("can't be blank")
  end

  it 'requires content to be at least 1 character' do
    message = Message.new(
      commission: commission,
      user: user,
      content: ''
    )

    expect(message).not_to be_valid
    expect(message.errors[:content]).to include("is too short (minimum is 1 character)")
  end

  it 'requires content to be at most 1000 characters' do
    long_content = 'a' * 1001
    message = Message.new(
      commission: commission,
      user: user,
      content: long_content
    )

    expect(message).not_to be_valid
    expect(message.errors[:content]).to include("is too long (maximum is 1000 characters)")
  end

  it 'requires commission to be present' do
    message = Message.new(
      sender: user,
      content: 'Test message'
    )

    expect(message).not_to be_valid
    expect(message.errors[:commission]).to include("must exist")
  end

  it 'requires user to be present' do
    message = Message.new(
      commission: commission,
      content: 'Test message'
    )

    expect(message).not_to be_valid
    expect(message.errors[:user]).to include("must exist")
  end
end