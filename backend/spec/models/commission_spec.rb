require 'rails_helper'

RSpec.describe Commission, type: :model do
  let(:user) { User.create!(email: 'user@example.com', password: 'password123') }
  let(:track) { Track.create!(title: 'Test Track', user: user, yt_url: 'https://youtube.com/watch?v=test') }

  it 'creates a valid commission' do
    commission = Commission.create!(
      user: user,
      track: track,
      description: 'Need a remix of this track',
      budget: 10000,
      status: 'pending'
    )

    expect(commission.user).to eq(user)
    expect(commission.track).to eq(track)
    expect(commission.description).to eq('Need a remix of this track')
    expect(commission.budget).to eq(10000)
    expect(commission.status).to eq('pending')
  end

  it 'has status enum' do
    commission = Commission.create!(
      user: user,
      track: track,
      description: 'Test',
      budget: 5000,
      status: 'pending'
    )

    expect(commission.pending?).to be true

    commission.status = 'accepted'
    expect(commission.accepted?).to be true

    commission.status = 'done'
    expect(commission.done?).to be true
  end
end
