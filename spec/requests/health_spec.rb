# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Health probe', type: :request do
  it 'reports ok when the database answers' do
    get health_path

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq('status' => 'ok', 'database' => 'ok')
  end

  it 'reports unavailable when the database does not' do
    allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(ActiveRecord::ConnectionNotEstablished)

    get health_path

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body['status']).to eq('error')
  end
end
