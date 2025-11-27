require 'rails_helper'

RSpec.describe Review, type: :model do
  let(:client) { User.create!(email: 'client@example.com', password: 'password123', is_client: true) }
  let(:musician) { User.create!(email: 'musician@example.com', password: 'password123', is_musician: true) }
  let(:job) { Job.create!(client: client, title: 'Need a remix', description: 'Test description', status: 'published', published_at: Time.current) }
  let(:proposal) { Proposal.create!(job: job, musician: musician, quote_total_jpy: 50000, delivery_days: 7, status: 'accepted') }
  let(:contract) { Contract.create!(proposal: proposal, client: client, musician: musician, escrow_total_jpy: 50000, status: 'active') }

  describe 'validations' do
    it 'creates a valid review with required fields' do
      review = Review.create!(contract: contract, reviewer: client, reviewee: musician, rating: 5, comment: 'Great work')
      expect(review.contract).to eq(contract)
      expect(review.reviewer).to eq(client)
      expect(review.reviewee).to eq(musician)
      expect(review.rating).to eq(5)
    end

    it 'requires rating to be within 1..5' do
      review = Review.new(contract: contract, reviewer: client, reviewee: musician, rating: 6)
      expect(review).not_to be_valid
      expect(review.errors[:rating]).to be_present
    end

    it 'enforces one review per contract' do
      Review.create!(contract: contract, reviewer: client, reviewee: musician, rating: 4)
      duplicate = Review.new(contract: contract, reviewer: client, reviewee: musician, rating: 3)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:contract_id]).to be_present
    end

    it 'allows comment to be blank but limits length' do
      review = Review.new(contract: contract, reviewer: client, reviewee: musician, rating: 4, comment: 'a' * 1001)
      expect(review).not_to be_valid
      expect(review.errors[:comment]).to be_present
    end
  end

  describe 'scopes' do
    let!(:review) { Review.create!(contract: contract, reviewer: client, reviewee: musician, rating: 4) }

    it 'finds reviews for a contract' do
      expect(Review.for_contract(contract.id)).to include(review)
    end

    it 'finds reviews involving a user' do
      expect(Review.for_user(client.id)).to include(review)
      expect(Review.for_user(musician.id)).to include(review)
    end
  end

  describe 'uuid helpers' do
    let!(:review) { Review.create!(contract: contract, reviewer: client, reviewee: musician, rating: 5).reload }

    it 'returns uuid in to_param' do
      expect(review.to_param).to eq(review.uuid)
    end

    it 'finds by uuid' do
      expect(Review.find_by_uuid(review.uuid)).to eq(review)
    end
  end
end
