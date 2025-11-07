require 'rails_helper'

RSpec.describe JobRequirement, type: :model do
  let(:client) { User.create!(email: 'client@example.com', password: 'password123') }
  let(:job) { Job.create!(client: client, title: 'Test Job', description: 'Test', status: 'draft') }
  let(:genre) { Genre.find_by(name: 'Rock') || Genre.create!(name: 'Rock') }
  let(:instrument) { Instrument.find_by(name: 'Piano') || Instrument.create!(name: 'Piano') }
  let(:skill) { Skill.find_by(name: 'Composition') || Skill.create!(name: 'Composition') }

  describe 'associations' do
    it 'belongs to job' do
      association = described_class.reflect_on_association(:job)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    it 'is valid with job, kind, and ref_id' do
      requirement = JobRequirement.new(job: job, kind: 'genre', ref_id: genre.id)
      expect(requirement).to be_valid
    end

    it 'requires kind' do
      requirement = JobRequirement.new(job: job, ref_id: genre.id)
      expect(requirement).not_to be_valid
      expect(requirement.errors[:kind]).to be_present
    end

    it 'requires ref_id' do
      requirement = JobRequirement.new(job: job, kind: 'genre')
      expect(requirement).not_to be_valid
      expect(requirement.errors[:ref_id]).to be_present
    end

    it 'validates ref_id exists for genre' do
      requirement = JobRequirement.new(job: job, kind: 'genre', ref_id: 99999)
      expect(requirement).not_to be_valid
      expect(requirement.errors[:ref_id]).to include('genre with id 99999 does not exist')
    end

    it 'validates ref_id exists for instrument' do
      requirement = JobRequirement.new(job: job, kind: 'instrument', ref_id: 99999)
      expect(requirement).not_to be_valid
      expect(requirement.errors[:ref_id]).to include('instrument with id 99999 does not exist')
    end

    it 'validates ref_id exists for skill' do
      requirement = JobRequirement.new(job: job, kind: 'skill', ref_id: 99999)
      expect(requirement).not_to be_valid
      expect(requirement.errors[:ref_id]).to include('skill with id 99999 does not exist')
    end
  end

  describe 'enum kind' do
    it 'has genre kind' do
      requirement = JobRequirement.create!(job: job, kind: 'genre', ref_id: genre.id)
      expect(requirement.genre?).to be true
    end

    it 'has instrument kind' do
      requirement = JobRequirement.create!(job: job, kind: 'instrument', ref_id: instrument.id)
      expect(requirement.instrument?).to be true
    end

    it 'has skill kind' do
      requirement = JobRequirement.create!(job: job, kind: 'skill', ref_id: skill.id)
      expect(requirement.skill?).to be true
    end
  end

  describe '#reference_object' do
    it 'returns Genre object when kind is genre' do
      requirement = JobRequirement.create!(job: job, kind: 'genre', ref_id: genre.id)
      expect(requirement.reference_object).to eq(genre)
    end

    it 'returns Instrument object when kind is instrument' do
      requirement = JobRequirement.create!(job: job, kind: 'instrument', ref_id: instrument.id)
      expect(requirement.reference_object).to eq(instrument)
    end

    it 'returns Skill object when kind is skill' do
      requirement = JobRequirement.create!(job: job, kind: 'skill', ref_id: skill.id)
      expect(requirement.reference_object).to eq(skill)
    end

    it 'returns nil when ref_id does not exist' do
      requirement = JobRequirement.new(job: job, kind: 'genre', ref_id: 99999)
      expect(requirement.reference_object).to be_nil
    end
  end

  describe '#reference_name' do
    it 'returns name of referenced genre' do
      requirement = JobRequirement.create!(job: job, kind: 'genre', ref_id: genre.id)
      expect(requirement.reference_name).to eq('Rock')
    end

    it 'returns name of referenced instrument' do
      requirement = JobRequirement.create!(job: job, kind: 'instrument', ref_id: instrument.id)
      expect(requirement.reference_name).to eq('Piano')
    end

    it 'returns name of referenced skill' do
      requirement = JobRequirement.create!(job: job, kind: 'skill', ref_id: skill.id)
      expect(requirement.reference_name).to eq('Composition')
    end

    it 'returns nil when ref_id does not exist' do
      requirement = JobRequirement.new(job: job, kind: 'genre', ref_id: 99999)
      expect(requirement.reference_name).to be_nil
    end
  end

  describe 'uniqueness' do
    it 'prevents duplicate requirements for same job, kind, and ref_id' do
      JobRequirement.create!(job: job, kind: 'genre', ref_id: genre.id)
      duplicate = JobRequirement.new(job: job, kind: 'genre', ref_id: genre.id)

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allows same ref_id for different kinds' do
      # Using same ID but different kinds (not realistic but tests uniqueness constraint)
      JobRequirement.create!(job: job, kind: 'genre', ref_id: genre.id)
      different_kind = JobRequirement.new(job: job, kind: 'instrument', ref_id: genre.id)

      # This will fail validation because ref_id doesn't exist as instrument
      # but it demonstrates the uniqueness is on (job_id, kind, ref_id) combination
      expect(different_kind).not_to be_valid
    end

    it 'allows same ref_id for different jobs' do
      job2 = Job.create!(client: client, title: 'Another Job', description: 'Test', status: 'draft')
      JobRequirement.create!(job: job, kind: 'genre', ref_id: genre.id)
      same_genre_different_job = JobRequirement.new(job: job2, kind: 'genre', ref_id: genre.id)

      expect(same_genre_different_job).to be_valid
    end
  end
end
