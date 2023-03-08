# frozen_string_literal: true

require 'rails_helper'

# Request specs render views for real. The controller specs did not, which is
# how a template error on /deals/new stayed green for the whole project.
RSpec.describe 'Funnel dashboard', type: :request do
  it 'renders the funnel with a count for every stage' do
    create(:deal, :staged, stages: %w[Lead])
    create(:deal, :staged, stages: %w[Lead Contacted])
    create(:deal, :staged, stages: %w[Lead Contacted Closed], probability: 100)

    get root_path

    expect(response).to have_http_status(:ok)
    DealHistory.stage_names.each { |stage| expect(response.body).to include(stage) }
    expect(response.body).to include('Pipeline funnel')
  end

  it 'shows a bounded, preloaded list of the latest stage moves' do
    create_list(:deal, DashboardController::RECENT_MOVES + 2, :staged, stages: %w[Lead])

    get root_path

    expect(response.body.scan('class="table table--moves"').size).to eq(DashboardController::RECENT_MOVES)
  end

  it 'renders an all-zero funnel without blowing up on an empty database' do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Win rate')
  end
end
