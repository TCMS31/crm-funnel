# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CompaniesController, type: :controller do
  describe 'GET #index' do
    let(:company) { FactoryBot.create(:company) }

    it 'assigns @companies and renders the index template' do
      get :index
      expect(response).to render_template(:index)
    end
  end

  describe 'GET #new' do
    it 'assigns @company and renders the new template' do
      get :new
      expect(assigns(:company)).to be_a_new(Company)
      expect(response).to render_template(:new)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new company and redirects to the index page' do
        expect do
          post :create, params: { company: attributes_for(:company) }
        end.to change(Company, :count).by(1)
        expect(response).to redirect_to(companies_path)
        expect(flash[:notice]).to eq('Company was successfully created.')
      end
    end

    context 'with invalid params' do
      it 'does not create a new company and renders the new template with errors' do
        expect do
          post :create, params: { company: { name: '' } }
        end.not_to change(Company, :count)
        expect(response).to render_template(:new)
        expect(assigns(:company).errors.full_messages).to include("Name can't be blank")
      end
    end
  end

  describe 'GET #edit' do
    let(:company) { FactoryBot.create(:company) }

    it 'assigns @company and renders the edit template' do
      get :edit, params: { id: company.id }
      expect(assigns(:company)).to eq(company)
      expect(response).to render_template(:edit)
    end
  end

  describe 'PATCH #update' do
    context 'with valid params' do
      let(:company) { FactoryBot.create(:company) }

      it 'updates the company and redirects to the index page' do
        patch :update, params: { id: company.id, company: { name: 'New Company Name' } }
        expect(assigns(:company).name).to eq('New Company Name')
        expect(response).to redirect_to(companies_path)
        expect(flash[:notice]).to eq('Company was successfully updated.')
      end
    end

    context 'with invalid params' do
      let(:company) { FactoryBot.create(:company) }

      it 'does not update the company and renders the edit template with errors' do
        old_name = company.name
        put :update, params: { id: company.id, company: { name: '' } }
        expect(company.name).to eq(old_name)
        expect(response).to render_template(:edit)
      end
    end
  end
end
