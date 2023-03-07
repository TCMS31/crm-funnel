# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DealHistory, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:stage) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:deal) }
  end

  describe 'enums' do
    it do
      expect(subject).to define_enum_for(:stage)
        .with_values(Lead: 0, Contacted: 1, Diligence: 2, Closed: 3, Rejected: 4)
    end
  end
end
