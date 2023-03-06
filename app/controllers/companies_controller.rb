# frozen_string_literal: true

# CRUD for the organisations deals are attached to.
class CompaniesController < ApplicationController
  PER_PAGE = 25

  before_action :set_company, only: %i[edit update destroy]

  def index
    @companies = Company.with_counts.recent.page(params[:page]).per(PER_PAGE)
  end

  def new
    @company = Company.new
  end

  def edit; end

  def create
    @company = Company.new(company_params)

    if @company.save
      redirect_to companies_path, notice: 'Company was successfully created.'
    else
      flash.now[:alert] = @company.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @company.update(company_params)
      redirect_to companies_path, notice: 'Company was successfully updated.'
    else
      flash.now[:alert] = @company.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @company.destroy
      redirect_to companies_path, notice: 'Company was successfully deleted.'
    else
      redirect_to companies_path, alert: @company.errors.full_messages.to_sentence
    end
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end

  def company_params
    params.require(:company).permit(:name)
  end
end
