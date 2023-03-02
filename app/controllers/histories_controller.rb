# frozen_string_literal: true

# Appends a stage entry to a deal. History is append-only, so there is no
# update or destroy: a mistake is corrected by recording the correct stage.
class HistoriesController < ApplicationController
  before_action :set_deal

  def new
    @deal_history = @deal.deal_histories.new
  end

  def create
    @deal_history = @deal.deal_histories.new(deal_history_params)

    if @deal_history.save
      redirect_to deal_path(@deal), notice: "Deal moved to #{@deal_history.stage}."
    else
      flash.now[:alert] = @deal_history.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_deal
    @deal = Deal.find(params[:deal_id])
  end

  def deal_history_params
    params.require(:deal_history).permit(:stage)
  end
end
