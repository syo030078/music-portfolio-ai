require 'rails_helper'

RSpec.describe Job, type: :model do
  let(:client) { User.create!(email: 'client@example.com', password: 'password123') }
  let(:track) { Track.create!(title: 'Test Track', user: client, yt_url: 'https://youtube.com/watch?v=test') }

  describe 'validations' do
    it 'creates a valid job with required fields' do
      job = Job.create!(
        client: client,
        title: 'Need a remix',
        description: 'Need a remix of this track',
        status: 'draft'
      )

      expect(job.client).to eq(client)
      expect(job.title).to eq('Need a remix')
      expect(job.description).to eq('Need a remix of this track')
      expect(job.status).to eq('draft')
    end

    it 'requires title' do
      job = Job.new(client: client, description: 'Test', status: 'draft')
      expect(job).not_to be_valid
      expect(job.errors[:title]).to be_present
    end

    it 'requires description' do
      job = Job.new(client: client, title: 'Test', status: 'draft')
      expect(job).not_to be_valid
      expect(job.errors[:description]).to be_present
    end

    it 'validates title length' do
      job = Job.new(client: client, title: 'a' * 256, description: 'Test', status: 'draft')
      expect(job).not_to be_valid
      expect(job.errors[:title]).to be_present
    end

    it 'allows track to be optional' do
      job = Job.create!(
        client: client,
        title: 'Job without track',
        description: 'This job does not reference a track',
        status: 'draft'
      )
      expect(job.track).to be_nil
      expect(job).to be_valid
    end

    it 'validates budget_min_jpy is positive' do
      job = Job.new(client: client, title: 'Test', description: 'Test', budget_min_jpy: -1000)
      expect(job).not_to be_valid
    end

    it 'validates budget_max_jpy is positive' do
      job = Job.new(client: client, title: 'Test', description: 'Test', budget_max_jpy: -5000)
      expect(job).not_to be_valid
    end

    it 'validates budget_max_jpy is greater than or equal to budget_min_jpy' do
      job = Job.new(
        client: client,
        title: 'Test',
        description: 'Test',
        budget_min_jpy: 10000,
        budget_max_jpy: 5000
      )
      expect(job).not_to be_valid
      expect(job.errors[:budget_max_jpy]).to be_present
    end

    it 'allows budget_max_jpy equal to budget_min_jpy' do
      job = Job.create!(
        client: client,
        title: 'Test',
        description: 'Test',
        budget_min_jpy: 10000,
        budget_max_jpy: 10000
      )
      expect(job).to be_valid
    end
  end

  describe 'enum status' do
    let(:job) { Job.create!(client: client, title: 'Test', description: 'Test', status: 'draft') }

    it 'has draft status' do
      expect(job.draft?).to be true
    end

    it 'can change to published' do
      job.status = 'published'
      expect(job.published?).to be true
    end

    it 'can change to in_review' do
      job.status = 'in_review'
      expect(job.in_review?).to be true
    end

    it 'can change to contracted' do
      job.status = 'contracted'
      expect(job.contracted?).to be true
    end

    it 'can change to completed' do
      job.status = 'completed'
      expect(job.completed?).to be true
    end

    it 'can change to closed' do
      job.status = 'closed'
      expect(job.closed?).to be true
    end
  end

  describe 'associations' do
    it 'belongs to client' do
      job = Job.create!(client: client, title: 'Test', description: 'Test')
      expect(job.client).to eq(client)
    end

    it 'has many messages' do
      job = Job.create!(
        client: client,
        title: 'Test job',
        description: 'Test description',
        status: 'draft'
      )

      message1 = job.messages.create!(user: client, content: 'First message')
      message2 = job.messages.create!(user: client, content: 'Second message')

      expect(job.messages.count).to eq(2)
      expect(job.messages).to include(message1, message2)
    end

    it 'destroys associated messages when job is deleted' do
      job = Job.create!(
        client: client,
        title: 'Test job',
        description: 'Test description',
        status: 'draft'
      )

      message = job.messages.create!(user: client, content: 'Test message')
      message_id = message.id

      job.destroy

      expect(Message.find_by(id: message_id)).to be_nil
    end

    it 'has many job_requirements' do
      job = Job.create!(
        client: client,
        title: 'Test job',
        description: 'Test description',
        status: 'draft'
      )

      genre = Genre.find_by(name: 'Rock') || Genre.create!(name: 'Rock')
      skill = Skill.find_by(name: 'Composition') || Skill.create!(name: 'Composition')

      req1 = job.job_requirements.create!(kind: 'genre', ref_id: genre.id)
      req2 = job.job_requirements.create!(kind: 'skill', ref_id: skill.id)

      expect(job.job_requirements.count).to eq(2)
      expect(job.job_requirements).to include(req1, req2)
    end

    it 'destroys associated job_requirements when job is deleted' do
      job = Job.create!(
        client: client,
        title: 'Test job',
        description: 'Test description',
        status: 'draft'
      )

      genre = Genre.find_by(name: 'Rock') || Genre.create!(name: 'Rock')
      requirement = job.job_requirements.create!(kind: 'genre', ref_id: genre.id)
      requirement_id = requirement.id

      job.destroy

      expect(JobRequirement.find_by(id: requirement_id)).to be_nil
    end
  end

  describe 'scopes' do
    it 'returns published jobs with published_at set' do
      published_job = Job.create!(
        client: client,
        title: 'Published job',
        description: 'Test',
        status: 'published',
        published_at: Time.current
      )

      draft_job = Job.create!(
        client: client,
        title: 'Draft job',
        description: 'Test',
        status: 'draft'
      )

      expect(Job.published).to include(published_job)
      expect(Job.published).not_to include(draft_job)
    end
  end

  describe 'default values' do
    it 'sets default status to draft' do
      job = Job.new(client: client, title: 'Test', description: 'Test')
      job.save!
      expect(job.status).to eq('draft')
    end

    it 'sets default is_remote to true' do
      job = Job.create!(client: client, title: 'Test', description: 'Test')
      expect(job.is_remote).to be true
    end
  end
end
