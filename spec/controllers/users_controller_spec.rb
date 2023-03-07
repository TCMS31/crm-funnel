# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  describe 'GET #index' do
    it 'assigns @users in reverse chronological order' do
      user1 = FactoryBot.create(:user, created_at: 1.hour.ago)
      user2 = FactoryBot.create(:user, created_at: 1.day.ago)
      user3 = FactoryBot.create(:user, created_at: 1.week.ago)
      get :index
      expect(assigns(:users)).to eq([user1, user2, user3])
    end

    it 'renders the index template' do
      get :index
      expect(response).to render_template(:index)
    end
  end

  describe 'GET #show' do
    it 'assigns the requested user to @user' do
      user = FactoryBot.create(:user)
      get :show, params: { id: user.id }
      expect(assigns(:user)).to eq(user)
    end

    it 'renders the show template' do
      user = FactoryBot.create(:user)
      get :show, params: { id: user.id }
      expect(response).to render_template(:show)
    end
  end

  describe 'GET #new' do
    it 'assigns a new user to @user' do
      get :new
      expect(assigns(:user)).to be_a_new(User)
    end

    it 'renders the new template' do
      get :new
      expect(response).to render_template(:new)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new user' do
        expect do
          post :create, params: { user: FactoryBot.attributes_for(:user) }
        end.to change(User, :count).by(1)
      end

      it 'redirects to the users index page' do
        post :create, params: { user: FactoryBot.attributes_for(:user) }
        expect(response).to redirect_to(users_path)
      end
    end

    context 'with invalid params' do
      it 'does not create a new user' do
        expect do
          post :create, params: { user: FactoryBot.attributes_for(:user, email: nil) }
        end.not_to change(User, :count)
      end

      it 'renders the new template with unprocessable entity status' do
        post :create, params: { user: FactoryBot.attributes_for(:user, email: nil) }
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested user to @user' do
      user = FactoryBot.create(:user)
      get :edit, params: { id: user.id }
      expect(assigns(:user)).to eq(user)
    end

    it 'renders the edit template' do
      user = FactoryBot.create(:user)
      get :edit, params: { id: user.id }
      expect(response).to render_template(:edit)
    end
  end
end
