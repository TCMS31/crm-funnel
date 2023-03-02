# frozen_string_literal: true

# The funnel overview: every deal counted once, in its current stage.
class DashboardController < ApplicationController
  RECENT_MOVES = 8

  def show
    @funnel = Crm::FunnelReport.new
    @recent_moves = DealHistory.latest_moves(RECENT_MOVES)
  end
end
