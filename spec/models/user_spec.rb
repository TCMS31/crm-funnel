# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:email) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:deals).dependent(:nullify) }
    it { is_expected.to belong_to(:company).required(false) }
  end

  describe '#full_name' do
    let(:user) { FactoryBot.create(:user, first_name: 'John', last_name: 'Doe') }

    it "returns the user's full name" do
      expect(user.full_name).to eq('John Doe')
    end
  end
end
