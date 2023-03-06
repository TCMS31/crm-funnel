# frozen_string_literal: true

# Deals are the pipeline rows. Creating one opens it at a starting stage;
# moving it along afterwards is HistoriesController's job.
class DealsController < ApplicationController
  PER_PAGE = 20

  before_action :set_deal, only: %i[show]

  def index
    @deals = Deal.for_index.page(params[:page]).per(PER_PAGE)
  end

  def show
    @deal_histories = @deal.deal_histories.includes(:deal)
  end

  def new
    @deal = Deal.new(probability: 0)
  end

  def create
    @deal = Deal.new(deal_params)

    if Crm::DealOpener.new(@deal, stage: params.dig(:deal, :stage)).call
      redirect_to deal_path(@deal), notice: 'Deal was successfully created.'
    else
      flash.now[:alert] = @deal.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_deal
    @deal = Deal.with_current_stage.find(params[:id])
  end

  def deal_params
    params.require(:deal).permit(:user_id, :company_id, :probability)
  end
end
