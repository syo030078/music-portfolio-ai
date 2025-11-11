require 'rails_helper'

RSpec.describe ThreadParticipant, type: :model do
  let(:client) { User.create!(email: 'client@example.com', password: 'password123', is_client: true).reload }
  let(:musician) { User.create!(email: 'musician@example.com', password: 'password123', is_musician: true).reload }
  let(:job) { Job.create!(client: client, title: 'Test job', description: 'Test', status: 'published', published_at: Time.current).reload }
  let(:thread) { Thread.create!(job: job).reload }

  describe 'associations' do
    it { should belong_to(:thread) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it 'validates uniqueness of thread_id scoped to user_id' do
      ThreadParticipant.create!(thread: thread, user: client)
      duplicate = ThreadParticipant.new(thread: thread, user: client)
      expect(duplicate).not_to be_valid
    end

    it 'allows same user in different threads' do
      thread2 = Thread.create!(job: job).reload
      ThreadParticipant.create!(thread: thread, user: client)
      participant2 = ThreadParticipant.new(thread: thread2, user: client)
      expect(participant2).to be_valid
    end
  end
end
