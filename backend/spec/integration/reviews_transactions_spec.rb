require 'rails_helper'

RSpec.describe 'Phase6 Reviews and Transactions Integration', type: :integration do
  let(:client) { User.create!(email: 'client@example.com', password: 'password123', is_client: true) }
  let(:musician) { User.create!(email: 'musician@example.com', password: 'password123', is_musician: true) }
  let(:job) { Job.create!(client: client, title: 'Need a remix', description: 'Test description', status: 'published', published_at: Time.current) }
  let(:proposal) { Proposal.create!(job: job, musician: musician, quote_total_jpy: 50000, delivery_days: 7, status: 'accepted') }
  let(:contract) { Contract.create!(proposal: proposal, client: client, musician: musician, escrow_total_jpy: 50000, status: 'active') }
  let(:milestone) { ContractMilestone.create!(contract: contract, title: 'First milestone', amount_jpy: 25000, status: 'open') }

  it 'creates review and transactions tied to a contract lifecycle' do
    review = Review.create!(contract: contract, reviewer: client, reviewee: musician, rating: 5, comment: 'Great job')
    escrow_tx = Transaction.create!(contract: contract, amount_jpy: 50000, kind: 'escrow_deposit', status: 'captured', provider: 'stripe')
    payout_tx = Transaction.create!(contract: contract, milestone: milestone, amount_jpy: 25000, kind: 'milestone_payout', status: 'paid_out')

    expect(review.contract).to eq(contract)
    expect(review.reviewer).to eq(client)
    expect(review.reviewee).to eq(musician)
    expect(review.rating).to eq(5)

    expect(escrow_tx.contract).to eq(contract)
    expect(escrow_tx.milestone).to be_nil
    expect(escrow_tx.captured?).to be true

    expect(payout_tx.contract).to eq(contract)
    expect(payout_tx.milestone).to eq(milestone)
    expect(payout_tx.paid_out?).to be true

    expect(contract.review).to eq(review)
    expect(contract.transactions.count).to eq(2)
    expect(milestone.transactions).to include(payout_tx)
  end

  it 'destroys dependent review and transactions when contract is removed' do
    Review.create!(contract: contract, reviewer: client, reviewee: musician, rating: 4)
    Transaction.create!(contract: contract, amount_jpy: 50000, kind: 'escrow_deposit', status: 'authorized')

    expect { contract.destroy }.to change(Review, :count).by(-1)
      .and change(Transaction, :count).by(-1)
  end

  it 'nullifies milestone reference on transaction when milestone is destroyed' do
    tx = Transaction.create!(contract: contract, milestone: milestone, amount_jpy: 25000, kind: 'milestone_payout', status: 'authorized')

    milestone.destroy

    expect(tx.reload.milestone_id).to be_nil
    expect(tx.contract).to eq(contract)
  end
end
