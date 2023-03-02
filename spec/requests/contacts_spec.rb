# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Contacts and companies', type: :request do
  describe 'GET /users' do
    it 'lists contacts with their company' do
      create(:user, first_name: 'Ada', last_name: 'Lovelace', company: create(:company, name: 'Initech'))

      get users_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Ada Lovelace').and include('Initech')
    end
  end

  describe 'GET /users/:id' do
    it 'shows the contact and their deals' do
      user = create(:user)
      create(:deal, :staged, stages: %w[Diligence], user: user)

      get user_path(user)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(user.full_name).and include('Diligence')
    end
  end

  describe 'GET /users/:id/edit' do
    # Regression: the company select only offered the 200 newest companies, so
    # editing a contact at an older company showed a blank choice and saving
    # the form detached them from it.
    it 'keeps the current company selectable however old it is' do
      company = create(:company, name: 'Aardvark Holdings', created_at: 1.year.ago)
      user = create(:user, company: company)
      create_list(:company, 200)

      get edit_user_path(user)

      selected = Nokogiri::HTML(response.body).at_css('#user_company_id option[selected]')
      expect(selected&.text).to eq('Aardvark Holdings')
    end
  end

  describe 'POST /users' do
    it 'rejects a duplicate e-mail and re-renders the form with the reason' do
      create(:user, email: 'ada@example.com')

      post users_path, params: { user: attributes_for(:user, email: 'ADA@example.com') }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Email has already been taken')
    end
  end

  describe 'GET /companies' do
    it 'lists companies with contact and deal counts' do
      company = create(:company, name: 'Initech')
      create_list(:user, 2, company: company)
      create(:deal, company: company)

      get companies_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Initech')
      expect(Company.with_counts.first.users_count).to eq(2)
      expect(Company.with_counts.first.deals_count).to eq(1)
    end
  end

  describe 'DELETE /companies/:id' do
    it 'detaches deals and contacts instead of destroying funnel history' do
      company = create(:company)
      deal = create(:deal, :staged, stages: %w[Closed], company: company)

      delete company_path(company)

      expect(response).to redirect_to(companies_path)
      expect(deal.reload.company_id).to be_nil
      expect(deal.deal_histories.count).to eq(1)
    end
  end

  describe 'flash messages' do
    it 'announces a notice politely and an alert assertively' do
      post users_path, params: { user: attributes_for(:user) }
      follow_redirect!
      expect(response.body).to include('role="status"')

      company = create(:company)
      allow(Company).to receive(:find).and_return(company)
      allow(company).to receive(:destroy).and_return(false)
      delete company_path(company)
      follow_redirect!
      expect(response.body).to include('role="alert"')
    end
  end
end
