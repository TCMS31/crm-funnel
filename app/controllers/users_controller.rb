# frozen_string_literal: true

# CRUD for contacts. `User` is the schema's name for a person in the CRM; it is
# not an authenticated account.
class UsersController < ApplicationController
  PER_PAGE = 25

  before_action :set_user, only: %i[show edit update destroy]

  def index
    @users = User.recent.includes(:company).page(params[:page]).per(PER_PAGE)
  end

  def show
    @deals = @user.deals.for_index
  end

  def new
    @user = User.new
  end

  def edit; end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to users_path, notice: 'Contact was successfully created.'
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(user_params)
      redirect_to users_path, notice: 'Contact was successfully updated.'
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.destroy
      redirect_to users_path, notice: 'Contact was successfully deleted.'
    else
      redirect_to users_path, alert: @user.errors.full_messages.to_sentence
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone_number, :company_id)
  end
end
