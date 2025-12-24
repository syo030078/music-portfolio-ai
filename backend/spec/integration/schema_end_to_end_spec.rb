require 'rails_helper'
require 'securerandom'

RSpec.describe 'Schema End-to-End Integration', type: :integration do
  it 'creates and links all schema tables through a lifecycle flow' do
    # Users and profiles
    client = User.create!(email: 'client@example.com', password: 'password123', is_client: true, display_name: 'Client')
    musician = User.create!(email: 'musician@example.com', password: 'password123', is_musician: true, display_name: 'Musician')
    client_profile = ClientProfile.create!(user: client, organization: 'Acme Corp')
    musician_profile = MusicianProfile.create!(user: musician, headline: 'Pro guitarist', hourly_rate_jpy: 5000)

    # Taxonomy masters and assignments
    rock = Genre.create!(name: 'Rock')
    guitar = Instrument.create!(name: 'Guitar')
    mixing = Skill.create!(name: 'Mixing')
    MusicianGenre.create!(user: musician, genre: rock)
    MusicianInstrument.create!(user: musician, instrument: guitar)
    MusicianSkill.create!(user: musician, skill: mixing)

    # Track and job
    track = Track.create!(user: client, title: 'Demo Track', yt_url: 'https://youtube.com/watch?v=dQw4w9WgXcQ', description: 'Demo description')
    job = Job.create!(
      client: client,
      track: track,
      title: 'Mix my song',
      description: 'Need pro mixing',
      status: 'published',
      published_at: Time.current,
      budget_min_jpy: 10000,
      budget_max_jpy: 20000,
      is_remote: true
    )

    genre_req = JobRequirement.create!(job: job, kind: 'genre', ref_id: rock.id)
    instrument_req = JobRequirement.create!(job: job, kind: 'instrument', ref_id: guitar.id)
    skill_req = JobRequirement.create!(job: job, kind: 'skill', ref_id: mixing.id)

    # Proposal and contract
    proposal = Proposal.create!(job: job, musician: musician, cover_message: 'I can handle this', quote_total_jpy: 15000, delivery_days: 5, status: 'submitted')
    contract = Contract.create!(proposal: proposal, client: client, musician: musician, escrow_total_jpy: 15000, status: 'active')
    milestone = ContractMilestone.create!(contract: contract, title: 'First draft', amount_jpy: 7500, due_on: Date.today + 7.days)
    review = Review.create!(contract: contract, reviewer: client, reviewee: musician, rating: 5, comment: 'Excellent delivery')
    escrow_tx = Transaction.create!(contract: contract, amount_jpy: 15000, kind: 'escrow_deposit', status: 'captured', provider: 'stripe', provider_ref: 'pi_123')
    payout_tx = Transaction.create!(contract: contract, milestone: milestone, amount_jpy: 7500, kind: 'milestone_payout', status: 'paid_out')

    # Conversations and messages (job and contract based)
    job_conversation = Conversation.create!(job: job)
    contract_conversation = Conversation.create!(contract: contract)

    job_cp_client = ConversationParticipant.create!(conversation: job_conversation, user: client)
    job_cp_musician = ConversationParticipant.create!(conversation: job_conversation, user: musician)
    contract_cp_client = ConversationParticipant.create!(conversation: contract_conversation, user: client)
    contract_cp_musician = ConversationParticipant.create!(conversation: contract_conversation, user: musician)

    Message.create!(conversation: job_conversation, sender: client, content: 'Please start with the chorus')
    Message.create!(conversation: job_conversation, sender: musician, content: 'Got it, starting now')
    Message.create!(conversation: contract_conversation, sender: client, content: 'Sharing milestone details')
    Message.create!(conversation: contract_conversation, sender: musician, content: 'Will deliver by the due date')

    # JWT denylist (revoked token)
    JwtDenylist.create!(jti: SecureRandom.uuid, exp: 1.day.from_now)

    # Expectations: persistence and associations across all tables
    expect(client_profile).to be_persisted
    expect(musician_profile).to be_persisted
    expect(rock).to be_persisted
    expect(guitar).to be_persisted
    expect(mixing).to be_persisted
    expect(track).to be_persisted
    expect(job).to be_published
    expect(job.job_requirements).to match_array([genre_req, instrument_req, skill_req])

    expect(proposal).to be_persisted
    expect(contract).to be_active
    expect(milestone.contract).to eq(contract)
    expect(review.reviewee).to eq(musician)
    expect(escrow_tx.contract).to eq(contract)
    expect(payout_tx.milestone).to eq(milestone)

    expect(job_conversation.parent).to eq(job)
    expect(contract_conversation.parent).to eq(contract)
    expect(job_conversation.participants).to match_array([client, musician])
    expect(contract_conversation.participants).to match_array([client, musician])
    expect(job_conversation.messages.count).to eq(2)
    expect(contract_conversation.messages.count).to eq(2)

    expect(job_cp_client.reload.last_read_at).to be_within(2.seconds).of(Time.current)
    expect(contract_cp_musician.reload.last_read_at).to be_within(2.seconds).of(Time.current)

    expect(JwtDenylist.count).to eq(1)
  end
end
