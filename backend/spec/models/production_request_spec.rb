require 'rails_helper'

RSpec.describe ProductionRequest, type: :model do
  let(:client) { User.create!(email: 'client@example.com', password: 'password123', is_client: true) }
  let(:musician) { User.create!(email: 'musician@example.com', password: 'password123', is_musician: true) }

  def valid_attrs
    {
      client: client,
      musician: musician,
      title: 'BGM for short film',
      description: 'Need atmospheric ambient music for a 10-minute short film',
      budget_jpy: 80_000,
      delivery_days: 14
    }
  end

  describe 'validations' do
    it 'is valid with all required fields' do
      expect(ProductionRequest.new(valid_attrs)).to be_valid
    end

    it 'requires title' do
      pr = ProductionRequest.new(valid_attrs.merge(title: nil))
      expect(pr).not_to be_valid
      expect(pr.errors[:title]).to be_present
    end

    it 'enforces title max length' do
      pr = ProductionRequest.new(valid_attrs.merge(title: 'a' * 256))
      expect(pr).not_to be_valid
      expect(pr.errors[:title]).to be_present
    end

    it 'requires description' do
      pr = ProductionRequest.new(valid_attrs.merge(description: nil))
      expect(pr).not_to be_valid
      expect(pr.errors[:description]).to be_present
    end

    it 'requires budget_jpy' do
      pr = ProductionRequest.new(valid_attrs.merge(budget_jpy: nil))
      expect(pr).not_to be_valid
      expect(pr.errors[:budget_jpy]).to be_present
    end

    it 'requires positive budget_jpy' do
      pr = ProductionRequest.new(valid_attrs.merge(budget_jpy: 0))
      expect(pr).not_to be_valid
      expect(pr.errors[:budget_jpy]).to be_present
    end

    it 'requires delivery_days' do
      pr = ProductionRequest.new(valid_attrs.merge(delivery_days: nil))
      expect(pr).not_to be_valid
      expect(pr.errors[:delivery_days]).to be_present
    end

    it 'requires positive integer delivery_days' do
      pr = ProductionRequest.new(valid_attrs.merge(delivery_days: 0))
      expect(pr).not_to be_valid
      expect(pr.errors[:delivery_days]).to be_present
    end

    it 'rejects non-integer delivery_days' do
      pr = ProductionRequest.new(valid_attrs.merge(delivery_days: 3.5))
      expect(pr).not_to be_valid
      expect(pr.errors[:delivery_days]).to be_present
    end

    it 'rejects self-request' do
      both_roles_user = User.create!(email: 'both@example.com', password: 'password123', is_client: true, is_musician: true)
      pr = ProductionRequest.new(valid_attrs.merge(client: both_roles_user, musician: both_roles_user))
      expect(pr).not_to be_valid
      expect(pr.errors[:musician]).to include('cannot request yourself')
    end

    it 'rejects non-client sender' do
      pr = ProductionRequest.new(valid_attrs.merge(client: musician))
      expect(pr).not_to be_valid
      expect(pr.errors[:client]).to include('must have client role')
    end

    it 'rejects non-musician receiver' do
      other_client = User.create!(email: 'other_client@example.com', password: 'password123', is_client: true)
      pr = ProductionRequest.new(valid_attrs.merge(musician: other_client))
      expect(pr).not_to be_valid
      expect(pr.errors[:musician]).to include('must have musician role')
    end
  end

  describe 'status enum' do
    let(:pr) { ProductionRequest.create!(valid_attrs) }

    it 'defaults to pending' do
      expect(pr.status).to eq('pending')
      expect(pr).to be_pending
    end

    it 'can be accepted' do
      pr.update!(status: 'accepted')
      expect(pr).to be_accepted
    end

    it 'can be rejected' do
      pr.update!(status: 'rejected')
      expect(pr).to be_rejected
    end

    it 'can be withdrawn' do
      pr.update!(status: 'withdrawn')
      expect(pr).to be_withdrawn
    end
  end

  describe 'scopes' do
    let!(:pr) { ProductionRequest.create!(valid_attrs) }

    it '.for_client returns requests sent by client' do
      expect(ProductionRequest.for_client(client.id)).to include(pr)
      expect(ProductionRequest.for_client(musician.id)).not_to include(pr)
    end

    it '.for_musician returns requests received by musician' do
      expect(ProductionRequest.for_musician(musician.id)).to include(pr)
      expect(ProductionRequest.for_musician(client.id)).not_to include(pr)
    end
  end

  describe '#to_param' do
    it 'returns uuid' do
      pr = ProductionRequest.create!(valid_attrs)
      pr.reload
      expect(pr.to_param).to eq(pr.uuid)
      expect(pr.uuid).to be_present
    end
  end

  describe '.find_by_uuid' do
    it 'finds by uuid' do
      pr = ProductionRequest.create!(valid_attrs)
      pr.reload
      expect(ProductionRequest.find_by_uuid(pr.uuid)).to eq(pr)
    end

    it 'returns nil for unknown uuid' do
      expect(ProductionRequest.find_by_uuid('nonexistent')).to be_nil
    end
  end
end
