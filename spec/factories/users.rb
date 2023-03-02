# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    sequence(:email) { |n| "contact#{n}@example.com" }
    phone_number { Faker::PhoneNumber.phone_number }
  end
end
