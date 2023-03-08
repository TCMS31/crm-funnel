# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Crm::DealOpener do
  let(:user) { FactoryBot.create(:user) }
  let(:company) { FactoryBot.create(:company) }
  let(:deal) { Deal.new(user: user, company: company, probability: 25) }

  it 'saves the deal and its opening stage entry' do
    expect(described_class.new(deal, stage: 'Contacted').call).to be(true)
    expect(deal.reload.deal_histories.map(&:stage)).to eq(['Contacted'])
  end

  it 'defaults to the first funnel stage' do
    described_class.new(deal).call
    expect(deal.deal_histories.first.stage).to eq('Lead')
  end

  it 'accepts any casing of a stage name' do
    described_class.new(deal, stage: 'rEjEcTeD').call
    expect(deal.deal_histories.first.stage).to eq('Rejected')
  end

  it 'falls back to the default rather than raising on an unknown stage' do
    described_class.new(deal, stage: 'Negotiating').call
    expect(deal.deal_histories.first.stage).to eq('Lead')
  end

  context 'when the deal is invalid' do
    let(:deal) { Deal.new(user: user, company: company, probability: 500) }

    it 'returns false and writes nothing at all' do
      expect { expect(described_class.new(deal).call).to be(false) }
        .to not_change(Deal, :count).and not_change(DealHistory, :count)
    end
  end
end
