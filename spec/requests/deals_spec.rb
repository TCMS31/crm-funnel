# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Deals' do
  describe 'GET /deals' do
    it 'lists deals with their current stage and hides the empty state' do
      create(:deal, :staged, stages: %w[Lead Diligence], probability: 65)

      get deals_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Diligence')
      expect(response.body).not_to include('No deals in the pipeline yet')
    end

    it 'renders a real table with a header cell for every column' do
      create(:deal, :staged, stages: %w[Lead])

      get deals_path

      table = response.parsed_body.at_css('table.data-table')
      expect(table.css('thead th[scope="col"]').size).to eq(6)
      expect(table.css('tbody tr td').size).to eq(6)
    end

    it 'shows the empty state only when there really are no deals' do
      get deals_path
      expect(response.body).to include('No deals in the pipeline yet')
    end

    it 'paginates instead of rendering every deal' do
      create_list(:deal, DealsController::PER_PAGE + 3)

      get deals_path

      expect(response.body.scan('class="data-table__row"').size).to eq(DealsController::PER_PAGE)
    end
  end

  describe 'GET /deals/new' do
    # Regression: this action assigned @deal but the template rendered
    # @deal_history, so every request 500'd with "First argument in form cannot
    # contain nil or be empty".
    it 'renders the form' do
      get new_deal_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Opening stage')
    end
  end

  describe 'POST /deals' do
    let(:user) { create(:user) }
    let(:company) { create(:company) }

    it 'opens a deal at the requested stage' do
      expect do
        post deals_path,
             params: { deal: { user_id: user.id, company_id: company.id, probability: 45, stage: 'Diligence' } }
      end.to change(Deal, :count).by(1).and change(DealHistory, :count).by(1)

      expect(Deal.last.current_deal_stage).to eq('Diligence')
      follow_redirect!
      expect(response.body).to include('Deal was successfully created.')
    end

    it 're-renders the form with the error when the probability is out of range' do
      post deals_path, params: { deal: { user_id: user.id, company_id: company.id, probability: 140 } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Probability')
    end
  end

  describe 'GET /deals/:id' do
    it 'shows the whole stage history in order' do
      deal = create(:deal, :staged, stages: %w[Lead Contacted Closed])

      get deal_path(deal)

      expect(response).to have_http_status(:ok)
      history = response.body.split('Stage history').last
      expect(history.index('Lead')).to be < history.index('Contacted')
      expect(history.index('Contacted')).to be < history.index('Closed')
    end

    it 'renders the not-found page for an unknown deal' do
      get deal_path(id: 0)

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include('Page not found')
    end
  end
end
