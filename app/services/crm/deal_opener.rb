# frozen_string_literal: true

module Crm
  # Opening a deal means two writes that must succeed together: the deal row and
  # its first stage entry. A deal with no history has no position in the funnel,
  # so the pair is committed in one transaction.
  class DealOpener
    DEFAULT_STAGE = DealHistory::STAGES.keys.first.to_s

    def initialize(deal, stage: nil)
      @deal = deal
      @stage = stage
    end

    def call
      ApplicationRecord.transaction do
        raise ActiveRecord::Rollback unless @deal.save

        @deal.deal_histories.create!(stage: stage_name)
      end

      @deal.persisted?
    end

    def stage_name
      DealHistory.stage_names.find { |name| name.casecmp?(@stage.to_s) } || DEFAULT_STAGE
    end
  end
end
