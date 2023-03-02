# frozen_string_literal: true

FactoryBot.define do
  factory :company do
    # Company names are unique (case-insensitively), and Faker repeats itself
    # often enough to make large lists flaky without the sequence suffix.
    sequence(:name) { |n| "#{Faker::Company.name} #{n}" }
  end
end
