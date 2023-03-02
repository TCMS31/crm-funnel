# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Crm::FunnelReport do
  subject(:report) { described_class.new }

  def deal_at(*stages, probability: 50)
    deal = FactoryBot.create(:deal, probability: probability)
    stages.each_with_index do |stage, index|
      FactoryBot.create(:deal_history, deal: deal, stage: stage, created_at: index.hours.from_now)
    end
    deal
  end

  describe 'counting by current stage' do
    before do
      deal_at('Lead')
      deal_at('Lead')
      deal_at('Contacted')
      # This deal has been in three stages. A report that grouped deal_histories
      # would count it three times; it belongs only in Diligence.
      deal_at('Lead', 'Contacted', 'Diligence')
      deal_at('Closed')
      deal_at('Rejected')
    end

    it 'counts each deal exactly once, in its latest stage' do
      expect(report.stages.map { |s| [s.name, s.deal_count] }).to eq(
        [['Lead', 2], ['Contacted', 1], ['Diligence', 1], ['Closed', 1], ['Rejected', 1]]
      )
    end

    it 'totals to the number of deals, not the number of history rows' do
      expect(DealHistory.count).to eq(8)
      expect(report.total_deals).to eq(Deal.count).and eq(6)
    end

    it 'lists every stage even when empty' do
      DealHistory.delete_all
      Deal.delete_all
      expect(described_class.new.stages.map(&:name)).to eq(DealHistory.stage_names)
      expect(described_class.new.stages.map(&:deal_count)).to all(eq(0))
    end
  end

  describe 'derived figures' do
    before do
      deal_at('Lead', probability: 10)
      deal_at('Contacted', probability: 40)
      deal_at('Diligence', probability: 90)
      deal_at('Closed', probability: 100)
      deal_at('Closed', probability: 100)
      deal_at('Closed', probability: 100)
      deal_at('Rejected', probability: 0)
    end

    it 'counts open deals as the three non-terminal stages' do
      expect(report.open_deals).to eq(3)
    end

    it 'expects (10 + 40 + 90) / 100 = 1.4 open deals to close' do
      expect(report.expected_open_deals).to eq(1.4)
    end

    it 'reports win rate over decided deals only (3 won of 4 decided)' do
      expect(report.win_rate).to eq(75.0)
    end

    it 'averages probability within a stage' do
      expect(report.stage('Closed').average_probability).to eq(100.0)
      expect(report.stage('Lead').average_probability).to eq(10.0)
    end

    it 'scales the funnel bars against the widest stage' do
      expect(report.relative_width(report.stage('Closed'))).to eq(100.0)
      expect(report.relative_width(report.stage('Lead'))).to eq(33.3)
    end
  end

  describe 'deals that were never staged' do
    before do
      deal_at('Lead')
      FactoryBot.create(:deal)
    end

    it 'reports them separately rather than folding them into Lead' do
      expect(report.unstaged_deals).to eq(1)
      expect(report.stage('Lead').deal_count).to eq(1)
      expect(report.total_deals).to eq(2)
    end
  end

  describe 'an empty pipeline' do
    it 'returns zeroes rather than dividing by zero' do
      expect(report.total_deals).to eq(0)
      expect(report.win_rate).to eq(0.0)
      expect(report.expected_open_deals).to eq(0.0)
      expect(report.relative_width(report.stage('Lead'))).to eq(0)
    end
  end
end
