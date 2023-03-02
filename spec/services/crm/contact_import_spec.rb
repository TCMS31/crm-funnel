# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Crm::ContactImport do
  subject(:import) { described_class.call(source: source, logger: nil) }

  describe 'merging repeated e-mails' do
    # The shipped crm_data.csv repeats 100 e-mails. In 19 of those pairs the
    # second row leaves `company` blank, which used to manufacture a second,
    # company-less deal for the same person.
    let(:source) do
      csv_source([
                   contact_row(email: 'dup@example.com', company: 'Initech', stage: 'Lead', probability: '20'),
                   contact_row(email: 'dup@example.com', company: '', stage: 'Lead', probability: '20')
                 ])
    end

    it 'creates one contact and exactly one deal' do
      import
      expect(User.count).to eq(1)
      expect(Deal.count).to eq(1)
    end

    it 'keeps the company from the row that had one' do
      import
      expect(Deal.first.company.name).to eq('Initech')
    end

    it 'records the repeated stage only once' do
      import
      expect(DealHistory.count).to eq(1)
    end

    it 'counts the merged row' do
      expect(import.duplicate_rows_merged).to eq(1)
    end
  end

  describe 'genuine stage progression' do
    let(:source) do
      csv_source([
                   contact_row(email: 'moving@example.com', stage: 'Lead'),
                   contact_row(email: 'moving@example.com', stage: 'Contacted'),
                   contact_row(email: 'moving@example.com', stage: 'Diligence')
                 ])
    end

    it 'keeps every distinct stage, in order' do
      import
      expect(Deal.first.deal_histories.chronological.map(&:stage)).to eq(%w[Lead Contacted Diligence])
    end

    it 'reports the latest stage as current' do
      import
      expect(Deal.with_current_stage.first.current_deal_stage).to eq('Diligence')
    end
  end

  describe 'probability handling' do
    let(:source) do
      csv_source([
                   contact_row(email: 'high@example.com', probability: '150'),
                   contact_row(email: 'blank@example.com', probability: '')
                 ])
    end

    it 'clamps out-of-range probabilities and says how many it clamped' do
      expect(import.probabilities_clamped).to eq(1)
      expect(User.find_by(email: 'high@example.com').deals.first.probability).to eq(100)
    end

    it 'treats a blank probability as zero' do
      import
      expect(User.find_by(email: 'blank@example.com').deals.first.probability).to eq(0)
    end
  end

  describe 'rejecting unusable rows' do
    let(:source) do
      csv_source([
                   contact_row(email: 'good@example.com'),
                   contact_row(email: ''),
                   contact_row(email: 'not-an-email', first_name: 'X'),
                   contact_row(email: 'nostage@example.com', stage: 'Negotiating')
                 ])
    end

    it 'imports the good row and reports the rest instead of failing the run' do
      expect(import.rows_read).to eq(4)
      expect(import.rows_rejected).to eq(3)
      expect(User.pluck(:email)).to eq(['good@example.com'])
    end

    it 'explains why each row was rejected' do
      reasons = import.rejections.flat_map(&:errors)
      expect(reasons).to include('email is blank')
      expect(reasons).to include(a_string_matching(/malformed/))
      expect(reasons).to include(a_string_matching(/not a known funnel stage/))
    end
  end

  describe 'normalisation' do
    let(:source) do
      csv_source([contact_row(email: '  ADA@Example.COM ', stage: ' diligence ', first_name: ' Ada  Byron ')])
    end

    it 'downcases e-mail, squishes names and accepts any stage casing' do
      import
      user = User.first
      expect(user.email).to eq('ada@example.com')
      expect(user.first_name).to eq('Ada Byron')
      expect(Deal.first.deal_histories.first.stage).to eq('Diligence')
    end
  end

  describe 'idempotency' do
    let(:source) { csv_source([contact_row, contact_row(email: 'second@example.com', company: 'Initech')]) }

    it 'adds nothing on a second run' do
      import
      second = described_class.call(source: source, logger: nil)

      expect(second.contacts_created).to eq(0)
      expect(second.deals_created).to eq(0)
      expect(second.stage_entries_created).to eq(0)
      expect([User.count, Deal.count, DealHistory.count]).to eq([2, 2, 2])
    end

    it 'appends only the new stage when the source moves a deal forward' do
      import
      moved = csv_source([contact_row(stage: 'Lead'), contact_row(stage: 'Contacted')])
      result = described_class.call(source: moved, logger: nil)

      expect(result.stage_entries_created).to eq(1)
      expect(User.find_by(email: 'ada@example.com').deals.first.deal_histories.chronological.map(&:stage))
        .to eq(%w[Lead Contacted])
    end
  end

  describe 'query volume' do
    let(:source) do
      csv_source(Array.new(50) do |i|
        contact_row(email: "contact#{i}@example.com", company: "Company #{i % 5}")
      end)
    end

    it 'stays flat instead of growing with the number of rows' do
      queries = 0
      subscription = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
        queries += 1 unless payload[:name].to_s.match?(/SCHEMA|TRANSACTION/)
      end
      import
      ActiveSupport::Notifications.unsubscribe(subscription)

      expect(Deal.count).to eq(50)
      expect(queries).to be < 15
    end
  end

  describe 'a missing column' do
    let(:source) { csv_source([contact_row], headers: %w[first_name last_name email]) }

    it 'fails loudly rather than importing nothing in silence' do
      expect { import }.to raise_error(Crm::Import::CsvSource::MissingHeadersError, /stage/)
    end
  end
end
