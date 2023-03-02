# frozen_string_literal: true

FactoryBot.define do
  factory :deal do
    probability { rand(0..100) }
    user
    company

    trait :staged do
      transient { stages { %w[Lead] } }

      after(:create) do |deal, evaluator|
        evaluator.stages.each_with_index do |stage, index|
          create(:deal_history, deal: deal, stage: stage, created_at: index.minutes.from_now)
        end
      end
    end
  end
end
