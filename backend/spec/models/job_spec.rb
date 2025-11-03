require 'rails_helper'

RSpec.describe Job, type: :model do
  let(:user) { User.create!(email: 'user@example.com', password: 'password123') }
  let(:track) { Track.create!(title: 'Test Track', user: user, yt_url: 'https://youtube.com/watch?v=test') }

  it 'creates a valid job' do
    job = Job.create!(
      user: user,
      track: track,
      description: 'Need a remix of this track',
      budget: 10000,
      status: 'pending'
    )

    expect(job.user).to eq(user)
    expect(job.track).to eq(track)
    expect(job.description).to eq('Need a remix of this track')
    expect(job.budget).to eq(10000)
    expect(job.status).to eq('pending')
  end

  it 'has status enum' do
    job = Job.create!(
      user: user,
      track: track,
      description: 'Test',
      budget: 5000,
      status: 'pending'
    )

    expect(job.pending?).to be true

    job.status = 'accepted'
    expect(job.accepted?).to be true

    job.status = 'done'
    expect(job.done?).to be true
  end

  it 'has many messages' do
    job = Job.create!(
      user: user,
      track: track,
      description: 'Test job',
      budget: 5000,
      status: 'pending'
    )

    message1 = job.messages.create!(user: user, content: 'First message')
    message2 = job.messages.create!(user: user, content: 'Second message')

    expect(job.messages.count).to eq(2)
    expect(job.messages).to include(message1, message2)
  end

  it 'destroys associated messages when job is deleted' do
    job = Job.create!(
      user: user,
      track: track,
      description: 'Test job',
      budget: 5000,
      status: 'pending'
    )

    message = job.messages.create!(user: user, content: 'Test message')
    message_id = message.id

    job.destroy

    expect(Message.find_by(id: message_id)).to be_nil
  end
end
