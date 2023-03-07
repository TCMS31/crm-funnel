# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DealsController, type: :controller do
  describe 'GET #index' do
    let(:deal) { FactoryBot.create(:deal) }

    it 'returns a successful response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns @deals in reverse chronological order' do
      deals = create_list(:deal, 3)
      get :index
      expect(assigns(:deals)).to eq(deals.reverse)
    end
  end

  describe 'GET #show' do
    let(:deal) { FactoryBot.create(:deal) }

    it 'returns a successful response' do
      get :show, params: { id: deal.id }
      expect(response).to be_successful
    end

    it 'assigns @deal to the correct deal' do
      get :show, params: { id: deal.id }
      expect(assigns(:deal)).to eq(deal)
    end
  end

  describe 'GET #new' do
    it 'returns a successful response' do
      get :new
      expect(response).to be_successful
    end

    it 'assigns a new deal to @deal' do
      get :new
      expect(assigns(:deal)).to be_a_new(Deal)
    end
  end

  describe 'POST #create' do
    let(:user) { FactoryBot.create(:user) }
    let(:company) { FactoryBot.create(:company) }

    context 'with valid attributes' do
      let(:valid_attributes) { { user_id: user.id, company_id: company.id, probability: 40 } }

      it 'creates the deal and its opening stage entry together' do
        expect do
          post :create, params: { deal: valid_attributes.merge(stage: 'Contacted') }
        end.to change(Deal, :count).by(1).and change(DealHistory, :count).by(1)

        expect(Deal.last.current_deal_stage).to eq('Contacted')
        expect(response).to redirect_to(deal_path(Deal.last))
      end

      it 'defaults to the first funnel stage when none is given' do
        post :create, params: { deal: valid_attributes }
        expect(Deal.last.current_deal_stage).to eq(Crm::DealOpener::DEFAULT_STAGE)
      end
    end

    context 'with invalid attributes' do
      let(:invalid_attributes) { { user_id: user.id, company_id: company.id, probability: 150 } }

      it 'does not create a deal or a stage entry' do
        expect do
          post :create, params: { deal: invalid_attributes }
        end.to not_change(Deal, :count).and not_change(DealHistory, :count)
      end

      it 'renders the new deal form with an unprocessable entity status' do
        post :create, params: { deal: invalid_attributes }
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash[:alert]).to match(/Probability/)
      end
    end
  end
end
