# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Deal stage history', type: :request do
  let!(:deal) { create(:deal, :staged, stages: %w[Lead], probability: 50) }

  it 'renders the move-stage form for a deal' do
    get new_deal_history_path(deal)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Move stage')
  end

  it 'appends a stage entry and redirects back to the deal' do
    expect do
      post deal_histories_path(deal), params: { deal_history: { stage: 'Contacted' } }
    end.to change { deal.deal_histories.count }.by(1)

    expect(response).to redirect_to(deal_path(deal))
    expect(deal.reload.current_deal_stage).to eq('Contacted')
  end

  it 'moves the deal from one funnel stage to the other, without inflating the total' do
    expect(Crm::FunnelReport.new.stage('Lead').deal_count).to eq(1)

    post deal_histories_path(deal), params: { deal_history: { stage: 'Contacted' } }

    report = Crm::FunnelReport.new
    expect(report.stage('Lead').deal_count).to eq(0)
    expect(report.stage('Contacted').deal_count).to eq(1)
    expect(report.total_deals).to eq(1)
  end

  it 'never rewrites history: the earlier stage is still there' do
    post deal_histories_path(deal), params: { deal_history: { stage: 'Closed' } }

    expect(deal.deal_histories.chronological.map(&:stage)).to eq(%w[Lead Closed])
  end

  it 're-renders the form when the stage is not a funnel stage' do
    post deal_histories_path(deal), params: { deal_history: { stage: 'Negotiating' } }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(deal.reload.current_deal_stage).to eq('Lead')
  end
end
