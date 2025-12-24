require 'rails_helper'
require 'securerandom'

RSpec.describe 'Messaging System Integration', type: :integration do
  let(:client) { User.create!(email: 'client@example.com', password: 'password123') }
  let(:musician) { User.create!(email: 'musician@example.com', password: 'password123') }
  let(:track) { Track.create!(title: 'Test Track', user: client, yt_url: 'https://youtube.com/watch?v=test') }
  let(:job) { Job.create!(client: client, track: track, title: 'Test Job', description: 'Test description', status: 'published', published_at: Time.current) }

  describe 'Job-based conversation workflow' do
    it 'creates conversation, adds participants, sends messages, and tracks unread counts' do
      # Step 1: Create a conversation for a job
      conversation = Conversation.create!(job: job)
      expect(conversation).to be_persisted
      expect(conversation.parent).to eq(job)

      # Step 2: Add participants to the conversation
      client_participant = ConversationParticipant.create!(conversation: conversation, user: client)
      musician_participant = ConversationParticipant.create!(conversation: conversation, user: musician)

      expect(conversation.participants).to include(client, musician)
      expect(conversation.participant?(client)).to be true
      expect(conversation.participant?(musician)).to be true

      # Step 3: Client sends a message
      message1 = Message.create!(conversation: conversation, sender: client, content: 'Hello, are you available?')
      expect(message1).to be_persisted

      # Client should be marked as read automatically (because client is the sender)
      expect(client_participant.reload.last_read_at).to be_within(1.second).of(Time.current)

      # Musician has 1 unread message (because musician's last_read_at is nil)
      # Note: musician_participant.last_read_at is nil, so all messages are unread for musician
      expect(conversation.unread_count_for(musician)).to eq(1)
      # Client has 0 unread messages (client just sent the message and was auto-marked as read)
      expect(conversation.unread_count_for(client)).to eq(0)

      # Step 4: Musician reads and replies
      musician_participant.mark_as_read!
      expect(conversation.unread_count_for(musician)).to eq(0)

      message2 = Message.create!(conversation: conversation, sender: musician, content: 'Yes, I am available!')
      expect(message2).to be_persisted

      # Musician should be marked as read automatically
      expect(musician_participant.reload.last_read_at).to be_within(1.second).of(Time.current)

      # Client now has 1 unread message
      expect(conversation.unread_count_for(client)).to eq(1)
      expect(conversation.unread_count_for(musician)).to eq(0)

      # Step 5: Multiple messages exchange
      message3 = Message.create!(conversation: conversation, sender: client, content: 'Great! What is your rate?')
      # After message3, client is auto-marked as read, musician has 1 unread (message3)
      expect(conversation.unread_count_for(musician)).to eq(1)
      expect(conversation.unread_count_for(client)).to eq(0)

      message4 = Message.create!(conversation: conversation, sender: musician, content: 'My rate is $100/hour')
      # After message4, musician is auto-marked as read, client has 1 unread (message4)
      expect(conversation.unread_count_for(client)).to eq(1)
      expect(conversation.unread_count_for(musician)).to eq(0)

      # Step 6: Both users mark as read
      client_participant.mark_as_read!
      musician_participant.mark_as_read!

      expect(conversation.unread_count_for(client)).to eq(0)
      expect(conversation.unread_count_for(musician)).to eq(0)

      # Verify all messages are associated with the conversation
      expect(conversation.messages.count).to eq(4)
      expect(conversation.messages).to include(message1, message2, message3, message4)
    end

    it 'prevents duplicate participants' do
      conversation = Conversation.create!(job: job)
      ConversationParticipant.create!(conversation: conversation, user: client)

      duplicate = ConversationParticipant.new(conversation: conversation, user: client)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include('has already been taken')
    end

    it 'handles conversation without participants gracefully' do
      conversation = Conversation.create!(job: job)
      other_user = User.create!(email: 'other@example.com', password: 'password123')

      expect(conversation.participant?(other_user)).to be false
      expect(conversation.unread_count_for(other_user)).to eq(0)
    end
  end

  describe 'Contract-based conversation workflow' do
    let(:proposal) { Proposal.create!(job: job, musician: musician, cover_message: 'I can help', quote_total_jpy: 50000, delivery_days: 7) }
    let(:contract) { Contract.create!(proposal: proposal, client: client, musician: musician, escrow_total_jpy: 50000) }

    it 'creates conversation for contract and manages message flow' do
      # Step 1: Create a conversation for a contract
      conversation = Conversation.create!(contract: contract)
      expect(conversation).to be_persisted
      expect(conversation.parent).to eq(contract)

      # Step 2: Add participants
      ConversationParticipant.create!(conversation: conversation, user: client)
      ConversationParticipant.create!(conversation: conversation, user: musician)

      # Step 3: Exchange messages about contract details
      message1 = Message.create!(conversation: conversation, sender: client, content: 'Please start working on the project')
      message2 = Message.create!(conversation: conversation, sender: musician, content: 'I will start today')

      expect(conversation.messages.count).to eq(2)
      expect(conversation.messages.order(:created_at).first.body).to eq('Please start working on the project')
      expect(conversation.messages.order(:created_at).last.body).to eq('I will start today')
    end

    it 'prevents conversation from belonging to both job and contract' do
      conversation = Conversation.new(job: job, contract: contract)
      expect(conversation).not_to be_valid
      expect(conversation.errors[:base]).to include('Cannot belong to both job and contract')
    end
  end

  describe 'Message validation and constraints' do
    let(:conversation) { Conversation.create!(job: job) }

    it 'validates message content presence and length' do
      # Empty body
      message = Message.new(conversation: conversation, sender: client, content: '')
      expect(message).not_to be_valid
      expect(message.errors[:content]).to include("can't be blank")

      # Too long body
      long_body = 'a' * 1001
      message = Message.new(conversation: conversation, sender: client, content: long_body)
      expect(message).not_to be_valid
      expect(message.errors[:content]).to include('is too long (maximum is 1000 characters)')

      # Valid body
      message = Message.new(conversation: conversation, sender: client, content: 'Valid message')
      expect(message).to be_valid
    end

    it 'requires conversation and sender' do
      message = Message.new(content: 'Test')
      expect(message).not_to be_valid
      expect(message.errors[:conversation]).to be_present
      expect(message.errors[:sender]).to be_present
    end
  end

  describe 'Unread count accuracy' do
    let(:conversation) { Conversation.create!(job: job) }
    let(:participant) { ConversationParticipant.create!(conversation: conversation, user: musician) }

    it 'accurately counts unread messages based on timestamps' do
      # Set last_read_at to 2 hours ago
      participant.update(last_read_at: 2.hours.ago)

      # Create old messages (before last_read_at)
      old_message = Message.create!(conversation: conversation, sender: client, content: 'Old message', created_at: 3.hours.ago)

      # Create new messages (after last_read_at)
      new_message1 = Message.create!(conversation: conversation, sender: client, content: 'New message 1', created_at: 1.hour.ago)
      new_message2 = Message.create!(conversation: conversation, sender: client, content: 'New message 2', created_at: 30.minutes.ago)

      expect(conversation.unread_count_for(musician)).to eq(2)
    end

    it 'returns all messages as unread when last_read_at is nil' do
      participant.update(last_read_at: nil)

      5.times { Message.create!(conversation: conversation, sender: client, content: 'Message') }

      expect(conversation.unread_count_for(musician)).to eq(5)
    end

    it 'automatically marks sender as read when sending a message' do
      participant.update(last_read_at: 1.hour.ago)

      # Create some unread messages
      3.times { Message.create!(conversation: conversation, sender: client, content: 'Unread message') }
      expect(conversation.unread_count_for(musician)).to eq(3)

      # Musician sends a message
      Message.create!(conversation: conversation, sender: musician, content: 'My reply')

      # Musician should now have 0 unread messages (all marked as read)
      expect(conversation.unread_count_for(musician)).to eq(0)
      expect(participant.reload.last_read_at).to be_within(1.second).of(Time.current)
    end
  end

  describe 'UUID support' do
    it 'uses UUID for conversations and conversation_participants' do
      conversation = Conversation.create!(job: job)
      participant = ConversationParticipant.create!(conversation: conversation, user: client)

      expect(conversation.id).to be_a(String)
      expect(conversation.id.length).to eq(36) # UUID format
      expect(participant.id).to be_a(String)
      expect(participant.id.length).to eq(36)

      # to_param returns UUID
      expect(conversation.to_param).to eq(conversation.id.to_s)
      expect(participant.to_param).to eq(participant.id.to_s)

      # find_by_uuid works
      found = Conversation.find_by_uuid(conversation.id)
      expect(found).to eq(conversation)
    end

    it 'message to_param returns uuid after reload' do
      conversation = Conversation.create!(job: job)
      message = Message.create!(conversation: conversation, sender: client, content: 'Test')

      # UUID is generated by PostgreSQL default, need to reload to see it
      message.reload

      expect(message.uuid).to be_present
      expect(message.uuid.length).to eq(36) # UUID format
      expect(message.to_param).to eq(message.uuid)
    end
  end

  describe 'Database constraints' do
    it 'enforces XOR parent constraint at the database level' do
      proposal = Proposal.create!(job: job, musician: musician, cover_message: 'I can help', quote_total_jpy: 50000, delivery_days: 7)
      contract = Contract.create!(proposal: proposal, client: client, musician: musician, escrow_total_jpy: 50000)
      conversation = Conversation.create!(job: job)

      expect {
        conversation.update_column(:contract_id, contract.id)
      }.to raise_error(ActiveRecord::StatementInvalid, /conversations_job_or_contract/)
    end

    it 'prevents duplicate participants via the unique index' do
      conversation = Conversation.create!(job: job)
      participant = ConversationParticipant.new(conversation: conversation, user: client)
      participant.save(validate: false)

      expect {
        duplicate = ConversationParticipant.new(conversation: conversation, user: client)
        duplicate.save(validate: false)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'rejects messages pointing to non-existent conversations' do
      expect {
        message = Message.new(conversation_id: SecureRandom.uuid, sender: client, content: 'Broken reference')
        message.save(validate: false)
      }.to raise_error(ActiveRecord::InvalidForeignKey)
    end
  end

  describe 'Cascade delete behavior' do
    it 'deletes conversation_participants and messages when conversation is deleted' do
      conversation = Conversation.create!(job: job)
      participant = ConversationParticipant.create!(conversation: conversation, user: client)
      message = Message.create!(conversation: conversation, sender: client, content: 'Test')

      expect { conversation.destroy }.to change { ConversationParticipant.count }.by(-1)
        .and change { Message.count }.by(-1)
    end

    it 'deletes conversations when job is deleted' do
      conversation = Conversation.create!(job: job)

      expect { job.destroy }.to change { Conversation.count }.by(-1)
    end

    it 'deletes conversations when contract is deleted' do
      proposal = Proposal.create!(job: job, musician: musician, cover_message: 'Test', quote_total_jpy: 10000, delivery_days: 7)
      contract = Contract.create!(proposal: proposal, client: client, musician: musician, escrow_total_jpy: 10000)
      conversation = Conversation.create!(contract: contract)

      expect { contract.destroy }.to change { Conversation.count }.by(-1)
    end

    it 'deletes conversation_participants when user is deleted' do
      conversation = Conversation.create!(job: job)
      temp_user = User.create!(email: 'temp@example.com', password: 'password123')
      participant = ConversationParticipant.create!(conversation: conversation, user: temp_user)

      expect { temp_user.destroy }.to change { ConversationParticipant.count }.by(-1)
    end
  end

  describe 'User associations' do
    it 'allows user to access their conversations through participants' do
      conversation1 = Conversation.create!(job: job)
      conversation2 = Conversation.create!(job: job)
      other_conversation = Conversation.create!(job: job)

      ConversationParticipant.create!(conversation: conversation1, user: client)
      ConversationParticipant.create!(conversation: conversation2, user: client)
      ConversationParticipant.create!(conversation: other_conversation, user: musician)

      expect(client.conversations).to include(conversation1, conversation2)
      expect(client.conversations).not_to include(other_conversation)
      expect(musician.conversations).to include(other_conversation)
      expect(musician.conversations).not_to include(conversation1, conversation2)
    end

    it 'allows user to access their sent messages' do
      conversation = Conversation.create!(job: job)
      message1 = Message.create!(conversation: conversation, sender: client, content: 'Message 1')
      message2 = Message.create!(conversation: conversation, sender: client, content: 'Message 2')
      musician_message = Message.create!(conversation: conversation, sender: musician, content: 'Musician message')

      expect(client.sent_messages).to include(message1, message2)
      expect(client.sent_messages).not_to include(musician_message)
      expect(musician.sent_messages).to include(musician_message)
      expect(musician.sent_messages).not_to include(message1, message2)
    end
  end
end
