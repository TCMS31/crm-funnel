# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Deal, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:probability) }

    it 'accepts only whole percentages from 0 to 100' do
      expect(subject).to validate_numericality_of(:probability)
        .is_greater_than_or_equal_to(0).is_less_than_or_equal_to(100).only_integer
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user).required(false) }
    it { is_expected.to belong_to(:company).required(false) }
    it { is_expected.to have_many(:deal_histories).dependent(:destroy) }
  end

  describe '#current_deal_stage' do
    let(:deal) { FactoryBot.create(:deal) }

    context 'when the deal has no history' do
      it 'returns nil' do
        expect(deal.current_deal_stage).to be_nil
      end
    end

    context 'when the deal has been through several stages' do
      before do
        FactoryBot.create(:deal_history, deal: deal, stage: 'Lead', created_at: 3.days.ago)
        FactoryBot.create(:deal_history, deal: deal, stage: 'Contacted', created_at: 2.days.ago)
        FactoryBot.create(:deal_history, deal: deal, stage: 'Diligence', created_at: 1.day.ago)
      end

      it 'returns the most recent stage, not the highest-numbered one' do
        expect(deal.reload.current_deal_stage).to eq('Diligence')
      end

      it 'returns the same answer whether or not the stage was pre-joined' do
        expect(described_class.with_current_stage.find(deal.id).current_deal_stage).to eq('Diligence')
      end

      it 'follows a backwards move' do
        FactoryBot.create(:deal_history, deal: deal, stage: 'Lead', created_at: 1.hour.ago)
        expect(deal.reload.current_deal_stage).to eq('Lead')
      end
    end
  end

  describe '.with_current_stage' do
    it 'resolves every deal stage without a query per row' do
      3.times do
        deal = FactoryBot.create(:deal)
        FactoryBot.create(:deal_history, deal: deal, stage: 'Closed')
      end

      queries = 0
      subscription = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
        queries += 1 unless payload[:name].to_s.match?(/SCHEMA|TRANSACTION/)
      end
      stages = described_class.with_current_stage.to_a.map(&:current_deal_stage)
      ActiveSupport::Notifications.unsubscribe(subscription)

      expect(stages).to all(eq('Closed'))
      expect(queries).to eq(1)
    end

    it 'leaves the stage nil for a deal with no history' do
      FactoryBot.create(:deal)
      expect(described_class.with_current_stage.first.current_deal_stage).to be_nil
    end
  end

  describe '#open?' do
    it 'is true in the three non-terminal stages and false once decided' do
      open_deal = FactoryBot.create(:deal)
      FactoryBot.create(:deal_history, deal: open_deal, stage: 'Diligence')
      closed_deal = FactoryBot.create(:deal)
      FactoryBot.create(:deal_history, deal: closed_deal, stage: 'Closed')

      expect(open_deal.reload).to be_open
      expect(closed_deal.reload).not_to be_open
    end
  end
end
