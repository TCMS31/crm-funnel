# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HistoriesController, type: :controller do
  let(:deal) { FactoryBot.create(:deal, :staged, stages: %w[Lead]) }

  describe 'GET #new' do
    it 'renders the new template' do
      get :new, params: { deal_id: deal.id }
      expect(response).to render_template(:new)
    end

    it 'assigns a new DealHistory belonging to the deal in the URL' do
      get :new, params: { deal_id: deal.id }

      expect(assigns(:deal_history)).to be_a_new(DealHistory)
      expect(assigns(:deal)).to eq(deal)
    end
  end
end
