# frozen_string_literal: true

FactoryBot.define do
  factory :deal_history do
    deal
    stage { DealHistory.stage_names.first }
  end
end
