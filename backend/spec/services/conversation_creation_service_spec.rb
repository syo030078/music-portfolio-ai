require 'rails_helper'

RSpec.describe ConversationCreationService do
  let(:client) { User.create!(email: 'client@example.com', password: 'password123', is_client: true).reload }
  let(:musician) { User.create!(email: 'musician@example.com', password: 'password123', is_musician: true).reload }
  let(:outsider) { User.create!(email: 'outsider@example.com', password: 'password123', is_musician: true).reload }
  let(:job) do
    Job.create!(
      client: client,
      title: 'Need a remix',
      description: 'Test description',
      status: 'published',
      published_at: Time.current
    ).reload
  end

  describe '.call with job_uuid' do
    it '案件のクライアントと操作者を参加者にして会話を作る' do
      result = described_class.call(actor: musician, job_uuid: job.uuid)

      expect(result.success?).to be true
      expect(result.conversation.job).to eq(job)
      expect(result.conversation.participants).to contain_exactly(client, musician)
    end

    it '案件が存在しなければ 404' do
      result = described_class.call(actor: musician, job_uuid: SecureRandom.uuid)

      expect(result.success?).to be false
      expect(result.status).to eq(:not_found)
    end

    it '公開されていない案件は 404（存在を明かさない）' do
      job.update!(status: 'draft')

      result = described_class.call(actor: musician, job_uuid: job.uuid)

      expect(result.success?).to be false
      expect(result.status).to eq(:not_found)
    end

    it '自分の案件には会話を作れない' do
      result = described_class.call(actor: client, job_uuid: job.uuid)

      expect(result.success?).to be false
      expect(result.status).to eq(:unprocessable_entity)
    end
  end

  describe '.call with contract_uuid' do
    let(:proposal) do
      Proposal.create!(job: job, musician: musician, quote_total_jpy: 50_000, delivery_days: 7, cover_message: 'よろしく')
    end
    let(:contract) do
      Contract.create!(proposal: proposal, client: client, musician: musician, escrow_total_jpy: 50_000, status: 'active').reload
    end

    it '契約の当事者なら、クライアントとミュージシャンを参加者にして会話を作る' do
      result = described_class.call(actor: musician, contract_uuid: contract.uuid)

      expect(result.success?).to be true
      expect(result.conversation.contract).to eq(contract)
      expect(result.conversation.participants).to contain_exactly(client, musician)
    end

    it '契約の当事者でなければ 403' do
      result = described_class.call(actor: outsider, contract_uuid: contract.uuid)

      expect(result.success?).to be false
      expect(result.status).to eq(:forbidden)
    end

    it '契約が存在しなければ 404' do
      result = described_class.call(actor: musician, contract_uuid: SecureRandom.uuid)

      expect(result.success?).to be false
      expect(result.status).to eq(:not_found)
    end
  end

  describe '親リソースの指定' do
    it 'job_uuid と contract_uuid のどちらもなければ 422' do
      result = described_class.call(actor: musician)

      expect(result.success?).to be false
      expect(result.status).to eq(:unprocessable_entity)
    end

    it 'job_uuid と contract_uuid の両方があれば 422' do
      result = described_class.call(actor: musician, job_uuid: job.uuid, contract_uuid: SecureRandom.uuid)

      expect(result.success?).to be false
      expect(result.status).to eq(:unprocessable_entity)
    end
  end

  describe 'トランザクション' do
    it '参加者の追加に失敗したら会話も作られない' do
      job
      allow(ConversationParticipant).to receive(:create!)
        .and_raise(ActiveRecord::RecordInvalid.new(ConversationParticipant.new))

      expect { described_class.call(actor: musician, job_uuid: job.uuid) }
        .not_to change(Conversation, :count)
    end
  end
end
